PLUGIN = nil

function Initialize(Plugin)
	PLUGIN = Plugin
	PLUGIN:SetName("Townvalds")
	PLUGIN:SetVersion(1)

	-- Load the Info shared library:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")

	--Bind all the commands:
	RegisterPluginInfoCommands()
	RegisterPluginInfoConsoleCommands()

	-- cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving) -- Hook example, calls OnPlayerMoving

	if not (cFile:IsFile(PLUGIN:GetLocalFolder() .. "/database.sqlite3")) then -- If true, means database is deleted, or the plugin runs for the first time
		LOG("[Townvalds] It seems like this is the first time running this plugin. Creating database...")
		CreateDatabase()
	end

	LOG("[Townvalds] Initialised " .. PLUGIN:GetName() .. " v." .. PLUGIN:GetVersion())

	db = sqlite3.open(PLUGIN:GetLocalFolder() .. "/database.sqlite3")
	stmt = db:prepare("SELECT name FROM test")
	stmt:step()
	data = stmt:rows()
	LOG(data)
	--LOG(data[1] .. " " .. data[2])
	return true
end

function OnDisable() -- Gets called when the plugin is unloaded, mostly when shutting down the server
	LOG(PLUGIN:GetName() .. " is shutting down...")
end
