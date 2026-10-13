# Dungeon Route Guide

WoW Forever addon (Interface 16001). Release: put a new `## vX.Y.Z` heading at the top of `CHANGELOG.md` and push it to main (the workflow tags the commit and runs BigWigsMods/packager), or push a `v*` tag. Uploads go to CurseForge 1728502 only (Wago is no longer used).

## Rules

- Do not add `Co-Authored-By`, `Claude-Session` or any other AI signature lines to commit messages, PR descriptions or release notes.
- The CurseForge changelog comes from `CHANGELOG.md` (`manual-changelog` in `.pkgmeta`), not from commit messages. Update it for every release.
- Map images in `Maps/CL_*.blp` are unmodified Atlas files (GPL-2.0). Keep `LICENSE.txt` and `CREDITS.txt`. The release no longer ships `Maps/`; maps come from `MinimapData.lua` + `MinimapTiles_v12/`.
- Do not regenerate `Data.lua` with `tools/build.py` (it predates the v1.0.8 minimap data and would drop it).
- Run `python3 run.py` and `python3 run.py enUS` in `tools/` before pushing; both must end with ALL CHECKS PASSED.
- Read every game API value through `ns.Safe` / `ns.Readable` (the Forever client returns secret values).
