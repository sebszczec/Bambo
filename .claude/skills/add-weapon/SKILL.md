---
name: add-weapon
description: Checklist for adding or changing a weapon in Space Thunder (player auto-weapon offered on level up, or an enemy/boss weapon) - Enums.WEAPONS, DamageValues, WeaponFactory class, Upgrades pool, bullet scenes. Use for any new projectile, weapon level scaling or weapon balance work.
---

# Adding a weapon

All weapons live in `singletons/weapon_factory.gd` as inner classes extending `Weapon`.

## 1. Register it
1. `singletons/enums.gd` - append to `WEAPONS` (append only; `DamageValues` iterates `WEAPONS.size()`).
2. `singletons/damage_values.gd` - set `_values[Enums.WEAPONS.X].MinValue/MaxValue`. Missing values = 0 damage.
3. `weapon_factory.gd` `get_weapon()` - add an `elif weapon == Enums.WEAPONS.X: result = X.new()` branch.

## 2. Write the class
Override what you need from `Weapon`:
- `setup()` - base stats: `shooting_delay`, `speed`, `life_time`, `spread`, `bullet_scene`, `audio.stream`, `type = Enums.WEAPONS.X`, `needs_target`.
  Call `super.setup()` when extending a concrete weapon. `setup()` runs from `_init`, before `apply_level()`.
- `apply_level()` - stats per `level` (player weapons only; called on creation and each `level_up()`). Existing curve: `delay * pow(0.88, level - 1)`.
- `shoot(owner, start_position, direction)` - check `canShoot`, play audio, spawn via `create_bullet()`, `owner.add_child`, `start_cooldown()`, `updateBulletNumber(n)`.
- `get_projectile_count()` - default adds `extra_projectiles + PlayerStatus.ProjectileCount` for player weapons.
- `process(delta, player)` - per-frame logic for persistent weapons (see `Orbit`); `clear()` if it owns long-lived nodes (called on player death).
- Spawn bullets from physics callbacks with `call_deferred("add_child", ...)`.

Rules:
- `start_cooldown()` already applies `PlayerStatus.get_delay_factor()` for player weapons - do not apply fire rate twice.
- Every spawned bullet must connect `freeing` -> `_on_bullet_freeing` (done by `create_bullet`) so bullet counts stay right.
- Bullet scenes: root `StaticBody2D` with `scripts/bullet.gd` (or subclass), `LifeTimer`, `HitBox` Area2D in group `"Bullet"` assigned to the exported `HitBox`, a `BulletEffect` node (used by `set_modulate_color` / `apply_rocket_look`). See `scenes/bullet.tscn`, `scenes/worm_bullet.tscn`.
  Player bullets that hit enemies need `collision_mask = 9` on the HitBox (enemy hitboxes are on layer 8, see `space-thunder-conventions`); enemy-only bullets keep the default mask 1.
  Hit/explosion particles come from `Juice.hit_effect` / `Juice.explosion_effect` - do not instantiate effect scenes per hit.
- `bullet.Piercing = true` for weapons that should not be destroyed on hit.

## 3a. Player weapon - offer it on level up
`singletons/upgrades.gd` `_build_pool()`:
```gdscript
_add_weapon("w_<id>", "Title", "Description when new", "Description on upgrade",
	PERKS + "<icon>.png", Enums.WEAPONS.X)
```
Max 6 levels, max `MAX_WEAPONS` (5) owned. `game_logic.add_weapon()` creates/levels it; non-main weapons auto-fire at `find_nearest_enemy()` if `needs_target`, else fire with `Vector2.RIGHT`.

## 3b. Enemy/boss weapon
```gdscript
_weapon = WeaponFactory.get_weapon(Enums.WEAPONS.X, true, false)  # damages player only
_weapon.set_owner(get_tree().current_scene)
_weapon.register_internal_nodes(self)
```
`player_owned` is false, so player stats do not affect it. Damage to the player comes from `DamageValues`.

## 4. Verify
Run `godot-check`; in game use F1 to level up until the weapon is offered; watch bullet counter in InformationBox returns to baseline.
