Deleting = {};
Leaving = {};

function TownCreate(Split, Player)
	if (Split[3] == nil) then
		Player:SendMessageFailure("You have to enter a town name! Usage: /town new (name)");
		return true;
	end

	local UUID = Player:GetUUID();
	local townId = GetPlayerTown(UUID);

	if (townId) then
		Player:SendMessageFailure("Please leave your current town before you create a new one");
	else
		local sql = "SELECT town_name FROM towns WHERE town_name = ?";
		local parameter = {Split[3]};
		local townName = ExecuteStatement(sql, parameter)[1];

		if (townName) then
			Player:SendMessageFailure("There already exists a town with that name, please choose a different one");
		else
			local sql = "SELECT * FROM plots WHERE (chunkX > ? AND chunkX < ?) AND (chunkZ > ? AND chunkZ < ?)";
			local parameters = {Player:GetChunkX() - config.min_distance_from_other_towns - 1, Player:GetChunkX() + config.min_distance_from_other_towns + 1, Player:GetChunkZ() - config.min_distance_from_other_towns - 1, Player:GetChunkZ() + config.min_distance_from_other_towns + 1};
			local remote_town = ExecuteStatement(sql, parameters);

			if (remote_town[1]) then --There is already a town close-by
				Player:SendMessageFailure("You're too close to an existing town, please move further away before trying to create a new town.");
			else -- Insert the town data in the database
				local sql = "INSERT INTO towns (town_name, town_explosions_enabled, town_pvp_enabled, town_spawnX, town_spawnY, town_spawnZ, town_spawnWorld) VALUES (?, ?, ?, ?, ? ,?, ?)";
				local parameters = {Split[3], 0, 0, math.floor(Player:GetPosX()), math.floor(Player:GetPosY()), math.floor(Player:GetPosZ()), Player:GetWorld():GetName()};
				local townId = ExecuteStatement(sql, parameters);

				local sql = "INSERT INTO plots (town_id, chunkX, chunkZ, world) VALUES (?, ?, ?, ?)";
				local parameters = {townId, Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
				ExecuteStatement(sql, parameters);

				local sql = "INSERT INTO town_residents (player_uuid, town_id, town_rank) VALUES (?, ?, ?)";
				local parameters = {UUID, townId, 'resident'}; --Add resident rank to later on make sure the player can't be kicked by removing the rank
				ExecuteStatement(sql, parameters);

				local parameters = {UUID, townId, 'mayor'};
				ExecuteStatement(sql, parameters);

				if (config.enable_town_spawns == 1) then
					--Setting mayor spawn position to the new town spawn
					Player:SetBedPos(Vector3i(math.floor(Player:GetPosX()), math.floor(Player:GetPosY()), math.floor(Player:GetPosZ())), Player:GetWorld());
				end

				Player:SendMessageSuccess("Created a new town called " .. Split[3]);
			end
		end
	end

	return true;
end

function TownDelete(Split, Player)
	local UUID = Player:GetUUID();
	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	if (Deleting[UUID]) then
		local sql = "SELECT town_name FROM towns WHERE town_id = ?";
		local parameter = {Deleting[UUID]};
		local townName = ExecuteStatement(sql, parameter)[1][1];

		DeleteTown(Deleting[UUID]);
		Deleting[UUID] = nil;
		Player:SendMessageSuccess(townName .. " has been deleted");
	else
		local town_target;

		if (Split[3]) then
			local sql = "SELECT town_id, town_name FROM towns WHERE town_name = ?";
			local parameter = {Split[3]};
			town_target = ExecuteStatement(sql, parameter)[1];

			if not (town_target) then
				Player:SendMessageFailure("That town does not exist");
				return true;
			end
		else
			local sql = "SELECT town_id, town_name FROM towns WHERE town_id = ?";
			local parameter = {town[1]};
			town_target = ExecuteStatement(sql, parameter)[1];
		end

		if (town[1] == town_target[1]) then
			if (TownRanks[town[2]] == TownRanks['mayor']) then
				Deleting[UUID] = town_target[1];
				Player:SendMessageInfo("Are you sure you want to delete " .. town_target[2] .. "?");
				Player:SendMessageInfo("Use `/town delete` again if you wish to continue.");
			else
				if not (Player:HasPermission("townvalds.town.delete.other")) then
					Player:SendMessageFailure("You have to be the mayor of your town to delete it");
				else
					Deleting[UUID] = town_target[1];
					Player:SendMessageInfo("Are you sure you want to delete " .. town_target[2] .. "?");
					Player:SendMessageInfo("Use `/town delete` again if you wish to continue.");
				end
			end
		else
			if not (Player:HasPermission("townvalds.town.delete.other")) then
				Player:SendMessageFailure("You are not allowed to delete someone else's town");
			else
				Deleting[UUID] = town_target[1];
				Player:SendMessageInfo("Are you sure you want to delete " .. town_target[2] .. "?");
				Player:SendMessageInfo("Use `/town delete` again if you wish to continue.");
			end
		end
	end

	return true;
end

function TownClaim(Split, Player)
	local UUID = Player:GetUUID();

	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	if (InTown[UUID]) then
		Player:SendMessageFailure("You can't claim land that is already part of a town!");
	elseif not (town[1]) then
		Player:SendMessageFailure("You have to be a resident of a town to claim land");
	elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
		Player:SendMessageFailure("You have to be higher ranked to claim land");
	else
		local sql = "SELECT town_id FROM plots WHERE town_id = ? AND (chunkX = ? + 1 OR chunkX = ? OR chunkX = ? - 1) AND (chunkZ = ? + 1 OR chunkZ = ? OR chunkZ = ? - 1)";
		local parameters = {town[1], Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkZ(), Player:GetChunkZ(), Player:GetChunkZ()};
		local result = ExecuteStatement(sql, parameters)[1];

		if not (result) then
			Player:SendMessageFailure("You have to be next to your town to claim land!");
		else -- The chunk to be claimed is next to an already existing chunk of the town
			local sql = "INSERT INTO plots (town_id, chunkX, chunkZ, world) VALUES (?, ?, ?, ?)";
			local parameters = {town[1], Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
			ExecuteStatement(sql, parameters);

			Player:SendMessageSuccess("Land succesfully claimed");
		end
	end

	return true;
end

function TownUnclaim(Split, Player)
	local UUID = Player:GetUUID();

	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	if not (InTown[UUID]) then
		Player:SendMessageFailure("You can't unclaim land if you're not inside a town!");
	elseif not (town[1]) then
		Player:SendMessageFailure("You have to be a resident of a town to unclaim land");
	elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
		Player:SendMessageFailure("You have to be higher ranked to unclaim land");
	else
		local sql = "SELECT townChunk_id, town_id FROM plots WHERE town_id = ? AND chunkX = ? AND chunkZ = ? AND world = ?";
		local parameters = {town[1], Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
		local plot = ExecuteStatement(sql, parameters)[1];

		if not (plot[2] == town[1]) then
			Player:SendMessageFailure("This plot doesn't belong to your town");
		else
			local sql = "SELECT COUNT(*) FROM plots WHERE town_id = ?";
			local parameter = {town[1]};
			local chunkCount = ExecuteStatement(sql, parameter)[1][1];

			if (chunkCount == 1) then
				Player:SendMessageFailure("Since this is the last chunk of this town, you can't remove it!");
			else
				local sql = "SELECT townChunk_id, chunkX, chunkZ, world FROM plots WHERE town_id = ? AND (chunkX = ? + 1 OR chunkX = ? OR chunkX = ? - 1) AND (chunkZ = ? + 1 OR chunkZ = ? OR chunkZ = ? - 1) AND world = ? AND townChunk_id <> ?";
				local parameters = {town[1], Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkZ(), Player:GetChunkZ(), Player:GetChunkZ(), Player:GetWorld():GetName(), plot[1]};
				local plots = ExecuteStatement(sql, parameters);

				local allowed = true;
				for key, value in pairs(plots) do
					local parameters = {town[1], value[2], value[2], value[2], value[3], value[3], value[3], value[4], value[1]};
					local plots_target = ExecuteStatement(sql, parameters); --Use the previous query, we need to let it get the same type of results for this plot

					if not (plots_target[2]) then --This chunk would be seperated from the town if the one next to it is unclaimed
						allowed = false;
						break;
					end
				end

				if not (allowed) then
					Player:SendMessageFailure("Unclaiming this chunk would cause a chunk to be disconnected from the town, this is not allowed");
				else
					local sql = "DELETE FROM plots WHERE town_id = ? AND chunkX = ? AND chunkZ = ? AND world = ?";
					local parameters = {town[1], Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
					ExecuteStatement(sql, parameters);
					Player:SendMessageSuccess("Land succesfully unclaimed.");
				end
			end
		end
	end

	return true;
end

function TownAddPlayer(Split, Player)
	if (Split[3] == nil) then
		Player:SendMessageFailure("You need to specify a player.");
		return true;
	end

	local UUID = Player:GetUUID();
	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	local UUID_target = cMojangAPI:GetUUIDFromPlayerName(Split[3], true);
	local town_target = {
		GetPlayerTown(UUID_target),
		GetPlayerTownRank(UUID_target);
	};

	if not (town[1]) then
		Player:SendMessageFailure("You have to be in a town to invite players");
	elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
		Player:SendMessageFailure("You have to be higher ranked to invite players");
	else
		if (town_target[1] == town[1]) then
			Player:SendMessageFailure(Split[3] .. " already belongs to your town");
		elseif (town_target[1]) then
			Player:SendMessageFailure(Split[3] .. " already belongs to a town");
		else
			local sql = "SELECT * FROM invitations WHERE player_uuid = ? AND town_id = ?";
			local parameters = {UUID_target, town[1]};
			local result = ExecuteStatement(sql, parameters)[1];

			if (result) then
				Player:SendMessageFailure(Split[3] .. " is already invited to your town");
			else
				local sql = "INSERT INTO invitations (player_uuid, town_id) VALUES (?, ?)";
				local parameters = {UUID_target, town[1]};
				ExecuteStatement(sql, parameters);

				Player:SendMessageSuccess(Split[3] .. " is succesfully invited to your town");
			end
		end
	end

	return true;
end

function TownKickPlayer(Split, Player)
	local UUID = Player:GetUUID();
	if (Split[3] == nil) then
		Player:SendMessageFailure("You need to specify a player.");
		return true;
	end

	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	local UUID_target = cMojangAPI:GetUUIDFromPlayerName(Split[3]);
	local town_target = {
		GetPlayerTown(UUID_target),
		GetPlayerTownRank(UUID_target);
	};

	if not (town[1]) then
		Player:SendMessageFailure("You have to be a resident of a town to kick players from it");
	elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
		Player:SendMessageFailure("You have to be higher ranked to kick players from your town");
	elseif not (town_target) or not (town[1] == town_target[1]) then
		Player:SendMessageFailure(Split[3] .. " is not a resident of your town");
	else
		if (UUID_target == "") then
			Player:SendMessageFailure("This player does not exist.");
		elseif (UUID_target == UUID) then
			Player:SendMessageFailure("You can't kick yourself");
		elseif not (TownRanks[town[2]] > TownRanks[town_target[2]]) then
			Player:SendMessageFailure("You have to be higher ranked to kick this player");
		else
			local sql = "DELETE FROM town_residents WHERE player_uuid = ?";
			local parameter = {UUID_target};
			ExecuteStatement(sql, parameter);

			Player:SendMessageSuccess(Split[3] .. " has been kicked from your town");

			cRoot:Get():DoWithPlayerByUUID(UUID_target,
			function (Player_target)
				local sql = "SELECT town_name FROM towns WHERE town_id = ?";
				local parameter = {town_target[1]};
				town_target[3] = ExecuteStatement(sql, parameter)[1][1];
				Player_target:SendMessageInfo("You have been kicked from " .. town_target[3] .. " by " .. Player:GetName());
			end
			);

			if(Channel[UUID_target] == "town" or Channel[UUID_target] == "nation") then
				Channel[UUID_target] = "global";
			end
		end
	end

	return true;
end

function TownJoin(Split, Player)
	local UUID = Player:GetUUID();

	local sql = "SELECT town_id FROM invitations WHERE nation_id is null AND player_uuid = ?";
	local parameters = {UUID};
	local invitations = ExecuteStatement(sql, parameters);

	if not (invitations[1]) then
		Player:SendMessageFailure("You have no invitations!");
	else
		local townId;

		if not (Split[3]) then --The player doesn't specify which town he wants to join
			if (invitations[2]) then --If the player has more than 1 invitation
				Player:SendMessageFailure("You have multiple invitations, please specify which one you want to join:");
				for key, value in pairs(invitations) do
					Player:SendMessageInfo(GetTownName(value[1]));
				end

				return true;
			else --If the player has only 1 invitation
				townId = invitations[1][1];
			end
		else --The player did specify which town he wants to join
			townId = GetTownId(Split[3]);
		end

		if not (config.invitation_duration == 0) then --If invitations are set to expire
			local sql = "SELECT invitations.invitation_id, invitations.invitation_date, towns.town_name FROM invitations INNER JOIN towns ON invitations.town_id = towns.town_id WHERE invitations.town_id = ? AND invitations.player_uuid = ?";
			local parameters = {townId, UUID};
			local invitation = ExecuteStatement(sql, parameters)[1];

			if not (os.time(os.date("!*t")) - GetTimestampFromString(invitation[2]) <= tonumber(config.invitation_duration)) then
				local sql = "DELETE FROM invitations WHERE invitation_id = ?";
				local parameter = {invitation[1]};
				ExecuteStatement(sql, parameter);

				Player:SendMessageFailure("Sorry, the invitation of " .. invitation[3] .. " is expired. Please request a new one from the mayor!");
				return true;
			end
		end

		local sql = "INSERT INTO town_residents (player_uuid, town_id, town_rank) VALUES (?, ?, 'resident')";
		local parameters = {UUID, townId};
		ExecuteStatement(sql, parameters);

		local sql = "DELETE FROM invitations WHERE player_uuid = ?";
		local parameters = {UUID};
		ExecuteStatement(sql, parameters);

		local sql = "SELECT town_spawnX, town_spawnY, town_spawnZ, town_spawnWorld FROM towns WHERE town_id = ?";
		local parameter = {townId};
		local town = ExecuteStatement(sql, parameter)[1];

		local spawnWorld = cRoot:Get():GetWorld(town[4]); --Have to do this seperately, otherwise Cuberite complains
		Player:SetBedPos(Vector3i(town[1], town[2], town[3]), spawnWorld);

		Player:SendMessageSuccess("You succesfully joined the town!");
	end

	return true;
end

function TownLeave(Split, Player)
	local UUID = Player:GetUUID();

	local sql = "SELECT town_id FROM town_residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local townId = ExecuteStatement(sql, parameter)[1][1];

	if not (townId) then
		Player:SendMessageFailure("You can't leave a town if you're not in one");
	else
		if not (Leaving[UUID]) then
			local sql = "SELECT player_name FROM residents INNER JOIN town_residents ON residents.player_uuid = town_residents.player_uuid WHERE town_id = ?";
			local parameter = {townId};
			local playersInTown = ExecuteStatement(sql, parameter);

			if (playersInTown[2] == nil) then
				Player:SendMessageInfo("Since you are the last member of your town, leaving it will cause it to removed.");
				Player:SendMessageInfo("Use `/town leave` again if you wish to continue.");
			else
				Player:SendMessageInfo("Are you sure you want to leave?");
				Player:SendMessageInfo("Use `/town leave` again if you wish to continue.");
			end

			Leaving[UUID] = true;
		else --The user confirmed he/she wants to leave
			local sql = "SELECT town_name FROM towns WHERE town_id = ?";
			local parameter = {townId};
			local townName = ExecuteStatement(sql, parameter)[1][1];

			local sql = "DELETE FROM town_residents WHERE player_uuid = ?";
			local parameter = {UUID};
			ExecuteStatement(sql, parameter);

			local sql = "UPDATE plots SET owner = NULL WHERE owner = ?";
			local parameter = {UUID};
			ExecuteStatement(sql, parameter);

			local mainSpawn = cRoot:Get():GetDefaultWorld();
			Player:SetBedPos(Vector3i(mainSpawn:GetSpawnX(), mainSpawn:GetSpawnY(), mainSpawn:GetSpawnZ()), mainSpawn)

			local sql = "SELECT player_uuid FROM town_residents WHERE town_id = ?";
			local parameter = {townId};
			local playersLeft = ExecuteStatement(sql, parameter);

			if not (playersLeft[1]) then --Make sure we don't remove the town if somebody just joined
				DeleteTown(townId);

				Player:GetWorld():BroadcastChatInfo("The town " .. townName .. " fell in ruins!");
			else
				Player:SendMessageInfo("You left " .. townName);
			end

			Leaving[UUID] = nil;

			if (Channel[UUID] == "town" or Channel[UUID] == "nation") then
				Channel[UUID] = "global";
			end
		end
	end

	return true;
end

function TownList(Split, Player)
	local sql = "SELECT town_name FROM towns"
	local towns = ExecuteStatement(sql);

	Player:SendMessageSuccess("[ Towns ]")

	for key, value in pairs(towns) do
		Player:SendMessageSuccess(value[1]);
	end

	return true;
end

function TownOnline(Split, Player)
	local UUID = Player:GetUUID();

	local town = {
		GetPlayerTown(UUID)
	};

	if not (town[1]) then
		Player:SendMessageFailure("You are not part of a town!");
	else
		local sql = "SELECT DISTINCT player_uuid FROM town_residents WHERE town_id = ?";
		local parameter = {town[1]};
		local player_targets = ExecuteStatement(sql, parameter);

		Player:SendMessageInfo("[ Online players ]");

		for key, value in pairs(player_targets) do
			cRoot:Get():DoWithPlayerByUUID(value[1],
			function (cPlayer)
				local player_target = {cPlayer:GetUUID()};
				if not (player_target[1] == UUID) then
					local sql = "SELECT player_name FROM residents WHERE player_uuid = ?";
					local parameter = {player_target[1]};
					player_target[2] = ExecuteStatement(sql, parameter)[1][1]; --We know this will always return a result so don't check it
					player_target[3] = GetPlayerTownRank(player_target[1]);
					Player:SendMessageInfo(player_target[2] .. " - " .. player_target[3]);
				end
			end
			);
		end
	end

	return true;
end

function TownRank(Split, Player)
	local UUID = Player:GetUUID();

	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID)
	};

	if not (town[1]) then
		Player:SendMessageFailure("You are not part of a town!");
	elseif not (town[2] == 'mayor') and not (town[2] == 'assistant') then
		Player:SendMessageFailure("You have to be a mayor or assistant to do rank related tasks");
	else
		if not (Split[3]) then
			Player:SendMessageFailure("This command requires an extra parameter! Usage: /town rank (list/add/remove) {playername} {rank}");
		elseif (Split[3] == "list") then
			for key, value in pairs(ranks) do
				Player:SendMessageInfo(key);
			end
		elseif (Split[3] == "add" or Split[3] == "remove") then
			if not (Split[4]) then
				Player:SendMessageFailure("Please specify a player!");
			elseif not (Split[5]) then
				Player:SendMessageFailure("Please specify a rank!");
			elseif not (TownRanks[Split[5]]) then --Check if the specified rank actually exists
				Player:SendMessageFailure("The rank you specified doesn't exist!");
			elseif (Split[5] == 'resident') then
				Player:SendMessageFailure("You can not assign or remove a resident rank")
			else
				local UUID_target = cMojangAPI:GetUUIDFromPlayerName(Split[4], true);

				if (UUID_target == UUID) then --Check if the player didn't specify him/herself
					Player:SendMessageFailure("You can not change your own rank");
				elseif (UUID_target == "") then --Check if the player actually exists
					Player:SendMessageFailure("That player doesn't exist");
				else
					local sql = "SELECT town_id, town_rank FROM town_residents WHERE player_uuid = ?";
					local parameter = {UUID_target};
					local town_target = ExecuteStatement(sql, parameter);

					if not (town_target[1]) or not (town_target[1][1] == town[1]) then --Check if the specified player is actually part of the command invokers town
						Player:SendMessageFailure("That player is not part of your town!");
					else
						if (town[2] == 'assistant') and ((Split[5] == 'mayor') or (Split[5] == 'assistant')) then
							Player:SendMessageFailure("You are not high enough ranked to change this rank of others");
						elseif (town[2] == 'mayor') and (Split[5] == 'mayor') then
							Player:SendMessageFailure("There can only be one mayor");
						else
							local hasRank_target = false;
							for key, value in pairs(town_target) do
								if (value[2] == Split[5]) then
									hasRank_target = true;
								end
							end

							if (Split[3] == "add") then
								if (hasRank_target == true) then
									Player:SendMessageFailure("That player already has this rank!");
								else
									local sql = "INSERT INTO town_residents (player_uuid, town_id, town_rank) VALUES (?, ?, ?)";
									local parameters = {UUID_target, town[1], Split[5]};
									ExecuteStatement(sql, parameters);

									Player:SendMessageSuccess("Rank granted to the player!");
								end
							else
								if (hasRank_target == true) then
									local sql = "DELETE FROM town_residents WHERE player_uuid = ? AND town_rank = ?";
									local parameter = {UUID_target, Split[5]};
									ExecuteStatement(sql, parameter);
									Player:SendMessageSuccess("Rank removed from the player!");
								else
									Player:SendMessageFailure("That player doesn't have this rank");
								end
							end
						end
					end
				end
			end
		else
			Player:SendMessageFailure("Unknown action '" .. Split[3] .. "'");
		end
	end

	return true;
end

function TownToggleExplosions(Split, Player)
	local UUID = Player:GetUUID();

	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	if not (town[1]) then
		Player:SendMessageFailure("You have to be part of a town to toggle explosions");
	elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
		Player:SendMessageFailure("You have to be higher ranked to toggle explosions");
	else
		local sql = "SELECT town_features FROM towns WHERE town_id = ?";
		local parameter = {town[1]};
		town[3] = ExecuteStatement(sql, parameter)[1][1];

		local newStatus;
		if (bit32.band(town[3], TOWNEXPLOSIONSENABLED) == 0) then --Explosions are off
			newStatus = bit32.bor(town[3], TOWNEXPLOSIONSENABLED);
			Player:SendMessageSuccess("Explosions are now enabled");
		else --Explosions are on
			newStatus = bit32.bxor(town[3], TOWNEXPLOSIONSENABLED);
			Player:SendMessageSuccess("Explosions are now disabled");
		end

		local sql = "UPDATE towns SET town_features = ? WHERE town_id = ?";
		local parameters = {newStatus, town[1]};
		ExecuteStatement(sql, parameters);
	end
	return true;
end

function TownTogglePVP(Split, Player)
	local UUID = Player:GetUUID();

	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	if not (town[1]) then
		Player:SendMessageFailure("You have to be part of a town to toggle pvp");
	elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
		Player:SendMessageFailure("You have to be higher ranked to toggle pvp");
	else
		local sql = "SELECT town_features FROM towns WHERE town_id = ?";
		local parameter = {town[1]};
		town[3] = ExecuteStatement(sql, parameter)[1][1];

		local newStatus;
		if (bit32.band(town[3], TOWNPVPENABLED) == 0) then --PVP is off
			newStatus = bit32.bor(town[3], TOWNPVPENABLED);
			Player:SendMessageSuccess("PVP is now enabled");
		else --PVP is on
			newStatus = bit32.bxor(town[3], TOWNPVPENABLED);
			Player:SendMessageSuccess("PVP is now disabled");
		end

		local sql = "UPDATE towns SET town_features = ? WHERE town_id = ?";
		local parameters = {newStatus, town[1]};
		ExecuteStatement(sql, parameters);
	end

	return true;
end

function TownToggleMobs(Split, Player)
	local UUID = Player:GetUUID();

	local town = {
		GetPlayerTown(UUID),
		GetPlayerTownRank(UUID);
	};

	if not (town[1]) then
		Player:SendMessageFailure("You have to be part of a town to toggle pvp");
	elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
		Player:SendMessageFailure("You have to be higher ranked to toggle pvp");
	else

		local sql = "SELECT town_features FROM towns WHERE town_id = ?";
		local parameter = {town[1]};
		town[3] = ExecuteStatement(sql, parameter)[1][1];

		local newStatus;
		if (bit32.band(town[3], TOWNMOBSENABLED) == 0) then --Mobs are off
			newStatus = bit32.bor(town[3], TOWNMOBSENABLED);
			Player:SendMessageSuccess("Mob spawning is now enabled");
		else --Mobs are on
			newStatus = bit32.bxor(town[3], TOWNMOBSENABLED);
			Player:SendMessageSuccess("Mob spawning is now disabled");
		end

		local sql = "UPDATE towns SET town_features = ? WHERE town_id = ?";
		local parameters = {newStatus, town[1]};
		ExecuteStatement(sql, parameters);
	end

	return true;
end

function TownSpawn(Split, Player)
	if not (config.enable_town_spawns == 1) and not (Player:HasPermission("townvalds.town.spawn.admin")) then
		Player:SendMessageFailure("Teleporting to town spawns is disabled by the server administrator");
	else
		local townId = GetPlayerTown(Player:GetUUID());
		local townId_target;
		if (Split[3]) and not (GetTownId(Split[3]) == townId) then
			if not (Player:HasPermission("townvalds.town.spawn.other")) and not (Player:HasPermission("townvalds.town.spawn.admin")) then
				Player:SendMessageFailure("You are not allowed to teleport to another town");
				return true;
			else
				townId_target = GetTownId(Split[3]);

				if not (Player:HasPermission("townvalds.town.spawn.admin")) and (config.teleport_to_friendly_town_spawns_only == 1) then
					local sql = "SELECT nation_id FROM towns WHERE town_id = ?";
					local parameter = {townId};
					local nationId = ExecuteStatement(sql, parameter)[1];

					local sql = "SELECT nation_id FROM towns WHERE town_id = ?";
					local parameter = {townId_target};
					local nationId_target = ExecuteStatement(sql, parameter)[1];

					if not (nationId[1] == nationId_target[1]) then
						Player:SendMessageFailure("You are only allowed to teleport to friendly towns (towns within your nation)");
						return true;
					end
				end
			end
		else
			if not (townId) then
				Player:SendMessageFailure("You are not part of a town you can teleport to");
				return true;
			else
				townId_target = townId;
			end
		end

		local sql = "SELECT town_spawnX, town_spawnY, town_spawnZ, town_spawnWorld FROM towns WHERE town_id = ?";
		local parameter = {townId_target};
		local spawn_target = ExecuteStatement(sql, parameter)[1];

		if not (spawn_target) then
			Player:SendMessageFailure("That town does not exist");
		else
			local world_target = cRoot:Get():GetWorld(spawn_target[4]);

			if (world_target:GetName() == Player:GetWorld():GetName()) then --If the player is already in the world of the spawn, just teleport
				Player:TeleportToCoords(spawn_target[1], spawn_target[2], spawn_target[3]);
			else --Otherwise move the player between dimensions
				Player:MoveToWorld(world_target, false, Vector3d(spawn_target[1], spawn_target[2], spawn_target[3]));
			end
		end
	end

	return true;
end

function TownSpawnSet(Split, Player)
	if not (config.enable_town_spawns) then
		Player:SendMessageFailure("Town spawns are disabled by the server administrator");
	else
		local UUID = Player:GetUUID();

		local town = {
			GetPlayerTown(UUID),
			GetPlayerTownRank(UUID);
		};

		if not (town[1]) then
			Player:SendMessageFailure("You have to be part of a town to set it's spawn");
		elseif not (TownRanks[town[2]] >= TownRanks['assistant']) then
			Player:SendMessageFailure("You have to be higher ranked to set a new town spawn");
		else
			local sql = "SELECT player_uuid FROM town_residents WHERE town_id = ?";
			local parameter = {town[1]};
			local townMembers = ExecuteStatement(sql, parameter);

			cRoot:Get():ForEachPlayer(
			function (cPlayer)
				local cPlayerUUID = cPlayer:GetUUID();
				for key, value in pairs(townMembers) do
					if (cPlayerUUID == value[1]) then
						cPlayer:SetBedPos(Vector3i(Player:GetPosX(), Player:GetPosY(), Player:GetPosZ()), Player:GetWorld());
					end
				end
			end
			);

			local sql = "UPDATE towns SET town_spawnX = ?, town_spawnY = ?, town_spawnZ = ?, town_spawnWorld = ? WHERE town_id = ?";
			local parameters = {Player:GetPosX(), Player:GetPosY(), Player:GetPosZ(), Player:GetWorld():GetName(), town[1]};
			ExecuteStatement(sql, parameters);

			Player:SendMessageSuccess("The new town spawn is set");
		end
	end

	return true;
end

function TownPermSet(Split, Player)
	local UUID = Player:GetUUID();

	if not (Split[4] == 'resident') and not (Split[4] == 'ally') and not (Split[4] == 'outsider') then
		Player:SendMessageFailure("You have to specify the level of permission you want to change");
		Player:SendMessageFailure("Resident, ally or outsider");
	elseif not (Split[5] == 'build') and not (Split[5] == 'destroy') and not (Split[5] == 'switch') and not (Split[5] == 'itemuse') then
		Player:SendMessageFailure("You have to specify which permission you want to change");
		Player:SendMessageFailure("Build, destroy, switch or itemuse");
	elseif not (Split[6] == 'on') and not (Split[6] == 'off') then
		Player:SendMessageFailure("You have to specify if you want to turn this permission on or off");
	else
		local sql = "SELECT towns.town_id, towns.nation_id, towns.town_permissions FROM towns INNER JOIN town_residents ON towns.town_id = town_residents.town_id WHERE town_residents.player_uuid = ?";
		local parameter = {UUID};
		local town = ExecuteStatement(sql, parameter)[1];

		if not (town) then
			Player:SendMessageFailure("You have to be in a town to change it's permissions");
		else
			if not (TownRanks[GetPlayerTownRank(UUID)] >= TownRanks['assistant']) then
				Player:SendMessageFailure("You are not high enough ranked to change the town permissions");
			else
				local modifiedPermission;

				if (Split[4] == 'resident') then
					if (Split[5] == 'build') then
						modifiedPermission = RESIDENTBUILD;
					elseif (Split[5] == 'destroy') then
						modifiedPermission = RESIDENTDESTROY;
					elseif (Split[5] == 'switch') then
						modifiedPermission = RESIDENTSWITCH;
					else
						modifiedPermission = RESIDENTITEMUSE;
					end
				elseif (Split[4] == 'ally') then
					if (Split[5] == 'build') then
						modifiedPermission = ALLYBUILD;
					elseif (Split[5] == 'destroy') then
						modifiedPermission = ALLYDESTROY;
					elseif (Split[5] == 'switch') then
						modifiedPermission = ALLYSWITCH;
					else
						modifiedPermission = ALLYITEMUSE;
					end
				else
					if (Split[5] == 'build') then
						modifiedPermission = OUTSIDERBUILD;
					elseif (Split[5] == 'destroy') then
						modifiedPermission = OUTSIDERDESTROY;
					elseif (Split[5] == 'switch') then
						modifiedPermission = OUTSIDERSWITCH;
					else
						modifiedPermission = OUTSIDERITEMUSE;
					end
				end

				local newPermissions = town[3];

				if (Split[6] == 'on') then
					newPermissions = bit32.bor(newPermissions, modifiedPermission);
				elseif (Split[6] == 'off') then
					newPermissions = bit32.bxor(newPermissions, modifiedPermission);
				end

				local sql = "UPDATE towns SET town_permissions = ? WHERE town_id = ?";
				local parameters = {newPermissions, town[1]};
				ExecuteStatement(sql, parameters);
			end
		end
	end
	return true;
end
