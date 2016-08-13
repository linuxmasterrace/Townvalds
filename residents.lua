function DisplayResident(Split, Player)
   -- Check if the player has entered the name of the resident
   if (Split[2] == nil) then
	  Player:SendMessageFailure("You have to enter a resident name! Usage: /resident (username)");
	  return true;
   end

   -- Query the resident info from the database
   local sql = "SELECT residents.player_uuid, residents.player_name, residents.first_joined, residents.last_online FROM residents WHERE residents.player_name = ?";
   local parameters = {Split[2]};
   local resident = ExecuteStatement(sql, parameters)[1];

   if not (resident) then
      Player:SendMessageFailure("Player not found in database!");
   else
	   local sql = "SELECT towns.town_name, town_residents.town_rank FROM towns INNER JOIN town_residents ON towns.town_id = town_residents.town_id WHERE town_residents.player_uuid = ?";
	   local parameter = {resident[1]};
	   local residentTown = ExecuteStatement(sql, parameter)[1];
	   
	   if not (residentTown) then
		   residentTown = {"none", "none"};
	   elseif not (residentTown[2]) then
		   residentTown[2] = "none";
	   end

	   Player:SendMessageInfo("Username: "..(resident[2] or "none"));
	   Player:SendMessageInfo("Town: "..(residentTown[1] or "none"));
	   Player:SendMessageInfo("Town Rank: "..(residentTown[2] or "none"));
	   Player:SendMessageInfo("First Joined: "..(resident[3] or "none"));
	   Player:SendMessageInfo("Last Online: "..(resident[4] or os.date("%Y-%m-%d %H:%M:%S")));
   end

   return true;
end
