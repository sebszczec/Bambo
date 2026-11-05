# Space Thunder - Game Design Document

> **Purpose:** the living specification of the game. It says what the game is, how it plays, which numbers
> are current, and where each rule lives in the code. Update it in the same change as any gameplay change.
> Xenite and Hangar rules per level are in Appendix A (level 1) and Appendix B (level 2) at the end of this document.
> Art detail lives in `art_level1.md` and `art_level2.md`; this document links to them instead of repeating them.
> **Engine:** Godot 4.7, Forward Plus, 2D, HDR 2D. Resolution 1920x1080.
> **Status legend:** *Built* = in the game now. *Planned* = listed in the code or the ladder, not finished.

---

## 1. Overview

| | |
|---|---|
| **Title** | Space Thunder (repo: Bambo) |
| **Genre** | Top-down survivor-style space shooter, with a meta-progression hangar between runs |
| **Perspective** | Camera looks straight down. Ships rotate to face their targets. |
| **Platform** | PC (Windows export preset in `export_presets.cfg`) |
| **Session** | One run is a survival clock of 10 minutes. Level 1 and 2 end on the final boss. |
| **Tone** | Pulpy sci-fi. A lone interceptor pilot holds the line against a biomechanical alien swarm. |
| **Pitch** | Hold the line for ten minutes against a growing swarm. Pick the upgrades that build your ship, then spend the Xenite you carried home to make the next run stronger. |

### 1.1 Design pillars

1. **Readable chaos.** Hundreds of enemies on screen must still be readable. Silhouettes, glow colour and
   hit feedback carry the information, not the HUD. See `art_level1.md` section 2 (style pillars).
2. **Every run builds a different ship.** Level-up choices ("pick 1 of 3") decide the run. No two runs
   should play the same.
3. **Small steps forward between runs.** Meta progression is permanent but modest. It makes a loss feel
   useful, never mandatory.
4. **Feel over realism.** Hit-stop, shake, flashes and explosions are part of the game's feedback, through
   the `Juice` singleton.
5. **Performance is a design constraint.** The game must hold frame rate with 100+ enemies, a bomb that
   kills everything in one frame, and a magnet that pulls 200 gems at once.

### 1.2 Target player

- Players of arcade shooters and survivor-likes who like build-crafting and short, repeatable runs.
- Sessions of 10-15 minutes, with the option to repeat a level for better upgrades.

---

## 2. Core loop

```
Level select (briefing) -> Hangar (spend Xenite on permanent upgrades) -> Run (10 min)
   ^                                                                          |
   |                                                                          v
   +------------- Bank Xenite, record deaths/runs, unlock next level <---- Win or death
```

- **In a run:** move, shoot, collect XP gems, pick upgrades on level up, survive the stages, kill the bosses.
- **Between runs (Hangar):** spend the level's Xenite bank on permanent upgrades. Start the next run.
- **Winning** the level's final boss marks the level completed and unlocks the next one.

---

## 3. Controls and input

- Movement: keyboard / gamepad via `InputManager` (cursor and input handling). Speed is `PlayerStatus.Speed`
  (default 100, +10 per Thrusters level, +4 % per Ion Thrusters rank).
- Pause menu: `scripts/pause_menu.gd`. Options: `scripts/options_panel.gd`, `scripts/settings_menu.gd`.
- Settings are stored by `ConfigHandler`, which also holds the visual flags (`show_damage_given`,
  `show_enemies_lifebar`, `show_damage_taken`) and the three save slots.
- *TBD:* the full key and gamepad map is not written down anywhere yet. Add it here when it is settled.

---

## 4. Run structure

### 4.1 Survival clock (`scripts/phase_guard.gd`)

| Parameter | Value | Source |
|---|---|---|
| Stage length | 60 s, 10 stages per level | `STAGE_LENGTH` |
| Stage table | `delay` (spawn interval), `max_alive` (enemy cap), `wave` (enemy mix) | `resources/levels/levelN/level.tres` |
| Elite | Level 1: at 450 s (7:30). Level 2: same time. | `elite_at` |
| Swarm | Every 120 s. Size = `swarm_base` + `swarm_per_stage` x stage (+2 per Endless step). Level 1: base 15, +2 per stage. | `swarm_every`, `swarm_base`, `swarm_per_stage` |
| Bosses | Scheduled by time; the next boss waits until the previous one is dead. No swarms during boss fights. | `bosses` |
| Victory | Killing the final boss (`final: true`) wins the level. | `scripts/game_logic.gd` |

### 4.2 Phases

- **Survival:** the default. Stages, elite, swarms and scheduled bosses.
- **Boss:** entered when the final boss is requested. Ends on the final boss's death (win) or on player death.
- **Endless** (dev console only, `scripts/dev_console.gd`): difficulty keeps growing every 60 s (+15 % per step,
  more max alive, +2 swarm per step). A boss arrives every 300 s, alternating between the level's two boss
  types. Not a player-facing mode.
- `Enums.PHASE` = `{ Survival, Boss, Endless }`.

### 4.3 Lose and win

- **Death:** the run ends. Xenite is banked, the run is counted, and the game-over screen offers retry or the
  main menu (`scripts/game_over_menu.gd`).
- **Win:** the level is completed, the run's Xenite is banked, a victory bonus is added to the score
  (`victory_bonus`: 5000 in level 1), and the win text is shown (`win_text`).

---

## 5. Player ship

### 5.1 Base stats (`singletons/player_status.gd`)

| Stat | Default | Notes |
|---|---|---|
| Max life | 100 | Reinforced Hull, Hull plating |
| Max shield | 100 | Shield Capacitor, Shield capacitor card |
| Base damage | 100 | Scaled by `get_damage_from_weapon`; weapon damage ranges live in `singletons/damage_values.gd` |
| Critical chance | 10 % | Targeting AI, Precision, Seismic Sensor |
| Critical multiplier | 200 % | Lethality, Fault Line |
| Speed | 100 | Thrusters, Ion Thrusters |
| Fire rate | 100 | Overclock, Pressure Valve, Cooling Vents |
| Pickup radius | 120 px | Tractor beam, Tractor Beam |
| Armor | 0 | subtracted from every hit, never below 1 damage |
| Regen | 0 life/s | Nanobots, Repair Nanites |
| Ricochet, Fracture, Slag | 0 | level 2 cards, see section 6.1 and Appendix B |

`PlayerStatus.reset()` runs at the start of every run so that perks do not leak between runs.

### 5.2 Health and shield

- Shield absorbs damage first, then life. Life regenerates at `Regen` per second when below max.
- Taking damage triggers `Juice` shake and flash, and the damage numbers are shown if
  `show_damage_taken` is on.
- Player death is handled in `scripts/player.gd` (damage in `_on_life_box_area_entered`).

### 5.3 Weapons

- The ship has **5 weapon slots**. The Blaster is always owned, so four more weapons fit in one run
  (`Upgrades.MAX_WEAPONS = 5`).
- Weapons are offered on level up, one card per weapon. Each card goes up to **level 6**.
- Each weapon is rebuilt at the start of every run.

