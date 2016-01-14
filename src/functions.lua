function OnPlayerJoined(Player)
	playerChunkX = Player:GetChunkX();
	playerChunkZ = Player:GetChunkZ();
	local inTown = false;
end

function DisplayVersion(Split, Player)
	if not (Player == nil) then
		Player:SendMessageInfo("Townvalds version: " .. PLUGIN:GetVersion())
	else
		LOG("Townvalds version: " .. PLUGIN:GetVersion())
	end

	return true
end

function CheckLocation(playerChunkX, playerChunkZ)
	if (playerChunkX == 1 .. playerChunkZ == 1) then
		--LOG("TEST")
	end
end

function OnPlayerBreakingBlock(Player, BlockType)
	playerChunkX = Player:GetChunkX()
	playerChunkZ = Player:GetChunkZ()

	CheckLocation(playerChunkX, playerChunkZ)
end

function OnPlayerMoving(Player, OldPosition, NewPosition)
	if not (playerChunkX == Player:GetChunkX() and playerChunkZ == Player:GetChunkZ()) then
		playerChunkX = Player:GetChunkX();
		playerChunkZ = Player:GetChunkZ();

		sql = "SELECT towns.town_name, townChunks.chunkX, townChunks.chunkZ FROM townChunks LEFT JOIN towns ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ?";
		parameters = {Player:GetChunkX(), Player:GetChunkZ()};
		result = ExecuteStatement(sql, parameters);
		--sql = "SELECT chunkX FROM townChunks WHERE town_id = 1";
		--result = ExecuteStatement(sql);

		if not (result[1] == nil) then
			if not (inTown == true) then
				Player:SendMessage("You're in the town " .. result[1][1]);
				inTown = true;
			end
		else
			inTown = false;
		end
	end

	return false;
end
