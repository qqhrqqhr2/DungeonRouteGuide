# tools

Data pipeline for `Data.lua` (not packaged).

1. Download the wowf.io guide pages into `wowf/` (`<slug>.html` Korean, `<slug>.en.html` English),
   and the Atlas classic maps into `atlas/Images/Atlas_ClassicWoW` (github.com/nanderson11/Atlas).
2. `python parse_wowf.py` -> `wowf.json` (steps, pins, quests);
   loot pages (`https://wowf.io/ko/dungeons/<slug>`) in the current folder -> `python parse_loot.py` -> `loot.json`
3. `python place.py` -> `placed.json` (wowf pins converted onto the Atlas maps using `anchors.py`)
4. Edit `texts.py` (tips, rewritten) and `routes.py` (route waypoints), then `python build.py` -> `../Data.lua`
5. `python run.py` (and `python run.py enUS`) runs `harness.lua`, a smoke test with stubbed WoW API (needs `pip install lupa`).
