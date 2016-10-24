InTown = {}
function CheckPlayerInTown(Player, chunkX, chunkZ)
    local sql = "SELECT towns.town_name, plots.chunkX, plots.chunkZ, plots.world FROM plots LEFT JOIN towns ON towns.town_id = plots.town_id WHERE plots.chunkX = ? AND plots.chunkZ = ? AND plots.world = ?";
    local parameters = {chunkX, chunkZ, Player:GetWorld():GetName()};
    local result = ExecuteStatement(sql, parameters)[1];
    local town = InTown[Player:GetUUID()];

    if (result) and (result[1]) and (not (town) or not (town == result[1])) then
        Player:SendMessage("You're in the town " .. result[1]);
        InTown[Player:GetUUID()] = result[1];
    elseif not (result) and (town) then
        Player:SendMessage("You have left the town "..town..".");
        InTown[Player:GetUUID()] = nil;
    end
end

function GetPlayerNation(UUID)
	local sql = "SELECT towns.nation_id FROM town_residents INNER JOIN towns ON town_residents.town_id = towns.town_id WHERE town_residents.player_uuid = ?";
	local parameter = {UUID};
	local nation = ExecuteStatement(sql, parameter)[1];

	if (nation) then
		return nation[1];
	else
		return nil;
	end
end

function GetPlayerTown(UUID)
    local sql = "SELECT town_id FROM town_residents WHERE player_uuid = ?";
    local parameter = {UUID};
    local town = ExecuteStatement(sql, parameter)[1];

    if (town) then
        return town[1];
    else
        return nil;
    end
end

function GetPlayerTownRank(UUID)
	local sql = "SELECT town_rank FROM town_residents WHERE player_uuid = ?";
	local parameter = {UUID};
	local townRankList = ExecuteStatement(sql, parameter);

	if not (townRankList) then
		return nil;
	else
		local rank = nil;
		for key, value in pairs(townRankList) do
			if (rank == nil) or (TownRanks[value[1]] > TownRanks[rank]) then
				rank = value[1];
			end
		end

		return rank;
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
	--Since we make use of foreign keys, plots will be deleted accordingly and town_id will be set to null in residents automatically
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

function CheckPermission(permissions, permissionToCheck)
	if (bit32.band(permissions, permissionToCheck) == 0) then
		return false; --Not allowed
	else
		return true; --Allowed
	end
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
