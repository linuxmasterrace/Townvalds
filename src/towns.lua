function TownCreate(Split, Player)
    -- Check if the player entered a name for the town
    if (Split[3] == nil) then
        Player:SendMessageFailure("You have to enter a town name! Usage: /town new (name)");
        return true;
    end

    local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

    -- Retrieve the player UUID from Mojang of the player that invoked the command
    local result = GetPlayerTown(UUID);

    if (result == nil) then
        sql = "SELECT town_name FROM towns WHERE town_name = ?";
        parameter = {Split[3]};
        local result = ExecuteStatement(sql, parameter);

        if(result[1] == nil) then
            sql = "SELECT town_id FROM townChunks WHERE (chunkX > ? AND chunkX < ?) AND (chunkZ > ? AND chunkZ < ?)";
            parameters = {Player:GetChunkX() - config.min_distance_from_other_towns - 1, Player:GetChunkX() + config.min_distance_from_other_towns + 1, Player:GetChunkZ() - config.min_distance_from_other_towns - 1, Player:GetChunkZ() + config.min_distance_from_other_towns + 1};
            local town_id = ExecuteStatement(sql, parameters);

            if not(town_id[1] and town_id[1][1]) then
                -- Insert the town data in the database
                sql = "INSERT INTO towns (town_name, town_owner) VALUES (?, ?)";
                parameters = {Split[3], UUID};
				local town_id = ExecuteStatement(sql, parameters);

                sql = "INSERT INTO townChunks (town_id, chunkX, chunkZ) VALUES (?, ?, ?)";
                parameters = {town_id, Player:GetChunkX(), Player:GetChunkZ()};
                ExecuteStatement(sql, parameters);

                local sql = "UPDATE residents SET town_id = ? WHERE player_uuid = ?";
                local parameters = {town_id, UUID};
                ExecuteStatement(sql, parameters);

                Player:SendMessageSuccess("Created a new town called " .. Split[3]);
            else
                Player:SendMessageFailure("You're too close to an existing town, please move further away before trying to create a new town.");
            end
        else
            Player:SendMessageFailure("There already exists a town with that name, please choose a different one");
        end
    else
        Player:SendMessageFailure("Please leave your current town before you create a new one");
    end

    return true;
end

function TownClaim(Split, Player)
	if(InTown[Player:GetName()] == nil) then
		-- Get the town of the player
		local town_id = GetPlayerTown(cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true));

		if not (town_id == nil) then
			sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ?";
			parameters = {Player:GetChunkX(), Player:GetChunkZ()};
			local result = ExecuteStatement(sql, parameters);

			if not (result[1] == town_id) then
				sql = "SELECT town_id FROM townChunks WHERE town_id = ? AND (chunkX = ? + 1 OR chunkX = ? OR chunkX = ? - 1) AND (chunkZ = ? + 1 OR chunkZ = ? OR chunkZ = ? - 1)";
				parameters = {town_id, Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkZ(), Player:GetChunkZ(), Player:GetChunkZ()};
				local result = ExecuteStatement(sql, parameters)[1];

				if not (result == nil) then -- The chunk to be claimed is next to an already existing chunk of the town
					sql = "INSERT INTO townChunks (town_id, chunkX, chunkZ) VALUES (?, ?, ?)";
					parameters = {town_id, Player:GetChunkX(), Player:GetChunkZ()};
					ExecuteStatement(sql, parameters);

					Player:SendMessageSuccess("Land succesfully claimed");
				else
					Player:SendMessageFailure("You have to be next to your town to claim land!");
				end

			else
				Player:SendMessageFailure("This chunk already belongs to a different town");
			end
		else
			Player:SendMessageFailure("You can't claim land if you're not in a town");
		end
	else
		Player:SendMessageFailure("You can't claim land that is already part of a town!");
	end
		return true;
end

function TownUnclaim(Split, Player)
	if not (InTown[Player:GetName()] == nil) then
		local town_id = GetPlayerTown(cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true));

		sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ?";
		parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		local result = ExecuteStatement(sql, parameters)[1][1];

		if(town_id == result) then
			sql = "DELETE FROM townChunks WHERE town_id = ? AND chunkX = ? AND chunkZ = ?";
			parameters = {town_id, Player:GetChunkX(), Player:GetChunkZ()};
			ExecuteStatement(sql, parameters);

			Player:SendMessageSuccess("Land succesfully unclaimed.");
		else
			Player:SendMessageFailure("This is not your town!");
		end
	else
		Player:SendMessageFailure("You can't unclaim land if you're not in a town!");
	end

	return true;