| Weapon (id) | Type | How it works | Level-up effect |
|---|---|---|---|
| Blaster (`w_blaster`) | `SMALL` | Main gun, starts at level 1 | Faster and wider |
| Heavy cannon (`w_cannon`) | `BIG` | Auto-aimed heavy shells | Faster, more shells |
| Nova (`w_nova`) | `SMALL_WAVE` | Ring of bullets around the ship | More bullets, faster pulse |
| Missiles (`w_missiles`) | `SMALL_HOMING` / `SMALL_HOMING_WIHT_DELAY` | Homing rockets | More rockets, faster reload |
| Fireworks (`w_fireworks`) | `FIREWORKS` | Shell that bursts into shrapnel | Bigger explosions |
| Orbit (`w_orbit`) | `ORBIT` | Blades circling the ship | Bigger blades, wider orbit; Lv 6 adds an outer ring |
| Bomb | `BOMB` | Area nuke (bomb perk) | Scaled by the bomb perk |

Weapon damage per hit (`singletons/damage_values.gd`), before stat multipliers:

| Type | Min - Max |
|---|---|
| Blaster | 10 - 20 |
| Heavy cannon | 30 - 50 |
| Nova | 25 - 40 |
| Missiles | 10 - 20 |
| Fireworks | 25 - 40 |
| Orbit | 15 - 25 |
| Worm spit (boss) | 20 - 30 |
| Bomb | 10 000 - 20 000 |

Weapon creation and scaling: `singletons/weapon_factory.gd`. Per-level skins (title, icon, trail colour) come
from `weapon_skin` in each level's `level.tres`. Level 2 renames the weapons (Rivet Gun, Drill Cannon,
Quake Charge, Tether Rocks).

### 5.4 Experience and levels

- Enemies drop XP gems. The `magnet` / pickup radius pulls them in. `player.collect_xp` accumulates XP, and
  `flushXp()` adds it once per frame with one sound.
- XP thresholds and level-up logic: `singletons/player_status.gd` (`xp_changed`, `leveled_up`).
- On level up the game pauses and shows the card picker (`scripts/level_up_menu.gd`): **pick 1 of 3** from
  `singletons/upgrades.gd`.

---

## 6. Upgrades and pickups

### 6.1 Level-up stat cards (`singletons/upgrades.gd`)

Max levels are the number of times a card can be picked in one run.

| Card | Effect per pick | Max | Level 1 | Level 2 |
|---|---|---|---|---|
| Damage (`damage`) | +15 % damage | 10 | yes | replaced by Carbide Tips (+12 %, max 10) |
| Precision (`crit_chance`) | +5 % critical chance | 8 | yes | replaced by Seismic Sensor (+6 %, max 6) |
| Lethality (`crit_mult`) | +30 % critical damage | 8 | yes | replaced by Fault Line (+35 %, max 6) |
| Thrusters (`speed`) | +10 % move speed | 5 | yes | yes |
| Overclock (`fire_rate`) | +12 % fire rate | 6 | yes | replaced by Pressure Valve (+10 %, max 6) |
| Multishot (`projectile`) | +1 projectile for every weapon | 3 | yes | replaced by Extra Charges (+1, max 3) |
| Hull plating (`max_life`) | +20 max life, heals 20 | 8 | yes | yes |
| Nanobots (`regen`) | +0.6 life per second | 5 | yes | yes |
| Armor (`armor`) | -2 damage from every hit | 5 | yes | yes |
| Shield capacitor (`shield`) | +25 max shield | 4 | yes | yes |
| Tractor beam (`magnet`) | +40 % pickup radius | 5 | yes | yes |
| Ricochet Plates (`ricochet`) | Straight shots and drill shells bounce to the nearest enemy, one more bounce per level | 3 | no | level 2 only |
| Fracture (`fracture`) | Every 6th enemy hit (counted across all enemies): +60 % damage, one hit sooner per level | 4 | no | level 2 only |
| Slag Trails (`slag`) | Shots burn enemies for 15 % of hit damage over 2 s per level | 4 | no | level 2 only |

The "replacement" pairs are deliberate: level 2 swaps some level 1 cards for tuned versions, so the pool
stays the same size. The `1` / `-1` flags in the code are the level filter (see `levels.gd` index).

### 6.2 Floor pickups (perks)

Dropped on the floor, collected by flying over them. Scenes in `scenes/perks/`, scripts in `scripts/`.
Names below are the scene names; the exact effect of each is in its script, which is the source of truth.
*TBD:* write one line of effect per pickup here after checking each script.

| Pickup | Scene | Script |
|---|---|---|
| Life | `life_perk` | `life_perk.gd` |
| Shield | `shield_perk` | `shield_perk.gd` |
| Damage up | `damage_up_perk` | `damage_up_perk.gd` |
| Critical chance up | `critic_chance_up_perk` | `critic_chance_up_perk.gd` |
| Critical multiplier | `critic_hit_multiplier_perk` | `critic_hit_multiplier_perk.gd` |
| Speed up | `speed_up_perk` | `speed_up_perk.gd` |
| Big gun | `big_gun_perk` | `big_gun_perk.gd` |
| Wave | `wave_perk` | `wave_perk.gd` |
| Homing | `homing_perk` | `homing_perk.gd` |
| Bomb | `bomb_perk` | `bomb_perk.gd` |
| Magnet | `magnet_perk` | `magnet_perk.gd` |

- Drop chances are per 1000 kills, set in `singletons/level_settings.gd` (floor-perk drop table).
- Pickups are capped and counted through `LevelSettings` and `DropService` (`scripts/drop_service.gd`).

### 6.3 Xenite (shards)

- The only meta currency. Dropped by enemies and bosses (see section 9.3).
- Collected during a run, **carried, not spent**. Banked when the run ends.
- Full rules and the Hangar tables: Appendix A (level 1) and Appendix B (level 2). The shared rules are the same in both.

---

## 7. Meta progression

### 7.1 Banks and levels

- Each level has its own Xenite bank, its own upgrade ranks, and its own stats (deaths, runs).
- Banking: every run banks its Xenite, won or lost. Surviving pays 2 Xenite per full minute. Victory adds
  +30 Xenite.
- Level n unlocks when level n-1 is completed (`singletons/levels.gd`).
- Save data: `ConfigHandler` (completed levels, last level) and `singletons/meta_progress.gd` (banks, ranks).

### 7.2 Hangar upgrades

Each rank costs `base cost x (current rank + 1)`. Bonuses apply to every run of that level.

| Upgrade (id) | Effect per rank | Max rank | Total to max |
|---|---|---|---|
| Reinforced Hull (`hull`) | Max life +10 | 5 | 225 |
| Shield Capacitor (`shield`) | Max shield +10 | 5 | 225 |
| Plasma Coils (`damage`) | Damage +5 % | 5 | 300 |
| Cooling Vents (`fire_rate`) | Fire rate +4 % | 5 | 300 |
| Ion Thrusters (`speed`) | Move speed +4 % | 4 | 150 |
| Ablative Plating (`armor`) | Armor +1 | 3 | 180 |
| Repair Nanites (`regen`) | Regen +0.4 life/s | 3 | 180 |
| Targeting AI (`crit`) | Critical chance +2 % | 4 | 200 |
| Tractor Beam (`magnet`) | Pickup radius +20 | 3 | 60 |
| Xenite Scanner (`salvage`) | Crystal drop chance +15 % (guaranteed drops not affected) | 3 | 150 |

Ranks are stored per level, so buying an upgrade in one level never changes another level's ranks.

---

## 8. Levels

The ladder lives in `singletons/levels.gd`. Each built level is data in `resources/levels/levelN/level.tres`
(`LevelDef`, `scripts/level_def.gd`). Level 2 inherits level 1 and only lists what differs.

