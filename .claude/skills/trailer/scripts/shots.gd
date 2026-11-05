extends SceneTree

# Trailer shot director - records one shot per run with Movie Maker (see the trailer skill):
#   godot --path . --write-movie <out.avi> --fixed-fps 60 --resolution 1920x1080 --script <abs path> -- --shot=<name>
# Shots: title, l1_open, l1_swarm, l1_boss, l1_worm, l2_open, l2_beetle, l2_nuke, l2_worm
# Player: god mode + autopilot (figure eight, dodges close enemies, aims at the nearest one via gamepad actions).

const SCOUT = 0
const GUARD = 1
const HUNTER = 2
const BOSS = 3
const WORM = 4
const MITE = 5
const BEETLE = 6   # level 2 Boulder Beetle (guard slot)
const WASP = 7     # level 2 Shard Wasp (hunter slot)
const MANTIS = 8   # level 2 Quarry Mantis (mid boss)
const QUEEN = 9    # level 2 Bedrock Queen (final boss)

var shot = "l1_open"
var game = null
var player = null
var autopilot = false
var t = 0.0
var center = Vector2.ZERO
var path_speed = 0.35
var path_radius = 260.0
var boss_floor = 0.0  # boss life is held above this share of max life until the scripted kill

func _initialize():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
	if shot == "title":
		change_scene_to_file("res://scenes/menus/start_menu.tscn")
		_title()
		return
	root.get_node("Levels").current = 1 if shot.begins_with("l2") else 0
	change_scene_to_file("res://scenes/shared/world.tscn")
	_run()

func _title():
	for i in 3:
		await process_frame
	var menu = current_scene
	menu.get_node("GridContainer").visible = false
	menu.highScoreTable.visible = false
	root.get_node("MenuMusic").process_mode = Node.PROCESS_MODE_DISABLED
	for c in root.get_node("MenuMusic").get_children():
		if c is AudioStreamPlayer:
			c.stop()
	await create_timer(7.0).timeout
	quit()

func _setup():
	for i in 3:
		await process_frame
	game = current_scene.get_node("GameLogic")
	player = game.player
	player.godMode = true
	player.get_node("AudioStreamPlayer2D2").stop()
	# FPS / enemy counters show the slow recording rate
	game.informationBox.get_node("CanvasLayer").visible = false
	root.get_node("PlayerStatus").XpToNext = 100000000
	root.get_node("InputManager").set_input_mode("gamepad")
	center = player.global_position
	autopilot = true
	# no reward menu (it pauses the game) after bosses / elites
	var dummy = GDScript.new()
	dummy.source_code = "extends Node\nfunc queue_chest(): pass\nfunc queue_level_up(): pass\nfunc is_open(): return false\n"
	dummy.reload()
	game.levelUpMenu.queue_free()
	game.levelUpMenu = Node.new()
	game.levelUpMenu.set_script(dummy)

func _give(id : String, times : int):
	var upgrades = root.get_node("Upgrades")
	for i in times:
		upgrades.choose(upgrades.get_entry(id))

func _kit():
	_give("w_missiles", 3)
	_give("w_nova", 2)
	_give("w_orbit", 2)
	_give("w_cannon", 2)
	_give("damage", 4)
	_give("fire_rate", 3)
	_give("projectile", 1)

func _stop_waves():
	game.phase_guard.stop_phase(game.phase_guard.current_phase)

func _ring(types : Array, count : int, rmin : float, rmax : float):
	for i in count:
		var pos = player.global_position + Vector2(randf_range(rmin, rmax), 0).rotated(randf() * TAU)
		game.spawn_enemy(types[i % types.size()], game._clamp_to_level(pos))

func _wait(s : float):
	await create_timer(s).timeout

