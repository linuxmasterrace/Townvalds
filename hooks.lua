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

	--Make sure if the town of the player has a new spawn since last join, to set the new spawn
	local sql = "SELECT towns.town_spawnX, towns.town_spawnY, towns.town_spawnZ, towns.town_spawnWorld FROM towns INNER JOIN residents ON towns.town_id = residents.town_id WHERE residents.player_uuid = ?";
	local parameter = {UUID};
	local townSpawn = ExecuteStatement(sql, parameter)[1];

	if (townSpawn) then
		local spawnWorld = cRoot:Get():GetWorld(townSpawn[4]);
		Player:SetBedPos(Vector3i(townSpawn[1], townSpawn[2], townSpawn[3]), spawnWorld);
	end

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
