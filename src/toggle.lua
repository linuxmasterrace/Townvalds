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
		local entity_sql = "SELECT town_id FROM towns WHERE town_explosions_enabled = ?";
		local entity_parameters = {"off"}
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

function InsideArea(pos, high, low)
	if pos <= high and pos >= low then
		return true
	end
end