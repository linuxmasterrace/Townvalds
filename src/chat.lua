function OnChat(Player, Message)
	if(config.handle_chat == true) then --Only handle chat if set so in the config
		local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);
		local senderName = Player:GetName();

		--If the player is in the specified channel, send it to the players having that channel active
		if(Channel[UUID] == "town") then --Town channel
			sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
			parameter = {UUID};
			local town_id = ExecuteStatement(sql, parameter)[1][1];

			sql = "SELECT player_uuid FROM residents WHERE town_id = ?";
			parameters = {town_id};
			local players = ExecuteStatement(sql, parameters);

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
					LOG(Player:GetPosX() - a_OtherPlayer:GetPosX());
					LOG(Player:GetPosZ() - a_OtherPlayer:GetPosZ());
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
		local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true);

		if(Split[1] == "/switchchat" or Split[1] == "/sc") then
			if not(Split[2]) then
				Player:SendMessageFailure("This command requires another argument!");
				Player:SendMessageFailure("Usage: /switchchat (channel)");
			else
				if(Split[2] == "global") then
					switchGlobal(Player, UUID);
				elseif(Split[2] == "town") then
					switchTown(Player, UUID);
				elseif(Split[2] == "local") then
					switchLocal(Player, UUID);
				else
					Player:SendMessageFailure("That channel doesn't exist.");
				end
			end
		elseif(Split[1] == "/lc") then
			switchLocal(Player, UUID);
		elseif(Split[1] == "/gc") then
			switchGlobal(Player, UUID);
		elseif(Split[1] == "/tc") then
			switchTown(Player, UUID);
		end

		return true;
	else
		return true;
	end
end

function switchLocal(Player, UUID)
	if(Channel[UUID] == "local") then
		Channel[UUID] = "local";
		Player:SendMessageInfo("Switched to the local channel. Your messages now have a reach of " .. config.range_localChat .. " blocks.");
	else
		Player:SendMessageFailure("You are already in this channel.");
	end
end

function switchGlobal(Player, UUID)
	if(Channel[UUID] == "global") then
		Channel[UUID] = "global";
		Player:SendMessageInfo("Switched to the global channel");
	else
		Player:SendMessageFailure("You are already in this channel.");
	end
end

function switchTown(Player, UUID)
	if(Channel[UUID] == "town") then
		sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
		parameter = {UUID};
		local town_id = ExecuteStatement(sql, parameter)[1][1];

		if(town_id) then
			Channel[UUID] = "town";
			Player:SendMessageInfo("Switched to the town channel");
		else
			Player:SendMessageFailure("You can not switch to town chat if you're not part of a town.");
		end
	else
		Channel[UUID] = "town";
		Player:SendMessageInfo("You are already in this channel.");
	end
end
