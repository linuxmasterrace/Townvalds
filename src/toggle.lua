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
    end
end

function OnTakeDamage(Receiver, TDI)
    if Receiver:IsPlayer() and TDI.Attacker ~= nil and TDI.Attacker:IsPlayer() then
        attacker_result = 1
        receiver_result = 1
        local town_sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ? AND world = ?";
        local pvp_sql = "SELECT town_pvp_enabled FROM towns WHERE town_id = ?";

        local attacker_parameters = {TDI.Attacker:GetChunkX(), TDI.Attacker:GetChunkZ(), Receiver:GetWorld():GetName()};
        local receiver_parameters = {Receiver:GetChunkX(), Receiver:GetChunkZ(), Receiver:GetWorld():GetName()};

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
