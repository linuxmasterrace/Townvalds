g_PluginInfo =
{
	Name = "Townvalds",
	Date = "2015-11-18",
	SourceLocation = "https://github.com/linuxmasterrace/townvalds",
	Description = "An open-source town plugin, based on Towny (for Bukkit)",

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
				reloadconfig =
				{
					Handler = LoadGeneralConfig,
					HelpString = "Reloads the Townvalds configuration file",
					Permission = "townvalds.reload-config",
				}
			}
		},
		["/nation"] =
		{
			Subcommands =
			{
				new =
				{
					Handler = NationCreate,
					HelpString = "Creates a new nation",
					Permission = "townvalds.nation.new",
				},
				leave =
				{
					Handler = NationLeave,
					HelpString = "Removes the town from the nation",
					Permission = "townvalds.nation.leave",
				},
				add =
				{
					Alias = {"invite"},
					Handler = NationAddTown,
					HelpString = "Invites a town to the nation",
					Permission = "townvalds.nation.add",
				},
				join =
				{
					Handler= NationJoin,
					HelpString = "If the town has an invitation to a nation, joins the nation",
					Permission = "townvalds.nation.join",
				},
				kick =
				{
					Handler = NationKick,
					HelpString = "Kicks the town from the nation",
					Permission = "townvalds.nation.kick",
				},
				list =
				{
					Handler = NationList,
					HelpString = "Prints a list of all nations",
					Permission = "townvalds.nation.list",
				},
				["toggle"] =
				{
					Subcommands =
					{
						friendlyfire =
						{
							Alias = {"ff"},
							Handler = NationToggleFriendlyFire,
							HelpString = "Toggles friendly fire in the current nation",
							Permission = "townvalds.nation.toggle",
						},
					}
				},
				["set"] =
				{
					Subcommands =
					{
						capital =
						{
							Handler = NationSetCapital,
							HelpString = "Changes the nation's capital",
							Permission = "townvalds.nation.set.capital",
						}
					}
				},
			}
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
				delete =
				{
					Alias = {"remove"},
					Handler = TownDelete,
					HelpString = "Deletes a town",
					Permission = "townvalds.town.delete"
				},
				claim =
				{
					Handler = TownClaim,
					HelpString = "Claims a chunk for the current town",
					Permission = "townvalds.town.claim",
				},
				unclaim =
				{
					Handler = TownUnclaim,
					HelpString = "Unclaims a chunk for the current town",
					Permission = "townvalds.town.unclaim",
				},
				add =
				{
					Handler = TownAddPlayer,
					HelpString = "Invites a player to a town",
					Permission = "townvalds.town.add",
				},
				kick =
				{
					Handler = TownKickPlayer,
					HelpString = "Kicks a resident of the town",
					Permission = "townvalds.town.kick",
				},
				join =
				{
					Handler = TownJoin,
					HelpString = "If the player has an invitation of the specified town, this joins that town",
					Permission = "townvalds.town.join",
				},
				leave =
				{
					Handler = TownLeave,
					HelpString = "Leave the current town",
					Permission = "townvalds.town.leave",
				},
				["toggle"] =
				{
					Subcommands =
					{
						explosions =
						{
							Handler = TownToggleExplosions,
							HelpString = "Toggles explosions in the current town",
							Permission = "townvalds.town.toggle"
						},
						pvp =
						{
							Handler = TownTogglePVP,
							HelpString = "Toggles PVP in the current town",
							Permission = "townvalds.town.toggle"
						},
						mobs =
						{
							Handler = TownToggleMobs,
							HelpString = "Toggles mob spawning in the current town",
							Permission = "townvalds.town.toggle"
						},
						fire =
						{
							Handler = TownToggleFire,
							HelpString = "Toggles fire in the current town",
							Permission = "townvalds.town.toggle"
						},
					}
				},
				["set"] =
				{
					Subcommands =
					{
						spawn =
						{
							Handler = TownSpawnSet,
							HelpString = "Sets the town spawn at the current position",
							Permission = "townvalds.town.set.spawn"
						},
						perm =
						{
							Handler = TownPermSet,
							HelpString = "Set permissions such as building, item use, switches, etc",
							Permission = "townvalds.town.set.perms"
						},
					}
				},
				list =
				{
					Handler = TownList,
					HelpString = "Lists towns",
					Permission = "townvalds.town.list",
				},
				online =
				{
					Handler = TownOnline,
					HelpString = "Lists players online in the town",
					Permission = "townvalds.town.online",
				},
				rank =
				{
					Handler = TownRank,
					HelpString = "Lists available ranks, or grant and remove a rank to a resident of the town",
					Permission = "townvalds.town.rank",
				},
				spawn =
				{
					Alias = {"teleport"},
					Handler = TownSpawn,
					HelpString = "Teleports the player to a town spawn",
					Permission = "townvalds.town.spawn",
				},
			}
		},
		["/plot"] =
		{
			Subcommands =
			{
				claim =
				{
					Handler = PlotClaim,
					HelpString = "Claims the plot for the player",
					Permission = "townvalds.plot.claim",
				},
				unclaim =
				{
					Handler = PlotUnclaim,
					HelpString = "Unclaims the plot",
					Permission = "townvalds.plot.unclaim",
				},
				["toggle"] =
				{
					Subcommands =
					{
						mobs =
						{
							Handler = PlotToggle,
							HelpString = "Toggles mob spawning in the current plot",
							Permission = "townvalds.plot.toggle"
						},
						explosions =
						{
							Handler = PlotToggle,
							HelpString = "Toggles explosions in the current plot",
							Permission = "townvalds.plot.toggle"
						},
						pvp =
						{
							Handler = PlotToggle,
							HelpString = "Toggles PVP in the current plot",
							Permission = "townvalds.plot.toggle"
						},
						fire =
						{
							Handler = PlotToggle,
							HelpString = "Toggles fire in the current plot",
							Permission = "townvalds.plot.toggle"
						}
					}
				}
			}
		},
		["/resident"] =
		{
			Handler = DisplayResident,
			HelpString = "Displays information about resident",
			Permission = "townvalds.resident.info",
		},
		["/switchchat"] =
		{
			Alias = {"/sc", "/gc", "/nc", "/tc", "/lc"},
			Handler = SwitchChat,
			HelpString = "Switches the active chat channel for the user",
			Permission = "townvalds.chat.switch",
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
				reloadconfig =
				{
					Handler = LoadConfig,
					HelpString = "Reloads the Townvalds configuration file",
				}
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
		["townvalds.database"] =
		{
			Description = "Database test",
			RecommendedGroups = "admins",
		},
		["townvalds.resident.info"] =
		{
			Description = "Allows the player to view information about a resident",
			RecommendedGroups = "default",
		},
		["townvalds.reload-config"] =
		{
			Description = "Allows the player to view information about a resident",
			RecommendedGroups = "admins",
		},
		["townvalds.nation.list"] =
		{
			Description = "Allows the player to see a list of existing nations",
			RecommendedGroups = "default",
		},
		["townvalds.nation.new"] =
		{
			Description = "Allows the player to create a new nation",
			RecommendedGroups = "default",
		},
		["townvalds.nation.leave"] =
		{
			Description = "Allows the player to remove his/her town from a nation",
			RecommendedGroups = "default",
		},
		["townvalds.nation.add"] =
		{
			Description = "Allows kings to invite new towns to their nations",
			RecommendedGroups = "default",
		},
		["townvalds.nation.join"] =
		{
			Description = "Allows mayors to let their town join a nation",
			RecommendedGroups = "default",
		},
		["townvalds.nation.kick"] =
		{
			Description = "Allows the king to kick a town from the nation",
			RecommendedGroups = "default",
		},
		["townvalds.nation.toggle"] =
		{
			Description = "Allows the player to toggle nation protections",
			RecommendedGroups = "default",
		},
		["townvalds.nation.set.capital"] =
		{
			Description = "Allows the player to set a different capital for nations",
			RecommendedGroups = "default",
		},
		["townvalds.town.new"] =
		{
			Description = "Allows the player to create a new town",
			RecommendedGroups = "default",
		},
		["townvalds.town.delete"] =
		{
			Description = "Allows the player to delete their own town",
			RecommendedGroups = "default",
		},
		["townvalds.town.delete.other"] =
		{
			Description = "Allows the player to delete any town",
			RecommendedGroups = "admins",
		},
		["townvalds.town.claim"] =
		{
			Description = "Allows the player to claim a new chunk for the town",
			RecommendedGroups = "default",
		},
		["townvalds.town.unclaim"] =
		{
			Description = "Allows the player to unclaim a chunk for the town",
			RecommendedGroups = "default",
		},
		["townvalds.town.add"] =
		{
			Description = "Allows the player to invite people to the town",
			RecommendedGroups = "default",
		},
		["townvalds.town.kick"] =
		{
			Description = "Allows the player to kick residents from the town",
			RecommendedGroups = "default",
		},
		["townvalds.town.rank"] =
		{
			Description = "Lists available ranks, or grant and remove a rank to a resident of the town",
			RecommendedGroups = "default",
		},
		["townvalds.town.toggle"] =
		{
			Description = "Allows the player to toggle town protections",
			RecommendedGroups = "default",
		},
		["townvalds.town.spawn"] =
		{
			Description = "Allows the player to teleport to their towns spawn",
			RecommendedGroups = "default",
		},
		["townvalds.town.spawn.other"] =
		{
			Description = "Allows the player to teleport to another towns spawn. This is used together with the 'teleport_to_friendly_town_spawns_only' config option",
			RecommendedGroups = "default",
		},
		["townvalds.town.spawn.admin"] =
		{
			Description = "Allows the player to always teleport to any town",
			RecommendedGroups = "admins",
		},
		["townvalds.town.set.spawn"] =
		{
			Description = "Allows the player to set the town spawn. This is used together with the 'enable_town_spawns' config option",
			RecommendedGroups = "default",
		},
		["townvalds.town.set.perms"] =
		{
			Description = "Allows the player to change permissions such as building, item use, switches, etc",
			RecommendedGroups = "default",
		},
		["townvalds.town.online"] =
		{
			Description = "Allows the player to see a list of online town members",
			RecommendedGroups = "default",
		},
		["townvalds.plot.claim"] =
		{
			Description = "Allows the player to claim a plot",
			RecommendedGroups = "default",
		},
		["townvalds.plot.unclaim"] =
		{
			Description = "Allows the player to unclaim a plot"
		},
		["townvalds.plot.toggle"] =
		{
			Description = "Allows the player to toggle plot features",
			RecommendedGroups = "default",
		},
		["townvalds.chat.switch"] =
		{
			Description = "Allows the player to switch between chat channels",
			RecommendedGroups = "default",
		},
	},
}
