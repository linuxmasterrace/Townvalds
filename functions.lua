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
    local sql = "SELECT town_id FROM residents WHERE player_uuid = ?";
    local parameter = {UUID};
    local townId = ExecuteStatement(sql, parameter)[1];

    if (townId) then
        return townId[1];
    else
        return nil;
    end
end

function GetTownName(townId)
    local sql = "SELECT town_name FROM towns WHERE town_id = ?";
    local parameter = {townId};
    local townName = ExecuteStatement(sql, parameter)[1];

    if (townName) then
        return townName[1];
    else
        return nil;
    end
end

function GetNationName(nationId)
	local sql = "SELECT nation_name FROM nations WHERE nation_id = ?";
	local parameter = {nationId};
	local nationName = ExecuteStatement(sql, parameter)[1];

	if (nationName) then
		return nationName[1];
	else
		return nil;
	end
end

function GetTownId(townName)
    local sql = "SELECT town_id FROM towns WHERE town_name = ?";
    local parameter = {townName};
    local townId = ExecuteStatement(sql, parameter)[1];

    if (townId) then
        return townId[1];
    else
        return nil;
    end
end

function GetNationId(nationName)
	local sql = "SELECT nation_id FROM nations WHERE nation_name = ?";
    local parameter = {nationName};
    local nationId = ExecuteStatement(sql, parameter)[1];

    if (nationId) then
        return nationId[1];
    else
        return nil;
    end
end

function DeleteTown(townId)
	--Since we make use of foreign keys, townChunks will be deleted accordingly and town_id will be set to null in residents automatically
	local sql = "DELETE FROM towns WHERE town_id = ?";
	local parameter = {townId};
	ExecuteStatement(sql, parameter);

	return true;
end

function GetTimestampFromString(timestring) --Returns the Lua timestamp from a string which is formatted as "YYYY-mm-dd HH:MM:SS"
	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)";
	local year, month, day, hour, minute, second = timestring:match(pattern);
	local convertedTimestamp = os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = second});

	return convertedTimestamp;
end

function DisplayVersion(Split, Player)
    if not (Player == nil) then
        Player:SendMessageInfo("Townvalds version: " .. PLUGIN:GetVersion());
    else
        LOG("Townvalds version: " .. PLUGIN:GetVersion());
    end

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
