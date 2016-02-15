config = {};

function LoadConfig()
   local newconfig = {};
   ini:ReadFile(PLUGIN:GetLocalFolder() .. "/config.ini");
   ini:DeleteHeaderComments();
   ini:AddHeaderComment("Configuration for Townvalds");

   if not (ini:FindKey("General")) then
      ini:AddKeyName("General")
   end
   ini:DeleteKeyComments("General");
   ini:AddKeyComment("General", "dbname - Filename of the database. REQUIRES PLUGIN RELOAD");
   
   newconfig.dbname = ini:GetValueSet("General", "dbname", "database.sqlite3");
   
   ini:WriteFile(PLUGIN:GetLocalFolder() .. "/config.ini");
   config = newconfig;

   return true;
end
