function PlotClaim(Split, Player)
	local UUID = Player:GetUUID();

	local sql = "SELECT town_id FROM town_residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local resident = ExecuteStatement(sql, parameter)[1];

	local sql = "SELECT townChunk_id, town_id, owner FROM plots WHERE chunkX = ? AND chunkZ = ? AND world = ?" ;
	local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
	local plot = ExecuteStatement(sql, parameters)[1];

	if(plot == nil) then
		Player:SendMessageFailure("You can not claim a plot if you're not inside a town");
	elseif((resident[1] == nil) or not (plot[2] == resident[1])) then
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
		local sql = "UPDATE plots SET owner = ? WHERE townChunk_id = ?";
		local parameter = {UUID, plot[1]};
		ExecuteStatement(sql, parameter);

		Player:SendMessageSuccess("You succesfully claimed this plot");
	end

	return true;
end

function PlotUnclaim(Split, Player)
	local UUID = Player:GetUUID();

	local sql = "SELECT town_id FROM town_residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local resident = ExecuteStatement(sql, parameter)[1];

	local sql = "SELECT townChunk_id, town_id, owner FROM plots WHERE chunkX = ? AND chunkZ = ? AND world = ?" ;
	local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
	local plot = ExecuteStatement(sql, parameters)[1];

	LOG(plot[3] .. " " .. UUID);
	if(plot == nil) then
		Player:SendMessageFailure("You can not unclaim a plot if you're not inside a town");
	elseif((resident[1] == nil) or not (plot[2] == resident[1])) then
		Player:SendMessageFailure("You can not unclaim a plot if you're not part of this town")
	elseif ((plot[3] == nil) or not (plot[3] == UUID)) then
		Player:SendMessageFailure("You can not unclaim a plot that is not yours");
	else
		local sql = "UPDATE plots SET owner = NULL WHERE townChunk_id = ?";
		local parameter = {plot[1]};
		ExecuteStatement(sql, parameter);

		Player:SendMessageSuccess("You succesfully unlcaimed this plot");
	end

	return true;
end

function PlotToggle(Split, Player)
	local UUID = Player:GetUUID();
	local townId = GetPlayerTown(UUID);

	if not (townId) then
		Player:SendMessageFailure("You can't toggle if you're not part of a town");
		return true;
	else
		local sql = "SELECT plots.plot_id, towns.town_id, plots.owner, plots.plot_features FROM towns INNER JOIN plots ON towns.town_id = plots.town_id WHERE plots.chunkX = ? AND plots.chunkZ = ? AND plots.world = ?";
		local parameters = {Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
		local plot = ExecuteStatement(sql, parameters)[1];

		local newStatus;
		if (plot == nil) then
			Player:SendMessageFailure("You have to be in a plot to toggle it's features");
			return true;
		elseif not (plot[3] == UUID) and not (plot[3]) and not (TownRanks[GetPlayerTownRank(UUID)] >= TownRanks['assistant']) then
			Player:SendMessageFailure("You can't toggle if you're not the owner of the plot");
			return true;
		else
			local PERMISSION;
			local INHERIT;
			local string;

			if (Split[3] == 'mobs') then
				PERMISSION = PLOTMOBSENABLED;
				INHERIT = PLOTMOBSINHERIT;
				string = "Mob spawning";
			elseif (Split[3] == 'explosions') then
				PERMISSION = PLOTEXPLOSIONSENABLED;
				INHERIT = PLOTEXPLOSIONSINHERIT;
				string = "Explosions";
			elseif (Split[3] == 'pvp') then
				PERMISSION = PLOTPVPENABLED;
				INHERIT = PLOTPVPINHERIT;
				string = "PVP";
			elseif (Split[3] == 'fire') then
				PERMISSION = PLOTFIREENABLED;
				INHERIT = PLOTFIREINHERIT;
				string = "Fire";
			end

			if not (Split[4] == nil) then --The user wants the plot to inherit the town value
				if not (Split[4] == "inherit") then
					Player:SendMessageFailure("This argument is not understood");
					return true;
				else
					if not (bit32.band(plot[4], PERMISSION) == 0) then --Mobs are enabled
						newStatus = bit32.bxor(plot[4], PERMISSION); --Remove on status
					else --Mobs are not enabled, continue
						newStatus = plot[4];
					end

					if (bit32.band(plot[4], INHERIT) == 0) then --Mobs are not inheriting from the town status
						newStatus = bit32.bor(newStatus, INHERIT); --Set inherit status
					end
					Player:SendMessageSuccess(string .. " now inherits the town value");
				end
			else
				if not (bit32.band(plot[4], INHERIT) == 0) then --Mobs are inheriting from the town status
					newStatus = bit32.bxor(plot[4], INHERIT); --Remove inherit status if set
				else --Mobs are not inheriting from the town status, continue
					newStatus = plot[4];
				end

				if (bit32.band(plot[4], PERMISSION) == 0) then --Mobs are off
					newStatus = bit32.bor(newStatus, PERMISSION);
					Player:SendMessageSuccess(string .. " is now enabled in this plot");
				else --Mobs are enabled
					newStatus = bit32.bxor(newStatus, PERMISSION);
					Player:SendMessageSuccess(string .. " is now disabled in this plot");
				end
			end

			local sql = "UPDATE plots SET plot_features = ? WHERE plot_id = ?";
			local parameters = {newStatus, plot[1]};
			ExecuteStatement(sql, parameters);
		end

		return true;
	end
end
