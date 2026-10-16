# Dungeon Route Guide

## v1.0.12

### 한국어

- 아제로스 전체 지도와 대륙 지도에 작은 던전 입구·이름·권장 레벨을 표시하고, 가까운 입구를 하나로 묶어 안내합니다. 지역·도시·던전 지도에서는 게임의 기본 표시를 사용합니다.
- 지도 하단 중앙의 기존 애드온 아이콘으로 검색·표시 옵션을 열고 닫습니다. 아이콘은 드래그로 이동하며 위치를 저장하고 지도 밖으로 나가지 않습니다.
- 던전 목록과 던전 표식의 좌·우클릭 기능을 제거했습니다. 한글·영문 검색 후 Enter를 누르면 해당 입구의 지역 지도를 엽니다. 해골 표식과 테두리는 가로·세로를 절반으로 줄였습니다.
- 로데론의 폐허를 남작 → 비열한 빅토르(선택) → 버려진 자(선택) → 비요크 → 라스마엘 순서로 조정하고 이동·이벤트 안내를 보완했습니다. 기존 완료 기록과 지도 좌표는 유지합니다.
- 호드는 하수도 열쇠가 있어도 야외 달라란에서 공격받으며 하수도를 통한 던전 입장은 유지된다는 주의사항을 한글·영문으로 추가했습니다.
- 군주 아쿠아니스 퀘스트 보상 3종을 툴팁에 연결했습니다. 현재 아이템 이름·등급·능력치는 게임 정보를 사용합니다.

### English

- Reorder Ruins of Lordaeron to the Baron → Viktor (optional) → the Abandoned (optional) → Bjork → Rath'mael, with updated passage/wave-event notes; keep boss IDs and native map positions tied to the same bosses
- Add a Korean/English warning that Horde characters are attacked in outdoor Dalaran even with the sewer key, while City of Dalaran dungeon access remains available
- Show all three Baron Aquanis quest reward options in tooltips, with Korean/English name fallbacks; read current names, quality and stats from the game
- Halve the width and height of world-map skull markers and their borders while keeping dungeon-name and level text readable
- Add a compact original-addon icon that opens Dungeon Route Guide search and display options; start it at the bottom center, support bounded dragging, and remember its position
- Remove the dungeon result list, per-dungeon selection and left/right-click actions on dungeon markers; keep name/level/location tooltips and pass clicks through to the map
- Keep Korean/English name search as a map-marker filter, with a result count and a clear button
- Press Enter after entering a dungeon name to open its entrance's zone map; prefer an exact name/key match, otherwise use the first partial match, and honor saved entrance coordinates
- Show compact dungeon entrance markers, names and recommended levels on the Azeroth world map and continent maps; use the game's own markers on detailed maps
- Group nearby entrances, including Scarlet Monastery wings, and list all grouped dungeons in the tooltip
- Keep markers readable while zooming, avoid overlapping labels, and provide entrance/name/level display toggles
- Add outdoor entrance positions for Ruins of Lordaeron and City of Dalaran; prefer saved entrance coordinates

## v1.0.11

- Quests show the level they can be taken from (99 dungeon quests); quests you are too low for show it in red in the Quests tab and tooltip
- City of Dalaran: Arcanic Enigma goes by its game name (신비한 수수께끼), Korean quest names Heart of Disruption (분열의 심장) and Opportunistic Education (기회주의 학습법), and updated boss notes (Fel Ancient in Runeweaver Square, Unstable Sentinel, Mana Devourer, Tome of Dalaran)
- Zooming and dragging the map redraw only the map, so panning stays smooth
- Floor links show the floor they lead to under the icon again, only where the name fits (one per destination nearby, never over a marker or another name; the tooltip always has it)

## v1.0.10

- The map follows the sub-zone you stand in again in Deadmines, Gnomeregan, Blackfathom Deeps and Uldaman (lost with the new minimap pages in 1.0.8)
- Credits describe the bundled minimap art correctly

## v1.0.9

