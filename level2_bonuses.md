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
- [ ] Weapon icons read as the weapon's shot at 44 px (HUD) and at 110 px (card).
- [ ] No icon uses enemy cyan as its main colour, and no pure red or green.
