# Space Thunder — Art Bible, Level 2 "Asteroid Siege" (rock bug enemies and bosses)

> **How to use this file in Gemini:** paste the whole document at the start of the conversation
> (or put it into the instructions of a Gem) and say: *"Follow this art bible for every image and
> animation you make."* Then use the prompt templates in section 10.
> Attach **one of the level 2 asteroids** (`resources/background/level2/asteroid_medium.png` or
> `asteroid_huge.png`) as a material reference for the rock, and a **Worm Boss frame** (level 1) as a
> reference for the painted technique, outline and glow, whenever Gemini starts drifting.
> Player ship, pickups and upgrade icons don't change: they are in `art_level1.md`.

---

## 1. The game in one paragraph

Space Thunder is a **top-down survivor-style space shooter** (1920×1080, Godot 4). The player
flies a small ship and fights growing swarms of alien creatures, elites and huge bosses. The camera
looks **straight down**. Every ship **rotates freely** in the game to face its target, so all ship
art must look right at any angle. The engine adds bloom/glow (HDR), explosions, bullets, lasers and
hit flashes on its own.

## 2. Level 2 setting

The alien hive retreated from First Contact into the **Hilda asteroid belt** and dug in. It infests
the rocks with black, root-like growths full of cold cyan light, and it breeds a new caste there:
**rock bugs**. These are insects, mites, beetles and mantises whose shells are **real asteroid
stone**. The hive grows them inside the rocks, and its black biomechanical tissue and cyan veins
run through the cracks of their stone armor.

**The background** (already done) is near-black space with a faint diagonal brown dust band and
dim, soft, outline-free asteroids (some covered with hive growth). The enemies fly over it, so
they must stand out from it at once (section 3, pillar 4).

## 3. Style pillars

1. **Stone insects.** Every enemy is a bug (mite, beetle, wasp, mantis, centipede, trilobite) whose
   carapace is made of **cratered, cracked asteroid rock**: heavy plates, chipped edges, small
   craters and pits, sharp rock spikes. The bug's anatomy reads clearly: legs, mandibles,
   segments, antennae and wings (made of thin stone or crystal slabs).
2. **Hive tissue in the cracks.** Between the stone plates and in the cracks there is **black,
   glossy biomechanical tissue** (tubes, roots, ribs, joints), like the hive growth on the
   background asteroids. The color and life come from **thin cyan emissive veins and dots** in
   that tissue: eyes, joints, cracks and organs. The glow carries readability on the dark background.
3. **Painted, crisp, readable.** Semi-realistic hand-painted 2D illustration with a **dark
   outline** around the silhouette and around major plates. Soft painted shading inside, clean
   edges outside. It should not be pixel art, flat vector, 3D render, photo or cel-shaded cartoon.
4. **Brighter and sharper than the scenery.** The background rocks are dim, soft and have no
   outline. The enemies have the **dark outline, lighter rock highlights on plate edges, and
   bright cyan glow**. A player must never mistake an enemy for a background rock or the other way
   round.
5. **Silhouette first.** A bug must be recognizable as a black shape at its in-game size
   (section 6): big, clear forms first, then medium plates, then small details. The smaller the
   enemy, the fewer the details. Legs and mandibles must read, not dissolve into rock lumps.
6. **One family.** Every level 2 enemy comes from the same rock brood: same stone, same black hive
   tissue, same cyan glow. Variety comes from shape and role, not from new colors or materials.
   They are relatives of the level 1 hive (same glow color, same outline and painting technique),
   but in stone instead of metal.

## 4. Palette

Use these colors. Do not introduce new hues. The rock colors are measured from the level 2
asteroid art.

| Role | Hex | Notes |
|---|---|---|
| Deepest shadow / outline | `#121314` | outline, deep cracks |
| Hive tissue | `#0E0F12` → `#1E2026` | black glossy tissue with a cold blue-grey sheen |
| Rock dark | `#242423` | main stone color (~35 % of the body) |
| Rock mid | `#393734` / `#595350` | plates facing the viewer |
| Rock light | `#756F69` → `#8E8780` | plate edges, crater rims, spikes, mandible tips (brighter than the background rocks) |
| **Emissive cyan (hive glow)** | `#3CBED4` → `#6BDBEB` → `#A0E4EF` | veins in cracks, eyes, joints, organs |
| Ore accent | `#CC9A6B` / `#D5C1A1` | sparse warm mineral flecks or ore veins in the stone, max ~3 % of the body |
| Thruster / wing plasma | `#A0E4EF` → white core | if a bug has jet vents: icy blue with a white center |

