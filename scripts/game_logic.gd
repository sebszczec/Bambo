extends Node

@export_range (1, 400) var MaxEnemyCount : int = 2
@export_range (0, 100) var ChanceForLifePerk : int = 100
@export_range (0, 100) var ChanceForShieldPerk : int = 100
@export_range (0, 100) var ChanceForBigGunPerk : int = 100
@export_range (0, 100) var ChanceForWavePerk : int = 100
@export_range (0, 100) var ChanceForHomingPerk : int = 100

var enemy_count = 0
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
var points_dict : Dictionary = {}
var active_enemies : Dictionary = {}

var enemy_scenes = [preload("res://scenes/enemy_1.tscn"), preload("res://scenes/enemy_2.tscn"), preload("res://scenes/enemy_3.tscn")]
var life_perk_scene = preload("res://scenes/life_perk.tscn")
var shield_perk_scene = preload("res://scenes/shield_perk.tscn")
var big_gun_perk_scene = preload("res://scenes/big_gun_perk.tscn")
var wave_perk_scene = preload("res://scenes/wave_perk.tscn")
var homing_perk_scene = preload("res://scenes/homing_perk.tscn")

@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var shootingTimer = $ShootingTimer


func _ready() -> void:
	world = get_parent()
	player = world.find_child("Player")
	
	init_weapons()
	weapon = weapons[Enums.WEAPONS.SMALL]
	
	init_points_dict()
	
	score = world.find_child("Score")
	lifeBar = world.find_child("LifeBar")
	shieldBar = world.find_child("ShieldBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	informationBox = world.find_child("InformationBox")
	activePerk = world.find_child("ActivePerk")
	
	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	player.connect("update_shield", _on_player_update_shield)
	
	activePerk.connect("timeout", _on_active_perk_timeout)
	
	lifeBar.value = player.MaxLife
	shieldBar.value = player.MaxShield
	afterburnerBar.value = player.MaxAfterburner
	
	enemy_spawn_timer.start()
	

func init_weapons():
	weapons[Enums.WEAPONS.SMALL] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL, false, true)
	weapons[Enums.WEAPONS.SMALL].set_owner(self)
	weapons[Enums.WEAPONS.BIG] = WeaponFactory.get_weapon(Enums.WEAPONS.BIG, false, true)
	weapons[Enums.WEAPONS.BIG].set_owner(self)
	weapons[Enums.WEAPONS.SMALL_WAVE] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL_WAVE, false, true)
	weapons[Enums.WEAPONS.SMALL_WAVE].set_owner(self)
	weapons[Enums.WEAPONS.SMALL_HOMING] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL_HOMING, false, true)
	weapons[Enums.WEAPONS.SMALL_HOMING].set_owner(self)
	weapons[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY] = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY, false, true)
	weapons[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY].set_owner(self)
	weapons[Enums.WEAPONS.FIREWORKS] = WeaponFactory.get_weapon(Enums.WEAPONS.FIREWORKS, false, true)
	weapons[Enums.WEAPONS.FIREWORKS].set_owner(self)
	
	for w in weapons.values():
		w.register_internal_nodes(player)
		w.connect("bulletNumerChange", _on_weapon_bullet_number_change)


func init_points_dict():
	points_dict["Enemy 1"] = 10
	points_dict["Enemy 2"] = 20
	points_dict["Enemy 3"] = 20


func _physics_process(_delta):
	if Input.is_action_pressed("ui_shoot"):
		weapon.shoot(self, player.getSatelitePosition(), player.getShootingVector())


func change_weapon(id: int):
	if id >= Enums.WEAPONS.size():
		return
	
	weapon = weapons[id]

func _on_active_perk_timeout(type: Enums.WEAPONS):
	weapon = weapons[type]

func _on_weapon_perk_taken(type: Enums.WEAPONS):
	weapon = weapons[type]
	activePerk.changeState(type)

func _on_weapon_bullet_number_change(value):
	informationBox.setBulletCount(value)

func _on_shooting_timer_timeout() -> void:
	canShoot = true

func _on_enemy_spawn_timer_timeout() -> void:
	if enemy_count == MaxEnemyCount:
		return

	var enemy = enemy_scenes[randi_range(0, enemy_scenes.size() - 1)].instantiate()
	active_enemies[enemy.get_instance_id()] = enemy
	enemy.connect("killed", _on_enemy_killed)
	
	var left_or_right = -1
	if randi_range(0, 1) == 1:
		left_or_right = 1
	
	var up_or_down = -1
	if randi_range(0, 1) == 1: 
		up_or_down = 1
	
	enemy.position.x = player.position.x + randf_range(100, 200) * left_or_right
	enemy.position.y = player.position.y + randf_range(100, 200) * up_or_down
	
	world.add_child(enemy)
	enemy.setup_rotation(deg_to_rad(randi_range(0, 360)))
	
	enemy_count = enemy_count + 1
	informationBox.increaseEnemyCount()
	
func _on_enemy_killed(id : int):
	enemy_count = enemy_count - 1
	informationBox.decreaseEnemyCount()
	var enemy = active_enemies[id]
	score.add_score(points_dict[enemy.get_enemy_name()])
	active_enemies.erase(id)
	addPerk(enemy.position)


func _on_player_damage_taken(value):
	lifeBar.value = value
	
func _on_player_update_afterburner(value):
	afterburnerBar.value = value
	
func _on_player_update_shield(value):
	shieldBar.value = value

func addPerk(pos : Vector2):
	var type = randi_range(0, Enums.PERKS.size() - 1)
	var chance = randi_range(0, 100)
	var perk = null
	
	if type == Enums.PERKS.LIFE:
		if chance > ChanceForLifePerk:
			return false
		perk = life_perk_scene.instantiate()
	elif type == Enums.PERKS.SHIELD:
		if chance > ChanceForLifePerk:
			return false
		perk = shield_perk_scene.instantiate()
	elif type == Enums.PERKS.BIG_GUN:
		if chance > ChanceForBigGunPerk:
			return false
		perk = big_gun_perk_scene.instantiate()
		perk.connect("taken", _on_weapon_perk_taken)
	elif type == Enums.PERKS.WAVE:
		if chance > ChanceForWavePerk:
			return false
		perk = wave_perk_scene.instantiate()
		perk.connect("taken", _on_weapon_perk_taken)
	elif type == Enums.PERKS.HOMING:
		if chance > ChanceForHomingPerk:
			return false
		perk = homing_perk_scene.instantiate()
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
