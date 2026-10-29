---
name: godot-check
description: Validate the Space Thunder Godot project headlessly - parse all GDScript, load scenes and report errors - and optionally launch the game. Use after any .gd/.tscn change, before committing, or when asked to run/test the game.
---

# Checking and running the project

Godot binary (4.7.2, console build prints to stdout):
`C:\Users\sebsz\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
(the `.exe` part of the first path is a folder). If it is missing, ask the user for the Godot path.

## Headless validation (preferred after edits)
Run from the repo root (Bash):
```bash
GODOT="/c/Users/sebsz/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 180 "$GODOT" --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|WARNING" \
  | grep -v -e "addons/godot_state_charts" -e "invalid UID" -e "leaked at exit" -e "still in use at exit" | head -50
```
`--import` loads the project, reimports changed assets and compiles every script and autoload, so parse errors, missing `res://` paths and broken `.tscn` references show up as `ERROR` / `SCRIPT ERROR` lines. No output = clean. Takes ~1 min.

Filtered noise (always present, harmless): "invalid UID ... using text path instead" (`.import` files are gitignored) and RID/ObjectDB/resource leak messages at exit.
Known real warning: `scenes/bullet.tscn` references `res://scripts/Bullet.gd` (capital B) - breaks on case-sensitive export platforms until fixed.

Single script:
```bash
"$GODOT" --headless --path . --check-only --script res://scripts/<file>.gd 2>&1 | head -30
```
Note: `--check-only` on a script that uses autoloads (`Enums`, `PlayerStatus`...) can report false "identifier not declared" errors; trust the `--import` run for those.

## Running the game
Launch in the background so the session is not blocked, then ask the user to play-test:
```bash
"$GODOT" --path . 2>&1 | tail -100
```
Run with `run_in_background`. Start a run directly from the world scene with `"$GODOT" --path . res://scenes/world.tscn`.
Debug cheats (debug builds only): F1 level up, F2 skip 60 s, F3 skip to boss, F4 spawn worm boss.

## Exporting
Preset "Windows Desktop" exports to `../../exports/Bambo.exe`:
```bash
"$GODOT" --headless --path . --export-release "Windows Desktop"
```
Only export when the user asks.
