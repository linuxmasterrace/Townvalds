function OnExploding(World, ExplosionSize, CanCauseFire, X, Y, Z, Source, SourceData)
	local town_sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ? AND world = ?";
	local town_parameters = {math.floor(X/16), math.floor(Z/16), World:GetName()};
	if ExecuteStatement(town_sql, town_parameters)[1] ~= nil then
		local town_id = ExecuteStatement(town_sql, town_parameters)[1][1];
		local explosion_sql = "SELECT town_explosions_enabled FROM towns WHERE town_id = ?";
		local explosion_parameters = {town_id};
		if ExecuteStatement(explosion_sql, explosion_parameters)[1][1] == 0 then
			return true;
		end
	end
end

function OnTakeDamage(Receiver, TDI)
	if Receiver:IsPlayer() and TDI.Attacker ~= nil and TDI.Attacker:IsPlayer() then
		attacker_result = 1
		receiver_result = 1
		local town_sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ?";
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
		local sql = "SELECT towns.town_mobs_enabled, townChunks.plot_mobs_enabled FROM towns INNER JOIN townChunks ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ?";
		local parameters = {Monster:GetChunkX(), Monster:GetChunkZ()};
		local town = ExecuteStatement(sql, parameters)[1];

		if not(town == nil) then --Check if the mob is in a town chunk
			if(town[2] == 2) then --The chunk inherit it's mob spawning property from the town
				if(town[1] == 0) then --Check if mob spawning is allowed
					return true;
				end
			elseif(town[2] == 0) then
				return true;
			end
		end
	end

	return false;
end
