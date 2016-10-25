function OnExploding(World, ExplosionSize, CanCauseFire, X, Y, Z, Source, SourceData)
	local sql = "SELECT town_id FROM plots WHERE chunkX = ? AND chunkZ = ? AND world = ?";
	local parameters = {math.floor(X/16), math.floor(Z/16), World:GetName()};

	for a = -1, 1, 1 do
		for b = -1, 1, 1 do
			parameters[1] = parameters[1] + a;
			parameters[2] = parameters[2] + b;
			local townId = ExecuteStatement(sql, parameters)[1];
			if (townId ~= nil) then
				local sql = "SELECT town_features FROM towns WHERE town_id = ?";
				local parameters = {townId[1]};
				local explosions = ExecuteStatement(sql, parameters)[1][1];

				if (bit32.band(explosions, TOWNEXPLOSIONSENABLED) == 0) then --Explosions are disabled
					return true;
				end
			end
			parameters[1] = parameters[1] - a; --reset chunks
			parameters[2] = parameters[2] - b;
		end
	end
end

function OnTakeDamage(Receiver, TDI)
	if Receiver:IsPlayer() and TDI.Attacker ~= nil and TDI.Attacker:IsPlayer() then
		attacker_result = 1
		receiver_result = 1
		local town_sql = "SELECT town_id FROM plots WHERE chunkX = ? AND chunkZ = ?";
		local pvp_sql = "SELECT town_pvp_enabled FROM towns WHERE town_id = ?";

		local attacker_parameters = {TDI.Attacker:GetChunkX(), TDI.Attacker:GetChunkZ()};
		local receiver_parameters = {Receiver:GetChunkX(), Receiver:GetChunkZ()};

		if ExecuteStatement(town_sql, attacker_parameters)[1] ~= nil then
			local attacker_town_id = ExecuteStatement(town_sql, attacker_parameters)[1][1];
			attacker_result = ExecuteStatement(pvp_sql, {attacker_town_id})[1][1];
		end

		if ExecuteStatement(town_sql, receiver_parameters)[1] ~= nil then
			local receiver_town_id = ExecuteStatement(town_sql, receiver_parameters)[1][1];
			receiver_result = ExecuteStatement(pvp_sql, {receiver_town_id})[1][1];
		end

		if attacker_result == 0 or receiver_result == 0 then
			return true;
		end
	end
end

function OnSpawningMonster(World, Monster)
	if(Monster:GetMobFamily() == 0) then --Check if the monster is hostile
		local sql = "SELECT towns.town_features, plots.plot_features FROM towns INNER JOIN plots ON towns.town_id = plots.town_id WHERE plots.chunkX = ? AND plots.chunkZ = ?";
		local parameters = {Monster:GetChunkX(), Monster:GetChunkZ()};
		local town = ExecuteStatement(sql, parameters)[1];

		if not(town == nil) then --Check if the mob is in a town chunk
			if not (bit32.band(town[2], PLOTMOBSINHERIT) == 0) then --The chunk inherit it's mob spawning property from the town
				if(bit32.band(town[1], TOWNMOBSENABLED) == 0) then --Mob spawning is not allowed by the town
					return true;
				end
			elseif (bit32.band(town[2], PLOTMOBSENABLED) == 0) then --Mob spawning is not allowed
				return true;
			end
		end
	end

	return false;
end
