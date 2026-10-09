# tools

Data pipeline for `Data.lua` (not packaged).

1. Download the wowf.io guide pages into `wowf/` (`<slug>.html` Korean, `<slug>.en.html` English),
   and the Atlas classic maps into `atlas/Images/Atlas_ClassicWoW` (github.com/nanderson11/Atlas).
2. `python parse_wowf.py` -> `wowf.json` (steps, pins, quests);
   loot pages (`https://wowf.io/ko/dungeons/<slug>`) in the current folder -> `python parse_loot.py` -> `loot.json`
2b. Blizzard map tiles: `blizmaps.py` lists the 12 tile file IDs per wowf floor (from the
   wowdev listfile, checked by stitching the tiles from wago.tools against the wowf client
   floor images). `displays.json` (creature display IDs) is extracted from the cmangos
   classic-db `creature_template`.
2c. `minimaps.py`: minimap tiles (file IDs from each map's WDT, MAID chunk) of the new Forever
   dungeons, the wowf image -> minimap fits and the shown part. `python sketches.py` redraws the sketch maps of the new Forever dungeons into `../Maps`.
3. `python place.py` -> `placed.json` (wowf pins converted onto the Atlas maps using `anchors.py`)
4. Edit `texts.py` (tips, rewritten) and `routes.py` (route waypoints), then `python build.py` -> `../Data.lua`
5. `python run.py` (and `python run.py enUS`) runs `harness.lua`, a smoke test with stubbed WoW API (needs `pip install lupa`).
