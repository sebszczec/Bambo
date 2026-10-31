extends SceneTree

# Performance stress test for Space Thunder - drives the real world scene.
# Usage (from the repo root, NOT headless so rendering is included):
#   "$GODOT" --path . --script .claude/skills/perf-stress/scripts/stress.gd -- [--enemies=400] [--gems=600] [--only=nuke|magnet]
# Scenarios:
#   nuke   - warm-up kill, spawn a mixed horde around the player, wait, idle window, take a bomb (nuke)
#   magnet - fill the floor with xp gems (drop_xp respects MAX_GEMS), then attract all of them
# Prints frame times (max / p95 / avg / top5) and engine monitors for every window.

var _args = {"enemies": 400, "gems": 600, "only": ""}

func _initialize():
	for a in OS.get_cmdline_user_args():
		var kv = a.trim_prefix("--").split("=")
		if kv.size() == 2 and _args.has(kv[0]):
			_args[kv[0]] = kv[1] if kv[0] == "only" else int(kv[1])
	change_scene_to_file("res://scenes/world.tscn")
	_run()

func _monitors() -> String:
	return "process %.1f ms, physics %.1f ms, nodes %d, draw calls %d, canvas items %d, collision pairs %d" % [
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)]

# time based window - with vsync off a frame count would be a fraction of a second
func _measure(label : String, seconds : float, action : Callable):
	var times = []
	var start = Time.get_ticks_usec()
	var last = start
	action.call()
	while last - start < seconds * 1000000:
		await process_frame
		var now = Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	var frames = times.size()
	times.sort()
	var total = 0.0
	for t in times:
		total += t
	print("%-11s (%4d frames): max %6.1f ms, p95 %5.1f ms, avg %5.1f ms, top5 %s" % [label, frames, times[-1], times[int(frames * 0.95)], total / frames, str(times.slice(-5))])
	print("             %s" % _monitors())

func _run():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for i in 60:
		await process_frame

	var game = current_scene.get_node("GameLogic")
	var status = root.get_node("PlayerStatus")
	var enums = root.get_node("Enums")
	game.phase_guard.stop_phase(game.phase_guard.current_phase)
	game.player.godMode = true
	# no level up menu (it pauses the game) while measuring
	status.XpToNext = 100000000
	var center = game.player.global_position

	if _args.only != "magnet":
		# warm-up: a few kills first, like in a real run, so first-use costs are not measured
		for i in 6:
			game.spawn_enemy([enums.ENEMIES.SCOUT, enums.ENEMIES.GUARD, enums.ENEMIES.HUNTER][i % 3], center + Vector2(300, 0).rotated(i))
		await create_timer(1.0).timeout
		game._on_bomb_taken(0)
		await create_timer(2.0).timeout

		var types = [enums.ENEMIES.SCOUT, enums.ENEMIES.SCOUT, enums.ENEMIES.GUARD, enums.ENEMIES.HUNTER]
		for i in _args.enemies:
			game.spawn_enemy(types[i % types.size()], center + Vector2(randf_range(250, 600), 0).rotated(randf() * TAU))
		await create_timer(1.5).timeout
		print("enemies alive: %d" % game.active_enemies.size())
		await _measure("idle horde", 1.0, func(): pass)
		await _measure("nuke", 2.5, func(): game._on_bomb_taken(0))
		print("gems after nuke: %d" % game.XpGemScript.alive_count)
		await create_timer(1.5).timeout

	if _args.only != "nuke":
		for i in _args.gems:
			game.drop_xp(center + Vector2(randf_range(400, 1500), 0).rotated(randf() * TAU), 1)
		await create_timer(1.0).timeout
		var xp = status.Xp
		print("gems on floor: %d" % game.XpGemScript.alive_count)
		await _measure("magnet", 2.5, func(): game.get_tree().call_group("XpGem", "attract"))
		print("gems left: %d, xp collected: %d" % [game.XpGemScript.alive_count, status.Xp - xp])

	quit()
