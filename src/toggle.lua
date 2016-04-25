explosion = cBlockArea()
exData = {}

function OnExploding(World, ExplosionSize, CanCauseFire, X, Y, Z, Source, SourceData)
	if not (Source == 4 or Source == 5) then
		cBlockArea.Read(explosion, World, X + ExplosionSize, X - ExplosionSize, Y + ExplosionSize, Y - ExplosionSize, Z + ExplosionSize, Z - ExplosionSize);
		exData = {X,Y,Z, ExplosionSize};
	end

	local town_sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ?";
	local town_parameters = {math.floor(X/16), math.floor(Z/16)};

	exData[5] = 1

	if ExecuteStatement(town_sql, town_parameters)[1] ~= nil then
		
		local town_id = ExecuteStatement(town_sql, town_parameters)[1][1];
		local entity_sql = "SELECT town_id FROM towns WHERE town_explosions_enabled = 0";
		local entity_parameters = {}
		local result = ExecuteStatement(entity_sql, entity_parameters);
		
		for k in pairs(result) do
			if k == town_id then
				exData[5] = 0
			end
		end
	end
end

function OnExploded(World, ExplosionSize, CanCauseFire, X, Y, Z, Source, SourceData)
	if exData[5] == 0 then
		cBlockArea.Write(explosion, World, X-ExplosionSize, Y-ExplosionSize, Z-ExplosionSize)
		exData = {}
	end
end

function OnSpawningEntity(World, Entity)
	if exData[5] == 0 then
		if exData[1] ~= nil then -- Test for explosion data
			position = Entity:GetPosition()
			if Entity:IsPickup() or Entity:IsFallingBlock() then
				if InsideArea(position.x, exData[1] + exData[4], exData[1] - exData[4]) then
					if InsideArea(position.y, exData[2] + exData[4] + 5, exData[2] - exData[4] - 3) then
						if InsideArea(position.z, exData[3] + exData[4], exData[3] - exData[4]) then
							Entity:SetPosition(exData[1], -100, exData[3]) -- Teleport entity to the void
						end
					end
				end
			end
		end
	end
end

function OnTakeDamage(Receiver, TDI)
    if Receiver:IsPlayer() and TDI.Attacker ~= nil then
        if TDI.Attacker:IsPlayer() then
            local town_sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ?";
            local town_parameters = {Receiver:GetChunkX(), Receiver:GetChunkZ()}; 
            
            if ExecuteStatement(town_sql, town_parameters)[1] ~= nil then
                local town_id = ExecuteStatement(town_sql, town_parameters)[1][1];
                local pvp_sql = "SELECT town_pvp_enabled FROM towns WHERE town_id = ?";
                local pvp_parameters = {town_id};
                local result = ExecuteStatement(pvp_sql, pvp_parameters)[1][1];
                
                if result == 0 then
                    TDI.FinalDamage = 0;
                    TDI.Knockback:Set(0,0,0);
                end
            end
        end
    end
end