func _run():
	await _setup()
	match shot:
		"l1_open":
			# real level start: banner + first speech, scouts close in
			await _wait(0.6)
			_ring([SCOUT], 14, 650, 900)
			await _wait(3.0)
			_ring([SCOUT], 14, 650, 900)
			await _wait(4.0)
			_ring([SCOUT, SCOUT, GUARD], 15, 650, 900)
			await _wait(4.0)
		"l1_swarm":
			_stop_waves()
			_kit()
			_ring([SCOUT, SCOUT, GUARD, HUNTER], 30, 600, 900)
			await _wait(2.5)
			game._on_swarm_requested(40)
			for i in 6:
				await _wait(1.5)
				_ring([SCOUT, GUARD, HUNTER, SCOUT], 14, 650, 900)
			await _wait(1.0)
		"l1_boss":
			_stop_waves()
			_kit()
			await _wait(0.5)
			game.spawn_boss(BOSS)
			game.boss.global_position = player.global_position + Vector2(700, -150)
			boss_floor = 0.6
			_ring([SCOUT, GUARD], 16, 600, 900)
			await _wait(5.0)
			boss_floor = 0.25
			await _wait(4.0)
			boss_floor = 0.0
			game.hurt_boss(100)
			await _wait(4.0)
		"l1_worm":
			_stop_waves()
			_kit()
			await _wait(0.5)
			game.spawn_boss(WORM)
			game.boss.global_position = player.global_position + Vector2(650, 100)
			boss_floor = 0.7
			await _wait(6.0)
			boss_floor = 0.35
			await _wait(8.0)
		"l2_open":
			await _wait(0.6)
			_ring([MITE], 16, 650, 900)
			await _wait(3.0)
			_ring([MITE], 16, 650, 900)
			await _wait(4.0)
			_ring([MITE, MITE, BEETLE], 15, 650, 900)
			await _wait(4.0)
		"l2_beetle":
			_stop_waves()
			_kit()
			_ring([BEETLE, MITE, MITE], 30, 550, 850)
			for i in 6:
				await _wait(1.8)
				_ring([BEETLE, MITE, WASP], 12, 650, 900)
			await _wait(1.0)
		"l2_nuke":
			_stop_waves()
			_give("w_orbit", 2)
			_give("w_nova", 1)
			_ring([MITE, MITE, BEETLE, WASP], 260, 350, 900)
			await _wait(4.0)
			game._on_bomb_taken(0)
			await _wait(3.0)
			game.get_tree().call_group("XpGem", "attract")
			await _wait(3.5)
		"l2_worm":
			_stop_waves()
			_kit()
			await _wait(0.5)
			game.spawn_boss(QUEEN)
			game.boss.global_position = player.global_position + Vector2(-650, 100)
			_ring([MITE, BEETLE, MITE], 15, 600, 900)
			boss_floor = 0.3
			await _wait(7.0)
			boss_floor = 0.0
			game.hurt_boss(100)
			await _wait(5.0)
	quit()

func _press(neg : String, pos : String, v : float):
	if v > 0.05:
		Input.action_release(neg)
		Input.action_press(pos, min(v, 1.0))
	elif v < -0.05:
		Input.action_release(pos)
		Input.action_press(neg, min(-v, 1.0))
	else:
		Input.action_release(neg)
		Input.action_release(pos)

func _process(delta):
	if !autopilot or !is_instance_valid(player):
		return false
	t += delta
	if boss_floor > 0.0 and is_instance_valid(game.boss):
		game.boss.Life = max(game.boss.Life, int(game.boss._max_life * boss_floor))

	# lazy figure eight around the start point, pushed away from close enemies
	var target = center + Vector2(sin(t * path_speed) * path_radius * 1.6, sin(t * path_speed * 2.0) * path_radius)
	var move = (target - player.global_position) / 120.0
	var nearest = null
	var best = INF
	var push = Vector2.ZERO
	for e in game.active_enemies.values():
		if !is_instance_valid(e):
			continue
		var d = e.global_position - player.global_position
		var l = d.length()
		if l < best:
			best = l
			nearest = e
		if l < 220 and l > 1:
			push -= d / l * (220 - l) / 220.0
	move += push * 2.0
	if move.length() > 1.0:
		move = move.normalized()
	_press("move_left", "move_right", move.x)
	_press("move_up", "move_down", move.y)

	var aim = Vector2.RIGHT.rotated(t * 2.0)
	if nearest != null and best < 1100:
		aim = (nearest.global_position - player.global_position).normalized()
	_press("aim_left", "aim_right", aim.x)
	_press("aim_up", "aim_down", aim.y)
	return false
