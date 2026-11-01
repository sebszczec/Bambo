# Space Thunder — Art Bible (ships, enemies, bosses, pickups, icons)

> **How to use this file in Gemini:** paste the whole document at the start of the conversation
> (or put it into the instructions of a Gem) and say: *"Follow this art bible for every image and
> animation you make."* Then use the prompt templates in section 9.
> The canonical reference for the style is the **Worm Boss** (section 11) — attach one of its
> frames as a reference image whenever Gemini starts drifting.
> **Pickups and upgrade icons** (magnet, nuke, life, the "pick 1 of 3" cards...) have their own
> rules and prompts in **section 12**. Sections 1-3 and 7 apply to them too, the rest is for ships.

---

## 1. The game in one paragraph

Space Thunder is a **top-down survivor-style space shooter** (1920×1080, Godot 4). The player
flies a small ship in the middle of deep space and fights growing swarms of alien machines,
elites and huge bosses. The camera looks **straight down**. Every ship **rotates freely** in the
game to face its target, so all ship art must look right at any angle. The background is a
very dark, almost black starfield with tiny white and pale blue stars. The engine adds bloom/glow
(HDR), explosions, bullets, lasers and hit flashes on its own.

## 2. Style pillars

1. **Biomechanical.** Enemies are living machines: armored segments like an insect or deep‑sea
   creature, built from engineered metal plates, pipes, rivets and vents. They are organic in shape
   and mechanical in material: mandibles, claws, spines, ribbed segments, glowing organs behind
   armor slits.
2. **Dark body, glowing veins.** Hulls are dark (deep navy, gunmetal, muted violet). Color and
   life come from **thin emissive lines and dots** (cyan) set into the armor seams. The glow
   carries the readability on a dark background.
3. **Painted, crisp, readable.** Semi‑realistic hand‑painted 2D illustration with a **dark
   outline** around the silhouette and around major plates. Soft painted shading inside, clean edges
   outside. It should not be pixel art, flat vector, 3D render, photo or cel-shaded cartoon.
4. **Silhouette first.** A ship must be recognisable as a black shape at its in‑game size
   (section 5). Big, clear forms, then medium plates, then small details. The smaller the ship,
   the fewer details it gets.
5. **One family.** Every enemy looks like it comes from the same alien hive and fleet: same
   materials, same palette, same glow color. Variety comes from shape and role, not from new
   colors or materials.

## 3. Palette

Use these colors. Do not introduce new hues. The shares are measured from the Worm Boss.

| Role | Hex | Notes |
|---|---|---|
| Deepest shadow / outline | `#12121F` | outline and the darkest gaps |
| Hull dark | `#1F1F30` | main armor color (~35 % of the body) |
| Hull mid | `#2D2E3E` / `#3B3E4F` | plates facing the viewer |
| Violet plating | `#54515E` → `#6A5A8C` | secondary plates, muted purple tint |
| Steel highlight | `#928C98` | edge highlights, claws, mandibles |
| Cold blue metal | `#395C75` / `#54849C` | panels near the glow lines |
| **Emissive cyan (enemy glow)** | `#3CBED4` → `#6BDBEB` → `#A0E4EF` | seams, "eyes", organs, vents |
| Amber accent | `#CC9A6B` / `#D5C1A1` | sparse warm stripes, max ~2 % of the body |
| Thruster plasma | `#A0E4EF` → white core | engine flames: icy blue with a white center |

**Faction colors:**

- **Enemies and bosses (the hive):** cyan emissive, amber accents. An enraged boss can show
  more amber and red‑orange glow (`#FF7A4A`), but the engine also tints it, so keep it subtle.
- **Player (Thunder):** the same painted technique and materials, but a **lighter, polished
  hull** (steel `#9AA3B5`, white‑silver highlights) and **electric yellow / white emissive**
  (`#FFE36B` → `#FFF7D0`). This makes the player readable among cyan enemies instantly.
  *(Proposal. Decide once, then keep it for every player ship.)*

**Reserved colors. Never use them in ship art:**

- **Pure green (`#00FF00` and any saturated green).** It is the chroma-key background
  (section 7), and the game uses green for enemy acid projectiles.
- Pure red is used for damage numbers and hit effects. Avoid large red areas.

## 4. Camera, orientation, lighting

