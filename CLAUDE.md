# Dungeon Route Guide

WoW Forever addon (Interface 16001). Release: push a `v*` tag; GitHub Actions runs BigWigsMods/packager.

## Rules

- Do not add `Co-Authored-By`, `Claude-Session` or any other AI signature lines to commit messages, PR descriptions or release notes.
- The CurseForge / Wago changelog comes from `CHANGELOG.md` (`manual-changelog` in `.pkgmeta`), not from commit messages. Update it for every release.
- Map images in `Maps/CL_*.blp` are unmodified Atlas files (GPL-2.0). Keep `LICENSE.txt` and `CREDITS.txt`.
- Read every game API value through `ns.Safe` / `ns.Readable` (the Forever client returns secret values).
