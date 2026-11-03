---
name: perf-stress
description: Measure Space Thunder frame times under load - big horde, nuke (bomb) killing hundreds of enemies, magnet pulling all xp gems - with a scripted run of the real world scene, and compare against the last commit. Use when the game stutters / FPS drops, before and after performance work, or after changing enemies, explosions, gems, Juice effects or collision layers.
---

# Performance stress test

Harness: `.claude/skills/perf-stress/scripts/stress.gd` (a `SceneTree` script that loads `res://scenes/shared/world.tscn`,
god mode on, phases stopped, level-ups disabled, vsync off). Godot binary and filtering as in `godot-check`.

```bash
GODOT="/d/Programy/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
timeout 170 "$GODOT" --path . --script "$(pwd -W)/.claude/skills/perf-stress/scripts/stress.gd" -- --enemies=400 > "$SP/stress.txt" 2>&1
grep -E "frames\)|process .* ms|alive|gems|SCRIPT ERROR|INVARIANT|registry|beetles|chain t|mines ok|bullets expire" "$SP/stress.txt"
```
Options after `--`: `--enemies=N` (mixed scout/scout/guard/hunter, default 400), `--gems=N` (default 600, capped by `MAX_GEMS`),
`--beetles=N` (boulder beetles in the beetle scenario, default 40), `--only=nuke|magnet|beetle|chain` (default: all four, in that order).
Run **without** `--headless` (it opens a window for a few seconds) - headless uses a dummy renderer and hides GPU/draw costs.
Run it 2x - single runs are noisy; compare `avg`/`p95` of the same window, the `max` is one frame.

**Pass/fail** - a run is bad if any of these appear (grep them, don't just eyeball the timings):
- `SCRIPT ERROR` anywhere (a crash signature, e.g. `Out of bounds get index` from the spawner registry)
- `INVARIANT FAIL` (registry count != active enemies, mines above `MaxMinesFromMeteors`, mine blast bullets alive with no mine left)
- an exit code other than 0

Windows printed: `idle horde` (crowd right after spawning), `nuke` (`game._on_bomb_taken`), `magnet` (`call_group("XpGem", "attract")`),
`beetle` (40 boulder beetles charge the player, then every shell is exploded twice in the same frame), `chain` (12 rocks moved next to the
ship, 4 broken by hand; rocks / mines / mine-blast bullets sampled each second for 6 s). Each frame window has engine monitors
(process/physics time, node count, draw calls, canvas items, **collision pairs**).

## Before / after comparison
Measure the last commit in a temporary worktree (in the scratchpad). `.import` files are gitignored, so copy them and `.godot`, then import:
```bash
git worktree add --detach "$SP/base" HEAD && cp -r .godot "$SP/base/"
find . -name "*.import" -not -path "./.godot/*" | while read f; do [ -f "$SP/base/${f%.import}" ] && cp "$f" "$SP/base/$f"; done
timeout 250 "$GODOT" --headless --path "$SP/base" --import >/dev/null 2>&1
# run the harness with --path "$SP/base"; afterwards remove it (long paths need rm first on Windows):
rm -rf "$SP/base"; git worktree prune
```

## Reading the numbers (reference, 400 enemies, Oct 2026 dev machine)
| window | before perf pass | after |
|---|---|---|
| nuke avg frame | 72-81 ms (whole 2.5 s) | ~2 ms |
| magnet max frame (600 gems) | 12-15 ms | ~4 ms |
| crowd collision pairs | 55-69k | 2-3k |

- **collision pairs** in the tens of thousands = Area2D layers/masks wrong (areas scanning each other). See collision rules in `space-thunder-conventions`.
- High `nodes` jumping on kills = something instantiates per death (should come from `Juice` pools).
- A single huge frame on the very first explosion is a first-use (shader/pipeline) cost - the harness does a warm-up kill to skip it.
- The remaining crowd cost in god mode is enemies sitting on the player (contact damage timers) - in a real run the player is dead long before.
- A ~1.2 s `idle horde` frame and an avg of 110-190 ms in that window was a real bug, not normal: bullets never expired, so the rock/mine chain filled the screen (see the regression below). If it comes back, check bullet lifetimes first.
- Bullet-group areas also belong to bombs (StaticBody2D with no `from_mine`/`is_fragment`). Read such flags with `get("flag")`, not `.flag`, or the harness throws `Invalid access to property`.
- **Pooled bullet lifetime**: `Bullet` arms its `LifeTimer` in `NOTIFICATION_POST_ENTER_TREE`. Never start a child Timer in `_enter_tree`: Godot prints `Unable to start the timer because it's not inside the scene tree` and the bullet lives forever. Commit 65d1878 moved the start into `_enter_tree` and caused the chain reaction.

### Measured (400 enemies, one run each)
| window | last commit 65d1878 (bullets never expire) | after timer fix |
|---|---|---|
| idle horde avg / max | 110-190 ms / 1.2 s | 9.7 / 48 ms |
| idle horde nodes | ~7450 | ~7580 |
| nuke avg / p95 | 2.0 / 4.0 ms | 1.7 / 3.4 ms |
| nuke nodes | ~1200-1280 | ~940 |
| magnet avg / p95 | 7.7 / 2.7 ms (one 940 ms frame) | 1.1 / 1.5 ms |

## Profiling single pieces
To time a function per call, write a similar `SceneTree` script in the scratchpad: spawn enemies, then loop
`Time.get_ticks_usec()` around e.g. `Juice.hit_effect`, `enemy.explode()`, `game.drop_xp`, `game._add_combo` for 100 enemies.