- **View:** strictly top‑down (dorsal view, looking straight down at the ship's back). A very
  slight 3/4 tilt that shows a bit of the sides is OK. Use no perspective vanishing, no horizon and no
  side view.
- **Orientation:** the ship's **front (nose, mouth, guns) points to the RIGHT** of the image. The
  game rotates it.
- **Symmetry:** ships should be roughly mirror-symmetric along the horizontal axis (left‑right
  of the ship = top‑bottom of the image). Creatures may curve (the worm does), but the head
  stays on the right.
- **Lighting:** soft and even, as if lit from the viewer, plus a subtle cool rim light on
  **both** sides. **No strong directional light and no cast shadows**, because the sprite
  rotates and a baked sun direction would look wrong.
- **No ground shadow, no reflections, no environment, no stars, no frame, no text.**

## 5. Size tiers (in game, on a 1920×1080 screen)

| Tier | Examples | Size in game (long side) | Detail level |
|---|---|---|---|
| Swarm / scout | Scout | 32–40 px | 2–3 big forms, 1–2 glow dots, thick outline |
| Fighter | Player, Guard, Hunter | 56–72 px | clear cockpit/head, 2 engines, a few glow lines |
| Elite | elite variants | 96–140 px | segmented armor, visible weapons |
| Boss | Boss, Worm Boss | 400–450 px | full detail, many segments, mouths and claws |

Generate art much bigger than the game size (Claude Code scales it down). Before approving a
design, **look at it shrunk to the in‑game size**. If the silhouette or the front/back is
unclear at that size, simplify.

## 6. Animation rules (most important for a consistent game)

The game builds every animation from the clips Gemini makes. A clip is an **animated GIF or a
video (MP4)**, and both work the same way. These rules make the clips usable:

1. **One clip per animation.** Idle, move, attack, death and so on are separate GIFs or MP4s.
   Don't put several actions in one clip.
2. **Every clip starts and ends on the approved key pose** (the static image from step 1). The
   game switches between animations at those moments, so they must match exactly. Loops (idle,
   move) also start and end on the same frame, so they loop with no jump.
3. **Animate in place.** The ship stays centered. It must not fly across the frame, rotate,
   zoom or drift. The game moves and rotates it. Fixed camera, no camera shake.
4. **Same canvas, same scale, same position** in every clip of one ship. The body must not
   grow or shrink between frames or between clips.
5. **GIF: 12 frames per second** (frame delay 80–83 ms). **Video: any frame rate** (24/30 fps
   is fine). Claude Code resamples to 12 fps and then interpolates to 24 fps. Keep changes between
   frames smooth and small; interpolation cannot fix big jumps.
6. **Motion comes from the body**: segments waving, plates opening, mandibles snapping, glow
   pulsing, thruster flames flickering, small hover bob (max ~2 % of size).
7. **No effects that the engine does itself.** Bullets, lasers, muzzle flashes, explosions,
   impact sparks, white hit flash, shields, **radar / scan waves and sweeping beams**, auras and
   bloom halos are all added by the game. A ship can *have* the device (a radar dish, a cannon);
   the signal or shot it emits must not be drawn. (Lesson from the Guard video: its baked radar
   waves and sweep had to be cut out, and they tinted the dishes where they overlapped.) A
   **charging glow** inside the mouth or gun and **thruster flames** are allowed and wanted.
8. **Glow stays inside the silhouette.** Glows are bright lines and dots on the hull with at most
   a thin soft edge. Large halos spill onto the background and break the transparency; the
   engine adds bloom.
9. **Death = breaking apart, not exploding.** Cracks open and plates separate. The glow
   flickers and dies, then pieces drift slightly apart. The engine adds the explosion and fire
   after the last frame.

### Animation set per tier

| Animation | Loop | Length @12 fps | Scout | Fighter / Player | Elite | Boss | Notes |
|---|---|---|---|---|---|---|---|
| `idle` | yes | 2–3 s (24–36 fr) | ✓ | ✓ | ✓ | ✓ | breathing, glow pulse, small bob |
| `move` | yes | 2–3 s | (= idle) | ✓ | ✓ | ✓ | thruster flames, body wave |
| `attack_<name>` | no | 0.8–1.5 s | – | ✓ | ✓ | ✓ ×3–4 | windup → hit → back to key pose |
| `charge` + `fire` | charge no, fire yes | 0.8 s + 1–2 s loop | – | – | opt. | ✓ for beams | mouth opens, glow builds; fire = held pose with flicker |
| `hurt` | no | 0.4–0.6 s | – | – | opt. | ✓ | short recoil, plates flinch, back to key pose |
| `special` | no | 1–2 s | – | – | opt. | ✓ | teleport, burrow, split, summon… |
| `enrage` | no | 1–1.5 s | – | – | – | ✓ | boss transforms; ends on the enraged key pose |
| `death` | no | 1–1.5 s | ✓ (short) | ✓ | ✓ | ✓ | breaking apart (rule 9) |

An **attack** is shaped as **anticipation** (pull back, open up, glow builds, ~40 %), then
**action** (snap forward or burst, ~20 %), then **recovery** (back to the key pose, ~40 %).
The game fires the projectile at the action moment.

## 7. Technical requirements for Gemini output

- **Background: one flat color, pure chroma green `#00FF00`**, the same in every frame.
  Never use a gradient, vignette, stars, texture or shadow on it. *(Proof from the Worm Boss:
  its GIF had a dark purple background close to the hull colors, and removing that background
  destroyed the dark armor. On flat green the cut‑out is clean.)*
- If Gemini makes the ship greenish because of the background, ask for **pure magenta
  `#FF00FF`** instead, and tell Claude Code which one you used.
- Ship centered, with **~8–10 % empty margin** on every side, in every frame. Nothing may
  touch or cross the canvas edge, including claws, flames and charging glows.
- Canvas: landscape **~2.3:1** for long creatures (worm), **square** for compact ships. Keep the
  same size for all clips of one ship.
- Key pose image: as large as Gemini gives (1024 px+). GIFs and videos: at least 400 px on the long side of
  the ship.
- Image rules: no text, no logos, no watermark, no UI, no frame around the image.

### GIF or video (MP4)?

Both work, and one ship can mix them (e.g. idle as a GIF, attack as an MP4).

| | GIF | MP4 (video) |
|---|---|---|
| Colors | only 256 → banding in glows and gradients | full color, **better quality** |
| Edges | hard, no soft transparency | soft, but compression smears green into the edges (Claude Code cleans it) |
| Frame rate | ask for 12 fps | whatever Gemini makes (24/30 fps), Claude Code resamples |
| Length | exactly the animation | often longer (e.g. 8 s), you can cut it (see below) |

**Rules for videos:**
- **Use image-to-video with the approved key pose as the first frame.** Ask for the last frame
  to be the same key pose, if your Gemini mode allows setting it.
- **Locked-off static camera**: no pan, zoom, dolly, orbit or shake. The ship stays in the center
  (also in landscape 16:9 video) and fills about 50–70 % of the frame height.
- **Flat `#00FF00` background** in every frame, as for GIFs. No lighting changes, flicker,
  particles, dust or lens flares on the background.
- Sound doesn't matter (it is ignored).
- **A video can be longer than the animation.** If only part of it is usable (e.g. the ship
  settles for 0.5 s, or the loop closes at 2.8 s of 8 s), tell Claude Code the part to use:
  *"move.mp4 from 0.5 s to 3.3 s"*. A loop has to end on a frame that matches its start.
- Prefer **one action per video**, as with GIFs. If Gemini only gives long videos, a single video
  with several actions separated by the key pose is acceptable; give Claude Code the times of
  each part.

## 8. Shape language by role

| Role | Shape | Reads as |
|---|---|---|
| Scout (swarm) | small dart / beetle, 1 glowing eye, short wings | fast and weak; comes in numbers |
| Guard | wide, heavy shell, armor plates up front | tanky and slow |
| Hunter | long and narrow, forward mandibles, big rear thrusters | fast and dangerous, chases you |
| Elite | larger version of a basic enemy + extra plating, more glow, amber accents | "this one is special" |
| Boss | huge creature or carrier with a clear head/mouth/weak spot, many segments | a fight on its own |
| Player | compact, clean, symmetric fighter or saucer; yellow‑white glow; no organic parts | "me", it should never be confused with an enemy |

## 9. Workflow and prompt templates

The pipeline: **Gemini key pose → Gemini animated GIFs or MP4 videos → Claude Code sprite sheet → game.**

### Step 1 — key pose (static image)

```
Using the Space Thunder art bible: create the KEY POSE of a <TIER> enemy called "<NAME>".
Role: <role from section 8, e.g. fast hunter that chases the player>.
Design: <shape idea: e.g. long narrow biomechanical hornet, forward mandibles, two rear thrusters>.
Strictly top-down view, front pointing RIGHT, mirror-symmetric, centered, 10% margin.
Painted semi-realistic 2D game sprite, dark outline, hull #1F1F30/#2D2E3E with muted violet plates,
thin cyan emissive seams (#3CBED4-#A0E4EF), tiny amber accents, soft even lighting, no cast shadow.
Flat pure #00FF00 background, no stars, no text. Must read clearly when shrunk to <SIZE> px.
```

Make 3–4 variants, shrink each to the in‑game size, and pick one. Save it as
`<name>_key.png`.

### Step 2 — animations (one GIF or MP4 per animation)

Attach the approved key pose, then for each animation in section 6.

**GIF:**

```
Animate THIS exact ship (attached key pose) as an animated GIF: "<animation>".
<what happens, e.g. idle: armor segments breathe slowly, cyan glow pulses, tiny hover bob>.
Rules: first and last frame = the attached key pose exactly; seamless loop (if loop);
animate in place - no movement across the frame, no rotation, no zoom, fixed camera;
same canvas size and position as the key pose; 12 fps, <N> frames, smooth small changes;
flat pure #00FF00 background in every frame; glow stays inside the silhouette;
no bullets, lasers, explosions or flashes (the game adds them).
```

**Video (MP4), image-to-video with the key pose as the first frame:**

```
Animate THIS exact ship (attached image = first frame) as a short video: "<animation>".
<what happens, e.g. move: armor segments wave like a centipede, icy blue thruster flames flicker>.
Locked-off static camera, top-down, no pan, no zoom, no camera shake.
The ship stays centered in place: no movement across the frame, no rotation, no size change.
The video ends on the same pose as the first frame (seamless loop / back to the key pose).
Flat pure #00FF00 background in every frame, no particles, no flicker, no lighting change.
Glow stays inside the silhouette. No bullets, lasers, explosions or flashes. Smooth, steady motion.
```

Check every clip before saving it:

- First and last frame look like the key pose.
- No pop when it loops.
- The ship doesn't drift or change size.
- The background is flat green everywhere.

Save the clips as `<name>_<animation>.gif` or `.mp4`, for example `hunter_idle.gif`,
`hunter_move.mp4`, `hunter_attack_bite.mp4`, `hunter_death.gif`. If you cut a video, write down
the part you want to use (seconds).

### Step 3 — Claude Code (sprite sheet and game)

Copy the files to `resources/<name>/source/` and ask Claude Code, e.g.:
*"Make sprite sheets from the GIFs and MP4s in resources/hunter/source/ and use them for the
Hunter (use the sprite-animation skill). hunter_move.mp4: use 0.5–3.3 s."* Claude Code then:

- removes the green background with `gif_to_sheet.py` (GIF, MP4, WebM and MOV), resamples videos to 12 fps and cuts them to the parts you named, giving every clip of the ship the same crop and pivot;
- interpolates to 24 fps and bridges loop seams;
- builds the Godot animations and picks the best frames where animations switch.

Tell Claude which clip is which animation, which parts of long videos to use, and which
background color you used if it isn't green.

## 10. Approval checklist

- [ ] Front points right, top‑down, symmetric, centered with margin.
- [ ] Only palette colors. Cyan glow for enemies, yellow‑white for the player. No green.
- [ ] Readable at in‑game size (shrink test). Front and back are obvious.
- [ ] Same family as the Worm Boss: dark armor, thin glowing seams, painted, outlined.
- [ ] Flat `#00FF00` background, nothing touches the edge.
- [ ] Every clip (GIF or MP4) starts and ends on the key pose. Loops have no jump. No drift,
  rotation, zoom or camera movement.
- [ ] No bullets, explosions, flashes or big halos baked in.

## 11. Reference: the Worm Boss (canonical example)

`resources/wormboss/source/worm_spritesheet_12fps.png` (frames 378×161 px, 12 fps; in game 1.1×,
~415 px long).

- **Design:** a giant armored space centipede. It has ribbed violet‑navy segments with
  cyan light strips between the plates, amber stripe accents, small spines along the back, and
  a head with four curved steel mandibles and glowing cyan "eyes". The tail ends in an icy blue
  plasma thruster.
- **What worked:** palette, glow amount, outline, painted detail, top‑down readability, head
  on the right.
- **What to fix in new ships:**
  - The worm came as **one continuous 10 s clip** (idle → body splits apart → flying with
    thrusters). Its sections did not start or end on a common pose. Claude Code had to generate
    bridge frames and time animation switches to hide the jumps. **Separate clips (GIF or MP4) that start and
    end on the key pose** (rule 6.2) avoid that.
  - Its background was dark purple and hard to remove. Use **flat green** (section 7).
  - It had **no dedicated attack animations** (spread shot, laser and mines reuse the flying
    frames). Request `attack_*` / `charge` / `fire` clips for bosses.

---

## 12. Pickups and upgrade icons

Two kinds of small art share one look:

- **Floor pickups.** They exist in the world. Enemies drop them and the player flies over them
  to take them: life, shield, magnet, nuke and the Xenite shard. They are tiny on screen and
  must pop out of a battlefield full of enemies, bullets and XP gems.
- **Upgrade icons.** They are UI. They appear on the cards of the level-up screen ("pick 1 of
  3"), in the HUD weapon slots and later in the Hangar. They are bigger, but the player
  compares three of them in a second, so each one must say what it does at a glance.

Both are **player technology** (human supplies and ship systems). The only exception is the
**Xenite shard**, a raw crystal of the alien hive. They use the same painted, outlined
technique as the ships (section 2.3), but they are **not ships**, so sections 4–6 don't
apply: no top-down view, no "front points right", no animation set.

### 12.1 Shared style rules

1. **One symbol per image.** Use a single bold emblem that reads as a black silhouette at 24 px: a
   cross, a shield, a horseshoe magnet, a warhead. No scenes, no ships, no hands, no letters
   or numbers. The game writes the text on the card.
2. **Front view, upright, centered.** It is an icon, not a top-down sprite. A slight 3/4 tilt
   for depth is fine. Floor pickups wobble ±15° in the game, so keep them upright and don't
   rotate them.
3. **Lit from the front**, soft. A thin bright rim on the top edge, darker bottom edge. There is no
   cast shadow and no ground.
4. **Dark outline** (`#12121F`, thick: about 4 % of the image width) around the silhouette, so
   it separates from any background.
5. **Glow stays inside the shape** (section 6.8). Bright emissive core and seams, with at most a
   thin soft edge. The engine adds bloom; a baked halo makes a muddy square in the game.
6. **Fill the canvas evenly.** The symbol takes about 80 % of a square canvas with an even
   ~10 % margin. Make every icon of the set the same visual size, so no icon looks bigger or
   more important on a card.
7. **Background: flat `#00FF00`** (section 7). Nothing touches the edge. **No green in the
   icon itself**, including regen. It would be cut out with the background.
8. **Same set, same session.** Generate a whole group (e.g. all floor pickups, all stat
   icons) in one Gemini conversation, and attach an already approved icon as a style reference
   for the next ones. Line thickness, lighting and saturation must match across the set.

### 12.2 Category colors

Color tells the player the category before they read anything. Keep the main color on the
emblem's emissive parts and use the metal colors from section 3 for the body.

| Category | Main color (emissive) | Used for |
|---|---|---|
| **Survival** | rose `#FF5C7A` → `#FFB3C1` | life pickup, hull plating, regen (nanobots), repair kit |
| **Defense** | electric blue `#3D8BFF` → `#A8CCFF` | shield pickup, shield capacitor, armor |
| **Offense** | player yellow `#FFE36B` → `#FFF7D0`, hot orange `#FF9A3C` | damage, precision, lethality, overclock, multishot |
| **Utility** | silver‑white `#E8ECF5` with a yellow core `#FFE36B` | thrusters (speed), tractor beam / magnet |
| **Weapons** | player yellow‑white, with the projectile color of that weapon | blaster, cannon, nova, missiles, fireworks, orbit |
| **Danger / nuke** | hazard orange `#FF7A2E`, black and yellow hazard stripes | nuke pickup only |
| **Xenite (alien)** | violet crystal `#8E5CFF` → `#D98CFF`, a thin cyan heart `#6BDBEB` | Xenite shard, Xenite scanner |

Avoid **enemy cyan** as the main color of any player item (it is the hive's color), and avoid
**pure red** (damage numbers). Survival is rose, not red.

### 12.3 Floor pickups (in the world)

**In game:** about **28–36 px** on screen, wobbling, on a near‑black starfield with bloom.
**Deliver:** a square key image (1024 px+). Claude Code cuts it out and saves it as a 96×96 PNG in
`resources/perks/`. The game scales it to 0.3.

All floor pickups except the Xenite shard share one **base shape**: a small **rounded
hexagonal supply token** (a thick metal rim, steel `#9AA3B5`, dark inner face) with the emblem
glowing in its center. The shared token teaches the player that this shape is something to grab.
The rim gets a thin ring in the category color.

| Pickup | File | Emblem in the token | Color |
|---|---|---|---|
| Life | `perks/pickup_life.png` | a rounded repair cross made of plates, a small heart‑shaped core | survival rose |
| Shield | `perks/pickup_shield.png` | a kite‑shaped energy shield with hexagonal cells | defense blue |
| **Magnet** | `perks/pickup_magnet.png` | a chunky horseshoe magnet, steel body, glowing yellow‑white pole tips, 2–3 short curved field lines **inside** the token | utility silver + yellow |
| **Nuke** (bomb) | `perks/pickup_nuke.png` | a round warhead seen from the front with a three‑blade radiation symbol, hazard stripes on the token rim, a glowing orange core | danger orange |
| Xenite shard | `perks/xenite.png` | **no token.** A cluster of 2–3 sharp violet crystal spikes grown out of a dark hive‑armor chip, with a thin cyan glow inside | xenite violet |

**The nuke must be the most striking pickup:** it has the strongest contrast, the hazard pattern and the
biggest glow core. It clears the whole screen, and the player should spot it from far away. The
magnet comes second.

**Optional: idle shimmer clip.** It is not required, since the game already wobbles and blinks
pickups. If you want one, make a 1–1.5 s seamless loop GIF (12 fps) or MP4: the glow pulses
and a glint sweeps across the metal. No movement, no rotation, no size change, first frame =
key image (section 6 rules 2–5).

### 12.4 Upgrade icons (cards, HUD, Hangar)

**In game:** the card icon is **110 px** high on a dark navy card (`#141A33`, `#262D59` when
selected, border `#4D66B3`), so dark navy parts of an icon need the outline and a light rim to
stand out. Weapon icons also appear in the HUD at **44 px**, so a weapon icon must still read at
that size. **Deliver:** a square key image (1024 px+). Claude Code saves a 256×256 PNG with
transparency in `resources/perks/`.

Card icons have **no token and no background plate**, because the card is the frame. The emblem
floats freely. Stat icons show the ship *system* that gets better; weapon icons show the
*weapon or its shot*.

| Upgrade (card title) | id | File | Emblem idea | Color |
|---|---|---|---|---|
| Damage | `damage` | `perks/icon_damage.png` | an energy blade / cannon shell with an up‑chevron | offense |
| Precision | `crit_chance` | `perks/icon_precision.png` | a targeting reticle with a glowing center dot | offense |
| Lethality | `crit_mult` | `perks/icon_lethality.png` | a cracked armor plate struck by a bright spark star | offense orange |
| Thrusters | `speed` | `perks/icon_thrusters.png` | an engine nozzle with a white‑yellow plasma flame and speed lines | utility |
| Overclock | `fire_rate` | `perks/icon_overclock.png` | a glowing reactor chip with a lightning bolt | offense |
| Multishot | `projectile` | `perks/icon_multishot.png` | three bullets fanning out from one point | offense |
| Hull plating | `max_life` | `perks/icon_hull.png` | layered hull plates with a rose cross / heart core | survival |
| Nanobots | `regen` | `perks/icon_nanobots.png` | a swarm of tiny repair drones around a rose cross | survival |
| Armor | `armor` | `perks/icon_armor.png` | a thick riveted armor plate, steel with a blue seam | defense |
| Shield capacitor | `shield` | `perks/icon_shield.png` | a battery cell with a hex shield emblem | defense |
| Tractor beam | `magnet` | `perks/icon_tractor.png` | the horseshoe magnet from 12.3 with a pull arrow (same design, no token) | utility |
| Repair kit (all maxed) | `heal` | `perks/icon_repair.png` | a toolbox / med canister with a rose cross | survival |
| Blaster | `w_blaster` | `perks/icon_blaster.png` | twin yellow‑white bolts | weapons |
| Heavy cannon | `w_cannon` | `perks/icon_cannon.png` | a fat cannon shell / barrel | weapons |
| Nova | `w_nova` | `perks/icon_nova.png` | a ring of bullets around a bright center | weapons |
| Missiles | `w_missiles` | `perks/icon_missiles.png` | a homing rocket with a curved exhaust trail | weapons |
| Fireworks | `w_fireworks` | `perks/icon_fireworks.png` | a shell bursting into a star of shrapnel | weapons + orange |
| Orbit | `w_orbit` | `perks/icon_orbit.png` | two or three blades circling a center point | weapons |

**Hangar upgrades** (permanent, bought with Xenite) can reuse the matching stat icon:

- hull → Hull plating
- shield → Shield capacitor
- damage → Damage
- fire_rate → Overclock
- speed → Thrusters
- armor → Armor
- regen → Nanobots
- crit → Precision
- magnet → Tractor beam

Only **Xenite scanner** (`salvage`) has its own icon (`perks/icon_xenite_scanner.png`): a scanner
dish locked onto a violet crystal, in xenite violet plus silver.

The Hangar rows show these icons (`icon` in `singletons/meta_progress.gd`). To redo an icon, generate
it again and keep the file name; the sheets used for the first set are in `resources/perks/source/`.

### 12.5 Prompt templates

**Floor pickup:**

```
Using the Space Thunder art bible (section 12): create a FLOOR PICKUP icon "<NAME>".
Base: small rounded hexagonal supply token, thick steel rim (#9AA3B5) with a thin <COLOR> ring,
dark inner face (#1F1F30). In its center: <EMBLEM from table 12.3>, glowing <COLOR> core.
Front view, upright, centered, symbol fills 80% of a square canvas, 10% margin.
Painted semi-realistic 2D game icon, thick dark outline #12121F, soft front light, no cast shadow.
Glow stays inside the shape, no halo. No text, no numbers, no green in the icon.
Flat pure #00FF00 background. Must read clearly when shrunk to 30 px.
```

**Upgrade icon:**

```
Using the Space Thunder art bible (section 12): create an UPGRADE ICON "<CARD TITLE>".
Emblem: <EMBLEM from table 12.4>. Category color: <COLOR from 12.2>, metal parts in steel
#9AA3B5 / dark hull #2D2E3E. No token, no background plate, the emblem floats alone.
Front view (slight 3/4 tilt OK), upright, centered, fills 80% of a square canvas, 10% margin.
Painted semi-realistic 2D game icon, thick dark outline #12121F, soft front light, no cast shadow.
Glow stays inside the shape, no halo. No text, no numbers, no green in the icon.
Flat pure #00FF00 background. Must read clearly at 110 px and still at 44 px.
Match the style of the attached approved icon.
```

Make 3–4 variants and shrink them to the in‑game size (30 px for pickups, 110 px and 44 px for
icons). Pick the one that reads best. Save it as `<name>_key.png`.

### 12.6 Delivery to Claude Code

Put the approved images in `resources/perks/source/` (Claude Code adds a `.gdignore` there so
the sources are not loaded by the game) and say, e.g.:
*"Cut out the icons in resources/perks/source/ (green background) and use them: magnet_key.png
for the magnet pickup and the Tractor beam card, nuke_key.png for the bomb pickup."*
Claude Code then:

- removes the background;
- trims the image to the same margin as the rest of the set;
- scales it (96 px pickups, 256 px icons) and saves it to `resources/perks/`;
- points the perk scene or the upgrade entry in `singletons/upgrades.gd` at the new file.

### 12.7 Checklist for pickups and icons

- [ ] One bold symbol, readable at in‑game size (30 px pickup, 110 / 44 px icon).
- [ ] Category color from 12.2. No green, no enemy cyan, no pure red.
- [ ] Floor pickups: hex token (except the Xenite shard); the nuke is the most eye‑catching.
- [ ] Upgrade icons: no token or plate; same visual size as the rest of the set.
- [ ] Thick dark outline, glow inside the shape, no halo, no text.
- [ ] Flat `#00FF00` background, ~10 % margin, nothing touches the edge.