### 8.1 Level 1 - First Contact (built)

- **Setting:** the Kuiper Belt. An interceptor holds the line before Earth's fleet arrives.
- **Tagline:** "They were never coming in peace."
- **Objective:** survive the invasion and destroy both alien flagships.
- **Bosses:** Hive Beetle (carrier) at 5:00 (not final). Worm Boss (final) at 10:00.
- **Elite:** a Guard with boosted life, bigger, violet tint, at 7:30. Drops 10 Xenite.
- **Boss life factor:** 0.8.
- **Enemies:** Scout (swarm fodder), Guard (elite-capable), Hunter (mid-tier). Bosses: Hive Beetle, Worm Boss.
- **Background / music:** `resources/levels/level1/` (see `art_level1.md`).
- **Stages:** 10 stages. The spawn delay falls from 1.1 s to 0.5 s; max alive rises from 25 to 110; the
  wave gets Guards and Hunters from stage 2 and 3.
- **Art brief:** `art_level1.md`.

### 8.2 Level 2 - Asteroid Siege (built)

- **Setting:** the Hilda asteroid belt. The hive has turned the rocks into nests.
- **Tagline:** "The rocks are alive now."
- **Objective:** break the hive siege and destroy both alien flagships.
- **Enemy swap** (level 1 index -> level 2 index): Scout -> Pebble Mite, Guard -> Boulder Beetle,
  Hunter -> Shard Wasp, Hive Beetle -> Quarry Mantis, Worm Boss -> Bedrock Queen.
- **Bosses:** Quarry Mantis at 5:00 (30 Xenite, replaces the Hive Beetle). Bedrock Queen at 10:00 (final, 60 Xenite).
- **Weapons:** same weapon types, renamed skins (Rivet Gun, Drill Cannon, Quake Charge, Tether Rocks).
- **Stat cards:** the level 2 replacement cards and three new cards (section 6.1).
- **Background / music:** `resources/levels/level2/`. Background has rock layers and asteroids as parallax.
- **Art brief:** `art_level2.md`.

### 8.3 Levels 3-10 (planned)

The ladder has eight more named levels. They are listed in `singletons/levels.gd` as unavailable.

| # | Name | Status |
|---|---|---|
| 3 | The Red Nebula | Not built |
| 4 | Hive Outpost | Not built |
| 5 | Silent Moons | Not built |
| 6 | Graveyard Belt | Not built |
| 7 | Brood Mother | Not built |
| 8 | Rift Crossing | Not built |
| 9 | Alien Homeworld | Not built |
| 10 | Heart of the Swarm | Not built |

*TBD for each:* setting, enemy roster, boss roster, unique mechanic, stat cards. Write these in this section
before building the level (the `add-level` skill covers the code side).

---

## 9. Enemies and bosses

### 9.1 Enemy roster

| Enum | Level 1 | Level 2 | Behaviour (short) | Notes |
|---|---|---|---|---|
| `SCOUT` | Scout | Pebble Mite | Swarm enemy, weakest | Drop 4 % Xenite |
| `GUARD` | Guard | Boulder Beetle | Mid-tier, can be an elite | Drop 12 % Xenite |
| `HUNTER` | Hunter | Shard Wasp | Mid-tier chaser | Drop 12 % Xenite |
| `BOSS` | Hive Beetle | Quarry Mantis | Carrier, stage 5 | Drop 25 / 30 Xenite |
| `WORM_BOSS` | Worm Boss | Bedrock Queen | Final boss | Drop 40 / 60 Xenite |

Level 2 enemy scripts and scenes: `scripts/pebble_mite.gd`, `boulder_beetle.gd`, `shard_wasp.gd`,
`quarry_mantis.gd`, `bedrock_queen.gd`, plus `mite_shock.gd`, `shard_wake.gd`, `beetle_blast.gd`, `mantis_rock.gd`.
Level 1 scripts: `enemy_1.gd`, `enemy_2.gd`, `enemy_3.gd`, `boss.gd`, `worm_boss.gd`, `worm_laser.gd`, `worm_mine.gd`.

*TBD (to fill in per enemy):* life, damage, speed, XP and points value (`LevelSettings`), attack pattern,
death behaviour, art reference.

### 9.2 Boss rules

- Bosses are spawned on schedule by `PhaseGuard`. The next boss waits for the current one to die.
- No swarms are spawned during a boss fight.
- The final boss starts the Boss phase and its death wins the level.
- Boss damage to the ship uses `DamageValues`; damage to bosses goes through
  `PlayerStatus.get_boss_damage_from_weapon(type, max_life, self)`.

### 9.3 Xenite drops

| Source | Drop | Chance |
|---|---|---|
| Swarm / Scout (L1) or Pebble Mite (L2) | 1 | 4 % |
| Guard / Hunter (L1), Boulder Beetle / Shard Wasp (L2) | 1 | 12 % |
| Elite | 10 | always |
| Mid-run boss | 25 (L1 Hive Beetle) / 30 (L2 Quarry Mantis) | always |
| Final boss | 40 (L1 Worm Boss) / 60 (L2 Bedrock Queen) | always |

The Xenite Scanner hangar upgrade multiplies the non-guaranteed chances by 1.15 - 1.45.

---

## 10. Interface and feedback

### 10.1 Screens

| Screen | Scene / script | Purpose |
|---|---|---|
| Start menu | `scenes/menus/start_menu.tscn`, `scripts/start_menu.gd` | Entry point; title logo and backdrop |
| Save slots | `save_slots.tscn` | Choose or create a save |
| Level select | `level_select.tscn`, `scripts/level_select.gd` | Mission ladder, briefing, level stats |
| Hangar | `hangar.tscn`, `scripts/hangar.gd` | Spend Xenite on permanent upgrades |
| In-run HUD | `scenes/shared/world.tscn`, `run_hud.gd`, `player_info.gd`, `score.gd` | Life, shield, XP, timer, score, weapon icons |
| Level up | `level_up_menu.tscn`, `level_up_menu.gd` | Pick 1 of 3 cards |
| Pause | `pause_menu.tscn`, `pause_menu.gd` | Pause, options |
| Game over | `game_over_menu.tscn`, `game_over_menu.gd` | Retry / Hangar / main menu |
| Options / settings | `options_panel.tscn`, `settings_menu.tscn` | Audio, visuals, controls |
| High scores | `scripts/high_score_table.gd`, `name_entry.gd` | Name entry and table |

### 10.2 Feedback and effects

- Use `Juice` for hit-stop, shake, flash, hit effects, explosions and sounds (`play_sound` caps one sound per 40 ms).
- Phase banners and count-downs: `phase_banner.gd`, `count_down.gd`. The elite shows a "SUPPLY CRATE!" banner.
- Boss indicator: `boss_indicator.gd` points to the boss when it is off screen.
- Floating text for damage and pickups: `floating_text.gd` (capped by `FloatingText.MAX_ALIVE`).

### 10.3 Options that change visuals

`ConfigHandler.load_visuals()` flags: `show_damage_given`, `show_enemies_lifebar`, `show_damage_taken`.

---

## 11. Audio

- Music per level: `resources/levels/levelN/music/` (level 2 music gain +6 dB, `music_db`).
- Menu music: `singletons/menu_music.gd`.
- Sound effects: `resources/shared/audio/`. Play through `Juice.play_sound(audio_player_2d)`.
- *TBD:* music and SFX volume defaults, and the sound list per weapon and enemy.

