# Space Thunder — Level 2 bonuses ("Asteroid Siege")

> **Scope:** the bonuses a player gets in level 2 from collecting Xenite crystals, and the skills (weapons)
> and stat cards that share the same icons. The bonus rules are the same in every level; section 2 is the
> only part that is specific to level 2. Level 1 has its own copy: `level1_bonuses.md`.
> Code references: `singletons/meta_progress.gd`, `singletons/level_settings.gd`, `singletons/upgrades.gd`,
> `singletons/weapon_factory.gd`, `singletons/damage_values.gd`, `scripts/shard.gd`.

---

## 1. Xenite crystals: what they are

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

## 2. Where crystals come from in level 2

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

## 3. Banking and spending

- **Every run banks its crystals**, won or lost. The total goes to the bank of **this level**.
- **Surviving pays:** 2 crystals for each full minute survived, even if the ship dies.
- **Victory pays:** +30 crystals on top when the final boss is killed.
- **Banks are per level.** Each level starts with an empty bank and its own upgrade ranks. Xenite banked in
  one level cannot be spent in another.
- **Hangar:** the bank is spent there on permanent upgrades (section 4). Each purchase costs
  `base cost × (current rank + 1)`, so the price of each rank goes up.
- **Deaths and runs** are counted per level and shown on the level select screen and in the Hangar.

## 4. Hangar bonuses (permanent, bought with Xenite)

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

## 5. Weapons (skills)

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
| Conical drill bit with spiral grooves, hot amber tip, steel body (`icon_cannon.png`) | **Drill Cannon** | `w_cannon` | spinning conical bit with a faint amber heat trail | dust burst, stronger screen shake | fires at the nearest enemy; a bit stops at the first enemy it hits, except from level 4 on, when it pierces one enemy and stops at the second | 30–50 | delay 1.0 s × 0.85 per level; life 0.8 s; +1 bit at levels 2, 4 and 6; pierce one enemy from level 4 |
| Stone disc split by radial cracks, amber light leaking from the cracks (`icon_nova.png`) | **Quake Charge** | `w_nova` | ring of angular rock shards with amber-lit edges, slowly spinning | small dust puffs | no target needed; a full ring of shards every pulse, around the ship | 25–40 | delay 2.2 s × 0.88 per level; ring size 12 + 4 × level (16 shards at level 1); shards live 1 s |
| Slim finned lance with a molten white-orange head and a curved ember trail (`icon_missiles.png`) | **Thermite Lances** | `w_missiles` | lance with a white-hot head, embers cooling from orange to dark | orange flash and flying embers | launched at the nearest enemy; each lance goes straight once fired | 10–20 | delay 1.2 s × 0.85 per level; lances = level (1 at level 1, 6 at level 6), fan spread |
| Stubby steel blasting canister with a fuse spark and two rock fragments flying off (`icon_fireworks.png`) | **Blast Charge** | `w_fireworks` | tumbling canister with a sparking fuse | boom and dust cloud, then burning fragments | one charge at the nearest enemy; after 0.7 s it bursts into a ring of fragments | charge and fragments 25–40 | delay 2.0 s × 0.88 per level; fragment count 12 + 4 × level |
| Chipped asteroid chunk on a glowing tether ring around a centre point (`icon_orbit.png`) | **Tether Rocks** | `w_orbit` | grey cratered stones at 2× scale, amber light in their cracks | knock off stone chips | no fire delay; rocks circle the ship and pass through enemies | 15–25 per rock hit | inner rocks 2 / 2 / 3 / 3 / 4 / 4 by level (+ Multishot); outer ring of 2 rocks at level 6; rock scale 2.0 → 3.0 (hit box too); inner radius 85 → 115, outer 190; spin 3.0 → 4.6 rad/s, outer ring −3.0 rad/s |

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

### 5.1 Stat cards (XP only, same icon style)

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

## 6. How bonuses change damage and enemies

**Damage per hit** (for every weapon):

```
damage = random(weapon range) × (BaseDamage / 100)
critical hit (chance = Critical chance, default 10 %): damage × (Critical multiplier / 100), default ×2
```

- Plasma Coils (Hangar, max) makes BaseDamage 125, so every hit is ×1.25.
- Damage (XP card) adds +15 % to BaseDamage per level.
- Level 2 weapons use the same damage ranges as level 1 (section 5), so the formula is unchanged.
- Targeting AI and Precision raise the critical chance; Lethality raises the critical multiplier (200 % → 230 %).
- Critical hits show a different floating number, so the player can see them.

**Enemies:**

- No Hangar bonus changes an enemy's stats. Enemies keep their life, speed and damage.
- The only Hangar bonus that touches enemies is **Xenite Scanner**: it changes how often they drop crystals.
- **Armor** and **Regen** change how much damage the ship takes from enemies, not what the enemies do.
- **Tractor Beam** (Hangar and XP card) makes the pickup radius bigger, so crystals are collected from further away.

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

## 7. Checklist for bonus and icon art

- [ ] Crystal (shard) reads as violet crystal spikes with a cyan glow; no token or plate.
- [ ] Hangar icons use the category colour (survival rose, defense blue, offense yellow/orange, utility silver + yellow, Xenite violet).
- [ ] Level 2 weapon icons and shots use the amber / steel palette (ore amber, steel, white-hot tips). No cyan.
- [ ] Weapon icons read as the weapon's shot at 44 px (HUD) and at 110 px (card).
- [ ] No icon uses enemy cyan as its main colour, and no pure red or green.
