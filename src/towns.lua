function TownCreate(Split, Player)
	-- Check if the player entered a name for the town
	if (Split[3] == nil) then
		Player:SendMessageFailure("You have to enter a town name! Usage: /town new (name)");
		return true;
	end

	-- Retrieve the player UUID from Mojang of the player that invoked the command
	local result = GetPlayerTown(cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true));
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

	if (result == nil) then
		sql = "SELECT town_name FROM towns WHERE town_name = ?";
		parameter = {Split[3]};
		local result = ExecuteStatement(sql, parameter);

		if(result[1] == nil) then
			-- Insert the town data in the database
			sql = "INSERT INTO towns (town_name, town_owner, town_explosions_enabled) VALUES (?, ?, ?)";
			parameters = {Split[3], UUID, 0};
			local town_id = ExecuteStatement(sql, parameters);

			sql = "INSERT INTO townChunks (town_id, chunkX, chunkZ) VALUES (?, ?, ?)";
			parameters = {town_id, Player:GetChunkX(), Player:GetChunkZ()};
			ExecuteStatement(sql, parameters);

			local sql = "UPDATE residents SET town_id = ? WHERE player_uuid = ?";
			local parameters = {town_id, UUID};
			ExecuteStatement(sql, parameters);

			Player:SendMessageSuccess("Created a new town called " .. Split[3]);
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

function TownToggle(Split, Player)
	if (Split[3] == nil) or (Split[4] == nil) then
		Player:SendMessageFailure("You have to enter a property! Usage: /town toggle (property) (value)");
		return true;
	end

	if not (Split[4] == "0" or Split[4] == "1") then
		Player:SendMessageFailure("(value) must be 0 or 1");
		Player:SendMessageFailure(Split[4]);
		return true;
	end

	if not (InTown[Player:GetName()] == nil) then
		local town_id = GetPlayerTown(cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true));

		sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ?";
		parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		local result = ExecuteStatement(sql, parameters)[1][1];
		
		if Split[3] == "explosions" then
			if(town_id == result) then
				sql = "UPDATE towns SET town_explosions_enabled= ? WHERE town_id = ?"
				paramters = {Split[4], town_id};
				ExecuteStatement(sql, paramters);

				Player:SendMessageSuccess("Property changed.");
			else
				Player:SendMessageFailure("This is not your town!");
			end
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