---

## 12. Art direction

- Level-specific art briefs: `art_level1.md` (biomechanical swarm, dark hulls, cyan glow) and `art_level2.md`
  (rock bugs). Both are used as Gemini prompts.
- Pickups and upgrade icons are shared across levels (`art_level1.md` section 12). Icon files are in
  `resources/shared/pickups/`.
- Asset locations: `asset-layout` skill and the `resources/` layout in section 13.

---

## 13. Technical contracts (summary)

Full detail is in the `space-thunder-conventions` skill. The rules that matter for design:

- **Collision layers:** 1 Player, 2 Rock, 3 Bullet, 4 Enemy. Enemies and bosses use layer 8 and mask 2.
  Enemies do not collide with the player body.
- **Groups:** `Enemy`, `Bullet`, `Rock`, `Player` (`player`), `XpGem`, perk groups.
- **Death is one-shot:** always check `isDead` before calling `explode()`.
- **Enum tables:** every new `Enums.ENEMIES`, `PERKS` or `WEAPONS` value must be added to every keyed
  table (`LevelSettings`, `DamageValues`, `WeaponFactory`, `Upgrades`).
- **Performance budget:** 100+ enemies on screen, nuke and magnet at full scale, no per-frame allocations in
  `_physics_process`. Measure with the `perf-stress` skill before and after changes.

### 13.1 Resource layout

```
resources/
  levels/level1/   background, music, enemies/, weapons/
  levels/level2/   background, music, enemies/, weapons/
  shared/          player, pickups, audio, fx, space, branding
  vendor/kenney/   third-party packs
  unused/          retired assets
```

---

## 14. Balance and tuning knobs

These are the values to change first when balancing. Keep the table current.

| Knob | Where |
|---|---|
| Stage delay / max alive / wave mix | `level.tres` `stages` |
| Boss and elite timing | `level.tres` `bosses`, `elite_at` |
| Swarm size and interval | `level.tres` `swarm_every`, `swarm_base`, `swarm_per_stage` |
| Boss life factor | `level.tres` `boss_life_factor` |
| Victory bonus | `level.tres` `victory_bonus` |
| Stat card values and max levels | `singletons/upgrades.gd` |
| Weapon damage ranges | `singletons/damage_values.gd` |
| Player base stats | `singletons/player_status.gd` |
| Enemy points and XP | `singletons/level_settings.gd` |
| Floor perk drop chances (per 1000) | `singletons/level_settings.gd` |
| Xenite drop chances and bank rules | Appendix A / B, `singletons/meta_progress.gd` |
| Hangar costs and ranks | `singletons/meta_progress.gd` |

---

## 15. Open questions and planned work

- Levels 3-10: setting, enemies, bosses, mechanics (section 8.3).
- Full control map, including gamepad (section 3).
- Per-enemy stat sheet (section 9.1).
- Endless mode: decide whether it becomes player-facing (currently dev console only).
- Balance pass on the level 2 cards and Xenite economy after first playtests.
- Confirm that the Bomb perk's bomb damage (10 000 - 20 000) is intended as a "kill everything" effect, and
  record that decision here.

---

## 16. How to keep this document up to date

1. Any change to a value in section 14 updates the value here in the same commit.
2. A new level, enemy, weapon, card or pickup gets a row in the matching table above.
3. Decisions that change a rule get a short "why" line next to the rule.
4. Level-specific Xenite and Hangar detail goes in that level's appendix (Appendix A or B); keep the shared
   rules identical in both.
5. Remove or mark *TBD* items when they are settled, and move them to the decision log below.

### Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-11-05 | Level 2 swaps some level 1 stat cards for tuned versions rather than adding cards | Keeps the pick pool the same size |
| 2026-11-05 | Xenite is carried, not spent, during a run | Keeps the run about survival and build choices; spending happens in the Hangar |

---

# Appendix A - Level 1 Xenite and Hangar rules

> Merged from the former `level1_bonuses.md`. Rules shared by every level are in sections 6.3 and 7;
> level 2 rules are in Appendix B.



---

### 1. Xenite crystals: what they are

Xenite is a violet alien crystal. In the game it is the **shard**: a small floating crystal dropped by
enemies. It is the only currency of the bonus system.

- **Visual:** a cluster of 2–3 sharp violet crystal spikes with a thin cyan glow inside (`perks/xenite.png`).
  No token or plate around it. Shard size grows with the enemy: bigger bundles from bosses look bigger.
- **Pickup:** it lies on the floor until the ship comes within the pickup radius (120 px by default), then it
  flies into the ship like an XP gem. Tractor Beam (below) makes the radius bigger.
- **Collected = carried, not spent.** Shards picked up during a run are only counted. Nothing changes
  on the ship until the run ends.
- **No in-run effect.** Crystals do not give a bonus in the middle of a run. All bonuses come from the
  Hangar, and they are applied when the next run starts.

### 2. Where crystals come from in level 1

Drop chance is per kill. Bosses and the elite always drop their bundle. The Xenite Scanner upgrade raises
every chance (section 4).

| Source | Enemy (level 1) | Drop | Notes |
|---|---|---|---|
| Swarm / scout | Scout | 4 % for 1 crystal | weakest source, comes in swarms |
| Guard | Guard | 12 % for 1 crystal | the elite Guard below is separate |
| Hunter | Hunter | 12 % for 1 crystal | |
| Elite (7:30) | Guard with 12× life, 1.8× size, violet tint | **10 crystals**, always | "SUPPLY CRATE!" banner |
| Stage 5 boss (5:00) | Hive Beetle | **25 crystals**, always | carrier, not the final boss |
| Final boss (10:00) | Worm Boss | **40 crystals**, always | ends the level |

Crystals dropped by a run that ends in a win are banked too (section 3), so the final boss is the
biggest single source of Xenite in level 1.

### 3. Banking and spending

- **Every run banks its crystals**, won or lost. The total goes to the bank of **this level**.
- **Surviving pays:** 2 crystals for each full minute survived, even if the ship dies.
- **Victory pays:** +30 crystals on top when the final boss is killed.
- **Banks are per level.** Each level starts with an empty bank and its own upgrade ranks. Xenite banked in
  one level cannot be spent in another.
- **Hangar:** the bank is spent there on permanent upgrades (section 4). Each purchase costs
  `base cost × (current rank + 1)`, so the price of each rank goes up.
- **Deaths and runs** are counted per level and shown on the level select screen and in the Hangar.

### 4. Hangar bonuses (permanent, bought with Xenite)

Every bonus applies to every run of the level after it is bought. "Percent" is relative to the normal
starting value of the stat (for example, Plasma Coils adds +5 to the base damage of 100).

