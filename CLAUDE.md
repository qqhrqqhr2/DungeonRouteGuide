# Dungeon Route Guide

WoW Forever addon (Interface 16001). Release: put a new `## vX.Y.Z` heading at the top of `CHANGELOG.md` and push it to main (the workflow tags the commit and runs BigWigsMods/packager), or push a `v*` tag. Uploads go to CurseForge 1728502 only (Wago is no longer used).

## Rules

- Do not add `Co-Authored-By`, `Claude-Session` or any other AI signature lines to commit messages, PR descriptions or release notes.
- The CurseForge changelog comes from `CHANGELOG.md` (`manual-changelog` in `.pkgmeta`), not from commit messages. Update it for every release.
- Map images in `Maps/CL_*.blp` are unmodified Atlas files (GPL-2.0). Keep `LICENSE.txt` and `CREDITS.txt`.
- Read every game API value through `ns.Safe` / `ns.Readable` (the Forever client returns secret values).
