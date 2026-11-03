---
name: add-level
description: How levels work in Space Thunder and how to add or change one - the Levels ladder in singletons/levels.gd (story, waves, bosses, rewards), per-level parallax background from Gemini art, enemy swaps per level ("replace"), unlocking (level n needs level n-1 cleared), the level select screen and the per-level art bible. Use when adding a level, making a level playable, changing a level's background, story, waves or enemies, or touching level unlocking.
---

# Levels

Every level is a 10-minute survival run with its own stages, bosses, story and look. All of it is data in
`Levels` autoload (`singletons/levels.gd`) builds the ladder from `resources/levels/levelN/level.tres` (`LevelDef`);
the run itself is the same `scenes/shared/world.tscn` for every level.

## Where things live
- `resources/levels/levelN/level.tres` - one `LevelDef` per playable level (`scripts/level_def.gd`). Its `data` dictionary
  holds the keys listed below; `inherits` points to a base level and the level only lists what differs (level 2 inherits
  level 1's stages, bosses and tuning).
- `singletons/levels.gd` - `LEVEL_DEFS` (the playable levels, `preload`ed) and `_UNBUILT_LEVELS` (name-only placeholders,
  shown as "UNDER DEVELOPMENT"). Max `MAX_LEVELS` = 10.
  - `is_available(i)` - the level has gameplay data.
  - `is_unlocked(i)` - available **and** (`i == 0` or level `i - 1` is completed). Launch, Hangar and `select()` use this.
  - `is_completed(i)` / `mark_completed(i)` - stored in the save slot (`ConfigHandler` "Progress/completed_levels"),
    `game_logic` marks it when the final boss dies. `select()` also restores the last played level on slot load and
    falls back to level 1 if that level is locked.
- Level-specific level-up cards are not in `levels.gd`: they are entries in `singletons/upgrades.gd` with
  `only_level` / `except_level` = the level index (see the add-upgrade skill). `weapon_skin` only renames weapons and swaps
  their card icon, it does not add or hide cards. A new level with its own cards needs its own index in those fields.
- `scripts/phase_guard.gd` reads `stages`, `bosses`, `elite_at`, `swarm_*` in `_load_level` (read only - the arrays
  can be consts).
- `scripts/game_logic.gd` - `_level_enemy(type)` applies the level's `"replace"` map to waves, swarms and boss minions
  (not to dev console spawns). Level title banner, victory bonus, `boss_life_factor`.
- `scripts/world.gd` - applies the level's `"background"` on `_ready`; levels without it keep the planets of `world.tscn`.
- `scripts/level_select.gd` - ladder + briefing; locked levels show the tagline and "Clear Level n - NAME to open it",
  Launch/Hangar disabled.
- Art brief per level in the repo root: `art_level1.md` (level 1 + player, pickups, icons - done), `art_level2.md`
  (level 2 rock bugs). Each one is **self-contained** - the user pastes the whole file into Gemini.

## Level entry
Keys of `data` in the `.tres` (written as `var_to_str` text; enums are their numbers, see the `LevelDef` header):
`name`, `tagline`, `story` (array of paragraphs), `objective`, `win_text`, `available`, `stages` (10 x
`{ delay, max_alive, wave : [[enemy, count, chance %], ...] }`), `bosses` (`[{ at (s), type, final }]`, the final one
ends the run), `elite_at`, `swarm_every`, `swarm_base`, `swarm_per_stage`, `boss_life_factor`, `victory_bonus`, and the
optional `replace` (`{ enemy : enemy }`), `background`, `music`, `music_db`, `weapon_skin`.

To add a level: create `resources/levels/levelN/level.tres` (set `inherits` to the base level when it only changes a few
keys), add its `preload` to `LEVEL_DEFS` in `levels.gd` and drop its placeholder from `_UNBUILT_LEVELS`. Generate the
`.tres` from a Godot script with `var_to_str` rather than typing the nested data by hand.

## Background art from Gemini
The user delivers a backdrop (opaque) plus single asteroids/props on green into `resources/levels/level<N>/background/source/`
(add an empty `.gdignore` there). Level music goes in `resources/levels/level<N>/music/`. Folder naming and moves: see the `asset-layout` skill.
1. Props: `python -I .claude/skills/add-level/scripts/cut_sprite.py "<src>" resources/levels/level<N>/background/<name>.png <width>`
   (keys any green by green dominance, so a dull green or a lighter square works too). Small 256 px, medium 512, huge 1024.
2. Backdrop: crop to 16:9 and resize to 1920x1080 jpg (PIL, quality ~92).
3. Check the cut-outs composited on dark and light (PIL contact sheet, Read it) for green fringes.
4. Add the `"background"` entry; place props inside the layer's mirror size, at most one huge prop in `near`.
5. Look at it in game (see Verify). The scene dims layers to 20/39/49 % for the bright Kenney planets - dark painted
   rocks disappear at that, so set `"brightness"` (level 2 uses 0.5 / 0.65 / 0.75).
Background props must stay dimmer, softer and outline-free compared to enemies, so they never read as something to shoot.

## Verify
- `godot-check` (the first `--import` reports `Failed loading resource` for new pngs - run it again).
- Scripted run of a level (see `godot-check`, "Scripted run"): set `get_root().get_node("Levels").current = <i>` in
  `_initialize`, `change_scene_to_file("res://scenes/shared/world.tscn")`, screenshot after ~3 s and again after moving the
  player (`player.global_position += Vector2(1500, 900)`) to check parallax seams. Compare against level 1 in the same way.
- Trailer footage of the new level: add `lN_*` shots to `trailer/scripts/shots.gd` (see the `trailer` skill).
- Unlocking: print `Levels.is_available(i)` / `is_unlocked(i)` from a scripted run and screenshot `res://scenes/menus/level_select.tscn`
  with a locked level focused (`current_scene._level_buttons[i].grab_focus()`).