| Icon (file) | Upgrade | id | Effect per rank | Max rank | Cost per rank | Total to max |
|---|---|---|---|---|---|---|
| Layered hull plates with a rose cross heart core (`icon_hull.png`) | Reinforced Hull | `hull` | Max life +10 | 5 | 15 / 30 / 45 / 60 / 75 | 225 |
| Battery cell with a hex shield emblem (`icon_shield.png`) | Shield Capacitor | `shield` | Max shield +10 | 5 | 15 / 30 / 45 / 60 / 75 | 225 |
| Energy blade or cannon shell with an up-chevron (`icon_damage.png`) | Plasma Coils | `damage` | Damage +5 % | 5 | 20 / 40 / 60 / 80 / 100 | 300 |
| Glowing reactor chip with a lightning bolt (`icon_overclock.png`) | Cooling Vents | `fire_rate` | Fire rate +4 % | 5 | 20 / 40 / 60 / 80 / 100 | 300 |
| Engine nozzle, plasma flame, speed lines (`icon_thrusters.png`) | Ion Thrusters | `speed` | Move speed +4 % | 4 | 15 / 30 / 45 / 60 | 150 |
| Thick riveted steel plate with a blue seam (`icon_armor.png`) | Ablative Plating | `armor` | Armor +1 | 3 | 30 / 60 / 90 | 180 |
| Swarm of tiny repair drones around a rose cross (`icon_nanobots.png`) | Repair Nanites | `regen` | Regen +0.4 life/s | 3 | 30 / 60 / 90 | 180 |
| Targeting reticle with a glowing centre dot (`icon_precision.png`) | Targeting AI | `crit` | Critical chance +2 % | 4 | 20 / 40 / 60 / 80 | 200 |
| Horseshoe magnet with a pull arrow (`icon_tractor.png`) | Tractor Beam | `magnet` | Pickup radius +20 (from 120) | 3 | 10 / 20 / 30 | 60 |
| Scanner dish locked onto a violet crystal (`icon_xenite_scanner.png`) | Xenite Scanner | `salvage` | Crystal drop chance +15 % | 3 | 25 / 50 / 75 | 150 |

Notes on the effects:

- **Armor** is subtracted from every hit the ship takes (`damage − armor`, never below 1). At rank 3 every
  hit is 3 smaller.
- **Regen** heals 0.4 life per second per rank, so 1.2 life per second at max.
- **Xenite Scanner** multiplies the chance of every enemy drop: rank 1 = ×1.15, rank 3 = ×1.45. A
  guaranteed drop (boss, elite) is not changed.

### 5. Weapons (skills)

Weapons are **not bought with crystals**. They come from **XP level-ups** during a run: the player picks one
card from three. A weapon card shows the weapon icon and "NEW!", and later "Lv 2", "Lv 3"... up to level 6.
The ship has **5 weapon slots**, and the Blaster is always one of them, so only four other weapons fit in
one run. Each weapon is rebuilt at the start of every run.

The Blaster is the main gun from the start. The others work on their own: they fire at the nearest enemy
(Heavy cannon, Missiles, Fireworks), fire in all directions (Nova), or orbit the ship (Orbit).

| Icon (file) | Weapon | Id | How it looks | How it works | Damage per hit | Level-up effect |
|---|---|---|---|---|---|---|
| Twin yellow-white bolts (`icon_blaster.png`) | Blaster | `w_blaster` | thin, fast, yellow-white bolts | main gun, fires where the player aims, straight bolts that stop at the first enemy | 10–20 | fire delay 0.14 s × 0.88 per level; +1 bolt at level 3 and again at level 5 |
| Fat cannon shell (`icon_cannon.png`) | Heavy cannon | `w_cannon` | big, heavy shells | fires at the nearest enemy, shells stop at the first hit | 30–50 | delay 1.0 s × 0.85 per level; life 0.8 s; +1 shell at levels 2, 4 and 6 |
| Ring of bullets around a bright centre (`icon_nova.png`) | Nova | `w_nova` | a ring of small bullets flying outward from the ship | no target needed; a full ring of bullets every pulse, hits everything around the ship | 25–40 | delay 2.2 s × 0.88 per level; ring size 12 + 4 × level (16 bullets at level 1); bullets live 1 s |
| Homing rocket with a curved exhaust (`icon_missiles.png`) | Missiles | `w_missiles` | warm orange-yellow rockets with a bigger glow | launched at the nearest enemy; each rocket goes straight once fired | 10–20 | delay 1.2 s × 0.85 per level; rockets = level (1 at level 1, 6 at level 6), fan spread |
| Shell bursting into a star of shrapnel (`icon_fireworks.png`) | Fireworks | `w_fireworks` | a shell that flies, then bursts in an orange-white star | one shell at the nearest enemy; after 0.7 s it bursts into a ring of shrapnel | shell and shrapnel 25–40 | delay 2.0 s × 0.88 per level; shrapnel count 12 + 4 × level |
| Two or three blades circling a centre point (`icon_orbit.png`) | Orbit | `w_orbit` | cyan-white blades circling the ship | no fire delay; blades circle the ship and pass through enemies | 15–25 per blade hit | blades = 1 + level + Multishot; orbit radius 80 + 6 × level; spin 2.6 + 0.4 × level rad/s |

#### 5.1 Stat cards (XP only, same icon style)

The level-up pool also has stat cards. They use the same icon style as the Hangar bonuses, but each is
bigger, and they only apply to the current run.

| Card | Icon | Effect | Max level |
|---|---|---|---|
| Damage | energy blade with up-chevron | +15 % damage | 10 |
| Precision | targeting reticle | +5 % critical chance | 8 |
| Lethality | cracked armor plate with a spark star | +30 % critical damage | 8 |
| Thrusters | engine nozzle with flame | +10 % move speed | 5 |
| Overclock | reactor chip with lightning bolt | +12 % fire rate | 6 |
| Multishot | three bullets fanning out | +1 projectile for every weapon | 3 |
| Hull plating | layered plates with rose cross | +20 max life, heals 20 | 8 |
| Nanobots | repair drones around rose cross | +0.6 life per second | 5 |
| Armor | riveted steel plate | −2 damage from every hit | 5 |
| Shield capacitor | battery cell with hex emblem | +25 max shield | 4 |
| Tractor beam | horseshoe magnet with pull arrow | +40 % pickup radius | 5 |

### 6. How bonuses change damage and enemies

**Damage per hit** (for every weapon):

```
damage = random(weapon range) × (BaseDamage / 100)
critical hit (chance = Critical chance, default 10 %): damage × (Critical multiplier / 100), default ×2
```

- Plasma Coils (Hangar, max) makes BaseDamage 125, so every hit is ×1.25.
- Damage (XP card) adds +15 % to BaseDamage per level.
- Targeting AI and Precision raise the critical chance; Lethality raises the critical multiplier (200 % → 230 %).
- Critical hits show a different floating number, so the player can see them.

**Enemies:**

- No Hangar bonus changes an enemy's stats. Enemies keep their life, speed and damage.
- The only Hangar bonus that touches enemies is **Xenite Scanner**: it changes how often they drop crystals.
- **Armor** and **Regen** change how much damage the ship takes from enemies, not what the enemies do.
- **Tractor Beam** (Hangar and XP card) makes the pickup radius bigger, so crystals are collected from further away.

**Level 1 enemy life** (the number the weapons have to wear down). Bosses use the level factor 0.8.

| Enemy | Base life | Contact or attack damage | Note |
|---|---|---|---|
| Scout | 30 | 8 | Dies to 2–3 Blaster hits |
| Guard | 120 | 20 | Rams after a radar lock |
| Hunter | 100 | 12 | Small gun every 0.5 s |
| Elite Guard | 1 440 (12× Guard) | 20 | 1.8× size, violet tint |
| Hive Beetle (boss) | 15 000 × 0.8 = 12 000 | 100 | Shell opens to fire |
| Worm Boss (final) | 20 000 × 0.8 = 16 000 | 120 | Four attacks |

---

### 7. Checklist for bonus and icon art

