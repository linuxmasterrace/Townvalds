function PlotToggleMobs(Split, Player)
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

	local sql = "SELECT towns.town_mobs_enabled, townChunks.plot_mobs_enabled FROM towns INNER JOIN townChunks ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ?";
	local parameters = {Player:GetChunkX(), Player:GetChunkZ()};
	local plot = ExecuteStatement(sql, parameters)[1];

	local toggle;
	if(plot == nil) then
		Player:SendMessageFailure("You have to be in a plot to toggle it's features");
	else
		if not(Split[4] == nil) then --The user wants the plot to inherit the town value
			if not(Split[4] == "inherit") then
				Player:SendMessageFailure("This argument is not understood");
				return true;
			else
				toggle = 2;
			end
		else
			if(plot[2] == 2 and plot[1] == 1) then --plot[2] at 2 means it inherits the town status
				toggle = 0;
			elseif(plot[2] == 2 and plot[1] == 0) then
				toggle = 1;
			elseif(plot[2] == 1) then
				toggle = 0;
			else
				toggle = 1;
			end
		end
	end

	if(toggle == 2) then --The user wants the plot to inherit the town value
		local sql = "UPDATE townChunks SET plot_mobs_enabled = 2 WHERE chunkX = ? AND chunkZ = ?";
		local parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		ExecuteStatement(sql, parameters);

		Player:SendMessageSuccess("Mob spawning now inherits the town value");
	elseif(toggle == 1) then --The user wants the plot to have mob spawning enabled
		local sql = "UPDATE townChunks SET plot_mobs_enabled = 1 WHERE chunkX = ? AND chunkZ = ?";
		local parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		ExecuteStatement(sql, parameters);

		Player:SendMessageSuccess("Mob spawning is now enabled in this plot");
	else --The user wants the plot to have mob spawning disabled
		local sql = "UPDATE townChunks SET plot_mobs_enabled = 0 WHERE chunkX = ? AND chunkZ = ?";
		local parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		ExecuteStatement(sql, parameters);

		Player:SendMessageSuccess("Mob spawning is now disabled in this plot");
	end
	return true;
end
