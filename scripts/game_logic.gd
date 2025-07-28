extends Node

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
var canShoot = true
var weapon = null
var weapons : Dictionary = {}
var active_enemies : Dictionary = {}

@onready var phase_guard = $PhaseGuard
@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var meteor_spawn_timer = $MeteorSpawnTimer
@onready var shootingTimer = $ShootingTimer
@onready var phase1_sound = $Phase1Sound
@onready var phase2_sound = $Phase2Sound
@onready var phase3_sound = $Phase3Sound
@onready var phase4_sound = $Phase4Sound
@onready var phase5_sound = $Phase5Sound

func _ready() -> void:
	world = get_parent()
	player = world.find_child("Player")
	
	init_weapons()
	PlayerStatus.CurrentWeapon = Enums.WEAPONS.SMALL
	weapon = weapons[PlayerStatus.CurrentWeapon]
	
	score = world.find_child("Score")
	lifeBar = world.find_child("LifeBar")
	shieldBar = world.find_child("ShieldBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	informationBox = world.find_child("InformationBox")
	activePerk = world.find_child("ActivePerk")
	
	score.connect("reached_1000_points", _on_reached_1000_points)
	score.connect("reached_2000_points", _on_reached_2000_points)
	score.connect("reached_4000_points", _on_reached_4000_points)
	score.connect("reached_7000_points", _on_reached_7000_points)
	
	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	player.connect("update_shield", _on_player_update_shield)
	
	activePerk.connect("timeout", _on_active_perk_timeout)
	
	lifeBar.value = PlayerStatus.MaxLife
	shieldBar.value = PlayerStatus.MaxShield
	afterburnerBar.value = PlayerStatus.MaxAfterburner
	
	#enemy_spawn_timer.start()
	phase_guard.connect("phase_timeout", _on_phase_timeout)
	phase_guard.start_phase(Enums.PHASE.Phase1)
	phase1_sound.position = player.position
	phase1_sound.play()
	
	meteor_spawn_timer.start()
	

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
	if Input.is_action_pressed("ui_shoot"):
		weapon.shoot(self, player.getSatelitePosition(), player.getShootingVector())


func change_weapon(id: Enums.WEAPONS):
	if id >= Enums.WEAPONS.size():
		return
	
	PlayerStatus.CurrentWeapon = id
	weapon = weapons[PlayerStatus.CurrentWeapon]
	activePerk.changeState(PlayerStatus.CurrentWeapon)
	weapon.shoot_on_start(self, player.getSatelitePosition(), player.getShootingVector())

func _on_reached_1000_points():
	phase_guard.start_phase(Enums.PHASE.Phase2)
	phase2_sound.position = player.position
	phase2_sound.play()
	
func _on_reached_2000_points():
	phase_guard.start_phase(Enums.PHASE.Phase3)
	phase3_sound.position = player.position
	phase3_sound.play()
	
func _on_reached_4000_points():
	phase_guard.start_phase(Enums.PHASE.Phase4)
	phase4_sound.position = player.position
	phase4_sound.play()
	
func _on_reached_7000_points():
	phase_guard.start_phase(Enums.PHASE.Phase5)
	phase5_sound.position = player.position
	phase5_sound.play()

func _on_phase_timeout(value):
	for step in value:
		for i in range(step.count):
			var enemy = LevelSettings.get_enemy(step.enemy)
			active_enemies[enemy.get_instance_id()] = enemy
			enemy.connect("killed", _on_enemy_killed)
			
			enemy.position.x = get_new_enemy_position(player.position.x, LevelSettings.MinX, LevelSettings.MaxX)
			enemy.position.y = get_new_enemy_position(player.position.y, LevelSettings.MinY, LevelSettings.MaxY)
			
			world.add_child(enemy)
			enemy.setup_rotation(deg_to_rad(randi_range(0, 360)))
			
			enemy_count = enemy_count + 1
			informationBox.increaseEnemyCount()

func _on_active_perk_timeout(type: Enums.WEAPONS):
	change_weapon(type)

func _on_weapon_perk_taken(type: Enums.WEAPONS):
	change_weapon(type)

func _on_weapon_bullet_number_change(value):
	informationBox.setBulletCount(value)

func _on_shooting_timer_timeout() -> void:
	canShoot = true

func _on_enemy_spawn_timer_timeout() -> void:
	if enemy_count == LevelSettings.MaxEnemyCount:
		return

	var enemy = LevelSettings.get_random_enemy()
	active_enemies[enemy.get_instance_id()] = enemy
	enemy.connect("killed", _on_enemy_killed)
	
	enemy.position.x = get_new_enemy_position(player.position.x, LevelSettings.MinX, LevelSettings.MaxX)
	enemy.position.y = get_new_enemy_position(player.position.y, LevelSettings.MinY, LevelSettings.MaxY)
	
	world.add_child(enemy)
	enemy.setup_rotation(deg_to_rad(randi_range(0, 360)))
	
	enemy_count = enemy_count + 1
	informationBox.increaseEnemyCount()
	
func get_new_enemy_position(player_position : float, min_value: float, max_value : float) -> float:
	var left_or_right = -1
	if randi_range(0, 1) == 1:
		left_or_right = 1
		
	var result = player_position + randf_range(300, 350) * left_or_right
	
	if result < min_value  or result > max_value:
		result = get_new_enemy_position(player_position, min_value, max_value)
	
	return result

	
func _on_enemy_killed(id : int):
	enemy_count = enemy_count - 1
	informationBox.decreaseEnemyCount()
	var enemy = active_enemies[id]
	score.add_score(LevelSettings.get_points(enemy.get_enemy_name()))
	active_enemies.erase(id)
	addPerk(enemy.position)


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