- [ ] Crystal (shard) reads as violet crystal spikes with a cyan glow; no token or plate.
- [ ] Hangar icons use the category colour (survival rose, defense blue, offense yellow/orange, utility silver + yellow, Xenite violet).
- [ ] Weapon icons read as the weapon's shot at 44 px (HUD) and at 110 px (card).
- [ ] No icon uses enemy cyan as its main colour, and no pure red or green.

---

# Appendix B - Level 2 Xenite and Hangar rules

> Merged from the former `level2_bonuses.md`. Rules shared by every level are in sections 6.3 and 7;
> level 1 rules are in Appendix A.



---

### 1. Xenite crystals: what they are

Xenite is a violet alien crystal. In the game it is the **shard**: a small floating crystal dropped by
enemies. It is the only currency of the bonus system.

- **Visual:** a cluster of 2–3 sharp violet crystal spikes with a thin cyan glow inside (`perks/xenite.png`).
  No token or plate around it. Shard size grows with the enemy: bigger bundles from bosses look bigger.
- **Pickup:** it lies on the floor until the ship comes within the pickup radius (120 px by default), then it
  flies into the ship like an XP gem. Tractor Beam (below) makes the radius bigger.
- **Collected = carried, not spent.** Shards picked up during a run are only counted. Nothing changes
  on the ship until the run ends.
- **No in-run effect.** Crystals do not give a bonus in the middle of a run. All bonuses come from the
  Hangar, and they are applied when the next run starts.

### 2. Where crystals come from in level 2

Drop chance is per kill. Bosses and the elite always drop their bundle. The Xenite Scanner upgrade raises
every chance (section 4).

| Source | Enemy (level 2) | Drop | Notes |
|---|---|---|---|
| Swarm / scout | Pebble Mite | 4 % for 1 crystal | weakest source, comes in swarms |
| Guard slot | Boulder Beetle | 12 % for 1 crystal | |
| Hunter slot | Shard Wasp | 12 % for 1 crystal | |
| Elite (7:30) | Boulder Beetle elite, 1.8× size, 12× life | **10 crystals**, always | "SUPPLY CRATE!" banner |
| Stage 5 boss (5:00) | Quarry Mantis | **30 crystals**, always | replaces the Hive Beetle, not the final boss |
| Final boss (10:00) | Bedrock Queen | **60 crystals**, always | ends the level |

Crystals dropped by a run that ends in a win are banked too (section 3), so the final boss is the
biggest single source of Xenite in each level.

### 3. Banking and spending

- **Every run banks its crystals**, won or lost. The total goes to the bank of **this level**.
- **Surviving pays:** 2 crystals for each full minute survived, even if the ship dies.
- **Victory pays:** +30 crystals on top when the final boss is killed.
- **Banks are per level.** Each level starts with an empty bank and its own upgrade ranks. Xenite banked in
  one level cannot be spent in another.
- **Hangar:** the bank is spent there on permanent upgrades (section 4). Each purchase costs
  `base cost × (current rank + 1)`, so the price of each rank goes up.
- **Deaths and runs** are counted per level and shown on the level select screen and in the Hangar.

### 4. Hangar bonuses (permanent, bought with Xenite)

Every bonus applies to every run of the level after it is bought. "Percent" is relative to the normal
starting value of the stat (for example, Plasma Coils adds +5 to the base damage of 100).

| Icon (file) | Upgrade | id | Effect per rank | Max rank | Cost per rank | Total to max |
|---|---|---|---|---|---|---|
| Layered hull plates with a rose cross heart core (`icon_hull.png`) | Reinforced Hull | `hull` | Max life +10 | 5 | 15 / 30 / 45 / 60 / 75 | 225 |
| Battery cell with a hex shield emblem (`icon_shield.png`) | Shield Capacitor | `shield` | Max shield +10 | 5 | 15 / 30 / 45 / 60 / 75 | 225 |
| Energy blade or cannon shell with an up-chevron (`icon_damage.png`) | Plasma Coils | `damage` | Damage +5 % | 5 | 20 / 40 / 60 / 80 / 100 | 300 |
| Glowing reactor chip with a lightning bolt (`icon_overclock.png`) | Cooling Vents | `fire_rate` | Fire rate +4 % | 5 | 20 / 40 / 60 / 80 / 100 | 300 |
| Engine nozzle, plasma flame, speed lines (`icon_thrusters.png`) | Ion Thrusters | `speed` | Move speed +4 % | 4 | 15 / 30 / 45 / 60 | 150 |
| Thick riveted steel plate with a blue seam (`icon_armor.png`) | Ablative Plating | `armor` | Armor +1 | 3 | 30 / 60 / 90 | 180 |
| Swarm of tiny repair drones around a rose cross (`icon_nanobots.png`) | Repair Nanites | `regen` | Regen +0.4 life/s | 3 | 30 / 60 / 90 | 180 |
| Targeting reticle with a glowing centre dot (`icon_precision.png`) | Targeting AI | `crit` | Critical chance +2 % | 4 | 20 / 40 / 60 / 80 | 200 |
| Horseshoe magnet with a pull arrow (`icon_tractor.png`) | Tractor Beam | `magnet` | Pickup radius +20 (from 120) | 3 | 10 / 20 / 30 | 60 |
| Scanner dish locked onto a violet crystal (`icon_xenite_scanner.png`) | Xenite Scanner | `salvage` | Crystal drop chance +15 % | 3 | 25 / 50 / 75 | 150 |

Notes on the effects:

- **Armor** is subtracted from every hit the ship takes (`damage − armor`, never below 1). At rank 3 every
  hit is 3 smaller.
- **Regen** heals 0.4 life per second per rank, so 1.2 life per second at max.
- **Xenite Scanner** multiplies the chance of every enemy drop: rank 1 = ×1.15, rank 3 = ×1.45. A
  guaranteed drop (boss, elite) is not changed.

### 5. Weapons (skills)

Weapons are **not bought with crystals**. They come from **XP level-ups** during a run: the player picks one
card from three. A weapon card shows the weapon icon and "NEW!", and later "Lv 2", "Lv 3"... up to level 6.
The ship has **5 weapon slots**, and the Blaster is always one of them, so only four other weapons fit in
one run. Each weapon is rebuilt at the start of every run.

The level 2 arsenal is **mining equipment turned into weapons**. The Thunder is fighting in a belt where
the hive's bugs wear stone shells, so the guns are tools a belt miner would carry: rivets, drill bits,
blasting charges, thermite lances, tethered boulders. Each one replaces a level 1 weapon one-to-one.
Damage ranges, cooldowns, level scaling and the 5-slot limit are the same as in level 1, so the balance
does not change. Only the look, the names and the impact change.

**Pillars of the level 2 arsenal:**

1. **Tools, not lasers.** Every weapon is a piece of mining kit. No energy zaps.
2. **Warm against cool.** Shots are ore amber (`#FF9A3C` → `#FFD08A`), steel (`#9AA3B5`) and white-hot tips.
   Cyan stays the hive's colour. The ship's yellow-white stays the core glow. No green, no pure red.
3. **Impacts throw stone.** A hit sprays grey rock chips and a small dust puff instead of a cyan spark.
4. **Heavy sound.** Clank, thump, rock crack. Sound design follows the same rule.
5. **One object per icon**, readable at 44 px (HUD) and 110 px (card), as in `art_level1.md` 12.1.

The Rivet Gun is the main gun from the start. The others work on their own: they fire at the nearest enemy
(Drill Cannon, Thermite Lances, Blast Charge), fire in all directions (Quake Charge), or orbit the ship
(Tether Rocks).

