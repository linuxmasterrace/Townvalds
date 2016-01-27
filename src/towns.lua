function TownCreate(Split, Player)
    -- Check if the player entered a name for the town
    if (Split[3] == nil) then
        Player:SendMessageFailure("You have to enter a town name! Usage: /town new (name)")
        return true
    end

    -- Retrieve the player UUID from Mojang of the player that invoked the command
    local UUID = cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true)

    if (UUID == "") then
        Player:SendMessageFailure("Invalid player!")
        return true
    end

    -- Insert the town data in the database
    local sql = "INSERT INTO towns (town_name, town_owner) VALUES (?, ?)";
    local parameters = {Split[3], UUID};
    local town_id = ExecuteStatement(sql, parameters);

    local townBaseChunk = {Player:GetChunkX(), Player:GetChunkZ()}

    local sql = "INSERT INTO townChunks (town_id, chunkX, chunkZ) VALUES (?, ?, ?)";
    local parameters = {town_id, townBaseChunk[1], townBaseChunk[2]}

    ExecuteStatement(sql, parameters);

	local sql = "UPDATE residents SET town_id = ? WHERE player_uuid = ?";
    local parameters = {town_id, UUID}
	ExecuteStatement(sql, parameters);

    Player:SendMessageSuccess("Created a new town!");

    return true
end

function DatabaseTest()
	local sql = "SELECT town_name FROM towns WHERE town_id = ?";
	local parameters = {1};
	result = ExecuteStatement(sql, parameters);

	return true;
end
