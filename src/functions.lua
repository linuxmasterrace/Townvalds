function OnPlayerJoined(Player)
	playerChunkX = Player:GetChunkX();
	playerChunkZ = Player:GetChunkZ();

	local inTown = false;

	local sql = "INSERT OR IGNORE INTO residents (player_uuid, player_name, town_id, town_rank, last_online) VALUES (?, ?, NULL, NULL, datetime(\"now\"))";
	local parameters = {cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true), Player:GetName()};
	if(ExecuteStatement(sql, parameters)==nil) then
		LOG("Couldn't add player "..Player:GetName().." to the database!!!")
	end
end

function DisplayVersion(Split, Player)
	if not (Player == nil) then
		Player:SendMessageInfo("Townvalds version: " .. PLUGIN:GetVersion())
	else
		LOG("Townvalds version: " .. PLUGIN:GetVersion())
	end

	return true
end

function OnPlayerMoving(Player, OldPosition, NewPosition)
	if not (playerChunkX == Player:GetChunkX() and playerChunkZ == Player:GetChunkZ()) then
		playerChunkX = Player:GetChunkX();
		playerChunkZ = Player:GetChunkZ();

		sql = "SELECT towns.town_name, townChunks.chunkX, townChunks.chunkZ FROM townChunks LEFT JOIN towns ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ?";
		parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		result = ExecuteStatement(sql, parameters);

		if not (result[1] == nil) then
			if not (inTown == true) then
				Player:SendMessage("You're in the town " .. result[1][1]);
				inTown = true;
			end
		else
			print(inTown);
			inTown = false;
		end
	end

	return false;
end

function CreateTable()
	local sql = "CREATE TABLE IF NOT EXISTS users (user_guid STRING PRIMARY KEY, town_id INTEGER)";
	result = ExecuteStatement(sql);

	return true;
end
