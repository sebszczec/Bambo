---
name: trailer
description: Make or update the Space Thunder YouTube trailer (or any gameplay video, clip, GIF or thumbnail) - record scripted gameplay shots with Godot Movie Maker (autopilot player, staged swarms, bosses, nuke), cut them with title cards and music in ffmpeg to 1080p60 YouTube spec, and render a thumbnail. Use when asked for a trailer, gameplay footage, a promo clip, a new shot for a new level/enemy, or to re-cut the existing trailer.
---

# Trailer

Two scripts in `.claude/skills/trailer/scripts/`:
- `shots.gd` - `SceneTree` director, records **one shot per Godot run** with Movie Maker (real rendering, fixed 60 fps,
  so the video is smooth however slow the machine renders).
- `build.py` - cut list + title cards (PIL, game font `kenvector_future.ttf`) + music mix -> `space_thunder_trailer.mp4`.

Last version (Nov 2026, 61 s, levels 1 + 2): `C:\Users\sebsz\Videos\SpaceThunderTrailer\` (mp4, thumbnail, scripts).

## 1. Record shots
Godot binary as in `godot-check`. Work dir `$SP` in the scratchpad, shots go to `$SP/shots/<shot>.avi` (MJPEG + PCM, ~1 GB each).
Run 3-4 shots in parallel (~2 min per batch), not headless:
```bash
GODOT="/d/Programy/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
SCRIPT="$(pwd -W)/.claude/skills/trailer/scripts/shots.gd"; mkdir -p "$SP/shots"
rec() { timeout 900 "$GODOT" --path . --write-movie "$(cygpath -w "$SP/shots/$1.avi")" --fixed-fps 60 --resolution 1920x1080 \
  --script "$SCRIPT" -- --shot=$1 > "$SP/shots/$1.log" 2>&1; echo "$1 done $?"; }
for s in title l1_open l1_swarm l1_boss; do rec $s & done; wait
for s in l1_worm l2_open l2_beetle l2_nuke l2_worm; do rec $s & done; wait
grep -h "SCRIPT ERROR" -A3 "$SP"/shots/*.log
```
`--resolution 1920x1080` works although the screen is 1536x864 (125 % scaling).

Check every shot with a 1 fps contact sheet (tile n = second n) and Read it before cutting:
```bash
ffmpeg -v error -y -i "$SP/shots/l1_boss.avi" -vf "fps=1,scale=480:-1,tile=4x4" -frames:v 1 "$SP/shots/sheet_l1_boss.jpg"
```
ffmpeg `drawtext` **segfaults** here (no fontconfig) - render any text with PIL instead.

### Shot director rules (`shots.gd`)
- Shot name prefix picks the level (`l2_*` -> `Levels.current = 1`); `title` records the start menu with buttons and
  high score table hidden and menu music stopped.
- `_setup()`: god mode, world music stopped (`Player/AudioStreamPlayer2D2`), FPS/enemy counters hidden (they show the
  slow recording fps), `XpToNext` huge (no level ups), input mode `gamepad` so the autopilot can drive with
  `Input.action_press("move_*"/"aim_*", strength)`, and `levelUpMenu` swapped for a no-op node - boss kills and elites
  open the supply crate menu, which **pauses the game** for the rest of the shot.
- `_stop_waves()` for staged shots, `_kit()` gives a showy weapon set, `_ring(types, n, rmin, rmax)` spawns around the player.
- Boss damage is a % of max life, so raising `Life` does not help: hold `boss_floor` (share of max life kept) until
  the scripted kill with `game.hurt_boss(100)`, else the kit kills a boss in ~4 s.
- Each shot starts with the level banner (~2 s); level-open shots keep the phase guard running so the phase 1 speech plays.
- New level or enemy: add a `"lN_*"` case in `_run()` with its enemy ids (plain ints, see `Enums.ENEMIES`).

## 2. Build
```bash
python -I .claude/skills/trailer/scripts/build.py "$(cygpath -w "$SP")"
```
- `cards`: black title cards (fade in/out), `o_end`: transparent overlay on the title shot (end card).
- `SEG`: `("card", name, seconds)` or `("shot", name, start, end, game_volume, overlay)`. Pick start/end from the
  contact sheets. Keep shots 2.5-7 s, a card between acts, the biggest moment (nuke) last before the end card.
- Music: `Orbital Colossus` (Matthew Pablo, CC-BY - credit it in the YouTube description), aligned so its natural
  ending (~147-150 s) lands on the end card: start = `MUSIC_END - length`, 2 s fade in. Game audio sits under it
  (0.55; 1.0 for the speech in the level-open shot), the mix is `loudnorm` to -14 LUFS.
- Output: H.264 high, CRF 16, yuv420p, 60 fps, GOP 30, faststart, AAC 320k 48 kHz.

Verify: final contact sheet (`fps=0.4,tile=5x5`), integrated loudness (`-af ebur128` -> I about -14 LUFS),
per 2 s RMS for silent gaps. You cannot hear the result - ask the user to watch it with sound.

## 3. Thumbnail
1280x720 PNG: grab a busy frame (`ffmpeg -ss 4.6 -i shots/l2_nuke.avi -frames:v 1`), darken (0.75), bottom gradient,
"SPACE THUNDER" in the game font with black stroke + glow, tagline in cyan underneath.

## Deliver
Copy mp4, thumbnail and any changed scripts to `C:\Users\sebsz\Videos\SpaceThunderTrailer\` (the scratchpad is temporary).
Never leave a director script in the repo root.
