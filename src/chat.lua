function OnChat(Player, Message)
	if(config.handle_chat == true) then --Only handle chat if set so in the config
		local UUID = Player:GetUUID();
		local senderName = Player:GetName();

		--If the player is in the specified channel, send it to the players having that channel active
		if(Channel[UUID] == "nation") then --Nation channel
			local sql = "SELECT residents.player_uuid FROM residents INNER JOIN towns ON residents.town_id = towns.town_id WHERE towns.nation_id = (SELECT nations.nation_id FROM nations INNER JOIN towns ON nations.nation_id = towns.nation_id INNER JOIN residents ON towns.town_id = residents.town_id WHERE residents.player_uuid = ?)";
			local parameter = {UUID};
			local players = ExecuteStatement(sql, parameter);

			for key, value in pairs(players) do
				cRoot:Get():DoWithPlayerByUUID(value[1],
				function (Player)
					Player:SendMessage("@b[Nation] @f" .. senderName .. ": " .. Message);
				end
				);
			end
		elseif(Channel[UUID] == "town") then --Town channel
			local sql = "SELECT player_uuid FROM residents WHERE town_id = (SELECT town_id FROM residents WHERE player_uuid = ?)";
			local parameter = {UUID};
			local players = ExecuteStatement(sql, parameter);

			for key, value in pairs(players) do
				player = cRoot:Get():DoWithPlayerByUUID(value[1],
				function (Player)
					Player:SendMessage("@b[Town] @f" .. senderName .. ": " .. Message);
				end
				);
			end
		elseif(Channel[UUID] == "local") then
			local world = Player:GetWorld():ForEachPlayer(
			function (a_OtherPlayer)
				if((math.abs(Player:GetPosX() - a_OtherPlayer:GetPosX()) <= config.range_localChat) and (math.abs(Player:GetPosZ() - a_OtherPlayer:GetPosZ()) <= config.range_localChat)) then
					a_OtherPlayer:SendMessage("@f[Local] " .. senderName .. ": " .. Message);
				end
			end
			);
		else
			cRoot:Get():BroadcastChat("@a[Global] @f" .. Player:GetName() .. ": " .. Message);
		end

		return true;
	else
		return false;
	end
end

Channel = {};
function SwitchChat(Split, Player)
	if(config.handle_chat == true) then --Only handle chat if set so in the config
		local UUID = Player:GetUUID();

		if(Split[1] == "/switchchat" or Split[1] == "/sc") then
			if not(Split[2]) then
				Player:SendMessageFailure("This command requires another argument!");
				Player:SendMessageFailure("Usage: /switchchat (channel)");
			else
				if(Split[2] == "global") then
					switchGlobal(Player, UUID);
				elseif(Split[2] == "nation") then
					switchNation(Player, UUID);
				elseif(Split[2] == "town") then
					switchTown(Player, UUID);
				elseif(Split[2] == "local") then
					switchLocal(Player, UUID);
				else
					Player:SendMessageFailure("That channel doesn't exist.");
				end
			end
		elseif(Split[1] == "/gc") then
			switchGlobal(Player, UUID);
		elseif(Split[1] == "/nc") then
			switchNation(Player, UUID);
		elseif(Split[1] == "/tc") then
			switchTown(Player, UUID);
		elseif(Split[1] == "/lc") then
			switchLocal(Player, UUID);
		end

		return true;
	else
		return true;
	end
end

function switchGlobal(Player, UUID)
	if (Channel[UUID] == "global") then
		Player:SendMessageFailure("You are already in this channel");
	else
		Channel[UUID] = "global";
		Player:SendMessageInfo("Switched to the global channel");
	end
end

function switchNation(Player, UUID)
	if (Channel[UUID] == "nation") then
		Player:SendMessageFailure("You are already in this channel");
	else
		local sql = "SELECT nations.nation_id FROM nations INNER JOIN towns ON nations.nation_id = towns.nation_id INNER JOIN residents ON towns.town_id = residents.town_id WHERE player_uuid = ?";
		local parameter = {UUID};
		local nation = ExecuteStatement(sql, parameter)[1];

		if not (nation) then
			Player:SendMessageFailure("You can not switch to nation chat if you're not part of a nation");
		else
			Channel[UUID] = "nation";
			Player:SendMessageSuccess("Switched to the nation channel");
		end
	end
end

function switchTown(Player, UUID)
	if (Channel[UUID] == "town") then
		Player:SendMessageFailure("You are already in this channel");
	else
		sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
		parameter = {UUID};
		local town_id = ExecuteStatement(sql, parameter)[1][1];

		if not (town_id) then
			Player:SendMessageFailure("You can not switch to town chat if you're not part of a town");
		else
			Channel[UUID] = "town";
			Player:SendMessageInfo("Switched to the town channel");
		end
	end
end

function switchLocal(Player, UUID)
	if (Channel[UUID] == "local") then
		Player:SendMessageFailure("You are already in this channel");
	else
		Channel[UUID] = "local";
		Player:SendMessageInfo("Switched to the local channel. Your messages now have a reach of " .. config.range_localChat .. " blocks");
	end
end
