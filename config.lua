config = {};

function LoadConfig()
	local newconfig = {};
	ini:ReadFile(PLUGIN:GetLocalFolder() .. "/config.ini");
	ini:DeleteHeaderComments();
	ini:AddHeaderComment("Configuration for Townvalds");

	if not (ini:FindKey("General")) then
		ini:AddKeyName("General");
	end
	if not (ini:FindKey("Nations")) then
		ini:AddKeyName("Nations");
	end
	if not (ini:FindKey("Towns")) then
		ini:AddKeyName("Towns");
	end
	if not (ini:FindKey("Chat")) then
		ini:AddKeyName("Chat");
	end

	ini:DeleteKeyComments("General");
	ini:DeleteKeyComments("Towns");
	ini:DeleteKeyComments("Chat");

	----------------------------------------------------------------------------------------------------------------------------------------------

	ini:AddKeyComment("General", "dbname - Filename of the database. REQUIRES PLUGIN RELOAD");
	ini:AddKeyComment("General", "");
	newconfig.dbname = ini:GetValueSet("General", "dbname", "database.sqlite3");

	----------------------------------------------------------------------------------------------------------------------------------------------

	ini:AddKeyComment("Towns", "invitation_duration - The time an invitation stays valid, in seconds.");
	ini:AddKeyComment("Towns", "If no expiration is wanted, set it to 0");
	ini:AddKeyComment("Towns", "");
	newconfig.invitation_duration = ini:GetValueSetI("Towns", "invitation_duration", "0");
	ini:AddKeyComment("Towns", "min_distance_from_other_towns - The minimum amount of chunks a new town has to be from existing towns");
	ini:AddKeyComment("Towns", "");
	newconfig.min_distance_from_other_towns = ini:GetValueSetI("Towns", "min_distance_from_other_towns", "5");
	ini:AddKeyComment("Towns", "enable_town_spawns - Allow players to spawn in their own town instead of the server spawn");
	ini:AddKeyComment("Towns", "");
	newconfig.enable_town_spawns = ini:GetValueSetI("Towns", "enable_town_spawns", "1");
	ini:AddKeyComment("Towns", "teleport_to_town_spawns - Allow players to teleport to town spawns");
	ini:AddKeyComment("Towns", "This option will be ignored if enable_town_spawns is set to 0");
	ini:AddKeyComment("Towns", "");
	newconfig.teleport_to_town_spawns = ini:GetValueSetI("Towns", "teleport_to_town_spawns", "1");
	ini:AddKeyComment("Towns", "teleport_to_friendly_town_spawns_only - Only allow players to teleport to town spawns in the same nation");
	ini:AddKeyComment("Towns", "This option will be ignored if enable_town_spawns is set to 0");
	ini:AddKeyComment("Towns", "Players that are allowed to teleport to other towns should get the permission 'townvalds.town.spawn.other'");
	ini:AddKeyComment("Towns", "Admins can still teleport to every town with the permission 'townvalds.town.spawn.admin'");
	ini:AddKeyComment("Towns", "");
	newconfig.teleport_to_friendly_town_spawns_only = ini:GetValueSetI("Towns", "teleport_to_friendly_town_spawns_only", "1");

	----------------------------------------------------------------------------------------------------------------------------------------------

	ini:AddKeyComment("Chat", "handle_chat - Let Townvalds handle the chat or not");
	ini:AddKeyComment("Chat", "You'll want to disable this if you have a different plugin to handle chat, but you will miss out of town and nation specific channels");
	ini:AddKeyComment("Chat", "");
	newconfig.handle_chat = ini:GetValueSetB("Chat", "handle_chat", true);
	ini:AddKeyComment("Chat", "range_localChat - The range a message will");
	ini:AddKeyComment("Chat", "");
	newconfig.range_localChat = ini:GetValueSetI("Chat", "range_localChat", "100");

	----------------------------------------------------------------------------------------------------------------------------------------------

	ini:WriteFile(PLUGIN:GetLocalFolder() .. "/config.ini");
	config = newconfig;

	LOG("[Townvalds] Config succesfully reloaded");

	return true;
end
