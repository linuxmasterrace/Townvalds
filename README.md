#Townvalds

An open-source town plugin for [Cuberite](https://www.cuberite.org) (a custom Minecraft compatible game server written in C++). We're aiming to create a fully FOSS town system compatible with Cuberite implementing towns, nations, and permissions and protections management to follow along with them.

You can contact us on IRC at #linuxmasterrace @ irc.snoonet.org
Do note that this channel talks about a whole lot of unrelated stuff as well, and you may need to contact us directly.

Townvalds requires [Cuberite](https://www.cuberite.org) and a legitimate [Minecraft](https://www.minecraft.net) account to run.

##(Planned) features
 - Towns
   - Players can create and join towns
   - Towns allow protection from monsters, explosions, pvp, fire and griefing
   - Towns can manage land based on chunks (plots)
     - Towns are divided into plots
     - Plots can be claimed by members of the town, to allow more specific protection
     - Players can allow or block other town members from building/destroying, opening doors and chests, and more
   - Town based spawns and teleporting
     - Players can spawn to their town upon death
     - Players can teleport to towns within their nations
 - Nations
   - Towns can join together forming nations
   - Nations can have war between them, allowing huge battles
   - Uses Minecraft's own team features
     - Members of towns in the nation will automatically be added to the nation's team
     - Allowing players to be lighten up in their team colors when shot with spectral arrows
     - Enable or disable friendly fire per nation
     - Track kills, town take overs and more when in war
 - Enhanced chat
   - Allow local and global chat, and chat per town and nation to keep enemies from hearing about your war tactics
   - Custom chat formatting per channel
 - Coiny integration
   - Charge money for the creation of towns and nations
   - Charge taxes

Most of these features are configurable in the settings file inside the plugin folder (will be created at first run).

###Current commands
| Command | Subcommands | Arguments | Aliases | Permission | Description |
| ------- | --------- | ----------- | ------- | ---------- | ----------- |
| /townvalds | version | | | townvalds.version | Displays the current plugin version to the player |
| | reloadconfig | | | townvalds.reload-config | Reloads the Townvalds configuration file |
| /nation | new | [name] | | townvalds.nation.new | Creates a new nation |
| | leave | | | townvalds.nation.leave | Removes the town from the nation |
| | list | | | townvalds.nation.list | Prints a list of all nations |
| | toggle | friendlyfire | | townvalds.nation.toggle | Toggles friendly fire on or off in the current nation |
| /town | new | [name] | | townvalds.town.new | Creates a new town on the current location |
| | claim | | | townvalds.town.claim | Claims a chunk for the current town |
| | unclaim | | | townvalds.town.unclaim | Unclaims a chunk for the current town |
| | add | [username] | | townvalds.town.add | Invites a player to the town |
| | kick | [username] | | townvalds.town.kick | Kicks a resident of the town |
| | join | {townname} | | townvalds.town.join | If the player has an invitation of a town, joins the town |
| | leave | | | townvalds.town.leave | Leaves the current town |
| | toggle | explosions | | townvalds.town.toggle | Toggles explosions on or off in the current town |
| | toggle | pvp | | townvalds.town.toggle | Toggle pvp on or off in the current town |
| | toggle | mobs | | townvalds.town.toggle | Toggle mob spawning on or off in the current town |
| | list | | | townvalds.town.list | Prints a list of all towns |
| | rank | [list/add/remove] {rank} {username} | | townvalds.town.rank | Lists available ranks, or grant or remove a rank to a resident of the town |
| /plot | claim | | | townvalds.plot.claim | Claims the plot for the player |
| | unclaim | | | townvalds.plot.unclaim | Unclaims the plot |
| | toggle | mobs | | townvalds.plot.toggle | Toggles mob spawning on or off in the current plot |
| /resident | | | | townvalds.resident.info | Displays information about a resident |
| /switchchat | | {global/nation/town/local} | /sc, /gc, /nc, /tc, /lc | townvalds.chat.switch | Switches the active chat channel |

##License
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
