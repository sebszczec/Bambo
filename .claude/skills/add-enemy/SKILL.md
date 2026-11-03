---
name: add-enemy
description: Step-by-step checklist for adding a new enemy or boss to Space Thunder - enums, LevelSettings registration, required script contract, scene structure, spawning via phase_guard/game_logic. Use when creating or reworking an enemy, elite or boss.
---

# Adding an enemy or boss

Reference implementations: `scripts/enemy_1.gd` (simple chaser), `enemy_2.gd`/`enemy_3.gd` (shooters),
`scripts/pebble_mite.gd` (level 2 swarm enemy: state machine Walk -> Charge -> Discharge -> Recover driven by animation frames, area shock attack, particle trail),
`scripts/boulder_beetle.gd` (level 2 kamikaze: 360 degree scan (`shaders/radar_sweep.gdshader`) triggers a charge, the blast kills enemies and breaks rocks in a radius with a physics shape query run in `_physics_process`, bosses and mines skipped),
`scripts/shard_wasp.gd` (level 2 chaser: orbits the player, aim line telegraph, locked-path lunge tested as a swept segment, leaves `scripts/shard_wake.gd` - a lingering wall of wing shards added to the world that cuts the player on entry only),
`scripts/boss.gd` (boss spawning minions), `scripts/quarry_mantis.gd` (level 2 mid boss: lunge with a wedge telegraph that is the real hit zone, rock spit with a custom bullet scene on `WORM_SPIT`, the worm laser recolored with `set_colors`, rockfall hazards `scripts/mantis_rock.gd`, enrage calls minions, death burst = `beetle_blast.tscn` with its own debris atlas), `scripts/worm_boss.gd` (boss with attack cycle, enrage, own weapon, laser/mines, sprite-sheet animations with planned switches - see `sprite-animation`).
Read the closest one before writing a new enemy.

## 1. Register it
1. `singletons/enums.gd` - append to `ENEMIES` (append at the end; values are numbers stored in the level data).
2. `singletons/level_settings.gd`:
   - `ENEMY_SCENE_PATHS[Enums.ENEMIES.X] = "res://scenes/levels/levelN/<name>.tscn"` (scenes load per level, see below).
   - Add the enum to `LEVEL_ENEMIES[n]` for the level that spawns it (drives the background load and release).
   - `_points_dict`, `_xp_dict`, `_shard_drops` are keyed by the enum; bosses also need a `BOSS_BANNERS` entry if they
     announce themselves and `BOSS_KINDS` if they are bosses.
   - Regular horde enemies are spawned by the wave tables, bosses only by phase logic.
## 2. Script contract
Scripts extend the shared bases: `extends EnemyBase` for an ordinary enemy (`scripts/enemy_base.gd`), `extends BossBase`
for a big boss with an attack loop (`scripts/boss_base.gd`). Set the identity and stats in `_init()` (scene overrides still
win): `enemy_name`, `Life`, `Damage`, `Knockback`, `RotationSpeed`, `idleAnimation`, `shapesFollowShip`, `fragmentTint`,
`dissolveIn`, `randomStartFrame`. Put the enemy's own behaviour in these hooks, do not copy the base methods:
- `_on_ready()` (extra setup, timers), `_show_life_bar(settings)`, `_on_died()` (stop own timers and emitters),
  `_on_player_contact()`, `_accepts_hits()`, `_knockback_enabled()`, `_damage_from_bullet(bullet)`, `_label_position(bullet)`,
  `_on_damage_taken()`, `explode()` (override only if the death is special, call `_disable_body()` and `_shatter()`).
- Bosses: `_on_boss_ready()`, `_pick_attack()`, `_perform(attack)`, `_keep_distance_for(attack)`, `_on_enrage()`,
  `_glow_sprite()`; the base provides `_chase`, `_wait`, `_play_matched`, `_beam_attack`, `_rain_rocks`, `_burst`, `_fling_piece`.
- Base contract: `signal killed` is emitted once with `get_instance_id()` when the enemy dies (the base does it in
  `explode()`); game logic reads `enemy_kind` (set by `LevelSettings.get_enemy`) for points, xp and shards.
