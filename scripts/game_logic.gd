extends Node

const VICTORY_BONUS = 5000
const ENDLESS_START_DELAY = 4.0
const BOSS_EXTRA_ALIVE = 5
const MAX_GEMS = 300
const SPAWN_MIN_DISTANCE = 950.0
const SPAWN_MAX_DISTANCE = 1100.0
const SWARM_RADIUS = 750.0
const ELITE_LIFE_FACTOR = 12
const ELITE_SCALE = 1.8
const COMBO_TIMEOUT = 2.0
const COMBO_STEPS = [10, 25, 50, 100]
const COMBO_NAMES = ["KILLING SPREE!", "RAMPAGE!", "UNSTOPPABLE!", "GODLIKE!"]
const CROWDED_ENEMY_COUNT = 120.0
const BASE_ZOOM = 1.25
const CROWDED_ZOOM = 1.0

var XpGemScript = preload("res://scripts/xp_gem.gd")
var RunHudScript = preload("res://scripts/run_hud.gd")
var levelUpMenuScene = preload("res://scenes/level_up_menu.tscn")

var enemy_count = 0
var meteor_count = 0
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
var active_enemies : Dictionary = {}
var elites : Dictionary = {}
var boss = null
var run_over = false
var kills = 0
var combo = 0
var combo_time_left = 0.0

@onready var phase_guard = $PhaseGuard
@onready var meteor_spawn_timer = $MeteorSpawnTimer
@onready var phase1_sound = $Phase1Sound
@onready var phase2_sound = $Phase2Sound
@onready var phase3_sound = $Phase3Sound
@onready var phase4_sound = $Phase4Sound
@onready var phase5_sound = $Phase5Sound

func _ready() -> void:
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
	levelUpMenu = levelUpMenuScene.instantiate()
	add_child(levelUpMenu)
	_update_weapons_hud()

	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	player.connect("update_shield", _on_player_update_shield)
	player.connect("killed", _on_player_killed)

	PlayerStatus.connect("xp_changed", _on_xp_changed)
	PlayerStatus.connect("leveled_up", _on_leveled_up)
	PlayerStatus.connect("max_life_changed", _on_max_life_changed)
	PlayerStatus.connect("max_shield_changed", _on_max_shield_changed)
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
		phase_guard.skip_time(phase_guard.RUN_LENGTH)

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
	if phase_guard.current_phase == Enums.PHASE.Survival and phase_guard.elapsed >= phase_guard.RUN_LENGTH - 60:
		hud.set_time_color(Color.RED)
	else:
		hud.set_time_color(Color.WHITE)

func _on_phase_started(phase : Enums.PHASE, _phase_name : String):
	if phase == Enums.PHASE.Endless:
		phaseBanner.show_text("ENDLESS MODE", Color.ORANGE)

func _on_stage_started(stage : int):
	if phase_guard.current_phase != Enums.PHASE.Survival:
		return

	# speech every two minutes
	var sounds = [phase1_sound, phase2_sound, phase3_sound, phase4_sound, phase5_sound]
	if stage % 2 == 0:
		var sound = sounds[min(stage / 2, sounds.size() - 1)]
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
			spawn_enemy(step.enemy, get_spawn_position())

func _on_swarm_requested(count : int):
	phaseBanner.show_text("SWARM INCOMING!", Color.RED)
	Juice.shake(4.0)
	var start_angle = randf() * TAU
	for i in range(count):
		var offset = Vector2(SWARM_RADIUS, 0).rotated(start_angle + i * TAU / count)
		spawn_enemy(Enums.ENEMIES.SCOUT, _clamp_to_level(player.global_position + offset))

func _on_elite_requested():
	phaseBanner.show_text("ELITE INCOMING", Color.MAGENTA)
	var elite = spawn_enemy(Enums.ENEMIES.GUARD, get_spawn_position(), ELITE_LIFE_FACTOR)
	elite.scale = Vector2(ELITE_SCALE, ELITE_SCALE)
	elite.modulate = Color(1.6, 0.6, 1.6)
	elites[elite.get_instance_id()] = true

func _on_boss_requested():
	phaseBanner.show_text("BOSS INCOMING", Color.RED)
	Juice.shake(10.0)
	boss = spawn_enemy(Enums.ENEMIES.BOSS, get_spawn_position())
	boss.connect("spawn_requested", _on_boss_spawn_requested)
	boss.connect("health_changed", _on_boss_health_changed)
	bossBar.max_value = boss.Life
	bossBar.value = boss.Life
	bossBar.visible = true

func _on_boss_spawn_requested(type : Enums.ENEMIES, pos : Vector2):
	if enemy_count >= phase_guard.get_max_alive() + BOSS_EXTRA_ALIVE:
		return
	spawn_enemy(type, pos)

func _on_boss_health_changed(value : int, max_value : int):
	bossBar.max_value = max_value
	bossBar.value = value

func spawn_enemy(type : Enums.ENEMIES, pos : Vector2, life_factor : float = 1.0):
	var enemy = LevelSettings.get_enemy(type)
	active_enemies[enemy.get_instance_id()] = enemy
	enemy.connect("killed", _on_enemy_killed)
	enemy.position = pos
	enemy.Life = int(enemy.Life * life_factor)

	# endless mode makes enemies stronger
	if phase_guard.difficulty > 1.0:
		enemy.Life = int(enemy.Life * phase_guard.difficulty)
		enemy.Damage = int(enemy.Damage * phase_guard.difficulty)

	world.add_child(enemy)
	enemy.setup_rotation(deg_to_rad(randi_range(0, 360)))

	enemy_count = enemy_count + 1
	informationBox.increaseEnemyCount()
	return enemy

