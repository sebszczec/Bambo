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
| Conical drill bit with spiral grooves, hot amber tip, steel body (`icon_cannon.png`) | **Drill Cannon** | `w_cannon` | spinning conical bit with a faint amber heat trail | dust burst, stronger screen shake | fires at the nearest enemy; a bit stops at the first enemy it hits, except from level 4 on, when it pierces one enemy and stops at the second. With Ricochet Plates, a bit that would stop bounces to the nearest other enemy instead (after any pierce) | 30–50 | delay 1.0 s × 0.85 per level; life 0.8 s; +1 bit at levels 2, 4 and 6; pierce one enemy from level 4 |
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
| Fracture | stone with a hammer mark | every 6th hit on the same enemy deals +60 % damage and cracks it | 4 | crack decal on the enemy; more cracks per stack | **Implemented** (every 6th hit on an enemy +60 %, one hit sooner per level, max level 4, level 2 only, `singletons/upgrades.gd`, `singletons/player_status.gd`, icon `resources/shared/pickups/icon_fracture.png`). Not yet: crack decal on the enemy and more cracks per stack |
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

## 6. How bonuses change damage and enemies

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

## 7. Checklist for bonus and icon art

- [ ] Crystal (shard) reads as violet crystal spikes with a cyan glow; no token or plate.
- [ ] Hangar icons use the category colour (survival rose, defense blue, offense yellow/orange, utility silver + yellow, Xenite violet).
- [ ] Level 2 weapon icons and shots use the amber / steel palette (ore amber, steel, white-hot tips). No cyan.
- [ ] Weapon icons read as the weapon's shot at 44 px (HUD) and at 110 px (card).
- [ ] No icon uses enemy cyan as its main colour, and no pure red or green.
- [ ] Level 2 stat card icons: one object each, same style as the Hangar icons, amber / steel palette.
