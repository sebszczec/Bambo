---
name: sprite-animation
description: Turn Gemini animated GIFs/videos or a grid sprite sheet (e.g. an AI-generated clip with a frameWidth/columns json) into smooth Godot AnimatedSprite2D animations for Space Thunder - find unnatural jumps and loop seams, double the frame rate with optical-flow in-betweens, bridge loop seams, pick the best entry/exit frames so switching animations (move -> attack, attack -> idle) looks natural, regenerate the SpriteFrames in a .tscn and measure the switches in the running game. Use when adding/replacing enemy or boss sprite sheets or when animations look choppy or pop.
---

# Sprite sheet -> smooth Godot animations

Scripts live in `.claude/skills/sprite-animation/scripts/` (Python 3, `pip install pillow numpy opencv-python`).
Run them with `python -I` from the repo root. No downloaded binaries (RIFE etc.) - the auto mode classifier blocks running them; OpenCV DIS optical flow is good enough for 2x.

Sheet json format (what the art tool exports, and what the scripts write):
`{"image": "x.png", "frameWidth", "frameHeight", "columns", "rows", "frameCount", "fps"}` - image path relative to the json.

## Where the art comes from
The user designs ships in **Google Gemini** following `art_bible.md` (repo root): first a static key pose, then **one clip per animation** (idle, move, attack_*, death...) - an animated GIF (12 fps) **or an MP4 video** (any fps, often longer than the animation) - that starts and ends on the key pose, flat `#00FF00` background, nose pointing right. Claude Code turns the GIFs into the sheet. When new art breaks those rules (dark background, one long clip, drifting ship) tell the user which rule to ask Gemini for, and keep `art_bible.md` up to date with what was learned.

0. **GIFs / videos -> sheet**: `python -I .../gif_to_sheet.py resources/<x>/source/<x>_12fps.json resources/<x>/source/<x>_idle.gif resources/<x>/source/<x>_move.mp4 ... --preview <scratch>/prev.png`
   - GIF, MP4, WebM, MOV can be mixed; every clip is resampled to `--fps 12` (Gemini videos are 24/30 fps). Cut long videos with `--trim <clip>=START:END` (seconds, clip = file name without extension) - the user names the usable part, otherwise find where the clip leaves and returns to the key pose with `analyze.py` on the untrimmed sheet. Compression leaves green on the edges: despill handles most of it, `--shrink 1` if a fringe is left.
   - one sheet for all clips of a ship, prints each clip's frame range (also `"clips"` in the json) - those ranges are the animations; idle/move clips loop, attacks start and end on the key pose so the switches are natural without bridges.
   - same crop for all clips (union of visible pixels) keeps size and pivot; all clips must have the same canvas.
   - `--key auto` for another flat background, `--width` to scale down (small ships: about 2-4x the in-game size, see art_bible.md tiers).
   - Read the preview (frame over dark and light background): holes in dark armor = background too close to the hull colors (the worm GIF on dark purple lost most of its armor) -> ask for a `#00FF00` version. Green fringe -> raise `--tol`.
   - `interpolate.py` makes in-betweens across clip boundaries too, they are just never used (output frame = 2 x source frame as usual).
   - **24 fps video**: keep it native (`--fps 0`) instead of 12 fps + interpolation - real frames beat flow in-betweens. Find the loop on a mid-size copy (`--width 256`, compare `sheet.diff(fr[b], fr[a])` for windows of 1.5-6 s against the median step), then cut it with `--trim` (seconds = frame / 24). Scout example: `resources/basic_enemy1/` - one 10 s Gemini video, natural loop frames 170..228 (seam 1.2 steps), no bridge needed.
   - **frame size**: textures use linear filtering without mipmaps (and `*.import` is gitignored, so no per-file mipmaps) - store frames at ~2x the on-screen size (scout: 80 px frames at scale 0.5 = 40 px). Much bigger frames shimmer on thin parts (legs) when shrunk.
   - horde enemies: start the loop on a random frame (`sprite.frame = randi() % count`) so a swarm does not move in sync.
   - `shaders/Dissolve.tres` samples its noise with `SCREEN_UV`, so it works on AnimatedSprite2D atlas frames; it ignores `modulate`/`self_modulate` (brightening has to be done in the sheet).
   - `object_explosion` fragments: set `explosion.SpriteTexture` to the current frame texture and add `sprite.rotation` to `explosion.rotation` (sheet drawn nose-right).
   - screenshots for checking (`get_viewport().get_texture().get_image()`) come out darker with `hdr_2d` (linear) - compare against a reference sprite in the same shot, not against the sheet.

## Folder layout
- Source GIFs and the 12fps sheet made from them (or a delivered sheet + preview gif) go to `resources/<enemy>/source/` with an empty `.gdignore`, so Godot does not import a texture nobody uses.
- Generated sheet + json + `<enemy>_animations.json` (the animation spec) next to it in `resources/<enemy>/`. Commit all of them - the spec and source are needed to regenerate.
- Example: `resources/wormboss/` (worm boss, `scenes/worm_boss.tscn`).

