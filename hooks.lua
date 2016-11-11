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

	return false;
end

function OnPlayerSpawned(Player) -- This is called after both connection and respawning
    CheckPlayerInTown(Player, Player:GetChunkX(), Player:GetChunkZ());

	return false;
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
	local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions FROM plots INNER JOIN towns ON plots.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
    local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), Player:GetWorld():GetName()};
    local town = ExecuteStatement(sql, parameters)[1];
    if not (town) then --The block being broken is not part of a town, so breaking is allowed
		return true;
	else
		if (town[1] == GetPlayerTown(Player:GetUUID())) then
			return not CheckPermission(town[3], RESIDENTDESTROY);
		else
			if (town[2] == GetPlayerNation(Player:GetUUID())) then
				return not CheckPermission(town[3], ALLYDESTROY);
			else
				return not CheckPermission(town[3], OUTSIDERDESTROY);
			end
		end
    end
end

function OnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
	local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions FROM plots INNER JOIN towns ON plots.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
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
				local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions, towns.town_features, plots.plot_features FROM plots INNER JOIN towns ON plots.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
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
							if not (bit32.band(town[5], PLOTFIREINHERIT) == 0) then -- The plot inherits it's fire property from the town
								if (bit32.band(town[4], TOWNFIREENABLED) == 0) then -- If fire is disabled in this town, prevent the fire from spreading
									return false;
								end
							elseif (bit32.band(town[5], PLOTFIREENABLED) == 0) then -- Fire is disabled
								return false;
							end

							return true;
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
	local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions FROM plots INNER JOIN towns ON plots.town_id = towns.town_id WHERE chunkX = ? AND chunkZ = ? AND world = ?";
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
		local sql = "SELECT plots.plot_features, towns.town_features FROM plots INNER JOIN towns ON towns.town_id = plots.town_id WHERE plots.chunkX = ? AND plots.chunkZ = ? AND plots.world = ?";
		local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), World:GetName()};
		local town = ExecuteStatement(sql, parameters)[1];

		if (town) then -- Check if the block is in a plot
			if not (bit32.band(town[1], PLOTFIREINHERIT) == 0) then -- The plot inherits it's fire property from the town
				if (bit32.band(town[2], TOWNFIREENABLED) == 0) then -- If fire is disabled in this town, prevent the fire from spreading
					return true;
				end
			elseif (bit32.band(town[1], PLOTFIREENABLED) == 0) then -- Fire is disabled
				return true;
			end
		end
	end

	return false;
end

function OnExploding(World, ExplosionSize, CanCauseFire, X, Y, Z, Source, SourceData)
	local sql = "SELECT plot_id, town_id FROM plots WHERE chunkX = ? AND chunkZ = ? AND world = ?";
	local parameters = {math.floor(X/16), math.floor(Z/16), World:GetName()};

	for a = -1, 1, 1 do
		for b = -1, 1, 1 do
			parameters[1] = parameters[1] + a;
			parameters[2] = parameters[2] + b;
			local plot = ExecuteStatement(sql, parameters)[1];
			if (plot ~= nil) then
				local sql = "SELECT plot_features FROM plots WHERE plot_id = ?";
				local parameter = {plot[1]};
				local explosions = ExecuteStatement(sql, parameter)[1][1];

				if not (bit32.band(explosions, PLOTEXPLOSIONSINHERIT) == 0) then -- The plot inherit it's explosions property from the town
					local sql = "SELECT town_features FROM towns WHERE town_id = ?";
					local parameter = {plot[2]};
					local explosions = ExecuteStatement(sql, parameter)[1][1];

					if (bit32.band(explosions, TOWNEXPLOSIONSENABLED) == 0) then -- Explosions are disabled
						return true;
					end
				elseif (bit32.band(explosions, PLOTEXPLOSIONSENABLED) == 0) then -- Explosions are disabled
					return true;
				end

				-- If here, explosions are enabled
				return false;
			end
			parameters[1] = parameters[1] - a; --reset chunks
			parameters[2] = parameters[2] - b;
		end
	end
end

function OnTakeDamage(Receiver, TDI)
	if Receiver:IsPlayer() and TDI.Attacker ~= nil and TDI.Attacker:IsPlayer() then
		local sql = "SELECT plot_id, town_id FROM plots WHERE chunkX = ? AND chunkZ = ? AND world = ?";

		local parameters_attacker = {TDI.Attacker:GetChunkX(), TDI.Attacker:GetChunkZ(), TDI.Attacker:GetWorld():GetName()};
		local parameters_receiver = {Receiver:GetChunkX(), Receiver:GetChunkZ(), Receiver:GetWorld():GetName()};

		local town_attacker = ExecuteStatement(sql, parameters_attacker)[1];
		local town_receiver = ExecuteStatement(sql, parameters_receiver)[1];

		if (town_attacker ~= nil) or (town_receiver ~= nil) then
			if (town_attacker == nil) and not (town_receiver == nil) then
				town_attacker = {town_receiver}; --Set it so we can use it in the query
			end

			local sql = "SELECT plot_features FROM plots WHERE plot_id = ?";
			local parameter = {town_attacker[1]};
			local pvp = ExecuteStatement(sql, parameter)[1][1];

			if not (bit32.band(pvp, PLOTPVPINHERIT) == 0) then -- The plot inherits it's pvp property from the town
				local sql = "SELECT town_features FROM towns WHERE town_id = ?";
				local parameter = {town_attacker[2]};
				local pvp = ExecuteStatement(sql, parameter)[1][1];

				if (bit32.band(pvp, TOWNPVPENABLED) == 0) then --PVP is disabled by the town
					return true;
				end
			elseif (bit32.band(pvp, PLOTPVPENABLED) == 0) then -- PVP is disabled
				return true;
			end
		end
	end

	return false;
end

function OnSpawningMonster(World, Monster)
	if (Monster:GetMobFamily() == 0) then --Check if the monster is hostile
		local sql = "SELECT plots.plot_features, towns.town_features FROM towns INNER JOIN plots ON towns.town_id = plots.town_id WHERE plots.chunkX = ? AND plots.chunkZ = ? AND plots.world = ?";
		local parameters = {Monster:GetChunkX(), Monster:GetChunkZ(), World:GetName()};
		local town = ExecuteStatement(sql, parameters)[1];

		if (town) then -- Check if the mob is in a plot
			if not (bit32.band(town[1], PLOTMOBSINHERIT) == 0) then -- The plot inherits it's mob spawning property from the town
				if (bit32.band(town[2], TOWNMOBSENABLED) == 0) then -- Mob spawning is not allowed by the town
					return true;
				end
			elseif (bit32.band(town[1], PLOTMOBSENABLED) == 0) then -- Mob spawning is not allowed
				return true;
			end
		end
	end

	return false;
end
