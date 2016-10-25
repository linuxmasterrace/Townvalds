function ConfigureDatabase()
	-- Create tables
	local sqlCreate = {
		"PRAGMA foreign_keys = ON",
		"CREATE TABLE IF NOT EXISTS nations (nation_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, nation_name STRING NOT NULL UNIQUE, nation_capital INTEGER NOT NULL UNIQUE)",
		"CREATE TABLE IF NOT EXISTS towns (town_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, town_name STRING NOT NULL UNIQUE, nation_id INTEGER, town_pvp_enabled INTEGER NOT NULL DEFAULT 0, town_fire_enabled INTEGER NOT NULL DEFAULT 0, town_features INTEGER NOT NULL DEFAULT 15, town_permissions INTEGER NOT NULL DEFAULT 15, town_spawnX INTEGER NOT NULL, town_spawnY INTEGER NOT NULL, town_spawnZ INTEGER NOT NULL, town_spawnWorld INTEGER NOT NULL, FOREIGN KEY (nation_id) REFERENCES nations(nation_id) ON UPDATE CASCADE ON DELETE SET NULL)",
		"CREATE TABLE IF NOT EXISTS plots (plot_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE, town_id INTEGER NOT NULL, owner STRING, chunkX INTEGER NOT NULL, chunkZ INTEGER NOT NULL, world STRING NOT NULL, plot_features INTEGER NOT NULL DEFAULT 15, FOREIGN KEY(`town_id`) REFERENCES towns(town_id) ON UPDATE CASCADE ON DELETE CASCADE)",
		"CREATE TABLE IF NOT EXISTS residents (player_uuid STRING NOT NULL PRIMARY KEY, player_name STRING NOT NULL UNIQUE, last_online INTEGER, first_joined INTEGER)",
		"CREATE TABLE IF NOT EXISTS town_residents (player_uuid STRING NOT NULL, town_id INTEGER NOT NULL, town_rank STRING, PRIMARY KEY (player_uuid, town_id, town_rank), FOREIGN KEY (player_uuid) REFERENCES residents(player_uuid) ON UPDATE CASCADE ON DELETE CASCADE, FOREIGN KEY (town_id) REFERENCES towns(town_id) ON UPDATE CASCADE ON DELETE CASCADE)",
		"CREATE TABLE IF NOT EXISTS invitations (invitation_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, player_uuid STRING, town_id INTEGER NOT NULL, nation_id INTEGER, invitation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (player_uuid) REFERENCES residents(player_uuid) ON UPDATE CASCADE ON DELETE CASCADE, FOREIGN KEY (town_id) REFERENCES towns(town_id) ON UPDATE CASCADE ON DELETE CASCADE, FOREIGN KEY (nation_id) REFERENCES nations(nation_id) ON UPDATE CASCADE ON DELETE CASCADE)",
	};
	for key in pairs(sqlCreate) do
		ExecuteStatement(sqlCreate[key]);
	end
end

function ExecuteStatement(sql, parameters)
	local stmt = db:prepare(sql);
	local result;

	if not (parameters == nil) then
		for key, value in pairs(parameters) do
			stmt:bind(key, value);
		end
	end

	local result = {};
	if (sql:match("SELECT")) then
		local x = 1;
		while (stmt:step() == sqlite3.ROW) do
			result[x] = stmt:get_values();
			x = x + 1;
		end
	else
		stmt:step();
	end

	stmt:finalize();

	if (sql:match("INSERT")) then
		result = db:last_insert_rowid();
	end

	if not (result == nil) then
		return result;
	else
		return 0;
	end
end
