PLUGIN = nil;

function Initialize(Plugin)
	PLUGIN = Plugin;
	PLUGIN:SetName("Townvalds");
	PLUGIN:SetVersion(1);

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
	cPluginManager.AddHook(cPluginManager.HOOK_EXPLODING, OnExploding);
	cPluginManager.AddHook(cPluginManager.HOOK_CHAT, OnChat);
	cPluginManager.AddHook(cPluginManager.HOOK_TAKE_DAMAGE, OnTakeDamage);
	cPluginManager.AddHook(cPluginManager.HOOK_SPAWNING_MONSTER, OnSpawningMonster);

	ini = cIniFile();

	--Create a new config if this is the first load, otherwise load the existing config file
	LoadConfig();

	--Create a new database if this is the first load, otherwise open the existing one
	if not (cFile:IsFile(PLUGIN:GetLocalFolder() .. cFile:GetPathSeparator() .. config.dbname)) then -- If true, means database is deleted, or the plugin runs for the first time
		LOG("[" .. PLUGIN:GetName() .. "] It looks like this is the first time running this plugin. Creating database...")
		db = sqlite3.open(PLUGIN:GetLocalFolder() .. cFile:GetPathSeparator() .. config.dbname);
		CreateDatabase()
	else
		LOG("[" .. PLUGIN:GetName() .. "] Opening database");
		db = sqlite3.open(PLUGIN:GetLocalFolder() .. cFile:GetPathSeparator() .. config.dbname);
	end

	--Compare players already online before loading the plugin with the database and sync the two
	LOG("[" .. PLUGIN:GetName() .. "] Syncing online players with the database");
	cRoot:Get():ForEachPlayer(
	function (Player)
		OnPlayerJoined(Player);
	end
	);

	--Compare existing nations to nations existing in the database and sync the two
	LOG("[" .. PLUGIN:GetName() .. "] Syncing nations with the database");
	NationSync();


	LOG("[" .. PLUGIN:GetName() .. "] Initialized " .. PLUGIN:GetName() .. " v." .. PLUGIN:GetVersion());
	return true;
end

function OnDisable() -- Gets called when the plugin is unloaded, mostly when shutting down the server
	LOG("[" .. PLUGIN:GetName() .. "] Disabling " .. PLUGIN:GetName() .. " v" .. PLUGIN:GetVersion());
	db:close();
end