end


function TownAddPlayer(Split, Player)
    if(Split[3] == nil) then
        Player:SendMessageFailure("You need to specify a player.");
        return true;
    end

    local town_id = GetPlayerTown(cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true));

    if not (town_id == nil) then
        local invitedPlayer = cMojangAPI:GetUUIDFromPlayerName(Split[3], true);
        if (invitedPlayer == "") then
            Player:SendMessageFailure("This player does not exist.");
            return true;
        end

        local remote_town_id = GetPlayerTown(invitedPlayer);

        if(remote_town_id == nil) then
            sql = "INSERT INTO invitations (player_uuid, town_id) VALUES (?, ?)";
            parameters = {cMojangAPI:GetUUIDFromPlayerName(Split[3], true), town_id};
            ExecuteStatement(sql, parameters);
            Player:SendMessageSuccess("The specified player is succesfully invited to the town");
        else
            Player:SendMessageFailure("The specified player already belongs to a town.");
        end
    else
        Player:SendMessageFailure("You have to be in a town to invite players!");
    end

    return true;
end

function TownJoin(Split, Player)
    local town_id;
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

	sql = "SELECT town_id FROM invitations WHERE player_uuid = ?";
	parameters = {UUID};
	local result = ExecuteStatement(sql, parameters);

	if(result[1] == nil) then
		Player:SendMessageFailure("You have no invitations!");

		return true;
	else
	    if(Split[3] == nil) then
			if not(result[2] == nil) then
                Player:SendMessageFailure("You have multiple invitations, please specify which one you want to join:");
                for key, value in pairs(result) do
                    Player:SendMessageInfo(GetTownName(value[1]));
                end

                return true;
            else
                town_id = result[1][1];
            end
	    else
	        town_id = GetTownId(Split[3]);
	    end

		if not (config.invitation_duration == "0") then
			sql = "SELECT invitation_id, invitation_date FROM invitations WHERE town_id = ? AND player_uuid = ?";
			parameters = {town_id, UUID};
			local invitation = ExecuteStatement(sql, parameters)[1];

			if not (os.time(os.date("!*t")) - GetTimestampFromString(invitation[2]) <= tonumber(config.invitation_duration)) then
				sql = "DELETE FROM invitations WHERE invitation_id = ?";
				parameter = {invitation[1]};
				ExecuteStatement(sql, parameter);

				Player:SendMessageFailure("Sorry, this invitation is too old. Please request a new one from the mayor!");
				return true;
			end
		end

		sql = "UPDATE residents SET town_id = ? WHERE player_uuid = ?";
	    parameters = {town_id, UUID};
	    ExecuteStatement(sql, parameters);

	    sql = "DELETE FROM invitations WHERE player_uuid = ?";
	    parameters = {UUID};
	    ExecuteStatement(sql, parameters);

	    Player:SendMessageSuccess("You succesfully joined the town!");
	end

    return true;
end

function TownLeave(Split, Player)
    sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
    parameter = {cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true)};
    local result = ExecuteStatement(sql, parameter);

    if(result[1] and result[1][1]) then
        sql = "UPDATE residents SET town_id = ? WHERE player_uuid = ?";
        parameters = {nil, cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true)};
        ExecuteStatement(sql, parameters);

        Player:SendMessageInfo("You left the town " .. GetTownName(result[1][1]));
    else
        Player:SendMessageFailure("You can't leave a town if you're not in one.");
    end

    return true;
end

function TownToggleExplosions(Split, Player)
	if not (Split[4] == "off" or Split[4] == "on") then
		Player:SendMessageFailure("(value) must be off or on");
		return true;
	end

	if not (InTown[Player:GetName()] == nil) then
		local town_id = GetPlayerTown(cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true));

		sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ?";
		parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		local result = ExecuteStatement(sql, parameters)[1][1];
		
		if(town_id == result) then
			sql = "UPDATE towns SET town_explosions_enabled= ? WHERE town_id = ?"
			paramters = {Split[4], town_id};
			ExecuteStatement(sql, paramters);

			Player:SendMessageSuccess("Property changed.");
		else
			Player:SendMessageFailure("This is not your town!");
		end
	else
		Player:SendMessageFailure("You can't toggle if you're not in a town!");
	end
	return true;
end

function TownList(Split, Player)
	local sql = "SELECT town_name FROM towns"
	local parameters = {};
	local result = ExecuteStatement(sql, parameters);

	Player:SendMessageSuccess("[ Towns ]")

	for k,v in pairs(result) do
		Player:SendMessageSuccess(v[1]);
	end
	return true;
end