| Icon (file) | Weapon | Id | Projectile look | Impact | How it works | Damage per hit | Level-up effect |
|---|---|---|---|---|---|---|---|
| Three domed steel rivets fanning out from one point, amber tracer behind each (`icon_blaster.png`) | **Rivet Gun** (main gun) | `w_blaster` | short steel slugs with a thin amber tracer | grey chip spray | main gun, fires where the player aims, straight slugs that stop at the first enemy | 10–20 | fire delay 0.14 s × 0.88 per level; +1 slug at level 3 and again at level 5 |
| Conical drill bit with spiral grooves, hot amber tip, steel body (`icon_cannon.png`) | **Drill Cannon** | `w_cannon` | spinning conical bit with a faint amber heat trail | dust burst, stronger screen shake | fires at the nearest enemy; a bit stops at the first enemy it hits, except from level 4 on, when it pierces one enemy and stops at the second. With Ricochet Plates, a bit that would stop bounces to the nearest other enemy instead (after any pierce) | 30–50 | delay 1.0 s × 0.85 per level; life 0.8 s; +1 bit at levels 2, 4 and 6; pierce one enemy from level 4 |
| Stone disc split by radial cracks, amber light leaking from the cracks (`icon_nova.png`) | **Quake Charge** | `w_nova` | ring of angular rock shards with amber-lit edges, slowly spinning | small dust puffs | no target needed; a full ring of shards every pulse, around the ship | 25–40 | delay 2.2 s × 0.88 per level; ring size 12 + 4 × level (16 shards at level 1); shards live 1 s |
| Slim finned lance with a molten white-orange head and a curved ember trail (`icon_missiles.png`) | **Thermite Lances** | `w_missiles` | lance with a white-hot head, embers cooling from orange to dark | orange flash and flying embers | launched at the nearest enemy; each lance goes straight once fired | 10–20 | delay 1.2 s × 0.85 per level; lances = level (1 at level 1, 6 at level 6), fan spread |
| Stubby steel blasting canister with a fuse spark and two rock fragments flying off (`icon_fireworks.png`) | **Blast Charge** | `w_fireworks` | tumbling canister with a sparking fuse | boom and dust cloud, then burning fragments | one charge at the nearest enemy; after 0.7 s it bursts into a ring of fragments | charge and fragments 25–40 | delay 2.0 s × 0.88 per level; fragment count 12 + 4 × level |
| Chipped asteroid chunk on a glowing tether ring around a centre point (`icon_orbit.png`) | **Tether Rocks** | `w_orbit` | grey cratered stones at 2× scale, amber light in their cracks | knock off stone chips | no fire delay; rocks circle the ship and pass through enemies. Each rock breaks after 3 + level hits: it fades with every hit, is invisible and harmless when broken, and comes back at full opacity after 5 s | 15–25 per hit, +25 % per level above 1 (level 6: 2.25×) | inner rocks 2 / 2 / 3 / 3 / 4 / 4 by level (+ Multishot); outer ring of 2 rocks at level 6; rock scale 2.0 → 3.0 (hit box too); inner radius 85 → 115, outer 190; spin 3.0 → 4.6 rad/s, outer ring −3.0 rad/s |

**Names are the only data change for the code.** The ids (`w_blaster`, `w_cannon`, ...) and the
`Enums.WEAPONS` values stay the same, so the weapon logic and balance need no edits. The names, icons,
projectile art and card text are the level 2 skin (see the code follow-up in the plan).

**Level-up card text for level 2:**

| Weapon | New card | Upgrade card |
|---|---|---|
| Rivet Gun | "Main gun" | "Faster and wider main gun" |
| Drill Cannon | "Auto-aimed drill shells" | "Faster, more shells. Lv 4: shells pierce one enemy" |
| Quake Charge | "Ring of rock shards around you" | "More shards, faster pulse" |
| Thermite Lances | "Self-guided burning lances" | "More lances, faster reload" |
| Blast Charge | "Charge bursting into fragments" | "Bigger blasts" |
| Tether Rocks | "Boulders circling your ship" | "More rocks, faster spin" |

#### 5.1 Stat cards (XP only, same icon style)

The level-up pool also has stat cards. They use the same icon style as the Hangar bonuses, but each is
bigger, and they only apply to the current run. Level 2 cards are not a rename of level 1's: several change
how the weapons look and fire. Palette rule as for the weapons: ore amber, steel, white-hot tips, grey rock
chips. No cyan, no pure red or green.

**Status legend:** *Implemented* = works in the game as the level 2 card. *Not implemented* = only in this document. A card can be
implemented for its stat effect while its weapon-visual part is still open; the Status cell then says so.
Checked against `singletons/upgrades.gd` (the level-up pool) and `singletons/levels.gd` (level 2 skins), which have
only the level 1 stat cards and the level 2 weapon names and icons.

**Global cards** (apply to every weapon):

| Card | Icon | Effect | Max level | Weapon change | Status |
|---|---|---|---|---|---|
| Carbide Tips | steel drill head with a hot amber tip and an up-chevron | +12 % damage | 10 | shots get a white-hot tip; bigger chip spray on hit | **Implemented** (+12 % damage, level 2 only, `singletons/upgrades.gd`, icon `resources/shared/pickups/icon_carbide.png`). Not yet: white-hot shot tip and chip spray |
| Fault Line | rock slab split by a glowing amber crack | +35 % critical damage | 6 | a crit throws 3 rock chips (small area hit, 20 % damage); amber flash and its own sound | **Implemented** (+35 % critical damage, level 2 only, `singletons/upgrades.gd`, icon `resources/shared/pickups/icon_fault_line.png`). Not yet: crit shatter (3 rock chips), amber flash and crit sound |
| Seismic Sensor | steel geophone spike with amber ripple rings | +6 % critical chance | 6 | amber ring pulse around the ship on each crit | **Implemented** (+6 % critical chance, level 2 only, `singletons/upgrades.gd`, icon `resources/shared/pickups/icon_seismic.png`). Not yet: amber ring pulse on crit |
| Pressure Valve | steel valve wheel with a puff of steam | +10 % fire rate | 6 | steam puff from the muzzle, shorter shot sound | **Implemented** (+10 % fire rate, level 2 only, `singletons/upgrades.gd`, icon `resources/shared/pickups/icon_pressure_valve.png`). Not yet: steam puff from the muzzle, shorter shot sound |
| Extra Charges | three blasting canisters tied together | +1 projectile for every weapon | 3 | shots leave the ship as a bundle | **Implemented** (+1 projectile for every weapon, level 2 only, `singletons/upgrades.gd`, icon `resources/shared/pickups/icon_extra_charges.png`). Not yet: bundle look on shots |
| Ricochet Plates | steel plate with a bounce arrow | straight shots (Rivet Gun, Thermite Lances) and Drill Cannon shells bounce to the nearest enemy, one bounce per level (level 2: twice) | 2 | slug or lance bends in flight, spark on each bounce | **Implemented** (bounce to the nearest enemy, level 2 only, `singletons/upgrades.gd`, `scripts/bullet.gd`, icon `resources/shared/pickups/icon_ricochet.png`). Not yet: slug or lance bend and spark on each bounce |
| Fracture | stone with a hammer mark | every 6th enemy hit (counted across all enemies) deals +60 % damage and cracks it | 4 | crack decal on the enemy; more cracks per stack | **Implemented** (every 6th enemy hit across all enemies +60 %, one hit sooner per level, max level 4, level 2 only, `singletons/upgrades.gd`, `singletons/player_status.gd`, icon `resources/shared/pickups/icon_fracture.png`). Not yet: crack decal on the enemy and more cracks per stack |
| Slag Trails | molten drip behind a shell | every shot leaves an ember trail that burns enemies for 15 % of hit damage over 2 s | 4 | glowing embers behind shots | **Implemented** (burn of 15 % of hit damage per level over 2 s, max level 4, level 2 only, `singletons/upgrades.gd`, `singletons/player_status.gd`, `scripts/bullet.gd`, icon `resources/shared/pickups/icon_slag_trails.png`). Not yet: glowing ember particles behind shots |

