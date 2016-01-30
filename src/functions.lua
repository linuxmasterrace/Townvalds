InTown = {}

function CheckPlayerInTown(Player, chunkX, chunkZ)
   local sql = "SELECT towns.town_name, townChunks.chunkX, townChunks.chunkZ FROM townChunks LEFT JOIN towns ON towns.town_id = townChunks.town_id WHERE townChunks.chunkX = ? AND townChunks.chunkZ = ?";
   local parameters = {chunkX, chunkZ};
   local result = ExecuteStatement(sql, parameters);
   local town = InTown[Player:GetName()];
   if(result[1] and result[1][1] and result[1][1] ~= town) then
      Player:SendMessage("You're in the town " .. result[1][1]);
      InTown[Player:GetName()] = result[1][1];
   elseif (not(result[1] and result[1][1]) and town) then
      Player:SendMessage("You have left the town "..town..".");
      InTown[Player:GetName()] = nil;
   end
end

function OnPlayerJoined(Player)
   local sql = "INSERT OR IGNORE INTO residents (player_uuid, player_name, town_id, town_rank, last_online) VALUES (?, ?, NULL, NULL, datetime(\"now\"))";
   local parameters = {cMojangAPI:GetUUIDFromPlayerName(Player:GetName(), true), Player:GetName()};
   if(ExecuteStatement(sql, parameters)==nil) then
      LOG("Couldn't add player "..Player:GetName().." to the database!!!")
   end
end

function OnPlayerSpawned(Player) -- This is called after both connection and respawning
   CheckPlayerInTown(Player, Player:GetChunkX(), Player:GetChunkZ());
end

function OnPlayerDestroyed(Player) -- This is called when a player that has been in the game disconnects
   InTown[Player:GetName()] = nil; -- We set it to nil so Lua can garbage collect it and so the player gets the message on connection
end

function DisplayVersion(Split, Player)
	if not (Player == nil) then
		Player:SendMessageInfo("Townvalds version: " .. PLUGIN:GetVersion())
	else
		LOG("Townvalds version: " .. PLUGIN:GetVersion())
	end

	return true
end

function OnPlayerMoving(Player, OldPosition, NewPosition)
   CheckPlayerInTown(Player, Player:GetChunkX(), Player:GetChunkZ());
   return false;
end

function CreateTable()
	local sql = "CREATE TABLE IF NOT EXISTS users (user_guid STRING PRIMARY KEY, town_id INTEGER)";
	result = ExecuteStatement(sql);

	return true;
end
