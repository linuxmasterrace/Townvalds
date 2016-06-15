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
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);
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
	local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);
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
		local sql = "SELECT COUNT(*) FROM towns WHERE nation_id = ?";
		local parameter = {town[3]};
		local townInNationCount = ExecuteStatement(sql, parameter)[1][1];

		if not (LeavingNation[UUID] == nil) then --The mayor wants to leave the nation
			local sql = "SELECT nation_name FROM nations WHERE nation_id = ?";
			local parameter = {town[3]};
			local nationName = ExecuteStatement(sql, parameter)[1][1];

			if(townInNationCount == 1) then
				local sql = "UPDATE towns SET nation_id = NULL WHERE town_owner = ?";
				local parameter = {UUID};
				ExecuteStatement(sql, parameter);

				local sql = "DELETE FROM nations WHERE nation_id = ?";
				local parameter = {town[3]};
				ExecuteStatement(sql, parameter);

				--Delete the nation from each world's team list
				cRoot:Get():ForEachWorld(
				function(cWorld)
					cWorld:GetScoreBoard():RemoveTeam(nationName);
				end
				);

				Player:GetWorld():BroadcastChatInfo("The nation " .. nationName .. " was abandoned!");
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
