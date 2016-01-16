g_PluginInfo =
{
	Name = "Townvalds",
	Date = "2015-11-18",
	Description = "An opensource town plugin, based on Towny (for Bukkit).",

	AdditionalInfo =
	{
		{
			Title = "What is Townvalds?",
			Contents = "Townvalds is an opensource town plugin. It's aiming to be a fully FOSS town system comparable to Towny for Bukkit. Townvalds (will) feature towns and nations.",
		},
	},
	Commands =
	{
		["/townvalds"] =
		{
			Subcommands =
			{
				version =
				{
					Handler = DisplayVersion,
					HelpString = "Displays the current plugin version to the player",
					Permission = "townvalds.version",
				},
			},
		},
		["/town"] =
		{
			Subcommands =
			{
				new =
				{
					Handler = TownCreate,
					HelpString = "Creates a new town on the current location",
					Permission = "townvalds.town.new",
				},
				claim =
				{
					Handler = TownClaim,
					HelpString = "Claims a chunk for the current town",
					Permission = "townvalds.town.claim",
				}
			}
		}
	},
	ConsoleCommands =
	{
		["townvalds"] =
		{
			HelpString = "The main Townvalds command",
			Subcommands =
			{
				version =
				{
					Handler = DisplayVersion,
					HelpString = "Displays the current plugin version to the player",
				},
				database =
				{
					Handler = CreateTable,
					HelpString = "townvalds.database",
				},
			},
		},
	},
	Permissions =
	{
		["townvalds.version"] =
		{
			Description = "Allows the player to view the version of the plugin",
			RecommendedGroups = "admins, mods",
		},
	},
}
