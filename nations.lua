--Syncs existing nations with nations in the database
function NationSync()
	cRoot:Get():ForEachWorld(
	function (cWorld)
		local scoreboard = cWorld:GetScoreBoard();

		local sql = "SELECT nation_name FROM nations";
		local result = ExecuteStatement(sql);

		if not (result == nil) then
			for key, value in pairs(result) do
				if (scoreboard:GetTeam(value[1]) == nil) then
					scoreboard:RegisterTeam(value[1], value[1], "", "");
				end
			end
		end

		local existingTeams = scoreboard:GetTeamNames();
		for key, value in pairs(existingTeams) do

			if not (result == nil) then
				local inDatabase = false;

				for dbKey, dbValue in pairs(result) do
					if(dbValue[1] == value) then
						inDatabase = true;
						break;
					end
				end

				if(inDatabase == false) then
					scoreboard:RemoveTeam(value);
				end
			else
				scoreboard:RemoveTeam(value);
			end
		end
	end
	);

	return true;
end


--Creates a new nation
function NationCreate(Split, Player)
	local UUID = Player:GetUUID();
	local sql = "SELECT towns.town_id, towns.town_owner, towns.nation_id FROM towns INNER JOIN residents ON towns.town_id == residents.town_id WHERE residents.player_uuid = ?";
	local parameter = {UUID};
	local town = ExecuteStatement(sql, parameter)[1];

	if (town == nil) then
		Player:SendMessageFailure("You can not create a nation if you're not part of a town!");
	elseif not (town[2] == UUID) then
		Player:SendMessageFailure("You can not create a nation if you're not the owner of a town!");
	elseif not (town[3] == nil) then
		Player:SendMessageFailure("Your town is already part of a nation!");
	else
		local sql = "INSERT INTO nations (nation_name, nation_capital) VALUES (?, ?)";
		local parameters = {Split[3], town[1]};
		local nation_id = ExecuteStatement(sql, parameters);

		local sql = "UPDATE towns SET nation_id = ? WHERE town_id = ?";
		local parameters = {nation_id, town[1]};
		ExecuteStatement(sql, parameters);

		cRoot:Get():ForEachWorld(
		function(cWorld)
			cWorld:GetScoreBoard():RegisterTeam(Split[3], Split[3], "", "");
		end
		);

		Player:SendMessageSuccess("Created a new nation called " .. Split[3]);
	end
	return true;
end

--Removes the player's town from the nation
LeavingNation = {};
function NationLeave(Split, Player)
	local UUID = Player:GetUUID();
	local sql = "SELECT towns.town_id, towns.town_owner, towns.nation_id FROM towns INNER JOIN residents ON towns.town_id = residents.town_id WHERE residents.player_uuid = ?";
	local parameter = {UUID};
	local town = ExecuteStatement(sql, parameter)[1];

	if(town == nil) then
		Player:SendMessageFailure("You can not leave nation if you're not part of a town!");
	elseif not (town[2] == UUID) then
		Player:SendMessageFailure("You can not leave a nation if you're not the owner of a town!");
	elseif (town[3] == nil) then
		Player:SendMessageFailure("Your town is not part of a nation!");
	else
		local sql = "SELECT nation_id, nation_name, nation_capital FROM nations WHERE nation_id = ?";
		local parameter = {town[3]};
		local nation = ExecuteStatement(sql, parameter)[1];

		local sql = "SELECT COUNT(*) FROM towns WHERE nation_id = ?";
		local parameter = {town[3]};
		local townInNationCount = ExecuteStatement(sql, parameter)[1][1];

		if (nation[3] == town[1]) and (townInNationCount > 1) then
			LeavingNation[UUID] = nil; --Make sure to clear the leaving queue, otherwise the town could leave if it's set as capital between the 2 commands
			Player:SendMessageFailure("Since your town is the capital, you can't leave the nation");
			Player:SendMessageFailure("First set a new capital using '/nation set capital [townname]'");
		else
			if (LeavingNation[UUID]) then --The mayor wants to leave the nation
				local sql = "SELECT player_uuid FROM residents WHERE town_id = ?";
				local parameter = {town[1]};
				local players = ExecuteStatement(sql, parameter);

				for key, value in pairs(players) do
					if (Channel[value[1]] == "nation") then
						Channel[value[1]] = "town";
					end
				end

				if(townInNationCount == 1) then
					local sql = "DELETE FROM nations WHERE nation_id = ?";
					local parameter = {town[3]};
					ExecuteStatement(sql, parameter);

					--Delete the nation from each world's team list
					cRoot:Get():ForEachWorld(
					function(cWorld)
						cWorld:GetScoreBoard():RemoveTeam(nation[2]);
					end
					);

					Player:GetWorld():BroadcastChatInfo("The nation " .. nation[2] .. " was abandoned!");
				else
					local sql = "UPDATE towns SET nation_id = NULL WHERE town_id = ?";
					local parameter = {town[1]};
					ExecuteStatement(sql, parameter);

					Player:SendMessageSuccess("Your town left the nation");
				end

				LeavingNation[UUID] = nil;
			else
				if(townInNationCount == 1) then
					Player:SendMessageInfo("Since your town is the last member of this nation, leaving it will cause it to be removed.");
					Player:SendMessageInfo("Use `/nation leave` again if you wish to continue.");
				else
					Player:SendMessageInfo("Are you sure you want your town to leave the nation?");
					Player:SendMessageInfo("Use `/nation leave` again if you wish to continue.");
				end

				LeavingNation[UUID] = true;
			end
		end
	end

	return true;
