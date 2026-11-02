---
name: asset-layout
description: Where art, sound and other resources live in Space Thunder after the level-based reorganisation - resources/levels/levelN (backgrounds, music, enemies), resources/shared (player, pickups, audio, fx, space, branding), resources/vendor (third-party packs), resources/unused - plus the rules for adding, moving or renaming an asset without breaking res:// references. Use when adding a new enemy, level, background, sound or icon file, when moving or renaming anything under resources/, or when a res:// path fails to load.
---

# Asset layout

`resources/` is grouped by where an asset is used. Put new files in the folder that matches
their owner, never in the root of `resources/`.

## Map

```
resources/
  levels/
    level1/
      background/              space_bg.jpg
      enemies/
        scout/                 scenes/enemy_1.tscn  (Scout)
        hunter/                scenes/enemy_3.tscn  (Hunter)
        guard/                 scenes/enemy_2.tscn  (Guard, also the elite)
        hive_beetle/           scenes/boss.tscn     (Hive Beetle boss)
        worm_boss/             scenes/worm_boss.tscn (+ mine-sheet.png for worm_mine)
    level2/
      background/              asteroid_*.png, bg.jpg, source/ (jfif originals)
      music/                   level2_asteroid_siege.ogg
      enemies/
        pebble_mite/           scenes/pebble_mite.tscn
        boulder_beetle/        scenes/boulder_beetle.tscn (elite of level 2 too)
        shard_wasp/            scenes/shard_wasp.tscn
        quarry_mantis/         scenes/quarry_mantis.tscn (mid boss)
        bedrock_queen/         scenes/bedrock_queen.tscn (final boss)
  shared/
    player/ufo/                player spritesheet (all levels)
    pickups/                   perk and upgrade icons, pickup_*.png, xenite.png, source/
    audio/explosions/          explosion sounds
    audio/sfx/                 sound effects, speech/ (phase lines), Menu sounds
    audio/music/               menu and fight tracks shared by levels
    fx/                        VFX_thunder.jpg
    space/meteors/             meteor rocks used by rock scenes
    branding/                  bruxa_logo.png (title)
  vendor/kenney/               particles/, planets/, space_shooter_redux/, ui/  (third-party, do not add our art here)
  unused/                      assets no script loads (kept for reference, safe to delete)
```

Per-enemy folder pattern (copy an existing one, e.g. `levels/level2/enemies/pebble_mite/`):

- `<name>_24fps.png` + `<name>_24fps.json` (spritesheet and frame grid) and the `.import` files Godot writes
- `<name>_animations.json` (the animation spec used by sprite-animation)
- extra textures the scene uses (shards, spit, mines) next to the sheet
- `source/` with an **empty `.gdignore`**: Gemini GIFs/MP4s, previews and originals that Godot must not import

Folder names are lowercase snake_case with no spaces. Scripts and scenes keep their own names
(`pebble_mite.gd`, `scenes/pebble_mite.tscn`), so the folder and the scene name usually match, but
check the table above for the exceptions (scout, hunter, guard, hive_beetle).

## Adding a new asset

1. Pick the owner: a level's enemy or background goes under `levels/levelN/`, a file several levels
   use goes under `shared/`. Never add our own art to `vendor/` or `unused/`.
2. Create the folder with the snake_case name. Drop the source files into `source/` first if they are
   not game-ready (`.gdignore` required there).
3. Refer to the file with its full `res://resources/...` path in code or in the scene.
4. Run `godot-check` (headless `--import` twice; the first run reports `Failed loading resource` for
   new pngs).

## Moving or renaming (do this carefully)

Scenes refer to textures and sounds by `uid=` and by path, and scripts refer to them by path.
Moving a file breaks any of them that were not updated.

- Preferred: move in the Godot editor's FileSystem dock. It updates every reference and keeps the uid.
- From a script or a shell: move the file together with its `.import` sidecar, rewrite every
  `res://resources/<old>` string (`.gd`, `.tscn`, `.tres`, `.import`, `.json`, `project.godot`, docs and
  skills), then delete `.godot/imported` and `.godot/exported` (generated caches) and run `godot-check`.
- Afterwards verify: every `res://` path in the project resolves to an existing file, and every scene
  loads. Scene-load check (write it as `res://_scene_check.gd`, run with `-s`, delete it afterwards):

  ```gdscript
  extends SceneTree
  func _initialize():
  	for file in DirAccess.get_files_at("res://scenes"):
  		if file.ends_with(".tscn"):
  			load("res://scenes/" + file)
  	quit()
  ```

- Do not rename folders that contain spaces: the editor can lock them. Copy and delete instead.
- Stale `*.tmp` files in `scenes/` are old save leftovers. They are gitignored and never loaded.

## Adding a new level's folders

Create `levels/levelN/{background,music,enemies}/` and `levels/levelN/enemies/<name>/source/` as needed,
then register the level in `singletons/levels.gd` (see the `add-level` skill). Level art brief goes in
the repo root as `art_levelN.md`.

## Related skills
`add-enemy` (enemy scripts, scenes, art location), `add-level` (ladder, background, music),
`add-upgrade` (perk icons in `shared/pickups/`), `sprite-animation` (sheets and specs per enemy folder),
`godot-check` (validation after any move), `space-thunder-conventions` (architecture).
