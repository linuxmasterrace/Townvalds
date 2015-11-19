function OnPlayerMoving(Player) -- Function example, gets called when the Player moves
	LOG("The player moved!")
	return false; -- Don't prevent the player from walking
end

function DisplayVersion(Split, Player)
	if(#Split < 2) then
		Player:SendMessage("Usage: /townvalds (option) [argument]")
		return true
	end

	if(Split[2] == "version") then
		if not (Player == nil) then
			Player:SendMessageInfo("Townvalds version: " .. PLUGIN:GetVersion())
		else
			LOG("Townvalds version: " .. PLUGIN:GetVersion())
		end
	end

	return true
end
