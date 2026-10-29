---
name: add-upgrade
description: How to add a level-up stat upgrade or a floor pickup perk in Space Thunder - Upgrades pool, PlayerStatus stats and reset, Enums.PERKS, perk scenes, drop chances. Use when adding/balancing player stats, level-up choices or dropped pickups.
---

# Adding upgrades and pickups

Two separate systems:
- **Level-up upgrades** (`singletons/upgrades.gd`) - chosen in `level_up_menu`, stat or weapon.
- **Floor pickups** (`Perk` scenes) - dropped by killed enemies with chance from `LevelSettings._perk_chances`.

## Level-up stat upgrade
1. If it needs a new stat, add to `singletons/player_status.gd` (autoload `PlayerStatus`):
   - `var NewStat : float = ...` and `const DEFAULT_NEW_STAT`, and **reset it in `reset()`** - otherwise it leaks between runs.
   - Optional `signal new_stat_changed` + `increase_new_stat()` if UI needs updates.
2. Use the stat where it matters (player.gd, weapon_factory.gd, game_logic.gd...).
3. Register in `Upgrades._build_pool()`:
```gdscript
_add_stat("id", "Title", "+X% effect", PERKS + "icon.png", max_level,
	func(): PlayerStatus.NewStat += X)
```
   Icons: `res://resources/perks/` (`PERKS`) or kenney power-ups (`PU`). Weight is 10 for stats, 12 for weapons.
   If applying needs the player, write a `_apply_x()` helper using `game.player` (see `_apply_max_life`).

## Floor pickup perk
1. `Enums.PERKS` - append the new value.
2. Scene `scenes/<name>_perk.tscn` + `scripts/<name>_perk.gd` extending `Perk` (`scripts/perk.gd`, an `Area2D`); copy `life_perk`/`magnet_perk`. Put the Area2D in a unique group, e.g. `"NewPerk"`.
3. `LevelSettings`: add to `_perk_scenes`; add to `_perk_chances` (per 1000, total of all chances must stay < 1000) if it should drop.
4. Effect: handle the group in `player.gd` `_on_life_box_area_exited()` (follow the existing `if area.is_in_group("...Perk")` blocks, show `createFloatingText`).
   Perks needing game logic (like `BOMB`) connect `taken` in `game_logic.addPerk()`.

## Verify
Run `godot-check`; in game use F1 to force level ups and confirm the option appears, applies, and is reset after restarting a run.
