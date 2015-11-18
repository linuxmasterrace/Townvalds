PLUGIN = nil

function Initialize(Plugin)
	PLUGIN = Plugin
	PLUGIN:SetName("Townvalds")
	PLUGIN:SetVersion(1)
	
	-- Load the Info shared library:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")
	
	--Bind all the commands:
	RegisterPluginInfoCommands();

	-- Hooks
	
		-- cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving) -- Hook example, calls OnPlayerMoving

	-- Command Bindings are not necessary, are now done in Info.Lua

	LOG("[Townvalds] Initialised " .. PLUGIN:GetName() .. " v." .. PLUGIN:GetVersion())
	return true
end

function OnDisable() -- Gets called when the plugin is unloaded, mostly when shutting down the server
	LOG(PLUGIN:GetName() .. " is shutting down...")
end