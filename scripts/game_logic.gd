extends Node

const LEVEL_END_DELAY = 4.0
const BOSS_EXTRA_ALIVE = 5
const MAX_GEMS = 200
const SPAWN_MIN_DISTANCE = 950.0
const SPAWN_MAX_DISTANCE = 1100.0
const SWARM_RADIUS = 750.0
const ELITE_LIFE_FACTOR = 12
const ELITE_SCALE = 1.8
const ELITE_SHARDS = 10
const COMBO_TIMEOUT = 2.0
const COMBO_STEPS = [10, 25, 50, 100]
const COMBO_NAMES = ["KILLING SPREE!", "RAMPAGE!", "UNSTOPPABLE!", "GODLIKE!"]
const CROWDED_ENEMY_COUNT = 120.0
const BASE_ZOOM = 1.25
const CROWDED_ZOOM = 1.0
# enemy scripts name their dead flag differently, get() / set() ignore the missing ones

var XpGemScript = preload("res://scripts/xp_gem.gd")
var RunHudScript = preload("res://scripts/run_hud.gd")
var DevConsoleScript = preload("res://scripts/dev_console.gd")
var levelUpMenuScene = preload("res://scenes/menus/level_up_menu.tscn")

var enemy_count : int:
	get:
		return spawner.count
var world = null
var score = null
var player = null
var informationBox = null
var lifeBar = null
var shieldBar = null
var afterburnerBar = null
var phaseBanner = null
var bossBar = null
var gameOverMenu = null
var hud = null
var levelUpMenu = null
# main gun, always fires where the player aims
var weapon = null
var bomb = null
# all weapons owned in this run, the main gun included
var owned_weapons : Array = []
var active_enemies : Dictionary:
	get:
		return spawner.active_enemies

var spawner : EnemySpawner = null
var boss = null
var run_over = false
var kills = 0
var combo_tracker : ComboTracker = null
var drops : DropService = null
var meteors : MeteorSpawner = null
# shard result of the finished run for the result screen
var run_shards = {}

@onready var phase_guard = $PhaseGuard
@onready var meteor_spawn_timer = $MeteorSpawnTimer
@onready var phase1_sound = $Phase1Sound
@onready var phase2_sound = $Phase2Sound
@onready var phase3_sound = $Phase3Sound
@onready var phase4_sound = $Phase4Sound
@onready var phase5_sound = $Phase5Sound
@onready var final_phase_sound = $FinalPhaseSound

