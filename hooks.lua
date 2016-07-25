function OnPlayerJoined(Player) -- This is called after connection
	local UUID = Player:GetUUID();
    local sql = "INSERT OR IGNORE INTO residents (player_uuid, player_name, town_id, town_rank, first_joined) VALUES (?, ?, NULL, NULL, datetime(\"now\"))";
    local parameters = {UUID, Player:GetName()};
    if(ExecuteStatement(sql, parameters) == nil) then
        LOG("Couldn't add player "..Player:GetName().." to the database!!!");
    end

	local sql = "UPDATE residents SET last_online = NULL WHERE player_uuid = ?";
	local parameters = {UUID};
	ExecuteStatement(sql, parameters);
	Channel[UUID] = "global";

	return true;
end

function OnPlayerSpawned(Player) -- This is called after both connection and respawning
    CheckPlayerInTown(Player, Player:GetChunkX(), Player:GetChunkZ());
end

function OnPlayerDestroyed(Player) -- This is called when a player that has been in the game disconnects
   InTown[Player:GetUUID()] = nil; -- We set it to nil so Lua can garbage collect it and so the player gets the message on connection
   local sql = "UPDATE residents SET last_online = datetime(\"now\") WHERE player_uuid = ?";
   local parameters = {Player:GetUUID()};
   ExecuteStatement(sql, parameters);
   return false;
end

function OnPlayerMoving(Player, OldPosition, NewPosition)
    CheckPlayerInTown(Player, Player:GetChunkX(), Player:GetChunkZ());
    return false;
end

function OnPlayerBreakingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
    return CheckBlockPermission(Player, BlockX, BlockZ);
end

function OnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
    return CheckBlockPermission(Player, BlockX, BlockZ);
end

function OnPlayerUsingItem(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType, BlockMeta)
	if (ItemToString(Player:GetEquippedItem()) == "lighter") then
		local sql = "SELECT towns.town_id, towns.town_fire_enabled FROM towns INNER JOIN townChunks ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ? AND townChunks.world = ?";
		local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), Player:GetWorld():GetName()};
		local town = ExecuteStatement(sql, parameters)[1];

		if (town and town[2] == 0) then --If fire is disabled in this town, prevent the player from starting a fire
			return true;
		else
			return false;
		end
	end

	return false;
end

function OnBlockSpread(World, BlockX, BlockY, BlockZ, Source)
	if (Source == ssFireSpread) then
		local sql = "SELECT towns.town_id, towns.town_fire_enabled FROM towns INNER JOIN townChunks ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ? AND townChunks.world = ?";
		local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), World:GetName()};
		local town = ExecuteStatement(sql, parameters)[1];

		if (town and town[2] == 0) then --If fire is disabled in this town, prevent the fire from spreading
			return true;
		else
			return false;
		end
	end

	return false;
end