**Weapon cards** (only in the pool once the named weapon is owned):

| Card | Needs | Icon | Effect | Max level | Weapon change | Status |
|---|---|---|---|---|---|---|
| Diamond Bit | Drill Cannon | drill bit with a diamond-white tip | +1 pierce (3 enemies in total); the bit drills into the first enemy for 0.5 s and deals tick damage | 3 | bit turns white while drilling | Not implemented (Drill Cannon exists; its level 4 pierce is in levels.gd) |
| Rotary Magazine | Rivet Gun | revolving drum | every 10th volley is a full burst: all slugs ×2 damage for 1 s | 3 | drum spin sound and sparks | Not implemented (Rivet Gun exists) |
| Seismic Rings | Quake Charge | stone disc with echo rings | the ring pulses twice; the second ring comes 0.3 s later, is bigger and knocks enemies back | 3 | two-stage pulse | Not implemented (Quake Charge exists) |
| Aftershock | Quake Charge | cracked disc with small arrows | a shard that kills an enemy spawns a mini pulse of 6 shards | 3 | mini pulses around kills | Not implemented (Quake Charge exists) |
| Thermite Cloud | Thermite Lances | burning lance with smoke | a lance leaves a burning patch where it hits, ticking for 2 s | 3 | lances turn bright orange | Not implemented (Thermite Lances exists) |
| Homing Fuses | Thermite Lances | lance with a curl trail | lances curve toward enemies; turn rate rises per level | 3 | curved flight path | Not implemented (Thermite Lances exists) |
| Cluster Charge | Blast Charge | canister with 3 smaller canisters | the burst releases 3 mini-charges, each bursting again after 0.5 s | 3 | smaller fragment ring | Not implemented (Blast Charge exists) |
| Long Fuse | Blast Charge | coiled fuse | the charge sticks to the first enemy, bursts 1 s later at full size, +40 % blast damage | 3 | fuse sparks while it sticks | Not implemented (Blast Charge exists) |
| Heavy Boulders | Tether Rocks | boulder with a weight mark | rocks +50 % size; they knock enemies back on hit, spin slows | 3 | bigger rocks | Not implemented (Tether Rocks exists) |
| Mining Laser Link | Tether Rocks | two rocks joined by a glowing beam | a beam links neighbouring rocks; enemies crossing it take tick damage | 3 | amber beam between rocks | Not implemented (Tether Rocks exists) |

**Survival and utility cards:**

| Card | Icon | Effect | Max level | Feel change | Status |
|---|---|---|---|---|---|
| Hardhat Plating | dented mining helmet with a lamp | +25 max life, heals 25 | 8 | none | Not implemented (level 1 "Hull plating" exists) |
| Rock Shell | grey stone carapace with amber cracks | −2 damage from every hit | 5 | rock chips on the hull, more per level | Not implemented (level 1 "Armor" exists) |
| Shock Absorber | coiled steel spring on a plate | +30 max shield | 4 | shield breaks in an amber flash and knocks back nearby enemies | Not implemented (level 1 "Shield capacitor" exists) |
| Grav Winch | winch hook pulling a crystal on a cable | +50 % pickup radius | 4 | gems fly in along a visible amber cable | Not implemented (level 1 "Tractor beam" exists) |
| Jet Boots | miner boot with a thruster flame | +10 % move speed | 5 | longer engine flame | Not implemented (level 1 "Thrusters" exists) |
| Magnet Core | horseshoe magnet with a spark | killed enemies pull nearby gems and xenite | 3 | magnetic spark on each pull | Not implemented |

Cards that change a weapon's behaviour need new code (weapon hooks, bullet scenes). Stat-only cards reuse the
existing `PlayerStatus` values.

**Pool rule for level 2:** a level 1 stat card is not offered in level 2 once its level 2 replacement is
implemented. So far **Damage** (replaced by Carbide Tips), **Precision** (replaced by Seismic Sensor), **Lethality** (replaced by Fault Line) and **Overclock** (replaced by Pressure Valve) and **Multishot** (replaced by Extra Charges) are removed. The other level 1 stat cards stay
in level 2 until their replacements exist, otherwise level 2 would lose those stats entirely.

### 6. How bonuses change damage and enemies

**Damage per hit** (for every weapon):

```
damage = random(weapon range) × (BaseDamage / 100)
critical hit (chance = Critical chance, default 10 %): damage × (Critical multiplier / 100), default ×2
```

- Plasma Coils (Hangar, max) makes BaseDamage 125, so every hit is ×1.25.
- Carbide Tips (XP card) adds +12 % to BaseDamage per level.
- Level 2 weapons use the same damage ranges as level 1 (section 5), so the formula is unchanged.
- Targeting AI and Seismic Sensor raise the critical chance; Fault Line raises the critical multiplier by 35 points per level (200 % → 235 % at level 1).
- Critical hits show a different floating number, so the player can see them.

**Enemies:**

- No Hangar bonus changes an enemy's stats. Enemies keep their life, speed and damage.
- The only Hangar bonus that touches enemies is **Xenite Scanner**: it changes how often they drop crystals.
- **Armor** and **Regen** change how much damage the ship takes from enemies, not what the enemies do.
- **Tractor Beam** (Hangar) and **Grav Winch** (XP card) make the pickup radius bigger, so crystals are collected from further away.

**Level 2 enemy life** (the number the weapons have to wear down). Bosses use the level factor 0.8.

| Enemy | Base life | Contact or attack damage | Note |
|---|---|---|---|
| Pebble Mite | 30 | 3 | Crawls in and stops at hull range |
| Boulder Beetle | 120 | 5 | 360° scanner, blast on its own |
| Shard Wasp | 90 | 6 | Circles the player, leaves shard wake |
| Elite Boulder Beetle | 1 440 (12× beetle) | 5 | 1.8× size |
| Quarry Mantis (boss) | 16 000 × 0.8 = 12 800 | — | Stalks the player, scythe attack |
| Bedrock Queen (final boss) | 16 000 × 0.8 = 12 800 | — | Four attacks, enraged below half life |

---

### 7. Checklist for bonus and icon art

- [ ] Crystal (shard) reads as violet crystal spikes with a cyan glow; no token or plate.
- [ ] Hangar icons use the category colour (survival rose, defense blue, offense yellow/orange, utility silver + yellow, Xenite violet).
- [ ] Level 2 weapon icons and shots use the amber / steel palette (ore amber, steel, white-hot tips). No cyan.
- [ ] Weapon icons read as the weapon's shot at 44 px (HUD) and at 110 px (card).
- [ ] No icon uses enemy cyan as its main colour, and no pure red or green.
- [ ] Level 2 stat card icons: one object each, same style as the Hangar icons, amber / steel palette.
