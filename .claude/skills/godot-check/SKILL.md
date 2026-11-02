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
A brand new texture reports `ERROR: Failed loading resource: res://....png` on the run that first imports it - run `--import` again, only the second run counts.
Folders with an empty `.gdignore` (e.g. `resources/levels/level1/enemies/worm_boss/source/`) are skipped by Godot - used for source art that the game does not load.
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

## Scripted run (see a change working without a human player)
A `SceneTree` script drives the real game, takes screenshots and prints state. Write it as `res://_<name>.gd` in the
repo root (it must be inside the project) and delete it together with its `.gd.uid` afterwards:
```bash
"$GODOT" --path . -s res://_test.gd 2>&1 | grep -v -e leaked -e "in use at exit"; rm -f _test.gd _test.gd.uid
```
- Autoloads are not identifiers in a `-s` script (`Identifier not found: Levels`) - use `get_root().get_node("Levels")`,
  and plain ints for enum values (e.g. `5` for `Enums.ENEMIES.PEBBLE_MITE`). Inside the running scene they work normally.
- `_initialize()`: set state (`Levels.current`), `change_scene_to_file("res://scenes/world.tscn")`. Do the work in
  `_process(delta)` (return `false`), find `current_scene.get_node("GameLogic")` / `"Player"`, `quit()` when done.
- Quiet test arena: `game.get_node("PhaseGuard").set_process(false)`, `.phase_timer.stop()`, `game.kill_all_enemies()`;
  `player.godMode = true` to survive, `player.set_physics_process(false)` to keep it still; spawn with
  `game.spawn_enemy(type, pos)`.
- Screenshot: `get_root().get_texture().get_image().save_png(path)`; crop around an object with
  `img.get_region(Rect2i(...))` using `node.get_global_transform_with_canvas().origin`. Save into the scratchpad, pass the
  path through an env var. Screenshots come out darker than the game (HDR 2D).
- Log state per frame (animation:frame, distances, `player.life` / `player.shield`) to check behaviour numerically.
- Drive the player: `get_root().get_node("InputManager").set_input_mode("gamepad")`, then each frame
  `Input.action_press("move_right", strength)` / `"aim_*"` (keyboard mode aims at the real mouse cursor).
- Level ups and boss / elite kills open `game.levelUpMenu`, which **pauses the tree** - set `PlayerStatus.XpToNext`
  huge and replace `game.levelUpMenu` with a node whose `queue_chest()` / `queue_level_up()` do nothing (see
  `trailer/scripts/shots.gd`).
- Video instead of screenshots: add `--write-movie <file.avi> --fixed-fps 60 --resolution 1920x1080` (Movie Maker,
  smooth however slow the render is). Hide `game.informationBox.get_node("CanvasLayer")`, its FPS counter shows the
  recording rate. Full recipe: `trailer` skill.

## Exporting
Preset "Windows Desktop" exports to `../../exports/Bambo.exe`:
```bash
"$GODOT" --headless --path . --export-release "Windows Desktop"
```
Only export when the user asks.

## Performance
Frame-time measurements (horde, nuke, magnet, before vs after a change): use the `perf-stress` skill.