**Faction colors:**

- **Rock bugs and bosses:** cyan glow, warm ore accents. An enraged boss may show more amber and
  red‑orange glow (`#FF7A4A`) in its cracks (lava-like), but the engine also tints it, so keep it
  subtle.
- **Player:** unchanged (see `art_level1.md`): light polished hull, yellow-white glow.

**Reserved colors. Never use them in enemy art:**

- **Pure green (`#00FF00` and any saturated green), including mossy or lichen green.** It is the
  chroma-key background (section 8), and the game uses green for enemy acid projectiles. Keep the
  cyan clearly blue-ish: a teal that drifts toward green gets cut out with the background.
- Pure red is used for damage numbers and hit effects. Avoid large red areas.

## 5. Camera, orientation, lighting

- **View:** strictly top-down (dorsal view, looking straight down at the bug's back). A very
  slight 3/4 tilt that shows a bit of the sides is OK. Use no perspective vanishing, no horizon and
  no side view.
- **Orientation:** the bug's **front (head, mandibles, stinger aim) points to the RIGHT** of the
  image. The game rotates it.
- **Symmetry:** bugs are mirror-symmetric along the horizontal axis (left‑right of the bug =
  top‑bottom of the image). Legs come in symmetric pairs. Long creatures may curve, but the head
  stays on the right.
- **Lighting:** soft and even, as if lit from the viewer, plus a subtle cool rim light on
  **both** sides. **No strong directional light and no cast shadows**, because the sprite rotates
  and a baked sun direction would look wrong. Craters are shaded softly from the inside, not by a
  sun.
- **No ground shadow, no reflections, no environment, no dust clouds, no stars, no frame, no text.**

## 6. Level 2 roster and size tiers (in game, on a 1920×1080 screen)

Each level 2 enemy takes over the role of a level 1 enemy, so the game logic stays the same.

| Enemy | Replaces (role) | Tier | Size in game (long side) | Shape | Detail level |
|---|---|---|---|---|---|
| **Pebble Mite** | Scout (swarm) | swarm | 32–40 px | a round pebble-shelled tick: one smooth stone dome, 6 short legs, 1 big cyan eye at the front | 2–3 big forms, 1–2 glow dots, thick outline |
| **Boulder Beetle** | Guard (kamikaze tank: crawls in, overloads and blows up) | fighter | 64–72 px | wide, heavy boulder carapace split in two wing-case halves, short thick legs, a blunt plow-like head; a cyan glow seam along the split | heavy plates up front, few glow lines |
| **Shard Wasp** | Hunter (chaser) | fighter | 56–68 px | long, narrow wasp: sharp flint-shard wings (thin translucent stone slabs edged in cyan), segmented stone abdomen with a stinger, forward mandibles, two vents at the back | clear head, wings, stinger; few glow lines |
| Elite variants | elite | elite | 96–140 px | larger version of a basic bug with extra rock spikes, more cracks with hive tissue, more glow, ore accents | segmented armor, visible weapons |
| **Quarry Mantis** | mid boss (5:00) | boss | 400–450 px | a giant mantis built of rock slabs: two huge stone scythe arms folded at the front, a triangular head with cyan compound eyes, a long segmented abdomen, hive tissue in every joint | full detail, many segments, claws, mouth |
| **Bedrock Queen** | final boss (10:00) | boss | 420–480 px | a colossal trilobite / woodlouse queen: a wide oval, a stack of overlapping cratered rock segments, a head shield with crown spikes, rows of legs at the edges, an X-shaped crack across the back full of black hive roots and cyan light (like the huge background asteroid), egg sacs glowing under the plates | full detail, many segments, mouths |

Generate art much bigger than the game size (Claude Code scales it down). Before approving a
design, **look at it shrunk to the in‑game size**. If the silhouette or the front/back is unclear
at that size, simplify. A rock bug shrunk too far turns into a gray blob: keep the legs and the
mandibles big and the outline thick.

## 7. Animation rules (most important for a consistent game)

The game builds every animation from the clips Gemini makes. A clip is an **animated GIF or a
video (MP4)**, and both work the same way. These rules make the clips usable:

1. **One clip per animation.** Idle, move, attack, death and so on are separate GIFs or MP4s.
   Don't put several actions in one clip.
2. **Every clip starts and ends on the approved key pose** (the static image from step 1). The
   game switches between animations at those moments, so they must match exactly. Loops (idle,
   move) also start and end on the same frame, so they loop with no jump.
3. **Animate in place.** The bug stays centered. It must not walk or fly across the frame, rotate,
   zoom or drift. The game moves and rotates it. Fixed camera, no camera shake.
4. **Same canvas, same scale, same position** in every clip of one bug. The body must not grow or
   shrink between frames or between clips.
5. **GIF: 12 frames per second** (frame delay 80–83 ms). **Video: any frame rate** (24/30 fps is
   fine). Claude Code resamples to 12 fps and then interpolates to 24 fps. Keep changes between
   frames smooth and small; interpolation cannot fix big jumps.
6. **Motion comes from the body**: legs scuttling in a walk cycle, wings buzzing, mandibles
   snapping, stone plates lifting and settling, glow pulsing in the cracks, small hover bob (max ~2 %
   of size). Stone is heavy: plates move slowly and stiffly; legs, antennae and wings move fast.
7. **No effects that the engine does itself.** Bullets, spit, thrown rocks, lasers, muzzle
   flashes, explosions, impact sparks, dust clouds, debris flying off, white hit flash, shields,
   scan waves and bloom halos are all added by the game. A bug can *have* the weapon (a stinger, a
   spitting mouth); the shot it fires must not be drawn. A **charging glow** inside the mouth,
   stinger or cracks is allowed and wanted.
8. **Glow stays inside the silhouette.** Glows are bright lines and dots in the cracks and tissue
   with at most a thin soft edge. Large halos spill onto the background and break the
   transparency; the engine adds bloom.
9. **Death = crumbling apart, not exploding.** The cracks widen, stone plates split off, the cyan
   glow flickers and dies, the legs curl in, then the pieces drift slightly apart. No dust cloud
   (the engine adds the explosion and debris after the last frame).

### Animation set per tier

| Animation | Loop | Length @12 fps | Mite | Beetle / Wasp | Elite | Boss | Notes |
|---|---|---|---|---|---|---|---|
| `idle` | yes | 2–3 s (24–36 fr) | ✓ | ✓ | ✓ | ✓ | breathing plates, glow pulse, antennae twitch, small bob |
| `move` | yes | 1–2 s | ✓ (scuttle) | ✓ | ✓ | ✓ | leg walk cycle or wing buzz, abdomen sway |
| `attack_<name>` | no | 0.8–1.5 s | – | ✓ | ✓ | ✓ ×3–4 | windup → hit → back to key pose |
| `charge` + `fire` | charge no, fire yes | 0.8 s + 1–2 s loop | – | – | opt. | ✓ for beams | mouth/cracks open, glow builds; fire = held pose with flicker |
| `hurt` | no | 0.4–0.6 s | – | – | opt. | ✓ | short recoil, plates flinch, back to key pose |
| `special` | no | 1–2 s | – | – | opt. | ✓ | curl into a ball, burrow, shed plates, lay eggs, summon |
| `enrage` | no | 1–1.5 s | – | – | – | ✓ | cracks split open, glow turns amber-orange; ends on the enraged key pose |
| `death` | no | 1–1.5 s | ✓ (short) | ✓ | ✓ | ✓ | crumbling apart (rule 9) |

An **attack** is shaped as **anticipation** (pull back, raise claws, glow builds, ~40 %), then
**action** (snap forward or burst, ~20 %), then **recovery** (back to the key pose, ~40 %). The
game fires the projectile at the action moment.

### Boss attack ideas (one clip each)

- **Quarry Mantis:** `attack_scythe` (both scythes slash forward in a cross), `attack_spit`
  (head pulls back, mouth glows, spits: the game fires a spread of rock shards), `charge` + `fire`
  (eyes and chest crack glow for a beam), `special` (scythes cross over the head, plates lock:
  armored guard pose), `enrage`, `death`.
- **Bedrock Queen:** `attack_slam` (head shield rises and slams down: the game spawns a shock
  ring), `attack_brood` (back plates lift, the egg sacs pulse: the game spawns Pebble Mites),
  `special_curl` (rolls into a stone ball and back: the game makes it charge), `charge` + `fire`
  (the X-crack on the back opens and glows: a beam), `enrage` (the crack splits wider, amber light),
  `death`.

## 8. Technical requirements for Gemini output

- **Background: one flat color, pure chroma green `#00FF00`**, the same in every frame. Never use a
  gradient, vignette, stars, texture or shadow on it. (A dull green like `#35B43F` with a lighter
  square, as on one of the background asteroids, still works but costs an extra cleanup step.)
- If Gemini makes the bug greenish because of the background (gray stone picks up green easily),
  ask for **pure magenta `#FF00FF`** instead, and tell Claude Code which one you used.
- Bug centered, with **~8–10 % empty margin** on every side, in every frame. Nothing may touch or
  cross the canvas edge, including legs, antennae, scythes, wings and charging glows.
- Canvas: **square** for compact bugs (mite, beetle, queen), landscape **~2:1** for long ones
  (wasp, mantis). Keep the same size for all clips of one bug.
- Key pose image: as large as Gemini gives (1024 px+). GIFs and videos: at least 400 px on the long
  side of the bug.
- Image rules: no text, no logos, no watermark, no UI, no frame around the image.

### GIF or video (MP4)?

Both work, and one bug can mix them (e.g. idle as a GIF, attack as an MP4).

| | GIF | MP4 (video) |
|---|---|---|
| Colors | only 256 → banding in glows and stone gradients | full color, **better quality** |
| Edges | hard, no soft transparency | soft, but compression smears green into the edges (Claude Code cleans it) |
| Frame rate | ask for 12 fps | whatever Gemini makes (24/30 fps), Claude Code resamples |
| Length | exactly the animation | often longer (e.g. 8 s), you can cut it (see below) |

**Rules for videos:**
- **Use image-to-video with the approved key pose as the first frame.** Ask for the last frame to
  be the same key pose, if your Gemini mode allows setting it.
- **Locked-off static camera**: no pan, zoom, dolly, orbit or shake. The bug stays in the center
  (also in landscape 16:9 video) and fills about 50–70 % of the frame height.
- **Flat `#00FF00` background** in every frame. No lighting changes, flicker, particles, dust or
  lens flares on the background. Stone bugs tempt video models to add dust and falling pebbles:
  forbid it in every prompt.
- Sound doesn't matter (it is ignored).
- **A video can be longer than the animation.** If only part of it is usable, tell Claude Code
  the part to use: *"mite_move.mp4 from 0.5 s to 2.0 s"*. A loop has to end on a frame that matches
  its start.
- Prefer **one action per video**. If Gemini only gives long videos, one video with several actions
  separated by the key pose is acceptable; give Claude Code the times of each part.

## 9. Shape language by role

| Role | Shape | Reads as |
|---|---|---|
| Swarm (Pebble Mite) | small round dome, tiny legs, one bright eye | fast and weak; comes in numbers |
| Tank (Boulder Beetle) | wide, heavy, blunt; thickest stone up front | tanky and slow, hard to kill |
| Chaser (Shard Wasp) | long and narrow, sharp wings, stinger, forward mandibles | fast and dangerous, chases you |
| Elite | larger version of a basic bug + spikes, more cracks and glow, ore accents | "this one is special" |
| Boss | huge creature with a clear head, mouth or glowing weak spot (crack), many segments | a fight on its own |

The rock bugs are rounder and heavier than the level 1 machines; the edges are broken stone, not
cut metal. Sharp, bright parts (mandibles, stinger, scythes, spikes) show where the danger is.

## 10. Workflow and prompt templates

The pipeline: **Gemini key pose → Gemini animated GIFs or MP4 videos → Claude Code sprite sheet → game.**

### Step 1 — key pose (static image)

```
Using the Space Thunder level 2 art bible: create the KEY POSE of a <TIER> enemy called "<NAME>".
Role: <role from section 9>. Design: <shape from the roster in section 6>.
A biomechanical insect whose carapace is made of cratered, cracked asteroid stone (#242423, #393734,
#595350, lighter edges #756F69-#8E8780), with black glossy hive tissue (#0E0F12) in the cracks and
joints and thin cyan emissive veins and eyes (#3CBED4-#A0E4EF), tiny warm ore flecks (#CC9A6B).
Strictly top-down view, front pointing RIGHT, mirror-symmetric, centered, 10% margin.
Painted semi-realistic 2D game sprite, dark outline #121314, soft even lighting, no cast shadow.
Flat pure #00FF00 background, no dust, no stars, no text. No green in the creature.
Must read clearly when shrunk to <SIZE> px.
```

Make 3–4 variants each, shrink them to the in‑game size, and pick one. Save it as
`<name>_key.png`, e.g. `pebble_mite_key.png`.

### Step 2 — animations (one GIF or MP4 per animation)

Attach the approved key pose, then for each animation in section 7.

**GIF:**

```
Animate THIS exact creature (attached key pose) as an animated GIF: "<animation>".
<what happens, e.g. move: six legs scuttle in a fast walk cycle, stone dome bobs slightly, cyan eye pulses>.
Rules: first and last frame = the attached key pose exactly; seamless loop (if loop);
animate in place - no movement across the frame, no rotation, no zoom, fixed camera;
same canvas size and position as the key pose; 12 fps, <N> frames, smooth small changes;
flat pure #00FF00 background in every frame; glow stays inside the silhouette;
no projectiles, dust, falling pebbles, explosions or flashes (the game adds them).
```

**Video (MP4), image-to-video with the key pose as the first frame:**

```
Animate THIS exact creature (attached image = first frame) as a short video: "<animation>".
<what happens, e.g. attack_scythe: the mantis raises both stone scythes, the cracks glow brighter,
then slashes them forward in a cross and returns to the starting pose>.
Locked-off static camera, top-down, no pan, no zoom, no camera shake.
The creature stays centered in place: no movement across the frame, no rotation, no size change.
The video ends on the same pose as the first frame (seamless loop / back to the key pose).
Flat pure #00FF00 background in every frame, no dust, no debris, no particles, no flicker,
no lighting change. Glow stays inside the silhouette. No projectiles, explosions or flashes.
Smooth, steady motion.
```

Check every clip before saving it:

- First and last frame look like the key pose.
- No pop when it loops.
- The bug doesn't drift or change size.
- The background is flat green everywhere, no dust.

Save the clips as `<name>_<animation>.gif` or `.mp4`, for example `pebble_mite_move.gif`,
`shard_wasp_attack_sting.mp4`, `quarry_mantis_attack_scythe.mp4`, `bedrock_queen_death.mp4`.
If you cut a video, write down the part you want to use (seconds).

### Step 3 — Claude Code (sprite sheet and game)

Copy the files to `resources/<name>/source/` (e.g. `resources/pebble_mite/source/`) and ask
Claude Code, e.g.: *"Make sprite sheets from the GIFs and MP4s in resources/pebble_mite/source/
and use them for the Pebble Mite in level 2 (use the sprite-animation skill). pebble_mite_move.mp4:
use 0.5–2.0 s."* Claude Code then:

- removes the green background, resamples videos to 12 fps and cuts them to the parts you named,
  giving every clip of the bug the same crop and pivot;
- interpolates to 24 fps and bridges loop seams;
- builds the Godot animations and picks the best frames where animations switch.

Tell Claude which clip is which animation, which parts of long videos to use, and which background
color you used if it isn't green.

## 11. Approval checklist

- [ ] Front points right, top‑down, symmetric, centered with margin.
- [ ] It is clearly a **bug** (legs, head, mandibles or wings read) made of **stone**, with black
  hive tissue and cyan glow in the cracks.
- [ ] Only palette colors. No green, no moss, teal stays blue-ish.
- [ ] Readable at in‑game size (shrink test). Front and back are obvious.
- [ ] Stands out from the background asteroids: dark outline, lighter plate edges, bright glow.
- [ ] Flat `#00FF00` background, nothing touches the edge.
- [ ] Every clip (GIF or MP4) starts and ends on the key pose. Loops have no jump. No drift,
  rotation, zoom or camera movement.
- [ ] No projectiles, dust, debris, explosions, flashes or big halos baked in.

## 12. References

- **Material:** `resources/background/level2/asteroid_medium.png` and `asteroid_huge.png`
  (stone, craters, black hive roots with cyan veins). The enemies use the same stone and hive
  tissue, but **brighter, sharper and outlined**.
- **Technique:** the level 1 Worm Boss, `resources/wormboss/source/worm_spritesheet_12fps.png`
  (painted detail, outline, glow amount, top-down readability, head on the right).
- **Lessons from level 1** (`art_level1.md` section 11): separate clips that start and end on the
  key pose, a flat green background, and dedicated `attack_*` / `charge` / `fire` clips for bosses.
- **Lessons from the Quarry Mantis** (`resources/quarry_mantis/source/`): one 8 s video with all actions in
  order (idle, walk, slash, spit, beam charge, death), each returning to the key pose, works well for a
  boss when Gemini only gives long videos. Video backgrounds come out as a dull green (`#29D027`), which
  Claude Code handles. For debris, an **exploded view** of the key pose (every piece apart on green) is
  cut into the debris atlas directly. Gemini still tints thin translucent parts (the wings) a little
  green, so ask for "blue-cyan, not teal" wings.