end


--Prints a list of nations to the player
function NationList(Split, Player)
	--Get nations from world instead of database to save queries
	--Since nations are always synced between worlds, this should work properly at all times
	local nations = Player:GetWorld():GetScoreBoard():GetTeamNames();
	if not (next(nations) == nil) then
		Player:SendMessageInfo("[ Nations ]");
		for key, value in pairs(nations) do
			Player:SendMessageInfo(value);
		end
	else
		Player:SendMessageInfo("There are no nations yet!");
	end

	return true;
end

--Toggles friendly fire in the nation
function NationToggleFriendlyFire(Split, Player)
	local UUID = Player:GetUUID();
	local sql = "SELECT towns.town_id, towns.nation_id FROM towns INNER JOIN residents ON towns.town_id = residents.town_id WHERE residents.player_uuid = ?";
	local parameter = {UUID};
	local town = ExecuteStatement(sql, parameter)[1];

	if (town == nil) then
		Player:SendMessageFailure("You're not part of a town");
	elseif (town[2] == nil) then
		Player:SendMessageFailure("Your town is not part of a nation");
	else
		local sql = "SELECT nation_name, nation_capital FROM nations WHERE nation_id = ?";
		local parameter = {town[2]};
		local nation = ExecuteStatement(sql, parameter)[1];

		local cTeam = Player:GetWorld():GetScoreBoard():GetTeam(nation[1]);

		if not(nation[2] == town[2]) then
			Player:SendMessageFailure("Your town is not the capital of this nation");
		else
			if(cTeam:AllowsFriendlyFire()) then
				cTeam:SetFriendlyFire(false);
				Player:SendMessageSuccess("Friendly fire is now disabled");
			else
				cTeam:SetFriendlyFire(true);
				Player:SendMessageSuccess("Friendly fire is now enabled")
			end
		end
	end

	return true;
end

function NationSetCapital(Split, Player)
	if not (Split[4]) then
		Player:SendMessageFailure("You have to specify the new capital");
		return true;
	end

	local UUID = Player:GetUUID();

	local sql = "SELECT town_id, town_owner, nation_id FROM towns WHERE town_id = ?";
	local parameter = {GetPlayerTown(UUID)};
	local town = ExecuteStatement(sql, parameter)[1];

	if not (town) then
		Player:SendMessageFailure("You're not part of a town");
	elseif not (town[2] == UUID) then --If the player is not the mayor of his town, then there is no way he is the king
		Player:SendMessageFailure("You're not the king of this nation");
	else
		local sql = "SELECT nation_id, nation_name, nation_capital FROM nations WHERE nation_id = ?";
		local parameter = {town[3]};
		local nation = ExecuteStatement(sql, parameter)[1];

		if not (nation) then
			Player:SendMessageFailure("You're town is not part of a nation");
		elseif not (nation[3] == town[1]) then --If the player's town is not the capital of the nation, then there is no way he is the king
			Player:SendMessageFailure("You're not the king of this nation");
		else
			local townId_remote = GetTownId(Split[4]);
			if not (townId_remote) then
				Player:SendMessageFailure("That town doesn't exist");
			else
				local sql = "SELECT town_id, town_name, nation_id FROM towns WHERE town_id = ?";
				local parameter = {townId_remote};
				local town_remote = ExecuteStatement(sql, parameter)[1];

				if not (town_remote) then
					Player:SendMessageFailure("That town is not part of a nation");
				elseif not (town_remote[3] == nation[1]) then
					Player:SendMessageFailure("That town is part of a different nation");
				else
					local sql = "UPDATE nations SET nation_capital = ? WHERE nation_id = ?";
					local parameters = {town_remote[1], nation[1]};
					ExecuteStatement(sql, parameters);

					Player:SendMessageSuccess(town_remote[2] .. " is now the new capital of " .. nation[2]);
				end
			end
		end
	end

	return true;
end