func _on_bomb_taken(_type: Enums.WEAPONS):
	bomb.shoot_on_start(self, player.getSatelitePosition(), player.getShootingVector())
	Juice.shake(12.0)
	Juice.hitstop(0.1)

func _on_weapon_bullet_number_change(value):
	informationBox.setBulletCount(value)

# random point on a ring just outside the screen
func get_spawn_position() -> Vector2:
	for i in range(8):
		var offset = Vector2(randf_range(SPAWN_MIN_DISTANCE, SPAWN_MAX_DISTANCE), 0).rotated(randf() * TAU)
		var pos = player.global_position + offset
		if pos.x > LevelSettings.MinX and pos.x < LevelSettings.MaxX and pos.y > LevelSettings.MinY and pos.y < LevelSettings.MaxY:
			return pos

	return _clamp_to_level(player.global_position + Vector2(SPAWN_MIN_DISTANCE, 0).rotated(randf() * TAU))

func _clamp_to_level(pos : Vector2) -> Vector2:
	return Vector2(clamp(pos.x, LevelSettings.MinX, LevelSettings.MaxX), clamp(pos.y, LevelSettings.MinY, LevelSettings.MaxY))

func get_combo_multiplier() -> int:
	var multiplier = 1
	for step in COMBO_STEPS:
		if combo >= step:
			multiplier += 1
	return multiplier

func _update_combo(delta):
	if combo == 0:
		return

	combo_time_left -= delta
	hud.set_combo_alpha(clamp(combo_time_left / (COMBO_TIMEOUT * 0.5), 0.2, 1.0))
	if combo_time_left <= 0:
		combo = 0
		hud.set_combo(0, 1)

func _add_combo():
	combo += 1
	combo_time_left = COMBO_TIMEOUT
	hud.set_combo(combo, get_combo_multiplier())
	hud.set_combo_alpha(1.0)

	var index = COMBO_STEPS.find(combo)
	if index != -1:
		phaseBanner.show_text(COMBO_NAMES[index], Color.MAGENTA)
		Juice.shake(3.0)

func drop_xp(pos : Vector2, value : int):
	# too many gems on the floor - add the value to an existing one
	if XpGemScript.alive_count >= MAX_GEMS:
		var gems = get_tree().get_nodes_in_group("XpGem")
		if gems.size() > 0:
			gems.pick_random().add_value(value)
			return

	var gem = LevelSettings.get_xp_gem(value)
	gem.position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	call_deferred("add_child", gem)

func _on_enemy_killed(id : int):
	enemy_count = enemy_count - 1
	informationBox.decreaseEnemyCount()
	var enemy = active_enemies[id]
	active_enemies.erase(id)

	if run_over:
		return

	kills += 1
	hud.set_kills(kills)
	_add_combo()
	Juice.shake(0.8)

	var enemy_name = enemy.get_enemy_name()
	score.add_score(LevelSettings.get_points(enemy_name) * get_combo_multiplier())
	drop_xp(enemy.position, LevelSettings.get_xp(enemy_name))
	addPerk(enemy.position)

	if elites.has(id):
		elites.erase(id)
		drop_xp(enemy.position, 50)
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
	levelUpMenu.queue_chest()

	if phase_guard.current_phase == Enums.PHASE.Boss:
		victory()
	else:
		phaseBanner.show_text("BOSS DEFEATED", Color.GOLD)

func victory():
	score.add_score(VICTORY_BONUS)
	phaseBanner.show_text("SECTOR CLEARED  +" + str(VICTORY_BONUS), Color.GOLD)
	get_tree().create_timer(ENDLESS_START_DELAY, false).connect("timeout", _start_endless)

func _start_endless():
	if run_over:
		return
	phase_guard.start_endless()

func get_run_summary() -> String:
	return "%s   Lv %d   %d kills" % [phase_guard.get_time_text(), PlayerStatus.Level, kills]

func _on_player_killed():
	run_over = true
	phase_guard.stop_phase(phase_guard.current_phase)
	meteor_spawn_timer.stop()
	for w in owned_weapons:
		if w.has_method("clear"):
			w.clear()

	var final_score = score.get_score()
	var summary = get_run_summary()
	gameOverMenu.show_result(final_score, summary)


func _on_player_damage_taken(value):
	lifeBar.value = value

func _on_player_update_afterburner(value):
	afterburnerBar.value = value

func _on_player_update_shield(value):
	shieldBar.value = value

func addPerk(pos : Vector2) -> bool:
	var perk = LevelSettings.get_random_perk()
	if perk == null:
		return false

	if perk.get_perk_type() == Enums.PERKS.BOMB:
		perk.connect("taken", _on_bomb_taken)

	perk.position = pos
	call_deferred("add_child", perk)
	return true

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
	if meteor_count >= LevelSettings.MaxMeteorCount:
		return

	meteor_count += 1

	var meteor = LevelSettings.get_random_meteor()
	var tmp_pos = Vector2(randf_range(LevelSettings.MinX, LevelSettings.MaxX), randf_range(LevelSettings.MinY, LevelSettings.MaxY))
	meteor.set_global_position(tmp_pos)
	var temp_vel = Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
	meteor.velocity = temp_vel
	meteor.connect("destroyed", _on_meteor_destroyed)
	world.add_child(meteor)

	informationBox.increaseMeteorCount()


func _on_meteor_destroyed():
	meteor_count = meteor_count - 1
	informationBox.decreaseMeteorCount()
