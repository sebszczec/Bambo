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
1. `singletons/enums.gd` - append to `ENEMIES` (append at the end; values are used as dictionary keys).
2. `singletons/level_settings.gd`:
   - `_points_dict["<Name>"]` and `_xp_dict["<Name>"]` - key must equal what `get_enemy_name()` returns.
   - `_enemy_scenes[Enums.ENEMIES.X] = preload("res://scenes/<name>.tscn")`.
   - Only add it to `get_random_enemy()` if it is a regular horde enemy (bosses are spawned by phase logic only).

## 2. Script contract (game_logic and player depend on these)
Root node: `CharacterBody2D` with `collision_layer = 8` and **`collision_mask = 2`** (rocks only). Never mask the player
(layer 1): the player body does not collide with enemies, so the enemy's depenetration shoves it along in front of the
ship and it looks glued to the player (happened with the Pebble Mite, fixed for every enemy and boss).
- Exported vars: `Life` (int), `Damage`, `IsDamageOverTime`, `DamageTickTime` - game_logic scales `Life`/`Damage` by difficulty before `add_child`, so read `Life` as max life in `_ready()`.
- `signal killed` emitted **once** with `get_instance_id()` when the enemy dies (before the death animation ends).
- `func get_enemy_name()` -> key used in LevelSettings dicts.
- `func setup_rotation(angle)` - called right after `add_child`.
- `func set_mark()` - used by the Mark node / targeting.
- `dispose()` that guards `is_queued_for_deletion()`; disable collision shapes with `set_deferred("disabled", true)` on death.
- `explode()` (also called by `game_logic.kill_all_enemies` after setting the dead flag) must stay cheap, a nuke runs it for the whole horde in one frame:
  `Juice.play_sound(audio)` instead of `audio.play()`, `set_physics_process(false)` and stop own timers (no shooting / radar after death),
  `explosion.SpriteTexture` = shown frame, then `explosion.explode()`; free after ~1.2 s (`wait_time = 1.2`, fragments fade in 1 s, particles/sound live in Juice).
  Bosses may call `explosion.init(Vector2(3, 3), 250)` first for a bigger burst.
- Bullet hits: in the `HitBox` `area_entered` handler check `area.is_in_group("Bullet")`, `bullet.is_damaging_enemy()`, then
  `Juice.hit_effect`, `Juice.flash(sprite)`, damage via `PlayerStatus.get_damage_from_weapon(bullet.Type)`, show `FloatingText` when `showDamage and FloatingText.can_spawn(crit)`.
- Find the player with `get_tree().get_first_node_in_group("player")`.
- Attacks that are not bullets or body contact (shock ring, beams) call `player.take_damage(amount)` (the player's hazard
  damage, handles armor/shield/god mode). Scale that damage with `Damage` (game_logic scales only `Damage`), e.g.
  `ShockDamage = int(ShockDamage * Damage / BASE_DAMAGE)` in `_ready`.
- Contact damage is read by the player from `Damage` / `IsDamageOverTime` / `DamageTickTime`. A horde enemy that stays
  alive on contact should use a single small hit (`IsDamageOverTime = false`) and stop at a `StopDistance` outside the
  hull - a pile of enemies ticking damage under the ship kills a player in seconds.

Boss extras (game_logic `_spawn_boss` connects them unconditionally):
- `signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)` - declare even if unused (`@warning_ignore("unused_signal")`).
- `signal health_changed(value : int, max_value : int)` - drives the boss bar.
- Optional `signal enraged` - connected only if present (`has_signal`).

Enemy weapons: `WeaponFactory.get_weapon(type, true, false)`, `set_owner(get_tree().current_scene)`, `register_internal_nodes(self)`; see `add-weapon`.

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

Art: new ships follow the art bible of their level (`art_level1.md`, `art_level2.md`) (style, palette, size tiers, nose pointing right -> AnimatedSprite2D `rotation = 1.5708`). Animated art (Gemini GIFs or MP4 videos, frame grid + json): use the `sprite-animation` skill to build the sheet, interpolate to 24fps, bridge loop seams and generate the SpriteFrames.

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
