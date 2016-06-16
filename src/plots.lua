function PlotClaim(Split, Player)
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

	local sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local resident = ExecuteStatement(sql, parameter)[1];

	local sql = "SELECT townChunk_id, town_id, owner FROM townChunks WHERE chunkX = ? AND chunkZ = ? AND world = ?" ;
	local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
	local plot = ExecuteStatement(sql, parameters)[1];

	if(plot == nil) then
		Player:SendMessageFailure("You can not claim a plot if you're not inside a town");
	elseif(resident[1] == nil or not plot[2] == resident[1]) then
		Player:SendMessageFailure("You can not claim a plot if you're not part of this town")
	elseif not(plot[3] == nil) then
		local sql = "SELECT player_uuid, player_name FROM residents WHERE player_uuid = ?";
		local parameter = {plot[3]};
		local owner = ExecuteStatement(sql, parameter)[1];

		if(owner[1] == UUID) then
			Player:SendMessageFailure("You already claimed this plot");
		else
			Player:SendMessageFailure("This plot is already claimed by " .. owner[2]);
		end
	else
		local sql = "UPDATE townChunks SET owner = ? WHERE townChunk_id = ?";
		local parameter = {UUID, plot[1]};
		ExecuteStatement(sql, parameter);

		Player:SendMessageSuccess("You succesfully claimed this plot");
	end

	return true;
end

function PlotUnclaim(Split, Player)
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

	local sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local resident = ExecuteStatement(sql, parameter)[1];

	local sql = "SELECT townChunk_id, town_id, owner FROM townChunks WHERE chunkX = ? AND chunkZ = ? AND world = ?" ;
	local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
	local plot = ExecuteStatement(sql, parameters)[1];

	if(plot == nil) then
		Player:SendMessageFailure("You can not unclaim a plot if you're not inside a town");
	elseif(resident[1] == nil or not plot[2] == resident[1]) then
		Player:SendMessageFailure("You can not unclaim a plot if you're not part of this town")
	elseif (plot[3] == nil or not plot[3] == UUID) then
		Player:SendMessageFailure("You can not unclaim a plot that is not yours");
	else
		local sql = "UPDATE townChunks SET owner = NULL WHERE townChunk_id = ?";
		local parameter = {plot[1]};
		ExecuteStatement(sql, parameter);

		Player:SendMessageSuccess("You succesfully unlcaimed this plot");
	end

	return true;
end

function PlotToggleMobs(Split, Player)
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

	local sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local town_id = ExecuteStatement(sql, parameter)[1][1];

	if (town_id == nil) then
		Player:SendMessageFailure("You can't toggle if you're not part of a town");
		return true;
	else
		local sql = "SELECT towns.town_id, towns.town_owner, towns.town_mobs_enabled, townChunks.plot_mobs_enabled FROM towns INNER JOIN townChunks ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ? AND townChunks.world = ?";
		local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
		local plot = ExecuteStatement(sql, parameters)[1];

		local toggle;
		if(plot == nil) then
			Player:SendMessageFailure("You have to be in a plot to toggle it's features");
			return true;
		elseif not(plot[2] == UUID) then
			Player:SendMessageFailure("You can't toggle if you're not the owner of the town");
			return true;
		else
			if not(Split[4] == nil) then --The user wants the plot to inherit the town value
				if not(Split[4] == "inherit") then
					Player:SendMessageFailure("This argument is not understood");
					return true;
				else
					toggle = 2;
				end
			else
				if(plot[4] == 2 and plot[3] == 1) then --plot[4] at 2 means it inherits the town status
					toggle = 0;
				elseif(plot[4] == 2 and plot[3] == 0) then
					toggle = 1;
				elseif(plot[4] == 1) then
					toggle = 0;
				else
					toggle = 1;
				end
			end
		end

		if(toggle == 2) then --The user wants the plot to inherit the town value
			local sql = "UPDATE townChunks SET plot_mobs_enabled = 2 WHERE chunkX = ? AND chunkZ = ? AND world = ?";
			local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
			ExecuteStatement(sql, parameters);

			Player:SendMessageSuccess("Mob spawning now inherits the town value");
		elseif(toggle == 1) then --The user wants the plot to have mob spawning enabled
			local sql = "UPDATE townChunks SET plot_mobs_enabled = 1 WHERE chunkX = ? AND chunkZ = ? AND world = ?";
			local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
			ExecuteStatement(sql, parameters);

			Player:SendMessageSuccess("Mob spawning is now enabled in this plot");
		else --The user wants the plot to have mob spawning disabled
			local sql = "UPDATE townChunks SET plot_mobs_enabled = 0 WHERE chunkX = ? AND chunkZ = ? AND world = ?";
			local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
			ExecuteStatement(sql, parameters);

			Player:SendMessageSuccess("Mob spawning is now disabled in this plot");
		end

		return true;
	end
end
