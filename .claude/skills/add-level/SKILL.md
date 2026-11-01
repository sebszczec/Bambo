---
name: add-level
description: How levels work in Space Thunder and how to add or change one - the Levels ladder in singletons/levels.gd (story, waves, bosses, rewards), per-level parallax background from Gemini art, enemy swaps per level ("replace"), unlocking (level n needs level n-1 cleared), the level select screen and the per-level art bible. Use when adding a level, making a level playable, changing a level's background, story, waves or enemies, or touching level unlocking.
---

# Levels

Every level is a 10-minute survival run with its own stages, bosses, story and look. All of it is data in
`singletons/levels.gd` (`Levels` autoload); the run itself is the same `scenes/world.tscn` for every level.

## Where things live
- `singletons/levels.gd` - `_levels` array (max `MAX_LEVELS` = 10). A level without `"available": true` is shown as
  "UNDER DEVELOPMENT". Shared wave data is in consts (`_LEVEL1_STAGES`, `_LEVEL1_BOSSES`) so levels can reuse it.
  - `is_available(i)` - the level has gameplay data.
  - `is_unlocked(i)` - available **and** (`i == 0` or level `i - 1` is completed). Launch, Hangar and `select()` use this.
  - `is_completed(i)` / `mark_completed(i)` - stored in the save slot (`ConfigHandler` "Progress/completed_levels"),
    `game_logic` marks it when the final boss dies. `select()` also restores the last played level on slot load and
    falls back to level 1 if that level is locked.
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
```gdscript
{
	"name" : "Asteroid Siege",
	"tagline" : "...", "story" : ["paragraph", ...], "objective" : "...", "win_text" : "ASTEROID SIEGE BROKEN",
	"available" : true,
	"stages" : _LEVEL1_STAGES,      # 10 x { delay, max_alive, wave : [[enemy, count, chance %], ...] }
	"bosses" : _LEVEL1_BOSSES,      # [{ at (s), type, final }], the final one ends the run
	"elite_at" : 450.0, "swarm_every" : 120.0, "swarm_base" : 15, "swarm_per_stage" : 2,
	"boss_life_factor" : 0.8, "victory_bonus" : 5000,
	"replace" : { Enums.ENEMIES.SCOUT : Enums.ENEMIES.PEBBLE_MITE },   # optional
	"background" : {                                                   # optional
		"base" : "res://resources/background/level2/bg.jpg",         # 1920x1080, fixed to the screen
		"brightness" : { "far" : 0.5, "mid" : 0.65, "near" : 0.75 },  # optional layer modulate
		"far" : [[texture, Vector2(pos), scale], ...],                # ParallaxLayer motion 0.1, mirror 1920x1080
		"mid" : [...],                                                # motion 0.3, mirror 2880x1620
		"near" : [...],                                               # motion 1.0, mirror 3840x2160
	},
}
```
Use `"replace"` to give a level its own enemies while it shares the waves of another level; give it own `stages`
when the mix or pacing should differ. Story and speech audio: the phase speeches in `world.tscn` are level 1 lines
and still play in every level.

## Background art from Gemini
The user delivers a backdrop (opaque) plus single asteroids/props on green into `resources/background/level<N>/source/`
(add an empty `.gdignore` there). A folder with a space in the name may be locked by the editor - copy instead of rename.
1. Props: `python -I .claude/skills/add-level/scripts/cut_sprite.py "<src>" resources/background/level<N>/<name>.png <width>`
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
  `_initialize`, `change_scene_to_file("res://scenes/world.tscn")`, screenshot after ~3 s and again after moving the
  player (`player.global_position += Vector2(1500, 900)`) to check parallax seams. Compare against level 1 in the same way.
- Unlocking: print `Levels.is_available(i)` / `is_unlocked(i)` from a scripted run and screenshot `res://scenes/level_select.tscn`
  with a locked level focused (`current_scene._level_buttons[i].grab_focus()`).
