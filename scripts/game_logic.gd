extends Node

const VICTORY_BONUS = 5000
const ENDLESS_START_DELAY = 4.0
const BOSS_EXTRA_ALIVE = 5

var enemy_count = 0
var meteor_count = 0
var world = null
var score = null
var player = null
var informationBox = null
var lifeBar = null
var shieldBar = null
var afterburnerBar = null
var activePerk = null
var phaseBanner = null
var bossBar = null
var gameOverMenu = null
var weapon = null
var weapons : Dictionary = {}
var active_enemies : Dictionary = {}
var boss = null
var run_over = false

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

	init_weapons()
	PlayerStatus.CurrentWeapon = Enums.WEAPONS.SMALL
	weapon = weapons[PlayerStatus.CurrentWeapon]

	score = world.find_child("Score")
	lifeBar = world.find_child("LifeBar")
	shieldBar = world.find_child("ShieldBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	informationBox = world.find_child("InformationBox")
	activePerk = world.find_child("ActivePerk")
	phaseBanner = world.find_child("PhaseBanner")
	bossBar = world.find_child("BossBar")
	gameOverMenu = world.find_child("GameOverMenu")

	score.connect("score_changed", _on_score_changed)

	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	player.connect("update_shield", _on_player_update_shield)
	player.connect("killed", _on_player_killed)

	activePerk.connect("timeout", _on_active_perk_timeout)

	lifeBar.max_value = PlayerStatus.MaxLife
	lifeBar.value = PlayerStatus.MaxLife
	shieldBar.max_value = PlayerStatus.MaxShield
	shieldBar.value = PlayerStatus.MaxShield
	afterburnerBar.max_value = PlayerStatus.MaxAfterburner
	afterburnerBar.value = PlayerStatus.MaxAfterburner

	phase_guard.connect("phase_timeout", _on_phase_timeout)
	phase_guard.connect("phase_started", _on_phase_started)
	phase_guard.connect("boss_requested", _on_boss_requested)
	phase_guard.connect("difficulty_changed", _on_difficulty_changed)
	phase_guard.start_phase(Enums.PHASE.Phase1)

	meteor_spawn_timer.start()

func _exit_tree() -> void:
	InputManager.set_gameplay_cursor(false)

func init_weapons():
	weapons[Enums.WEAPONS.SMALL] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL, false, true)
	weapons[Enums.WEAPONS.BIG] = WeaponFactory.get_weapon(Enums.WEAPONS.BIG, false, true)
	weapons[Enums.WEAPONS.SMALL_WAVE] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL_WAVE, false, true)
	weapons[Enums.WEAPONS.SMALL_HOMING] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL_HOMING, false, true)
	weapons[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY, false, true)
	weapons[Enums.WEAPONS.FIREWORKS] = WeaponFactory.get_weapon(Enums.WEAPONS.FIREWORKS, false, true)
	weapons[Enums.WEAPONS.BOMB] = WeaponFactory.get_weapon(Enums.WEAPONS.BOMB, false, true)

	for w in weapons.values():
		w.set_owner(self)
		w.register_internal_nodes(player)
		w.connect("bulletNumerChange", _on_weapon_bullet_number_change)


func _physics_process(_delta):
	if player.isDead:
		return

	if Input.is_action_pressed("shoot"):
		weapon.shoot(self, player.getSatelitePosition(), player.getShootingVector())


func change_weapon(id: Enums.WEAPONS):
	if id >= Enums.WEAPONS.size():
		return

	PlayerStatus.CurrentWeapon = id
	weapon = weapons[PlayerStatus.CurrentWeapon]
	activePerk.changeState(PlayerStatus.CurrentWeapon)
	weapon.shoot_on_start(self, player.getSatelitePosition(), player.getShootingVector())

func _on_score_changed(value : int):
	phase_guard.check_score(value)

func _on_phase_started(phase : Enums.PHASE, phase_name : String):
	var sounds = [phase1_sound, phase2_sound, phase3_sound, phase4_sound, phase5_sound]
	var sound = sounds[min(phase, sounds.size() - 1)]
	sound.position = player.position
	sound.play()

	if phase == Enums.PHASE.Boss:
		return # boss banner is shown when the boss is spawned
	elif phase == Enums.PHASE.Endless:
		phaseBanner.show_text("ENDLESS MODE", Color.ORANGE)
	else:
		phaseBanner.show_text(phase_name.to_upper())