func _ready() -> void:
	# bullets find the living enemies through the group (see Bullet._bounce_to_next)
	add_to_group("GameLogic")
	# only this level's enemy scenes are kept in memory, see LevelSettings.activate_level
	LevelSettings.activate_level(Levels.current)
	world = get_parent()
	player = world.find_child("Player")

	InputManager.set_gameplay_cursor(true)
	Juice.reset()
	Upgrades.reset(self)

	init_weapons()

	score = world.find_child("Score")
	lifeBar = world.find_child("LifeBar")
	shieldBar = world.find_child("ShieldBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	informationBox = world.find_child("InformationBox")
	phaseBanner = world.find_child("PhaseBanner")
	bossBar = world.find_child("BossBar")
	gameOverMenu = world.find_child("GameOverMenu")
	# weapons are permanent now, the timed weapon panel is not needed
	world.find_child("ActivePerkPanel").visible = false

	hud = RunHudScript.new()
	add_child(hud)
	combo_tracker = ComboTracker.new(hud, phaseBanner)
	drops = DropService.new(self, Callable(self, "_on_bomb_taken"))
	meteors = MeteorSpawner.new(world, informationBox)
	spawner = EnemySpawner.new(world, informationBox, phase_guard, player, Callable(self, "_on_enemy_killed"))
	levelUpMenu = levelUpMenuScene.instantiate()
	add_child(levelUpMenu)
	if OS.is_debug_build():
		var console = DevConsoleScript.new()
		console.game = self
		add_child(console)
	_update_weapons_hud()

	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	player.connect("update_shield", _on_player_update_shield)
	player.connect("killed", _on_player_killed)

	PlayerStatus.connect("xp_changed", _on_xp_changed)
	PlayerStatus.connect("leveled_up", _on_leveled_up)
	PlayerStatus.connect("max_life_changed", _on_max_life_changed)
	PlayerStatus.connect("max_shield_changed", _on_max_shield_changed)
	PlayerStatus.connect("shards_changed", hud.set_shards)
	hud.set_xp(PlayerStatus.Xp, PlayerStatus.XpToNext)

	lifeBar.max_value = PlayerStatus.MaxLife
	lifeBar.value = PlayerStatus.MaxLife
	shieldBar.max_value = PlayerStatus.MaxShield
	shieldBar.value = PlayerStatus.MaxShield
	afterburnerBar.max_value = PlayerStatus.MaxAfterburner
	afterburnerBar.value = PlayerStatus.MaxAfterburner

	phase_guard.connect("phase_timeout", _on_phase_timeout)
	phase_guard.connect("phase_started", _on_phase_started)
	phase_guard.connect("stage_started", _on_stage_started)
	phase_guard.connect("boss_requested", _on_boss_requested)
	phase_guard.connect("elite_requested", _on_elite_requested)
	phase_guard.connect("swarm_requested", _on_swarm_requested)
	phase_guard.connect("difficulty_changed", _on_difficulty_changed)
	phase_guard.connect("time_changed", _on_time_changed)
	phase_guard.start_phase(Enums.PHASE.Survival)
	phaseBanner.show_text(Levels.get_title(), Color.CYAN)

	meteor_spawn_timer.start()

func _exit_tree() -> void:
	InputManager.set_gameplay_cursor(false)
	Juice.reset()

func init_weapons():
	PlayerStatus.CurrentWeapon = Enums.WEAPONS.SMALL
	weapon = _create_weapon(Enums.WEAPONS.SMALL)
	owned_weapons.append(weapon)

	bomb = WeaponFactory.get_weapon(Enums.WEAPONS.BOMB, false, true)
	bomb.set_owner(self)
	bomb.register_internal_nodes(player)

func _create_weapon(type : Enums.WEAPONS):
	var w = WeaponFactory.get_weapon(type, false, true)
	w.is_player_weapon = true
	w.set_owner(self)
	w.register_internal_nodes(player)
	w.connect("bulletNumerChange", _on_weapon_bullet_number_change)
	w.apply_level()
	return w

# public - called by upgrades, adds a new weapon or levels up an owned one
func add_weapon(type : Enums.WEAPONS):
	for w in owned_weapons:
		if w.type == type:
			w.level_up()
			_update_weapons_hud()
			return

	owned_weapons.append(_create_weapon(type))
	_update_weapons_hud()

func _update_weapons_hud():
	var list = []
	for w in owned_weapons:
		list.append([Upgrades.get_weapon_icon(w.type), w.level])
	hud.set_weapons(list)

func _physics_process(delta):
	if player.isDead:
		return

	# main gun fires automatically where the player aims
	weapon.shoot(self, player.getSatelitePosition(), player.getShootingVector())

	# other weapons work on their own
	var target = null
	var target_searched = false
	for w in owned_weapons:
		if w == weapon:
			continue

		w.process(delta, player)
		if !w.canShoot:
			continue

		if w.needs_target:
			if !target_searched:
				target = find_nearest_enemy()
				target_searched = true
			if target == null:
				continue
			w.shoot(self, player.global_position, target.global_position - player.global_position)
		else:
			w.shoot(self, player.global_position, Vector2.RIGHT)

	_update_combo(delta)

	var crowd = clamp(enemy_count / CROWDED_ENEMY_COUNT, 0.0, 1.0)
	player.setBaseZoom(lerp(BASE_ZOOM, CROWDED_ZOOM, crowd))

func _unhandled_input(event: InputEvent) -> void:
	if !OS.is_debug_build() or !(event is InputEventKey) or !event.pressed or event.echo:
		return

	# debug cheats
	if event.keycode == KEY_F1:
		PlayerStatus.add_xp(PlayerStatus.XpToNext - PlayerStatus.Xp)
	elif event.keycode == KEY_F2:
		phase_guard.skip_time(60)
	elif event.keycode == KEY_F3:
		phase_guard.skip_time(phase_guard.run_length)
	elif event.keycode == KEY_F4 and boss == null:
		spawn_boss(Enums.ENEMIES.WORM_BOSS)
	elif event.keycode == KEY_F5 and boss == null:
		spawn_boss(Enums.ENEMIES.QUARRY_MANTIS)

func _on_xp_changed(value : int, max_value : int):
	hud.set_xp(value, max_value)

func _on_leveled_up(level : int):
	hud.set_level(level)
	levelUpMenu.queue_level_up()

func _on_max_life_changed(value : float):
	lifeBar.max_value = value

func _on_max_shield_changed(value : float):
	shieldBar.max_value = value

func _on_time_changed(_seconds : int):
	hud.set_time(phase_guard.get_time_text())
	if phase_guard.current_phase == Enums.PHASE.Survival and phase_guard.elapsed >= phase_guard.run_length - 60:
		hud.set_time_color(Color.RED)
	else:
		hud.set_time_color(Color.WHITE)

func _on_phase_started(phase : Enums.PHASE, _phase_name : String):
	if phase == Enums.PHASE.Endless:
		phaseBanner.show_text("ENDLESS MODE", Color.ORANGE)
	elif phase == Enums.PHASE.Boss:
		final_phase_sound.position = player.position
		final_phase_sound.play()

func _on_stage_started(stage : int):
	if phase_guard.current_phase != Enums.PHASE.Survival:
		return

	# speech for the first threat levels, matching the banner number
	var sounds = [phase1_sound, phase2_sound, phase3_sound, phase4_sound, phase5_sound]
	if stage < sounds.size():
		var sound = sounds[stage]
		sound.position = player.position
		sound.play()

	if stage > 0:
		phaseBanner.show_text("THREAT LEVEL " + str(stage + 1), Color.ORANGE_RED)

func _on_difficulty_changed(value : float):
	phaseBanner.show_text("DIFFICULTY x%0.2f" % value, Color.ORANGE_RED)

func _on_phase_timeout(value):
	for step in value:
		for i in range(step.count):
			if enemy_count >= phase_guard.get_max_alive():
				return
			spawn_enemy(_level_enemy(step.enemy), get_spawn_position())

func _on_swarm_requested(count : int):
	phaseBanner.show_text("SWARM INCOMING!", Color.RED)
	Juice.shake(4.0)
	var start_angle = randf() * TAU
	for i in range(count):
		var offset = Vector2(SWARM_RADIUS, 0).rotated(start_angle + i * TAU / count)
		spawn_enemy(_level_enemy(Enums.ENEMIES.SCOUT), _clamp_to_level(player.global_position + offset))

func _on_elite_requested():
	phaseBanner.show_text("ELITE INCOMING", Color.MAGENTA)
	var elite = spawn_enemy(Enums.ENEMIES.GUARD, get_spawn_position(), ELITE_LIFE_FACTOR)
	elite.scale = Vector2(ELITE_SCALE, ELITE_SCALE)
	elite.modulate = Color(1.6, 0.6, 1.6)
	spawner.elites[elite.get_instance_id()] = true

func _on_boss_requested(type : Enums.ENEMIES, _is_final : bool):
	# levels share the boss list, a level can swap a boss for its own (level 2: hive carrier -> quarry mantis)
	spawn_boss(_level_enemy(type))

# public - also used by the dev console
func spawn_boss(type : Enums.ENEMIES):
	var banner = LevelSettings.get_boss_banner(type)
	if banner.is_empty():
		phaseBanner.show_text("HIVE CARRIER DETECTED", Color.RED)
	else:
		phaseBanner.show_text(banner[0], banner[1])
	Juice.shake(10.0)
	# easier levels get weaker bosses
	boss = spawn_enemy(type, get_spawn_position(), Levels.get_current().get("boss_life_factor", 1.0))
	boss.connect("spawn_requested", _on_boss_spawn_requested)
	boss.connect("health_changed", _on_boss_health_changed)
	if boss.has_signal("enraged"):
		boss.connect("enraged", _on_boss_enraged)
	bossBar.max_value = boss.Life
	bossBar.value = boss.Life
	bossBar.visible = true

# public - dev console, takes percent of the boss max life
func hurt_boss(percent : float):
	if boss == null:
		return
	var damage = PlayerStatus.Damage.new()
	damage.Value = int(bossBar.max_value * percent / 100.0)
	damage.Critical = false
	if boss.handleDamage(damage, boss.global_position) == false:
		_kill_enemy(boss)

# public - dev console, every enemy explodes as if shot, returns how many
func kill_all_enemies() -> int:
	return spawner.kill_all()

func _kill_enemy(enemy) -> bool:
	return spawner.kill(enemy)

func _on_boss_spawn_requested(type : Enums.ENEMIES, pos : Vector2):
	if enemy_count >= phase_guard.get_max_alive() + BOSS_EXTRA_ALIVE:
		return
	spawn_enemy(_level_enemy(type), pos)

# levels share waves, a level can swap an enemy for its own (level 2: scout -> pebble mite)
func _level_enemy(type : Enums.ENEMIES) -> Enums.ENEMIES:
	return spawner.level_enemy(type)

func _on_boss_health_changed(value : int, max_value : int):
	bossBar.max_value = max_value
	bossBar.value = value

func _on_boss_enraged():
	phaseBanner.show_text("%s ENRAGED" % boss.get_enemy_name().to_upper(), Color.ORANGE_RED)
	Juice.shake(8.0)

func spawn_enemy(type : Enums.ENEMIES, pos : Vector2, life_factor : float = 1.0):
	return spawner.spawn(type, pos, life_factor)

func _on_bomb_taken(_type: Enums.WEAPONS):
	bomb.shoot_on_start(self, player.getSatelitePosition(), player.getShootingVector())
	Juice.shake(12.0)
	Juice.hitstop(0.1)

func _on_weapon_bullet_number_change(value):
	informationBox.setBulletCount(value)

# random point on a ring just outside the screen
func get_spawn_position() -> Vector2:
	return spawner.spawn_position()

func _clamp_to_level(pos : Vector2) -> Vector2:
	return spawner.clamp_to_level(pos)

func get_combo_multiplier() -> int:
	return combo_tracker.multiplier()

func _update_combo(delta):
	combo_tracker.update(delta)

func _add_combo():
	combo_tracker.add_kill()

func drop_xp(pos : Vector2, value : int):
	drops.drop_xp(pos, value)

func drop_shard(pos : Vector2, value : int):
	drops.drop_shard(pos, value)

func _on_enemy_killed(id : int):
	var enemy = spawner.unregister(id)

	if run_over:
		return

	kills += 1
	hud.set_kills(kills)
	_add_combo()
	Juice.shake(0.8)

	score.add_score(LevelSettings.get_points(enemy.enemy_kind) * get_combo_multiplier())
	drop_xp(enemy.position, LevelSettings.get_xp(enemy.enemy_kind))
	var shards = LevelSettings.get_shard_drop(enemy.enemy_kind)
	if shards > 0:
		drop_shard(enemy.position, shards)
	addPerk(enemy.position)

	if spawner.elites.has(id):
		drop_xp(enemy.position, 50)
		drop_shard(enemy.position, ELITE_SHARDS)
		Juice.hitstop(0.08)
		Juice.shake(8.0)
		phaseBanner.show_text("SUPPLY CRATE!", Color.CYAN)
		levelUpMenu.queue_chest()

	if enemy == boss:
		_on_boss_killed()

func _on_boss_killed():
	boss = null
	bossBar.visible = false
	phase_guard.on_boss_killed()
	Juice.hitstop(0.25, 0.02)
	Juice.shake(14.0)

	if phase_guard.is_final_boss_phase():
		level_complete()
	else:
		phaseBanner.show_text("BOSS DEFEATED", Color.GOLD)
		levelUpMenu.queue_chest()

# the final boss is dead - the level is won
func level_complete():
	var level = Levels.get_current()
	var bonus = level.get("victory_bonus", 0)
	score.add_score(bonus)
	phaseBanner.show_text("%s  +%d" % [level.get("win_text", "SECTOR CLEARED"), bonus], Color.GOLD)
	_end_run(false)
	world.find_child("PauseMenu").lock()
	# the swarm breaks up with its flagship gone (no score after run_over)
	kill_all_enemies()
	# the first clear unlocks the next level, the result screen offers it first
	var next = Levels.current + 1
	var first_clear = !Levels.is_completed(Levels.current)
	Levels.mark_completed(Levels.current)
	var next_level = next if first_clear and Levels.is_unlocked(next) else -1
	get_tree().create_timer(LEVEL_END_DELAY, false).connect("timeout", _show_level_result.bind(next_level))

func _show_level_result(next_level : int):
	gameOverMenu.show_result(score.get_score(), get_run_summary(), true, run_shards, next_level)

func get_run_summary() -> String:
	return "%s   %s   Lv %d   %d kills" % [Levels.get_current()["name"], phase_guard.get_time_text(), PlayerStatus.Level, kills]

func _end_run(died : bool):
	run_over = true
	_bank_shards(died)
	phase_guard.stop_phase(phase_guard.current_phase)
	meteor_spawn_timer.stop()
	for w in owned_weapons:
		if w.has_method("clear"):
			w.clear()

func _on_player_killed():
	# died after the level was won - the result screen comes from level_complete
	if run_over:
		return
	_end_run(true)

	var final_score = score.get_score()
	var summary = get_run_summary()
	gameOverMenu.show_result(final_score, summary, false, run_shards)

# every run counts - collected shards plus salvage go to the level's bank, won or lost
func _bank_shards(died : bool):
	var salvage = MetaProgress.get_salvage(phase_guard.elapsed, !died)
	var level = Levels.current
	run_shards = {
		"collected" : PlayerStatus.Shards,
		"salvage" : salvage,
		"bank" : MetaProgress.finish_run(level, PlayerStatus.Shards + salvage, died),
		"deaths" : MetaProgress.get_deaths(level),
	}


func _on_player_damage_taken(value):
	lifeBar.value = value

func _on_player_update_afterburner(value):
	afterburnerBar.value = value

func _on_player_update_shield(value):
	shieldBar.value = value

func addPerk(pos : Vector2) -> bool:
	return drops.add_random_perk(pos)

# public - dev console
func drop_perk(type : Enums.PERKS, pos : Vector2):
	drops.drop_perk(type, pos)

func find_nearest_enemy():
	var result = null
	var tmp = 1000000 # max distance 1000 px
	for enemy in active_enemies.values():
		var distance = player.position.distance_squared_to(enemy.position)
		if distance < tmp:
			tmp = distance
			result = enemy

	return result


func _on_meteor_spawn_timer_timeout() -> void:
	meteors.spawn()
