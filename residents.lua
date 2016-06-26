function DisplayResident(Split, Player)
   -- Check if the player has entered the name of the resident
   if (Split[2] == nil) then
	  Player:SendMessageFailure("You have to enter a resident name! Usage: /resident (username)");
	  return true;
   end

   -- Query the resident info from the database
   local sql = "SELECT residents.player_name, towns.town_name, residents.town_rank, residents.first_joined, residents.last_online FROM residents LEFT JOIN towns ON towns.town_id = residents.town_id WHERE residents.player_name = ?";
   local parameters = {Split[2]};
   local result = ExecuteStatement(sql, parameters)[1];

   if(result[1]==nil) then
      Player:SendMessageFailure("Player not found in database!");
   else
      Player:SendMessageInfo("Username: "..(result[1] or "none"));
      Player:SendMessageInfo("Town: "..(result[2] or "none"));
      Player:SendMessageInfo("Town Rank: "..(result[3] or "none"));
      Player:SendMessageInfo("First Joined: "..(result[4] or "none"));
      Player:SendMessageInfo("Last Online: "..(result[5] or os.date("%Y-%m-%d %H:%M:%S")));
   end

   return true;
end