- Collision: root `CharacterBody2D` with `collision_layer = 8` and **`collision_mask = 2`** (rocks only). Never mask the
  player (layer 1): the depenetration shoves the player along and it looks glued to the ship.
- `explode()` must stay cheap, a nuke runs it for the whole horde in one frame: `Juice.play_sound(audio)`, physics off,
  `_disable_body()`, `_shatter()` (fragments via `explosion`, dies after `DEATH_DELAY`).
## 3. Scene structure (`scenes/<name>.tscn`)
Mirror `enemy_1.tscn`: `CollisionShape2D`, `Ship` (Node2D, holds Sprite2D/AnimatedSprite2D, rotated to face player), `LifeBar` (instance of `life_bar.tscn`),
`HitBox` (Area2D, **groups=["Enemy"]**, `collision_layer = 8`, default mask 1) + collision shape, `Explosion` (`object_explosion.tscn`), `AudioStreamPlayer2D`, `Mark` (`mark.tscn`).
Sprites use the Dissolve material (`shaders/Dissolve.tres`) for the spawn tween; `Juice.is_flashing` must be checked before touching shader params.
Effects built from `resources/vendor/kenney/particles` (white textures, tint with an HDR color so bloom makes them glow):
- one-shot effects with many sprites: a child Node2D with its own script that creates its Sprite2Ds on first use and only
  runs `_process` while active (`scripts/mite_shock.gd`: lightning ring from `spark_05/06` bolts laid along a circle,
  re-randomized every 45 ms, additive `CanvasItemMaterial` shared as a static).
- trails: a `GPUParticles2D` inside `Ship` at the tail, before the sprite (draws behind), world-space particles (default),
  small `amount`, `fixed_fps = 30`, color ramp fading in and out; toggle `emitting` only when the state changes
  (`FrostTrail` in `scenes/pebble_mite.tscn`, `smoke_07`).
- big bursts: a layered scene instead of `object_explosion` (its square tiles of a glowing frame look like polygons under
  bloom) - `scenes/beetle_blast.tscn`: screen-texture refraction ring (`shaders/shockwave.gdshader`), additive flash,
  aligned spark streaks, debris from a part atlas (`CanvasItemMaterial.particles_animation` + `anim_offset_max = 1`,
  atlas cut from the key pose with `sprite-animation/scripts/cut_shards.py`) and a frost smoke cloud.

Art location: `resources/levels/level<N>/enemies/<name>/` (sheet, json, `<name>_animations.json`, `source/` with `.gdignore`), see the `asset-layout` skill. Art: new ships follow the art bible of their level (`art_level1.md`, `art_level2.md`) (style, palette, size tiers, nose pointing right -> AnimatedSprite2D `rotation = 1.5708`). Animated art (Gemini GIFs or MP4 videos, frame grid + json): use the `sprite-animation` skill to build the sheet, interpolate to 24fps, bridge loop seams and generate the SpriteFrames.

## 4. Make it appear
- Waves, swarms and bosses are level data in `singletons/levels.gd` (see `add-level`): add `[Enums.ENEMIES.X, count, chance%]`
  to a level's `stages`, or make the enemy take another one's place in one level with
  `"replace" : { Enums.ENEMIES.SCOUT : Enums.ENEMIES.X }` (covers waves, swarms and boss minions).
- Dev console: add a name to `ENEMY_NAMES` in `scripts/dev_console.gd` (`spawn <name> <count>`).
- Boss: add `{ "at" : seconds, "type" : Enums.ENEMIES.X, "final" : bool }` to a level's `bosses`; `phase_guard` emits
  `boss_requested`, `game_logic.spawn_boss(type)` spawns it - add its banner text there.
- Debug: in debug builds F1 = level up, F2 = +60s, F3 = jump to boss, F4 = spawn worm boss, F5 = spawn quarry mantis (add a key for the new boss while testing if useful).

## 5. Verify
Run the `godot-check` skill, then a scripted run (`godot-check`, "Scripted run": spawn the enemy next to a still player, log
animation/frame, distance and player life, screenshot crops), then play-test (F2/F3 cheats) - check killed/score/xp, boss bar, death cleanup, no errors in output.
For a horde enemy also run `perf-stress` (dev console `spawn <name> 200` + `perk bomb` for a manual check) - collision pairs must stay in the low thousands.
