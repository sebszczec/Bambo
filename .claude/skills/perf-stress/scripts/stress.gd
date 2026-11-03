extends SceneTree

# Performance and crash stress test for Space Thunder - drives the real world scene.
# Usage (from the repo root, NOT headless so rendering is included):
#   "$GODOT" --path . --script .claude/skills/perf-stress/scripts/stress.gd -- [--enemies=400] [--gems=600] [--beetles=40] [--only=nuke|magnet|beetle|chain]
# Scenarios (all run when --only is empty):
#   nuke   - warm-up kill, spawn a mixed horde around the player, wait, idle window, take a bomb (nuke)
#   magnet - fill the floor with xp gems (drop_xp respects MAX_GEMS), then attract all of them
#   beetle - spawn boulder beetles that charge the player, then explode every shell TWICE in one frame
#            (the double-kill that used to emit `killed` twice and crash the spawner)
#   chain  - spawn rocks next to the player, break some by hand (fragments, mines, mine blasts), sample
#            rocks / mines / live bullets: mines must stay under the cap and bullets must expire
# Every window ends with a registry check (spawner.count == active_enemies) and a line starting with
# INVARIANT FAIL when a check breaks. Any SCRIPT ERROR in the output is a failure too.
# Prints frame times (max / p95 / avg / top5) and engine monitors for every window.

var _args = {"enemies": 400, "gems": 600, "beetles": 40, "only": ""}

func _initialize():
	for a in OS.get_cmdline_user_args():
		var kv = a.trim_prefix("--").split("=")
		if kv.size() == 2 and _args.has(kv[0]):
			_args[kv[0]] = kv[1] if kv[0] == "only" else int(kv[1])
	change_scene_to_file("res://scenes/shared/world.tscn")
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

# registry invariant: every counted enemy is in the registry and the other way round
func _check_registry(game) -> void:
	var counted = game.spawner.count
	var registered = game.spawner.active_enemies.size()
	if counted == registered:
		print("registry ok: count %d, active %d" % [counted, registered])
	else:
		print("INVARIANT FAIL registry: count %d, active %d" % [counted, registered])

# mine blasts only: the player's own auto-weapon keeps firing, so the total is not a leak signal
func _live_mine_bullets() -> int:
	var script = load("res://scripts/bullet.gd")
	var n = 0
	for node in current_scene.find_children("*", "StaticBody2D", true, false):
		if node.get_script() == script and node.get("from_mine") == true:
			n += 1
	return n

# rocks are the only CharacterBody2D with a destruction hook
func _rocks() -> Array:
	var rocks = []
	for node in current_scene.find_children("*", "CharacterBody2D", true, false):
		if node.has_method("handle_destruction"):
			rocks.append(node)
	return rocks

func _run():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for i in 60:
		await process_frame

	var game = current_scene.get_node("GameLogic")
	var status = root.get_node("PlayerStatus")
	var enums = root.get_node("Enums")
	var levels = root.get_node("LevelSettings")
	game.phase_guard.stop_phase(game.phase_guard.current_phase)
	game.player.godMode = true
	# no level up menu (it pauses the game) while measuring
	status.XpToNext = 100000000
	var center = game.player.global_position

	if _args.only == "" or _args.only == "nuke":
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
		_check_registry(game)
		await create_timer(1.5).timeout

	if _args.only == "" or _args.only == "magnet":
		for i in _args.gems:
			game.drop_xp(center + Vector2(randf_range(400, 1500), 0).rotated(randf() * TAU), 1)
		await create_timer(1.0).timeout
		var xp = status.Xp
		print("gems on floor: %d" % game.XpGemScript.alive_count)
		await _measure("magnet", 2.5, func(): game.get_tree().call_group("XpGem", "attract"))
		print("gems left: %d, xp collected: %d" % [game.XpGemScript.alive_count, status.Xp - xp])
		_check_registry(game)

	if _args.only == "" or _args.only == "beetle":
		for i in _args.beetles:
			game.spawn_enemy(enums.ENEMIES.BOULDER_BEETLE, center + Vector2(randf_range(200, 350), 0).rotated(randf() * TAU))
		# let them wake, lock on and start their charges
		await create_timer(1.0).timeout
		var shells = 0
		for enemy in game.spawner.active_enemies.values():
			# an earlier kill in this loop can free a later entry
			if is_instance_valid(enemy) and enemy.get("enemy_kind") == enums.ENEMIES.BOULDER_BEETLE:
				# two hits in one physics step: the second must not emit killed again
				enemy.explode()
				enemy.explode()
				shells += 1
		print("beetles double-killed: %d" % shells)
		await _measure("beetle", 2.0, func(): pass)
		_check_registry(game)

	if _args.only == "" or _args.only == "chain":
		for i in 12:
			game.meteors.spawn()
		await create_timer(0.3).timeout
		# bring the rocks next to the ship so the chain can reach it and the player's shots
		var rocks = _rocks()
		for rock in rocks:
			rock.global_position = center + Vector2(randf_range(150, 400), 0).rotated(randf() * TAU)
		await create_timer(0.3).timeout
		# break a few by hand, like bullets would: fragments and mines follow
		for rock in rocks.slice(0, 4):
			if !rock.is_dead:
				rock.handle_destruction()
		var mine_cap = levels.MaxMinesFromMeteors
		var worst_mines = 0
		var worst_bullets = 0
		for step in 6:
			await create_timer(1.0).timeout
			var mines = get_nodes_in_group_count("Mine")
			var bullets = _live_mine_bullets()
			worst_mines = max(worst_mines, mines)
			worst_bullets = max(worst_bullets, bullets)
			print("chain t+%ds: rocks %d, mines %d (cap %d), mine blast bullets %d" % [step + 1, _rocks().size(), mines, mine_cap, bullets])
		if worst_mines > mine_cap:
			print("INVARIANT FAIL mines: peaked at %d, cap %d" % [worst_mines, mine_cap])
		else:
			print("mines ok: peak %d, cap %d" % [worst_mines, mine_cap])
		# once no mine is left, no mine blast can still be in flight: its bullets must have expired
		var stray = _live_mine_bullets()
		if get_nodes_in_group_count("Mine") == 0 and stray > 0:
			print("INVARIANT FAIL bullets: %d mine blast bullets alive with no mine left" % stray)
		else:
			print("bullets expire ok: %d mine blast bullets alive, %d mines" % [stray, get_nodes_in_group_count("Mine")])
		_check_registry(game)

	quit()

func get_nodes_in_group_count(group : String) -> int:
	return get_nodes_in_group(group).size()
