InTown = {}

function CheckPlayerInTown(Player, chunkX, chunkZ)
    local sql = "SELECT towns.town_name, townChunks.chunkX, townChunks.chunkZ, townChunks.world FROM townChunks LEFT JOIN towns ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ? AND townChunks.world = ?";
    local parameters = {chunkX, chunkZ, Player:GetWorld():GetName()};
    local result = ExecuteStatement(sql, parameters);
    local town = InTown[Player:GetUUID()];
    if(result[1] and result[1][1] and result[1][1] ~= town) then
        Player:SendMessage("You're in the town " .. result[1][1]);
        InTown[Player:GetUUID()] = result[1][1];
    elseif (not(result[1] and result[1][1]) and town) then
        Player:SendMessage("You have left the town "..town..".");
        InTown[Player:GetUUID()] = nil;
    end
end

function CheckBlockPermission(Player, BlockX, BlockZ)
    local sql = "SELECT town_id FROM townChunks WHERE chunkX = ? AND chunkZ = ? AND world = ?";
    local parameters = {math.floor(BlockX / 16), math.floor(BlockZ / 16), Player:GetWorld():GetName()};
    local town_id = ExecuteStatement(sql, parameters);
    if (town_id[1] and town_id[1][1]) then --The block being broken is part of a town
        local sql = "SELECT * FROM residents WHERE player_uuid = ? AND town_id = ?";
        local parameters = {Player:GetUUID(), town_id[1][1]};
        local result = ExecuteStatement(sql, parameters);
        if (result[1] and result[1][1]) then -- Player is in a town he belongs to
            return false;
        else -- Player is in a town he doesn't belong to, prevent block breaking
            return true;
        end
    else -- The block being broken is NOT part of a town
        return false;
    end
end

function GetPlayerTown(UUID)
    sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
    parameters = {UUID};
    local result = ExecuteStatement(sql, parameters);

    if (result[1] and result[1][1]) then
        return result[1][1];
    else
        return nil;
    end
end

function GetTownName(townId)
    sql = "SELECT town_name FROM towns WHERE town_id = ?";
    parameters = {townId};
    local townName = ExecuteStatement(sql, parameters)[1];

    if (townName) then
        return townName[1];
    else
        return nil;
    end
end

function GetTownId(townName)
    sql = "SELECT town_id FROM towns WHERE town_name = ?";
    parameters = {townName};
    local townId = ExecuteStatement(sql, parameters)[1];

    if(townId) then
        return townId[1];
    else
        return nil;
    end
end

function GetTimestampFromString(timestring) --Returns the Lua timestamp from a string which is formatted as "YYYY-mm-dd HH:MM:SS"
	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)";
	local year, month, day, hour, minute, second = timestring:match(pattern);
	local convertedTimestamp = os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = second});

	return convertedTimestamp;
end

function OnPlayerJoined(Player)
	local UUID = Player:GetUUID();
    local sql = "INSERT OR IGNORE INTO residents (player_uuid, player_name, town_id, town_rank, last_online) VALUES (?, ?, NULL, NULL, datetime(\"now\"))";
    local parameters = {UUID, Player:GetName()};
    if(ExecuteStatement(sql, parameters) == nil) then
        LOG("Couldn't add player "..Player:GetName().." to the database!!!");
    end

	Channel[UUID] = "global";

	return true;
end

function OnPlayerSpawned(Player) -- This is called after both connection and respawning
    CheckPlayerInTown(Player, Player:GetChunkX(), Player:GetChunkZ());
end

function OnPlayerDestroyed(Player) -- This is called when a player that has been in the game disconnects
    InTown[Player:GetUUID()] = nil; -- We set it to nil so Lua can garbage collect it and so the player gets the message on connection
end

function DisplayVersion(Split, Player)
    if not (Player == nil) then
        Player:SendMessageInfo("Townvalds version: " .. PLUGIN:GetVersion());
    else
        LOG("Townvalds version: " .. PLUGIN:GetVersion());
    end

    return true;
end

function OnPlayerMoving(Player, OldPosition, NewPosition)
    CheckPlayerInTown(Player, Player:GetChunkX(), Player:GetChunkZ());
    return false;
end

function OnPlayerBreakingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
    return CheckBlockPermission(Player, BlockX, BlockZ);
end

function OnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, BlockType, BlockMeta)
    return CheckBlockPermission(Player, BlockX, BlockZ);
end

function CreateTable()
    local sql = "CREATE TABLE IF NOT EXISTS users (user_guid STRING PRIMARY KEY, town_id INTEGER)";
    result = ExecuteStatement(sql);

    return true;
end

function Set(list)
	local set = {};
	for _, l in ipairs(list) do
		set[l] = true;
	end

	return set;
end

function InsideArea(pos, high, low)
    if pos <= high and pos >= low then
        return true
    end
end
