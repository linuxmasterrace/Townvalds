function OnPlayerJoined(Player) -- This is called after connection
	local UUID = Player:GetUUID();
    local sql = "INSERT OR IGNORE INTO residents (player_uuid, player_name, first_joined) VALUES (?, ?, datetime(\"now\"))";
    local parameters = {UUID, Player:GetName()};
    if(ExecuteStatement(sql, parameters) == nil) then
        LOG("Couldn't add player "..Player:GetName().." to the database!!!");
    end

	local sql = "UPDATE residents SET last_online = NULL WHERE player_uuid = ?";
	local parameters = {UUID};
	ExecuteStatement(sql, parameters);
	Channel[UUID] = "global";

	--Make sure if the town of the player has a new spawn since last join, to set the new spawn
	local sql = "SELECT towns.town_spawnX, towns.town_spawnY, towns.town_spawnZ, towns.town_spawnWorld FROM towns INNER JOIN town_residents ON towns.town_id = town_residents.town_id WHERE town_residents.player_uuid = ?";
	local parameter = {UUID};
	local townSpawn = ExecuteStatement(sql, parameter)[1];

	if (townSpawn) then
		local spawnWorld = cRoot:Get():GetWorld(townSpawn[4]);
		Player:SetBedPos(Vector3i(townSpawn[1], townSpawn[2], townSpawn[3]), spawnWorld);
	else
		local spawnWorld = cRoot:Get():GetDefaultWorld();
		Player:SetBedPos(Vector3i(spawnWorld:GetSpawnX(), spawnWorld:GetSpawnY(), spawnWorld:GetSpawnZ()), spawnWorld);
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
	local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions FROM townChunks INNER JOIN towns ON townChunks.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
    local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), Player:GetWorld():GetName()};
    local town = ExecuteStatement(sql, parameters)[1];
    if not (town) then --The block being broken is not part of a town, so breaking is allowed
		return true;
	else
		if (town[1] == GetPlayerTown(Player:GetUUID())) then
<<<<<<< HEAD
			return not CheckPermission(town[3], RESIDENTDESTROY);
		else
			if (town[2] == GetPlayerNation(Player:GetUUID())) then
				return not CheckPermission(town[3], ALLYDESTROY);
			else
				return not CheckPermission(town[3], OUTSIDERDESTROY);
=======
			if (CheckPermission(town[3], RESIDENTDESTROY) == false) then
				return true; --Prevent
			else
				return false; --Allow
			end
		else
			if (town[2] == GetPlayerNation(Player:GetUUID())) then
				if (CheckPermission(town[3], ALLYDESTROY) == false) then
					return true; --Prevent
				else
					return false; --Allow
				end
			else
					if (CheckPermission(town[3], OUTSIDERDESTROY) == false) then
					return true; --Prevent
				else
					return false; --Allow
				end
>>>>>>> Added town permissions
			end
		end
    end
end

function OnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
	local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions FROM townChunks INNER JOIN towns ON townChunks.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
    local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), Player:GetWorld():GetName()};
    local town = ExecuteStatement(sql, parameters)[1];
    if not (town) then --The block being broken is not part of a town, so placing is allowed
		return true;
	else
		if (town[1] == GetPlayerTown(Player:GetUUID())) then
			return not CheckPermission(town[3], RESIDENTBUILD);
		else
			if (town[2] == GetPlayerNation(Player:GetUUID())) then
				return not CheckPermission(town[3], ALLYBUILD);
			else
				return not CheckPermission(town[3], OUTSIDERBUILD);
			end
		end
    end
end

function OnPlayerUsingItem(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType, BlockMeta)
	local itemUsed = ItemToString(Player:GetEquippedItem());
	--Since this hook is always called twice when using buckets, we need the 2nd call which has BlockFace at -1 parameters
	if (BlockFace == -1) or (itemUsed == "lighter") or (itemUsed == "firecharge") then
		local CallBacks = {
			OnNextBlock = function(a_BlockX, a_BlockY, a_BlockZ, a_BlockType, a_BlockMeta) --The actual check if the item is allowed or not
				local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions, towns.town_fire_enabled FROM townChunks INNER JOIN towns ON townChunks.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
			    local parameters = {math.floor(a_BlockX / 16), math.floor(a_BlockZ / 16), Player:GetWorld():GetName()};
			    local town = ExecuteStatement(sql, parameters)[1];
			    if not (town) then --The item is used on a block that is not part of a town, so it's allowed
					return false;
				else
					if (town[1] == GetPlayerTown(Player:GetUUID())) then
						allowed = CheckPermission(town[3], RESIDENTITEMUSE);
					else
						if (town[2] == GetPlayerNation(Player:GetUUID())) then
							allowed = CheckPermission(town[3], ALLYITEMUSE);
						else
							allowed = CheckPermission(town[3], OUTSIDERITEMUSE);
						end
					end

					if (allowed == true) then
						if (itemUsed == "lighter") or (itemUsed == "firecharge") then
							if (town[4] == 0) then --If fire is disabled in this town, prevent the player from starting a fire
								return false; --Prevent item use
							else
								return true; --Allow item use
							end
						else
							return true; --Allow item use
						end
					else
						return false; --Prevent item use
					end
				end
			end
		};
		local EyePos = Player:GetEyePosition();
		local LookVector = Player:GetLookVector();
		LookVector:Normalize(); --Make the vector 1m long
		local Start = EyePos + LookVector;
		local End = EyePos + LookVector * 50;
		return cLineBlockTracer.Trace(Player:GetWorld(), CallBacks, Start.x, Start.y, Start.z, End.x, End.y, End.z);
	end
end

function OnPlayerUsingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType, BlockMeta)
	local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions FROM townChunks INNER JOIN towns ON townChunks.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
    local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), Player:GetWorld():GetName()};
    local town = ExecuteStatement(sql, parameters)[1];

    if not (town) then --The block being used is not part of a town, so using is allowed
		return true;
	else
		if (town[1] == GetPlayerTown(Player:GetUUID())) then
			if (CheckPermission(town[3], RESIDENTSWITCH) == false) then
				return true; --Prevent
			else
				return false; --Allow
			end
		else
			if (town[2] == GetPlayerNation(Player:GetUUID())) then
				if (CheckPermission(town[3], ALLYSWITCH) == false) then
					return true; --Prevent
				else
					return false; --Allow
				end
			else
					if (CheckPermission(town[3], OUTSIDERSWITCH) == false) then
					return true; --Prevent
				else
					return false; --Allow
				end
			end
		end
    end
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