func _on_difficulty_changed(value : float):
	phaseBanner.show_text("DIFFICULTY x%0.2f" % value, Color.ORANGE_RED)

func _on_phase_timeout(value):
	for step in value:
		for i in range(step.count):
			if enemy_count >= phase_guard.get_max_alive():
				return
			spawn_enemy(step.enemy, get_spawn_position())

func _on_boss_requested():
	phaseBanner.show_text("BOSS INCOMING", Color.RED)
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

func spawn_enemy(type : Enums.ENEMIES, pos : Vector2):
	var enemy = LevelSettings.get_enemy(type)
	active_enemies[enemy.get_instance_id()] = enemy
	enemy.connect("killed", _on_enemy_killed)
	enemy.position = pos

	# endless mode makes enemies stronger
	if phase_guard.difficulty > 1.0:
		enemy.Life = int(enemy.Life * phase_guard.difficulty)
		enemy.Damage = int(enemy.Damage * phase_guard.difficulty)

	world.add_child(enemy)
	enemy.setup_rotation(deg_to_rad(randi_range(0, 360)))

	enemy_count = enemy_count + 1
	informationBox.increaseEnemyCount()
	return enemy

func _on_active_perk_timeout(type: Enums.WEAPONS):
	change_weapon(type)

func _on_weapon_perk_taken(type: Enums.WEAPONS):
	change_weapon(type)

func _on_weapon_bullet_number_change(value):
	informationBox.setBulletCount(value)

func get_spawn_position() -> Vector2:
	return Vector2(get_new_enemy_position(player.position.x, LevelSettings.MinX, LevelSettings.MaxX),
		get_new_enemy_position(player.position.y, LevelSettings.MinY, LevelSettings.MaxY))

func get_new_enemy_position(player_position : float, min_value: float, max_value : float) -> float:
	var left_or_right = -1
	if randi_range(0, 1) == 1:
		left_or_right = 1

	var result = player_position + randf_range(300, 350) * left_or_right

	if result < min_value  or result > max_value:
		result = player_position - randf_range(300, 350) * left_or_right

	return clamp(result, min_value, max_value)


func _on_enemy_killed(id : int):
	enemy_count = enemy_count - 1
	informationBox.decreaseEnemyCount()
	var enemy = active_enemies[id]
	active_enemies.erase(id)

	if run_over:
		return

	score.add_score(LevelSettings.get_points(enemy.get_enemy_name()))
	addPerk(enemy.position)

	if enemy == boss:
		_on_boss_killed()

func _on_boss_killed():
	boss = null
	bossBar.visible = false
	phase_guard.on_boss_killed()

	if phase_guard.current_phase == Enums.PHASE.Boss:
		victory()
	else:
		phaseBanner.show_text("BOSS DEFEATED", Color.GOLD)

func victory():
	score.add_score(VICTORY_BONUS)
	phaseBanner.show_text("SECTOR CLEARED  +" + str(VICTORY_BONUS), Color.GOLD)
	ConfigHandler.save_run_result(score.get_score(), phase_guard.get_phase_name())
	get_tree().create_timer(ENDLESS_START_DELAY, false).connect("timeout", _start_endless)

func _start_endless():
	if run_over:
		return
	phase_guard.start_endless(score.get_score())

func _on_player_killed():
	run_over = true
	phase_guard.stop_phase(phase_guard.current_phase)
	meteor_spawn_timer.stop()

	var final_score = score.get_score()
	var new_record = ConfigHandler.save_run_result(final_score, phase_guard.get_phase_name())
	gameOverMenu.show_result(final_score, phase_guard.get_phase_name(), ConfigHandler.get_high_score(), new_record)


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

	if perk.get_perk_type() >= Enums.PERKS.BIG_GUN:
		perk.connect("taken", _on_weapon_perk_taken)

	perk.position = pos
	call_deferred("add_child", perk)
	return true

func find_nearest_enemy():
	var result = null
	var tmp = 1000000 # TODO: define max distance
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