- Align route dots, completion checks, type icons and boss numbers with the first line of wrapped monster names
- Add mouse-wheel scrolling and a scrollbar to Route, Quests and Prep; keep each tab position and clamp it when content or window size changes
- Display every visible quest and wrap long route names, quest descriptions and preparation notes; include all loot icons in the scrollable panel
- Complete City of Dalaran boss loot: all 26 drops across eight bosses, including Lyn the Ignored and Arcane Anomaly
- Show 18 City of Dalaran quest reward options in quest tooltips, with English and Korean name fallbacks
- Clarify that the Titan Relic is returned for Excavation Site follow-up quests, so another dungeon run is not required for the relic
- Explain how to reach the Shade of the Archmage through the NPC outside the Violet Citadel

## v1.0.8

- All 18 dungeons and 29 areas now use bundled minimap tiles, with square fit, mouse-wheel zoom, pan and Fit reset
- Align map orientation and prevent clickable goals and floor links from overlapping
- Scarlet Monastery no longer selects Graveyard when the wing is unknown; retry zone detection or select the current wing with /drg wing library (or /drg wing auto)
- Include the original addon icon for the screen button and addon list
- Add Korean names for all 106 quest entries, including new dungeon quests; prefer the game's Korean title when available, with a bundled Korean fallback
- Translate quest objectives and attunement instructions and remove development labels and external guide-site names from the game UI

## v1.0.7

- City of Dalaran has two floors: the sewers where the run starts (Atrexis, Lyn the Ignored) on the game's own indoor minimap of the sewers, and the city on the outdoor minimap
- Floors switch by themselves in dungeons without area data too: the sub-zone you stand in when a boss dies is remembered for that boss's floor
- City of Dalaran: Mana Devourer and Arcanic Enigma placed where they stand in the game; Mana Wraith is no longer listed as a boss (elite trash)

## v1.0.6

- Hall of Thanes, Excavation Site, Ruins of Lordaeron and City of Dalaran now show the game's own minimap of the dungeon (loaded from the client by file ID, community guide positions fitted onto it). City of Dalaran has no positions on community guide yet, so its boss spots are estimated from the guide's area names
- Hand-drawn sketch maps for these four dungeons as a fallback (client without the tiles, or Options > Map art: Atlas), redrawn in the style of the game's dungeon maps
- City of Dalaran is recognised when you enter it (instance 2959), so progress and auto-checks work there too
- community guide updates: City of Dalaran boss tactics (no longer the BlizzCon-demo notes), attunement quests for both factions in the Prep tab, how to summon Lyn the Ignored, and 10 more boss drops
- New dungeon quests: Dalaran (Starving Arcane, Heart of Disruption for each faction) and Scarlet Monastery Library (Past Due)
- Ruins of Lordaeron: the unconfirmed rare Lordaeron Captain is no longer listed
- A dungeon without any map shows the route as a numbered flow chart instead of an empty area
- /drg mapscan (outside dungeons) looks for the game's own world maps of the dungeons

## v1.0.5

- Item names show right away from the game's own item table instead of waiting for the server; /drg item <id> shows what the game knows about an item
- Loading bar while item info is still coming from the server; items the game does not have are marked as such instead of "Loading…" forever
- Long loot lists scroll: the card next to the window has a scroll bar, and the icon rows under the tip scroll with the mouse wheel
- Loot refreshed for all dungeons from the current community guide lists
- Prep tab: drops of trash mobs and of named mobs off the route (e.g. Deathsworn Captain, Techbot) are grouped by source; click one to see the full item list with names
- The Route list ends with a "Trash mobs" row (and rows for named mobs off the route); click it to see their drops under the tip and in the card
- Trash drops show which mob drops them and how often (e.g. Defias Blackguard 6%), or "any mob in the dungeon, low chance" for dungeon-wide drops; mob-specific drops are listed first
- Full monster names as community guide lists them (e.g. 잠들지 않는 아즈쉬르, 돌연변이 요정용 instead of shortened names)
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

- 18 WoW Forever dungeons from the community guide guides: route order, bosses, rares, NPCs and quest spots
- Map legend (entrance / boss / rare / NPC / quest spot), quest "!" badges, alternate spawn spots
- Multi-page maps (Blackfathom Deeps), dungeon picker, Route / Quests / Prep tabs
- Kill detection by creature ID and by name
- Screen icon: left-click opens the guide anywhere, right-click starts the entrance arrow
- Addon icon / logo

## v0.1.x

- First test builds: route overlay, automatic boss checks, next-objective bar, instance reset detection
