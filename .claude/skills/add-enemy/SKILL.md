---
name: add-enemy
description: Step-by-step checklist for adding a new enemy or boss to Space Thunder - enums, LevelSettings registration, required script contract, scene structure, spawning via phase_guard/game_logic. Use when creating or reworking an enemy, elite or boss.
---

# Adding an enemy or boss

Reference implementations: `scripts/enemy_1.gd` (simple chaser), `enemy_2.gd`/`enemy_3.gd` (shooters),
`scripts/boss.gd` (boss spawning minions), `scripts/worm_boss.gd` (boss with attack cycle, enrage, own weapon, laser/mines, sprite-sheet animations with planned switches - see `sprite-animation`).
Read the closest one before writing a new enemy.

## 1. Register it
1. `singletons/enums.gd` - append to `ENEMIES` (append at the end; values are used as dictionary keys).
2. `singletons/level_settings.gd`:
   - `_points_dict["<Name>"]` and `_xp_dict["<Name>"]` - key must equal what `get_enemy_name()` returns.
   - `_enemy_scenes[Enums.ENEMIES.X] = preload("res://scenes/<name>.tscn")`.
   - Only add it to `get_random_enemy()` if it is a regular horde enemy (bosses are spawned by phase logic only).

## 2. Script contract (game_logic and player depend on these)
Root node: `CharacterBody2D`.
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

Boss extras (game_logic `_spawn_boss` connects them unconditionally):
- `signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)` - declare even if unused (`@warning_ignore("unused_signal")`).
- `signal health_changed(value : int, max_value : int)` - drives the boss bar.
- Optional `signal enraged` - connected only if present (`has_signal`).

Enemy weapons: `WeaponFactory.get_weapon(type, true, false)`, `set_owner(get_tree().current_scene)`, `register_internal_nodes(self)`; see `add-weapon`.

## 3. Scene structure (`scenes/<name>.tscn`)
Mirror `enemy_1.tscn`: `CollisionShape2D`, `Ship` (Node2D, holds Sprite2D/AnimatedSprite2D, rotated to face player), `LifeBar` (instance of `life_bar.tscn`),
`HitBox` (Area2D, **groups=["Enemy"]**, `collision_layer = 8`, default mask 1) + collision shape, `Explosion` (`object_explosion.tscn`), `AudioStreamPlayer2D`, `Mark` (`mark.tscn`).
Sprites use the Dissolve material (`shaders/Dissolve.tres`) for the spawn tween; `Juice.is_flashing` must be checked before touching shader params.
Art: new ships follow `art_bible.md` (style, palette, size tiers, nose pointing right -> AnimatedSprite2D `rotation = 1.5708`). Animated art (Gemini GIFs or MP4 videos, frame grid + json): use the `sprite-animation` skill to build the sheet, interpolate to 24fps, bridge loop seams and generate the SpriteFrames.

## 4. Make it appear
- Horde enemy: add `[Enums.ENEMIES.X, count, chance%]` entries to `_stages` waves in `scripts/phase_guard.gd`.
- Boss: extend `_on_boss_requested()` in `game_logic.gd` (rotation uses `boss_count`), add a banner text in `_spawn_boss`.
- Debug: in debug builds F1 = level up, F2 = +60s, F3 = jump to boss, F4 = spawn worm boss (add a key for the new boss while testing if useful).

## 5. Verify
Run the `godot-check` skill, then play-test (F2/F3 cheats) - check killed/score/xp, boss bar, death cleanup, no errors in output.
For a horde enemy also run `perf-stress` (dev console `spawn <name> 200` + `perk bomb` for a manual check) - collision pairs must stay in the low thousands.
