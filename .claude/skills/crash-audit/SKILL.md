---
name: crash-audit
description: Static crash audit for the Space Thunder (Bambo) Godot GDScript project - headless compile, scene signal and node-path checks, and grep sweeps for the crash patterns that have actually bitten this codebase (invalid property access on the wrong node type, unguarded array and dictionary lookups, freed-instance calls, double death signals, missing enum table entries). Use when asked to look for crashes, review a change for runtime errors, after a "Invalid access" / "Invalid call" / "Nonexistent function" / "Division by zero" / "previously freed" error in the Godot log, or before a release.
---

# Crash audit (static)

Static means nothing is run in the game: the checks read code and scenes. Pair it with `godot-check`
(headless compile) and `perf-stress` (runtime load). A clean audit does not prove there are no crashes;
it proves the listed patterns are absent. Runtime-only failures need a scripted run (`godot-check`).

## Procedure
1. **Compile everything** (Godot's own analyzer). In a fresh worktree the first `--import` floods the log with
   "Failed loading resource" and cascading "Parse error" lines because assets are not imported yet. Run it
   **twice**, only the second run counts:
   ```bash
   "/c/Users/sebsz/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --import > "$CLAUDE_JOB_DIR/tmp/import.log" 2>&1
   grep -E "ERROR|WARNING" "$CLAUDE_JOB_DIR/tmp/import.log" | grep -v -e "invalid UID" -e "leaked at exit" -e "in use at exit" -e "first_scan"
   ```
   Empty output = clean. Run it with `run_in_background` (about a minute).
2. **Scene wiring**: `python -I .claude/skills/crash-audit/scripts/check_connections.py .` - every `[connection ... method="x"]`
   in a `.tscn` must exist on the target's script or its `extends` chain. Expect `problems: 0`.
3. **Node paths**: `python -I .claude/skills/crash-audit/scripts/check_node_paths.py .` - every `$Name` / `get_node("...")`
   must exist in each scene that attaches the script. Each MISSING line is either an instanced child or a node
   built in code; confirm by reading the code before calling it a bug. The six known ones are listed below.
   Use `-I` so a planted `json.py` or similar in the project cannot shadow the stdlib.
4. **Grep sweeps** (below). Read every hit in context before reporting it.
5. **Read the risky functions** (collision handlers, `_physics_process`, death paths, pooled objects) end to end.
6. **Report** each finding as: file:line, the failing input or state, the Godot error it produces, and whether it is
   live (reproduced or read from a real call path) or latent (no current call path reaches it).

## Grep sweeps
Run from the repo root, excluding `addons/` (third-party, do not edit):
- **Direct property on another node** (the class of the original `isDead` crash):
  `grep -rn "get_parent()\.[a-zA-Z_]" scripts singletons` and any `area.get_parent().X` / `body.X` read. Use `.get("X")`
  or `has_method` unless the node type is guaranteed.
- **Array indexing that assumes non-empty**: `\[0\]`, `\[-1\]`, `.front()`, `.back()`, `.pick_random()`, `.max()`, `.min()`.
  Each needs a size or emptiness guard in the same function.
- **Dictionary `[]` lookups of enum keys**: every `_table[enum]` must cover every enum value, or use `.get(key, default)`.
- **Division by a variable**: `/ count`, `/ max...`, `/ duration`. Integer division by zero is a runtime error; float
  division gives inf/NaN that later reaches `int()` or an index.
- **Casts that can yield null**: `x as Type` followed by a method call on the result.
- **Freed-instance access**: references held across frames (static registries, `Target`, `_player`, signal-bound
  callables). Need `is_instance_valid()` or a `NOTIFICATION_PREDELETE` / `tree_exiting` cleanup.
- **Death paths**: every `killed.emit` must sit behind an `isDead` guard in the caller (or in `explode()` itself).
- **Missing methods on pooled or polymorphic nodes**: anything in a group that another script calls methods on
  (e.g. the `"Bullet"` group must only hold nodes that implement `is_damaging_player()` and `is_damaging_enemy()`).
- **Missing-file loads**: `preload` / `load` of paths that do not exist (the compile step catches `preload`).

## Verified safe in this codebase (do not re-report)
- `apply_burn` returns unless the target has `handleDamage`, so mines in the `"Enemy"` group never reach the burn tick.
- `bullet.gd` `_has_live_target`, `_release_target`, `_bounce_to_next` all check `is_instance_valid` before touching `Target`.
- `bullet.gd` `_count_rock_hit` divides by `MaxHits` only on the `MaxHits > 0` branch.
- `XpGem.all` is pruned on `NOTIFICATION_PREDELETE`, so `drop_service` never calls a freed gem.
- `drop_service` `pick_random()` is guarded by `all.size() > 0`; attack option lists in boss scripts always keep
  at least one entry (4 options, at most 3 erased).
- `WeaponFactory.get_weapon` covers all `Enums.WEAPONS` and falls back to `SmallBullet`.
- Enemy tables (`_points_dict`, `_xp_dict`, `ENEMY_SCENE_PATHS`) cover all `Enums.ENEMIES`; perk scenes cover all
  `Enums.PERKS`. `_perk_chances` has only 4 keys on purpose: `get_random_perk` iterates it and `get_chance` has no callers.
- The `"Bullet"` group holds only bullet classes and `bomb.tscn` (which has both methods).
- Enemies are created only in `EnemySpawner.spawn`, which registers them, so every `killed` has a registry entry.
- Boulder beetle blast checks `has_signal("killed")` and `isDead` before it kills, so mines are skipped.
- `beetle_blast.tscn` provides the `ShaderMaterial` on `Shockwave` and the texture on `Flash`.
- `Debris` in the boss scenes comes from the instanced `beetle_blast.tscn`. `LifeTimer` exists on every bullet scene.
- The six remaining node-path MISSING lines are expected: `Debris` (instanced) and the four `VBoxContainer/*` plus
  `Level` lookups in `level_up_menu.gd`, whose UI is built in `_build()`.

## Known latent issue (not reproduced)
- `scripts/enemy_spawner.gd` `unregister(id)` does `active_enemies[id]` with no guard. If `killed` ever fires for an
  enemy not in the registry, the lookup raises "Invalid get index" and `game_logic._on_enemy_killed` would then use
  a null enemy. No current path does this. Hardening: `active_enemies.get(id)` plus an early return in
  `_on_enemy_killed`. Make that change only together with a reproduction.

## Fixed so far
- `scripts/bullet.gd` tether-rock hit on a mine: `area.get_parent().isDead` became `.get("isDead")`
  (`Invalid access to property or key 'isDead' on a base object of type 'CharacterBody2D (mine.gd)'`).

## Rules when fixing
- Prefer the project's existing idiom: `.get("prop")` for optional fields, `has_method()` for optional behaviour,
  `is_instance_valid()` before touching a held reference.
- Keep fixes local. Do not change gameplay (what a mine or rock should do) to silence a crash; ask first if the right
  behaviour is unclear, and say so.
- After any fix: re-run step 1 (second pass) and both scripts, then `godot-check` before committing.

## Related
`godot-check` (compile and run), `space-thunder-conventions` (collision contract, `isDead` and `killed` rules),
`perf-stress` (runtime load), `add-enemy` (new enemies must go into every table above).
