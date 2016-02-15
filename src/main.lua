PLUGIN = nil;

function Initialize(Plugin)
	PLUGIN = Plugin;
	PLUGIN:SetName("Townvalds");
	PLUGIN:SetVersion(1);

	LOG("Initialized " .. PLUGIN:GetName() .. " v." .. PLUGIN:GetVersion());
	-- Load the Info shared library:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua");

	--Bind all the commands:
	RegisterPluginInfoCommands();
	RegisterPluginInfoConsoleCommands();

	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_JOINED, OnPlayerJoined);
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving);
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed);
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_SPAWNED, OnPlayerSpawned);
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock);
	cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_PLACING_BLOCK, OnPlayerPlacingBlock);

    ini = cIniFile();

    LoadConfig();

	if not (cFile:IsFile(PLUGIN:GetLocalFolder() .. cFile:GetPathSeparator() .. config.dbname)) then -- If true, means database is deleted, or the plugin runs for the first time
       LOG("[" .. PLUGIN:GetName() .. "] It looks like this is the first time running this plugin. Creating database...")
       db = sqlite3.open(PLUGIN:GetLocalFolder() .. cFile:GetPathSeparator() .. config.dbname);
       CreateDatabase()
	else
       db = sqlite3.open(PLUGIN:GetLocalFolder() .. cFile:GetPathSeparator() .. config.dbname);
	end

	return true;
end

function OnDisable() -- Gets called when the plugin is unloaded, mostly when shutting down the server
   LOG("[" .. PLUGIN:GetName() .. "] Disabling " .. PLUGIN:GetName() .. " v" .. PLUGIN:GetVersion());
   db:close();
end
