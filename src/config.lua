config = {};

function LoadConfig()
	local newconfig = {};
	ini:ReadFile(PLUGIN:GetLocalFolder() .. "/config.ini");
	ini:DeleteHeaderComments();
	ini:AddHeaderComment("Configuration for Townvalds");

 	if not (ini:FindKey("General")) then
		ini:AddKeyName("General");
	elseif not (ini:FindKey("Towns")) then
		ini:AddKeyName("Towns");
	end
   ini:DeleteKeyComments("General");
   ini:DeleteKeyComments("Towns");

   ini:AddKeyComment("General", "dbname - Filename of the database. REQUIRES PLUGIN RELOAD");
   newconfig.dbname = ini:GetValueSet("General", "dbname", "database.sqlite3");

   ini:AddKeyComment("Towns", "invitation_duration - The time an invitation stays valid, in seconds.");
   ini:AddKeyComment("Towns", "If no expiration is wanted, set it to 0");
   newconfig.invitation_duration = ini:GetValueSet("Towns", "invitation_duration", "0");

   ini:WriteFile(PLUGIN:GetLocalFolder() .. "/config.ini");
   config = newconfig;

   LOG("[Townvalds] Config succesfully reloaded");

   return true;
end
