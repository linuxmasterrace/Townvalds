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
		local sql = "SELECT town_id FROM plots WHERE chunkX = ? AND chunkZ = ? AND world = ?";

		local parameters_attacker = {TDI.Attacker:GetChunkX(), TDI.Attacker:GetChunkZ(), TDI.Attacker:GetWorld():GetName()};
		local parameters_receiver = {Receiver:GetChunkX(), Receiver:GetChunkZ(), Receiver:GetWorld():GetName()};

		local townId_attacker = ExecuteStatement(sql, parameters_attacker)[1];
		local townId_receiver = ExecuteStatement(sql, parameters_receiver)[1];

		if (townId_attacker ~= nil) or (townId_receiver ~= nil) then
			if (townId_attacker == nil) and not (townId_receiver == nil) then
				townId_attacker = {townId_receiver[1]}; --Set it so we can use it in the query
			end

			local sql = "SELECT town_features FROM towns WHERE town_id = ?";
			local parameter = {townId_attacker[1]};
			local townFeatures = ExecuteStatement(sql, parameter)[1][1];

			if (bit32.band(townFeatures, TOWNPVPENABLED) == 0) then --PVP is disabled
				return true;
			end
		end
	end
end

function OnSpawningMonster(World, Monster)
	if(Monster:GetMobFamily() == 0) then --Check if the monster is hostile
		local sql = "SELECT towns.town_mobs_enabled, plots.plot_features FROM towns INNER JOIN plots ON towns.town_id = plots.town_id WHERE plots.chunkX = ? AND plots.chunkZ = ?";
		local parameters = {Monster:GetChunkX(), Monster:GetChunkZ()};
		local town = ExecuteStatement(sql, parameters)[1];

		if not(town == nil) then --Check if the mob is in a town chunk
			if not (bit32.band(town[2], PLOTMOBSINHERIT) == 0) then --The chunk inherit it's mob spawning property from the town
				if(town[1] == 0) then --Check if mob spawning is allowed
					return true;
				end
			elseif (bit32.band(town[2], PLOTMOBSENABLED) == 0) then --Mob spawning is not allowed
				return true;
			end
		end
	end

	return false;
end
