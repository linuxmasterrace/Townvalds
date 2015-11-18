PLUGIN = nil

function Initialize(Plugin)
	Plugin:SetName("Townvalds")
	Plugin:SetVersion(1)

	-- Hooks

	PLUGIN = Plugin -- NOTE: only needed if you want OnDisable() to use GetName() or something like that
	
	-- cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving) -- Hook example, calls OnPlayerMoving

	-- Command Bindings
	
	cPluginManager.BindCommand("/townvalds", "townvalds.version", DisplayVersion, "~ Displays the current plugin version")

	LOG("Initialised " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())
	return true
end

function OnDisable() -- Gets called when the plugin is unloaded, mostly when shutting down the server
	LOG(PLUGIN:GetName() .. " is shutting down...")
end

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
		Player:SendMessageInfo("Townvalds version: " .. PLUGIN:GetVersion())
	end
	
	return true
end