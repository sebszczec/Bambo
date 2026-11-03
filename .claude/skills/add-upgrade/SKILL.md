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
   Icons: `res://resources/shared/pickups/` (`PERKS`) or kenney power-ups (`PU`). Weight is 10 for stats, 12 for weapons.
   If applying needs the player, write a `_apply_x()` helper using `game.player` (see `_apply_max_life`).

### Level-specific cards (`only_level` / `except_level`)
The pool is shared by all levels. Two optional `_add_stat` arguments limit a card to a level index (index into `Levels._levels`):
- `only_level = 1` - the card is offered only in level 2 (Asteroid Siege). Used by all level 2 cards.
- `except_level = 1` - the card is hidden in level 2. Use it on the level 1 card that a level 2 card replaces
  (Damage, Precision, Lethality, Overclock, Multishot so far). `_is_available()` checks both.
```gdscript
# not offered in level 2 (index 1): replaced by Carbide Tips there
_add_stat("damage", "Damage", "+15% damage", PERKS + "icon_damage.png", 10,
	func(): PlayerStatus.increase_damage(15), -1, 1)
# level 2 only: Asteroid Siege replacement for Damage
_add_stat("carbide", "Carbide Tips", "+12% damage", PERKS + "icon_carbide.png", 10,
	func(): PlayerStatus.increase_damage(12), 1)
```
Weapon entries (`_add_weapon`) have no level keys; `_is_available` reads them with `.get()`, so keep that when editing it.
The level 2 design lives in `level2_bonuses.md` section 5.1 (status per card, "Implemented" / "Not implemented"). When a card is
implemented, update its status cell there and the pool rule note below the table.

Level 2 card state at the time of writing: replaced level 1 cards hidden in level 2 = Damage, Precision, Lethality,
Overclock, Multishot. Still offered in level 2 until their replacements exist = Hull plating, Armor, Shield capacitor,
Tractor beam, Thrusters, Nanobots. Check the doc before assuming.

### Per-enemy effects
`PlayerStatus.get_damage_from_weapon(type, target)` takes the hit enemy as `target` (the enemies pass `self`; bosses use
`get_boss_damage_from_weapon(type, max_life, self)`). Use it for effects that count hits per enemy: Fracture stores
`fracture_hits` with `set_meta` on the target. Pass `self` at any new call site.
Burns (Slag Trails) are started in `bullet.gd` with `PlayerStatus.apply_burn(enemy, type)`. The tick calls the enemy's own
`handleDamage` and sets its `isDead` / `_isDead` / `_is_dead` flag before `explode()`, so a burn death does not explode twice.
Enemies that have no `handleDamage` are skipped.

### New stats added for level 2 cards
- `Ricochet` (bounces per shot, read by `bullet.gd` through `BounceCount`; only Rivet Gun and Thermite Lances, see add-weapon).
- `Fracture` (level, scaled threshold: hit `7 - Fracture`, +60 % damage, see Per-enemy effects).
- `Slag` (level, burn of `15 % x Slag` of the hit over 2 s).
All three are reset in `PlayerStatus.reset()`.

### Card icons (Gemini key art)
Icons come from Gemini with the upgrade-icon prompt in `art_level1.md` 12.5 (plus the level 2 palette). The user saves the
chosen image to `resources/shared/pickups/source/<Name>.jfif` (or `_key.png`). Then:
1. Cut out and scale: `python -I .claude/skills/add-upgrade/scripts/cut_icon.py "<src>" resources/shared/pickups/icon_<id>.png`
   (green background to alpha, trimmed to the emblem, placed on a square with 10 % margin, 256 px).
2. Check it next to an existing icon on dark navy (`#141A33`) before wiring it.
3. Run `godot-check` (`--import` twice) so the `.import` file is created.
4. Point the `_add_stat` / `_add_weapon` entry at `PERKS + "icon_<id>.png"`.

## Floor pickup perk
1. `Enums.PERKS` - append the new value.
2. Scene `scenes/<name>_perk.tscn` + `scripts/<name>_perk.gd` extending `Perk` (`scripts/perk.gd`, an `Area2D`); copy `life_perk`/`magnet_perk`. Put the Area2D in a unique group, e.g. `"NewPerk"`.
3. `LevelSettings`: add to `_perk_scenes`; add to `_perk_chances` (per 1000, total of all chances must stay < 1000) if it should drop.
4. Effect: handle the group in `player.gd` `_on_life_box_area_exited()` (follow the existing `if area.is_in_group("...Perk")` blocks, show `createFloatingText`).
   Perks needing game logic (like `BOMB`) connect `taken` in `game_logic.addPerk()`.

## Verify
Run `godot-check`; in game use F1 to force level ups and confirm the option appears, applies, and is reset after restarting a run.
