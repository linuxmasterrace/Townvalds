function TownCreate(Split, Player)
	if (Split[3] == nil) then
		Player:SendMessageFailure("You have to enter a town name! Usage: /town new (name)");
		return true;
	end

	local UUID = Player:GetUUID();
	local townId = GetPlayerTown(UUID);

	if not (townId == nil) then
		Player:SendMessageFailure("Please leave your current town before you create a new one");
	else
		local sql = "SELECT town_name FROM towns WHERE town_name = ?";
		local parameter = {Split[3]};
		local townName = ExecuteStatement(sql, parameter)[1];

		if (townName) then
			Player:SendMessageFailure("There already exists a town with that name, please choose a different one");
		else
			local sql = "SELECT * FROM townChunks WHERE (chunkX > ? AND chunkX < ?) AND (chunkZ > ? AND chunkZ < ?)";
			local parameters = {Player:GetChunkX() - config.min_distance_from_other_towns - 1, Player:GetChunkX() + config.min_distance_from_other_towns + 1, Player:GetChunkZ() - config.min_distance_from_other_towns - 1, Player:GetChunkZ() + config.min_distance_from_other_towns + 1};
			local remote_town = ExecuteStatement(sql, parameters);

			if (remote_town[1]) then --There is already a town close-by
				Player:SendMessageFailure("You're too close to an existing town, please move further away before trying to create a new town.");
			else -- Insert the town data in the database
				local sql = "INSERT INTO towns (town_name, town_owner, town_explosions_enabled, town_pvp_enabled) VALUES (?, ?, ?, ?)";
				local parameters = {Split[3], UUID, 0, 0};
				local townId = ExecuteStatement(sql, parameters);

				local sql = "INSERT INTO townChunks (town_id, chunkX, chunkZ, world) VALUES (?, ?, ?, ?)";
				local parameters = {townId, Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
				ExecuteStatement(sql, parameters);

				local sql = "UPDATE residents SET town_id = ? WHERE player_uuid = ?";
				local parameters = {townId, UUID};
				ExecuteStatement(sql, parameters);

				Player:SendMessageSuccess("Created a new town called " .. Split[3]);
			end
		end
	end

	return true;
end

Deleting = {};
function TownDelete(Split, Player)
	local UUID = Player:GetUUID();
	local townId = GetPlayerTown(UUID);

	if (Deleting[UUID]) then
		local sql = "SELECT town_name FROM towns WHERE town_id = ?";
		local parameter = {Deleting[UUID]};
		local townName = ExecuteStatement(sql, parameter)[1][1];

		DeleteTown(Deleting[UUID]);
		Deleting[UUID] = nil;
		Player:SendMessageSuccess(townName .. " has been deleted");
	else
		local town;
		if (Split[3]) then
			local sql = "SELECT town_id, town_name, town_owner FROM towns WHERE town_name = ?";
			local parameter = {Split[3]};
			town = ExecuteStatement(sql, parameter)[1];

			if not (town) then
				Player:SendMessageFailure("That town does not exist");
				return true;
			end
		else
			local sql = "SELECT town_id, town_name, town_owner FROM towns WHERE town_id = ?";
			local parameter = {townId};
			town = ExecuteStatement(sql, parameter)[1];
		end

		if (town[1] == townId) then
			if (town[3] == UUID) then
				Deleting[UUID] = town[1];
				Player:SendMessageInfo("Are you sure you want to delete " .. town[2] .. "?");
				Player:SendMessageInfo("Use `/town delete` again if you wish to continue.");
			else
				if not (Player:HasPermission("townvalds.town.delete.other")) then
					Player:SendMessageFailure("You have to be the owner of your town to delete it");
				else
					Deleting[UUID] = town[1];
					Player:SendMessageInfo("Are you sure you want to delete " .. town[2] .. "?");
					Player:SendMessageInfo("Use `/town delete` again if you wish to continue.");
				end
			end
		else
			if not (Player:HasPermission("townvalds.town.delete.other")) then
				Player:SendMessageFailure("You are not allowed to delete someone else's town");
			else
				Deleting[UUID] = town[1];
				Player:SendMessageInfo("Are you sure you want to delete " .. town[2] .. "?");
				Player:SendMessageInfo("Use `/town delete` again if you wish to continue.");
			end
		end
	end

	return true;
end

function TownClaim(Split, Player)
	local UUID = Player:GetUUID();

	if (InTown[UUID]) then
		Player:SendMessageFailure("You can't claim land that is already part of a town!");
	else
		local townId = GetPlayerTown(Player:GetUUID());

		local sql = "SELECT towns.town_id, towns.town_owner FROM towns INNER JOIN residents ON towns.town_id = residents.town_id WHERE residents.player_uuid = ?";
		local parameter = {UUID};
		local town = ExecuteStatement(sql, parameter)[1];

		if (town == nil) then
			Player:SendMessageFailure("You can't claim land if you're not part of a town!");
		elseif not (town[2] == UUID) then
			Player:SendMessageFailure("You can't claim land if you're not the mayor of your town!");
		else
			local sql = "SELECT town_id FROM townChunks WHERE town_id = ? AND (chunkX = ? + 1 OR chunkX = ? OR chunkX = ? - 1) AND (chunkZ = ? + 1 OR chunkZ = ? OR chunkZ = ? - 1)";
			local parameters = {townId, Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkX(), Player:GetChunkZ(), Player:GetChunkZ(), Player:GetChunkZ()};
			local result = ExecuteStatement(sql, parameters)[1];

			if not (result) then
				Player:SendMessageFailure("You have to be next to your town to claim land!");
			else -- The chunk to be claimed is next to an already existing chunk of the town
				local sql = "INSERT INTO townChunks (town_id, chunkX, chunkZ, world) VALUES (?, ?, ?, ?)";
				local parameters = {town[1], Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
				ExecuteStatement(sql, parameters);

				Player:SendMessageSuccess("Land succesfully claimed");
			end
		end
	end

	return true;
end

function TownUnclaim(Split, Player)
	local UUID = Player:GetUUID();

	if not (InTown[UUID]) then
		Player:SendMessageFailure("You can't unclaim land if you're not inside a town!");
	else
		local townId = GetPlayerTown(UUID);

		local sql = "SELECT town_owner FROM towns INNER JOIN residents ON towns.town_id = residents.town_id WHERE residents.player_uuid = ?";
		local parameter = {UUID};
		local town = ExecuteStatement(sql, parameter)[1];

		if (town == nil) then
			Player:SendMessageFailure("You can't unclaim land if you're not part of this town!");
		elseif not (town[1] == UUID) then
			Player:SendMessageFailure("You can't unclaim land if you're not the mayor of this town!");
		else
			local sql = "SELECT COUNT(*) FROM townChunks WHERE town_id = ?";
			local parameter = {townId};
			local chunkCount = ExecuteStatement(sql, parameter)[1][1];

			if (chunkCount == 1) then
				Player:SendMessageFailure("Since this is the last chunk of this town, you can't remove it!");
			else
				local sql = "DELETE FROM townChunks WHERE town_id = ? AND chunkX = ? AND chunkZ = ? AND world = ?";
				local parameters = {townId, Player:GetChunkX(), Player:GetChunkZ(), Player:GetWorld():GetName()};
				ExecuteStatement(sql, parameters);

				Player:SendMessageSuccess("Land succesfully unclaimed.");
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
	local townId = GetPlayerTown(UUID);

	if not (townId) then
		Player:SendMessageFailure("You have to be in a town to invite players!");
	else
		local UUID_target = cMojangAPI:GetUUIDFromPlayerName(Split[3], true);

		if (UUID_target == "") then
			Player:SendMessageFailure("This player does not exist.");
			return true;
		end

		local townId_target = GetPlayerTown(UUID_target);

		if (townId_target == townId) then
			Player:SendMessageFailure(Split[3] .. " already belongs to your town");
		elseif (townId_target) then
			Player:SendMessageFailure(Split[3] .. " already belongs to a town");
		else
			local sql = "SELECT * FROM invitations WHERE player_uuid = ? AND town_id = ?";
			local parameters = {UUID_target, townId};
			local result = ExecuteStatement(sql, parameters)[1];

			if (result) then
				Player:SendMessageFailure(Split[3] .. " is already invited to your town");
			else
				local sql = "INSERT INTO invitations (player_uuid, town_id) VALUES (?, ?)";
				local parameters = {UUID_target, townId};
				ExecuteStatement(sql, parameters);

				Player:SendMessageSuccess(Split[3] .. " is succesfully invited to your town");
			end
		end
	end

	return true;
end

function TownKickPlayer(Split, Player)
	if (Split[3] == nil) then
		Player:SendMessageFailure("You need to specify a player.");
		return true;
	end

	local UUID = Player:GetUUID();
	local townId = GetPlayerTown(UUID);
	local UUID_target = cMojangAPI:GetUUIDFromPlayerName(Split[3]);

	if (UUID_target == "") then
		Player:SendMessageFailure("This player does not exist.");
		return true;
	elseif (UUID_target == UUID) then
		Player:SendMessageFailure("You can't kick yourself");
		return true;
	end

	if not (townId) then
		Player:SendMessageFailure("You have to be in a town to kick players");
	elseif not (townId == GetPlayerTown(UUID_target)) then
		Player:SendMessageFailure(Split[3] .. " is not a resident of your town");
	else
		local sql = "SELECT town_name, town_owner FROM towns WHERE town_id = ?";
		local parameter = {townId};
		local town = ExecuteStatement(sql, parameter)[1];

		if not (town[2] == UUID) then
			Player:SendMessageFailure("You have to be the town mayor to kick residents")
		else
			local sql = "UPDATE residents SET town_id = NULL WHERE player_uuid = ?";
			local parameter = {UUID_target};
			ExecuteStatement(sql, parameter);

			Player:SendMessageSuccess(Split[3] .. " has been kicked from your town");

			cRoot:Get():DoWithPlayerByUUID(UUID_target,
			function (Player_target)
				Player_target:SendMessageInfo("You have been kicked from " .. town[1] .. " by " .. Player:GetName());
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

	local sql = "SELECT town_id FROM invitations WHERE player_uuid = ?";
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

		local sql = "UPDATE residents SET town_id = ? WHERE player_uuid = ?";
		local parameters = {townId, UUID};
		ExecuteStatement(sql, parameters);

		local sql = "DELETE FROM invitations WHERE player_uuid = ?";
		local parameters = {UUID};
		ExecuteStatement(sql, parameters);

		Player:SendMessageSuccess("You succesfully joined the town!");
	end

	return true;
end

Leaving = {};
function TownLeave(Split, Player)
	local UUID = Player:GetUUID();

	local sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local townId = ExecuteStatement(sql, parameter)[1][1];

	if not (townId) then
		Player:SendMessageFailure("You can't leave a town if you're not in one");
	else
		if not (Leaving[UUID]) then
			local sql = "SELECT player_name FROM residents WHERE town_id = ?";
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

			local sql = "UPDATE residents SET town_id = NULL WHERE player_uuid = ?";
			local parameter = {UUID};
			ExecuteStatement(sql, parameter);

			local sql = "UPDATE townChunks SET owner = NULL WHERE owner = ?";
			local parameter = {UUID};
			ExecuteStatement(sql, parameter);

			local sql = "SELECT player_uuid FROM residents WHERE town_id = ?";
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

function TownRank(Split, Player)
	local UUID = Player:GetUUID();

	local sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local townId = ExecuteStatement(sql, parameter)[1][1];

	if not(townId) then
		Player:SendMessageFailure("You are not part of a town!");
	else
		local ranks = Set{"assistent"};

		if not (Split[3]) then
			Player:SendMessageFailure("This command requires an extra parameter! Usage: /town rank (list/add/remove) {rank} {playername}");
		elseif (Split[3] == "list") then
			for key, value in pairs(ranks) do
				Player:SendMessageInfo(key);
			end
		elseif (Split[3] == "add" or Split[3] == "remove") then
			if not (Split[4]) then
				Player:SendMessageFailure("Please specify a rank!");
			else
				if not (ranks[Split[4]]) then --Check if the specified rank actually exists
					Player:SendMessageFailure("The rank you specified doesn't exist!");
				else
					if not (Split[5]) then
						Player:SendMessageFailure("Please specify a player!");
					else
						local UUID_target = cMojangAPI:GetUUIDFromPlayerName(Split[5], true);

						if (UUID_target == UUID) then --Check if the player didn't specify him/herself
							Player:SendMessageFailure("You can not change your own rank");
						elseif (UUID_target == "") then --Check if the player actually exists
							Player:SendMessageFailure("The specified player doesn't exist");
						else
							local sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
							local parameter = {UUID_target};
							local townId_target = ExecuteStatement(sql, parameter)[1][1];

							if not (townId_target == townId) then --Check if the specified player is actually part of the command invokers town
								Player:SendMessageFailure("The specified player is not part of your town!");
							else
								if (Split[3] == "add") then
									local sql = "UPDATE residents SET town_rank = ? WHERE player_uuid = ?";
									local parameters = {Split[4], player_uuid};
									ExecuteStatement(sql, parameters);

									Player:SendMessageSuccess("Rank granted to the player!");
								else
									local sql = "UPDATE residents SET town_rank = NULL WHERE player_uuid = ?";
									local parameter = {UUID_target};
									ExecuteStatement(sql, parameter);

									Player:SendMessageSuccess("Rank removed from the player!");
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

	if not (InTown[Player:GetUUID()]) then
		Player:SendMessageFailure("You can't toggle if you're not inside your town!");
	else
		local townId = GetPlayerTown(UUID);

		local sql = "SELECT town_owner, town_explosions_enabled FROM towns WHERE town_id = ?";
		local parameter = {townId};
		local town = ExecuteStatement(sql, parameter)[1];

		if not (town) then
			Player:SendMessageFailure("You can't toggle if you're not part of this town!");
		elseif not (town[1] == UUID) then
			Player:SendMessageFailure("You can't toggle if you're not the owner of this town!");
		else
			local sql = "UPDATE towns SET town_explosions_enabled = ? WHERE town_id = ?";
			local parameter;

			if (town[2] == 0) then
				parameter = {1, townId};

				Player:SendMessageSuccess("Explosions enabled");
			else
				parameter = {0, townId};

				Player:SendMessageSuccess("Explosions disabled");
			end

			ExecuteStatement(sql, parameter);
		end
	end

	return true;
end

function TownTogglePVP(Split, Player)
	local UUID = Player:GetUUID();

	if not (InTown[Player:GetUUID()]) then
		Player:SendMessageFailure("You can't toggle if you're not inside your town!");
	else
		local townId = GetPlayerTown(UUID);

		local sql = "SELECT town_owner, town_pvp_enabled FROM towns WHERE town_id = ?";
		local parameter = {townId};
		local town = ExecuteStatement(sql, parameter)[1];

		if not (town) then
			Player:SendMessageFailure("You can't toggle if you're not part of this town!");
		elseif not (town[1] == UUID) then
			Player:SendMessageFailure("You can't toggle if you're not the owner of this town!");
		else
			local sql = "UPDATE towns SET town_pvp_enabled = ? WHERE town_id = ?";
			local parameter;

			if (town[2] == 0) then
				parameter = {1, townId};

				Player:SendMessageSuccess("PVP enabled");
			else
				parameter = {0, townId};

				Player:SendMessageSuccess("PVP disabled");
			end

			ExecuteStatement(sql, parameter);
		end
	end

	return true;
end

function TownToggleMobs(Split, Player)
	local UUID = Player:GetUUID();

	if not (InTown[Player:GetUUID()]) then
		Player:SendMessageFailure("You can't toggle if you're not inside your town!");
	else
		local townId = GetPlayerTown(UUID);

		local sql = "SELECT town_owner, town_mobs_enabled FROM towns WHERE town_id = ?";
		local parameter = {townId};
		local town = ExecuteStatement(sql, parameter)[1];

		if not (town) then
			Player:SendMessageFailure("You can't toggle if you're not part of this town!");
		elseif not (town[1] == UUID) then
			Player:SendMessageFailure("You can't toggle if you're not the owner of this town!");
		else
			local sql = "UPDATE towns SET town_mobs_enabled = ? WHERE town_id = ?";
			local parameter;

			if (town[2] == 0) then
				parameter = {1, townId};

				Player:SendMessageSuccess("Mob spawning enabled");
			else
				parameter = {0, townId};

				Player:SendMessageSuccess("Mob spawning disabled");
			end

			ExecuteStatement(sql, parameter);
		end
	end

	return true;
end
