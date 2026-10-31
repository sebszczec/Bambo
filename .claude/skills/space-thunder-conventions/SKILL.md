---
name: space-thunder-conventions
description: Architecture map and coding conventions for the Space Thunder (Bambo) Godot 4.7 GDScript project. Load before changing any .gd/.tscn file in this repo - gameplay, enemies, weapons, perks, UI, phases or balance.
---

# Space Thunder - architecture & conventions

Godot 4.7 (Forward Plus, 2D, HDR 2D on), 1920x1080, top-down survivor-style space shooter.
Main scene `scenes/start_menu.tscn` -> `scenes/world.tscn` (holds `GameLogic`, `Player`, HUD nodes).
Addon: `addons/godot_state_charts` (third-party, do not edit).

## Layout
- `singletons/` - autoloads (registered in `project.godot` `[autoload]`):
  - `Enums` - `WEAPONS`, `PERKS`, `ENEMIES`, `MASKS {PLAYER=1, ENEMY=8}`, `PHASE`.
  - `LevelSettings` - level bounds, points/xp per enemy name, floor-perk drop chances (per 1000), preloaded scenes for enemies/perks/meteors/gems.
  - `DamageValues` - min/max damage per `Enums.WEAPONS`.
  - `WeaponFactory` - `get_weapon(type, damaging_player, damaging_enemy)` + all weapon classes (inner classes of `Weapon`).
  - `PlayerStatus` - run stats (damage, crit, speed, fire rate, projectiles, armor, regen...), xp/level, `reset()` per run, `get_damage_from_weapon()`.
  - `Upgrades` - level-up pool ("pick 1 of 3"), stat and weapon entries.
  - `Juice` - hitstop, shake, flash and shared effect pools (ring buffers under a `JuicePool` node in the current scene): `hit_effect(target, pos)`, `explosion_effect(pos, scale, color, amount)`, `play_sound(audio_player_2d)` (plays a copy of the node's stream on one of 6 shared players, max one per 40 ms).
  - `ConfigHandler` (settings file), `InputManager` (cursor/input).
- `scripts/game_logic.gd` - run orchestration: owned weapons, spawning, kills, combo, xp drops, bosses, victory/endless.
- `scripts/phase_guard.gd` - run clock: 10 one-minute stages (spawn delay, max alive, wave mix), swarms, elite, boss at `RUN_LENGTH`, then Endless.
- `scripts/player.gd` - player ship; takes damage in `_on_life_box_area_entered`, picks up perks in `_on_life_box_area_exited` by group.
- `scenes/` one `.tscn` per object, script of the same name in `scripts/`. `resources/` art/sfx (source-only art in `resources/<x>/source/` with `.gdignore`), `shaders/` shaders.

## Collision & groups (core contract)
- Physics layers: 1 Player, 2 Rock, 3 Bullet, 4 Enemy (bit values 1, 2, 4, 8). Bullet *body* masks use `Enums.MASKS` and double as "who it damages" flags (`is_damaging_enemy()`).
- Damage is detected through `Area2D` children with groups: enemy `HitBox` in group `"Enemy"`, bullet `HitBox` in `"Bullet"`, rocks `"Rock"`, player `"Player"`, gems `"XpGem"` (group only, no area), perks e.g. `"LifePerk"`.
- Area layers (Godot 4 areas report only what is in their **own mask**) - keep them, a pile of 400 enemies otherwise makes ~60k collision pairs:
  - every `"Enemy"` HitBox (enemies, bosses, mines): `collision_layer = 8`, mask 1 (default) - sees player, bullets, rocks, perks but not other enemies.
  - player `LifeBox` and player bullet HitBoxes (`bullet.tscn`, `big_bullet.tscn`): `collision_mask = 9` (default layer 1 + Enemy).
  - areas that only scan (radar `Beam`, worm laser `HurtBox`): `collision_layer = 0`, `monitorable = false`.
  - everything else (perks, rocks, enemy bullets, bomb) stays on layer 1 / mask 1.
- Player finds enemies via `get_tree().get_first_node_in_group("player")` (lowercase group on the player node).
- Enemy damage to player: player reads `enemy.Damage`, `enemy.IsDamageOverTime`, `enemy.DamageTickTime` from `area.get_parent()`.
- Bullet damage to enemy: `PlayerStatus.get_damage_from_weapon(bullet.Type)`; to player: `DamageValues.get_damage(bullet.Type)`.
- Non-bullet hazards (e.g. worm laser) call the player's public hazard damage function (see `player.gd` comment "damage from hazards").

## Code style (match it)
- Tabs, snake_case functions, `PascalCase` for exported/public stats (`Life`, `Damage`, `Speed`), `_underscore` for private vars in newer scripts.
- Short lowercase comments explaining *why*; mark functions called from other objects with `# public`.
- Signals connected by name: `obj.connect("killed", _on_enemy_killed)`.
- Timers created in code (`var t = Timer.new()` + `add_child`) are common; use `call_deferred("add_child", x)` when spawning from physics callbacks.
- Free nodes through `dispose()` that guards `is_queued_for_deletion()`; bullets emit `freeing` before freeing.
- Respect `ConfigHandler.load_visuals()` flags (`show_damage_given`, `show_enemies_lifebar`, `show_damage_taken`).
- Use `Juice` for feedback (shake/hitstop/flash/hit_effect) instead of ad-hoc effects.
- Performance matters (100+ enemies, a nuke kills them all in one frame, the magnet brings 200 gems at once):
  - avoid per-frame collision shape resizing, node searches, or allocations in `_physics_process`.
  - nothing heavy per death: no instantiating effect nodes (use the `Juice` pools), no own death sound (`Juice.play_sound(audio)`), no group searches (use static registries such as `XpGem.all` / `alive_count`).
  - count objects spawned with `call_deferred("add_child")` in `_init`, not `_ready` - otherwise caps (`MAX_GEMS`, `FloatingText.MAX_ALIVE`) miss everything spawned in the same frame.
  - batch per-pickup work per frame (`player.collect_xp` only accumulates, `flushXp()` adds xp and plays one sound).
  - `object_explosion.tscn` draws its fragments itself (`_draw`, no child sprites), gets coarser above 30 live explosions and skips fragments above 80.
  - measure with the `perf-stress` skill before and after.

## Files to commit
New scripts come with `*.gd.uid` files - commit them together. `.godot/` and `*.import` are gitignored.
Edit `.tscn` by hand carefully: keep `[ext_resource]` ids unique, update `load_steps`, keep `uid=` values unique (or omit them for new resources).

## Related skills
`add-enemy`, `add-weapon`, `add-upgrade`, `godot-check`, `perf-stress` (frame times for horde / nuke / magnet, before vs after), `sprite-animation` (Gemini GIFs / MP4 videos / sprite sheets -> smooth AnimatedSprite2D).
Visual style of all ships: `art_bible.md` in the repo root (used as the Gemini brief).