## Workflow
1. **Look at the clip** - render a downscaled contact sheet with PIL and Read it; AI clips are usually one continuous take (idle -> action -> move), not one row per animation.
2. **Find sections and pops**: `python -I .claude/skills/sprite-animation/scripts/analyze.py <sheet.json>` prints the step (difference) between consecutive frames. Sections show up as plateaus; jumps are steps far above their neighbours. Search loop points by comparing candidate end/start pairs (`sheet.diff`). An AI clip rarely has a natural loop - expect to bridge or ping-pong.
3. **Interpolate**: `python -I .../interpolate.py <src.json> <dst.json> --factor 2 --bridge FROM:TO:N`
   - output frame `2*i` = source frame `i`, odd frames are in-betweens; bridges get indices after the last frame (printed).
   - bridge loop seams with N frames so the seam step is close to the animation's median step (seam 37 vs median ~20 -> 3 frames at 2x).
   - check a few in-betweens and bridges visually (crop with PIL, Read the png) - fast motion ghosts a bit, a plain crossfade ghosts much more.
   - keep the sheet under 16384 px per side; VRAM is uncompressed (`*.import` is gitignored), 242 frames of 378x161 is ~60 MB.
4. **Animation spec** `resources/<enemy>/<enemy>_animations.json`:
   `{"texture_id": "2_sheet", "spriteframes_id": "SpriteFrames_x", "animations": [{"name", "frames": [...], "loop", "speed"}]}`
   - loops without a natural seam: ping-pong (`0..N` then `N-1..1`) or play the section + bridge frames.
   - keep durations when doubling frames: double the speed too.
   - keep the animation names the script plays (`sprite.play("...")`).
   - `"entries"` / `"exits"` - see *Natural switches* below.
5. **Check the spec**: `analyze.py <sheet.json> <animations.json>` prints median / worst step and loop seam per animation and flags `<-- POP` seams, plus the entry/exit report.
6. **Write the scene**: `python -I .../spriteframes.py scenes/<x>.tscn <sheet.json> <animations.json>` replaces the AtlasTextures + SpriteFrames (+ entry/exit metadata), repoints the texture ext_resource and fixes `load_steps`.
7. Run the `godot-check` skill (the first `--import` run reports `Failed loading resource` for a brand new png - run it again).
8. **Measure the switches in the running game** (step 9 below).

## Orientation and scale
Enemies face the player with their `+Y` side. A sheet drawn head-right needs `rotation = 1.5708` on the AnimatedSprite2D (and on a crossfade ghost); muzzle / eye markers then sit on `+Y` at `(head offset from frame center) * scale`. Collision capsules are along Y.

## Natural switches between animations
Animations cut from different parts of one clip pop when the AI switches (move -> attack, attack -> idle). First list every switch the script makes (grep `sprite.play` and the awaits around it) and sort them:

- **planned, out of a loop** (chase -> attack): store an *exit* frame - the loop frame whose next frame matches the target's first frame (`"exits": {"Move": ["Spread", ...]}` -> `metadata/exit_Move`). The script times the loop to sit on it: worm `_chase` starts Move, then `_plan_move` picks one or two loops and sets `speed_scale` (0.75-1.35) so the loop reaches the exit frame when the chase timer ends; `_reach_frame` absorbs a frame of drift. If the attack is a part of the move section, the switch is exactly continuous (sets `_seamless`, no crossfade). If no loop frame is close, prepend a bridge (`--bridge MOVE_SRC:ATTACK_SRC:N`, start the attack with that move frame).
- **into a loop** (attack -> idle, flinch -> move): loops can start anywhere, store *entry* tables (`"entries": ["Idle", "Move"]` -> `metadata/entry_Idle = {&"Anim": PackedInt32Array(...)}`, the loop frame whose previous frame matches each frame of each animation) and start with `_play_matched(&"Idle")`.
- **fixed end -> loop** that still pops (worm Spread/Mines end -> Idle was 15-26): append a bridge to an idle pose plus that pose frame itself, and make sure the animation finishes before the attack does (raise `speed`).
- **variable end** (laser beam stops at any LaserFire frame): reuse frames - `LaserEnd` has the Spread frames (incl. the bridge to idle) and is started with `_play_matched` from the current frame.
- **interruptions** (Hurt, Death): unplanned, crossfade only. Re-plan what was interrupted: after a flinch `_resume_move` starts Move from the best entry and restarts the chase timer with a new plan; a flinch still playing when the chase ends plays out first.
- **everything else**: the `Ghost` Sprite2D next to the AnimatedSprite2D (same rotation/scale) crossfades the last frame over 0.15 s - `_on_animation_changed` / `_on_frame_changed` in `scripts/worm_boss.gd`. On `play()` Godot emits `frame_changed` for the *new* animation before `animation_changed`, so the last shown frame is tracked only while the animation name still matches. Godot hitstop scales `Engine.time_scale`, timers and animations stay in sync.

9. **Measure in the game**: `python -I .claude/skills/sprite-animation/scripts/switch_test.py <godot_console_exe> res://scenes/<x>.tscn <sheet.json> --call _play_hurt --every 5.3`
   runs the enemy with all autoloads at 4x speed against a stub player, logs every switch and prints jump avg/max and how many were crossfaded per switch type. Compare with the loop step from `analyze.py` (worm: move step ~3.3, idle ~0.8 in these units). Planned switches should be ~1 step and not crossfaded; only interruptions should stay large. `SCRIPT ERROR`s about the player come from the stub, add the missing member to `PLAYER` in the script.
