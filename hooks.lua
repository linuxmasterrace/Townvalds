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
