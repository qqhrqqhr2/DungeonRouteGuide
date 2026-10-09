# Dungeon Route Guide

## Unreleased

- wowf.io updates: City of Dalaran boss tactics (no longer the BlizzCon-demo notes), attunement quests for both factions in the Prep tab, how to summon Lyn the Ignored, and 10 more boss drops
- New dungeon quests: Dalaran (Starving Arcane, Heart of Disruption for each faction) and Scarlet Monastery Library (Past Due)
- Ruins of Lordaeron: the unconfirmed rare Lordaeron Captain is no longer listed

## v1.0.5

- Item names show right away from the game's own item table instead of waiting for the server; /drg item <id> shows what the game knows about an item
- Loading bar while item info is still coming from the server; items the game does not have are marked as such instead of "Loading…" forever
- Long loot lists scroll: the card next to the window has a scroll bar, and the icon rows under the tip scroll with the mouse wheel
- Loot refreshed for all dungeons from the current wowf.io lists
- Prep tab: drops of trash mobs and of named mobs off the route (e.g. Deathsworn Captain, Techbot) are grouped by source; click one to see the full item list with names
- The Route list ends with a "Trash mobs" row (and rows for named mobs off the route); click it to see their drops under the tip and in the card
- Trash drops show which mob drops them and how often (e.g. Defias Blackguard 6%), or "any mob in the dungeon, low chance" for dungeon-wide drops; mob-specific drops are listed first
- Full monster names as wowf.io lists them (e.g. 잠들지 않는 아즈쉬르, 돌연변이 요정용 instead of shortened names)
- When you target or mouse over a boss, the name your game client shows is remembered and used in the guide from then on

## v1.0.4

- Ways to another map area are now a clear arrow button with the area name under it; click it to open that area's map
- Multi-floor dungeons switch the map floor by themselves: by the sub-zone you stand in (Deadmines, Gnomeregan, Blackfathom Deeps, Uldaman) and by the boss or NPC you target. Picking a floor by hand holds until you walk into another area

## v1.0.3

- Next objective follows the group: after each kill it points to the nearest open step on the map (steps left behind count as farther), so killing bosses out of order no longer sends you back to boss 1
- A boss killed out of order only ticks off the talks / quest spots on its own stretch of the route
- No more "Skipped" label in the list: bosses taken later are just open
- Only bosses are numbered (1, 2, 3 … in route order); NPCs, rares and quest spots show an icon instead (speech bubble, star, "!")

## v1.0.2

- Skipped bosses no longer block the guide: the next objective continues after the furthest boss you have killed, and a boss left behind is marked "Skipped" in the list (it comes back as the objective only at the end)

## v1.0.1

- Support link: Options > Support the addon, or /drg donate (shows the Buy Me a Coffee address to copy)

## v1.0.0

- First public release on CurseForge and Wago
- Sharper maps: the game's own dungeon map art (read from the client, nothing extra to download) for 13 dungeons; Atlas maps stay as a fallback and for Wailing Caverns. Switch with Options > Map art or /drg map. Place names on these maps follow the game client language
- Click a boss to open a card with its 3D model (drag to rotate, wheel to zoom) and the full loot list
- Fixed loot icons being covered by their quality colour
- Dungeons with several maps: area dropdown in the map corner ("Area 2/4"), with a "Next objective →" link when the next stop is on another map
- English layout: header buttons and tabs size to their text, boss count shown with a skull icon
- The map window no longer closes with ESC; use the X button (or /drg)
- Route lines removed; numbered markers show the order and the next one glows
- Edit mode now just moves markers (/drg edit)
- Hand-drawn sketch maps for Hall of Thanes, Excavation Site and Ruins of Lordaeron
- Dungeon dropdown and a "Current" button that jumps back to the dungeon you are in
- Smaller, see-through markers so the map underneath stays visible
- The window can be dragged by the map area too
- Shorter footer: only browse / sketch / edit notes (credits stay in CREDITS.txt)
- Language option: Auto (game language), Korean or English (Options menu or /drg lang)
- Boss loot: item list in marker tooltips and item icons under the tip (hover for the item tooltip, Shift-click to link); trash drops on the Prep tab

## v0.2.0

- 18 WoW Forever dungeons from the wowf.io guides: route order, bosses, rares, NPCs and quest spots
- Map legend (entrance / boss / rare / NPC / quest spot), quest "!" badges, alternate spawn spots
- Multi-page maps (Blackfathom Deeps), dungeon picker, Route / Quests / Prep tabs
- Kill detection by creature ID and by name
- Screen icon: left-click opens the guide anywhere, right-click starts the entrance arrow
- Addon icon / logo

## v0.1.x

- First test builds: route overlay, automatic boss checks, next-objective bar, instance reset detection
