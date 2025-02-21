extends Node

@export_range (1, 400) var MaxEnemyCount : int = 20
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

var enemy_scenes = [preload("res://scenes/enemy_1.tscn"), preload("res://scenes/enemy_2.tscn")]
var life_perk_scene = preload("res://scenes/life_perk.tscn")
var shield_perk_scene = preload("res://scenes/shield_perk.tscn")
var big_gun_perk_scene = preload("res://scenes/big_gun_perk.tscn")
var wave_perk_scene = preload("res://scenes/wave_perk.tscn")
var homing_perk_scene = preload("res://scenes/homing_perk.tscn")

@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var shootingTimer = $ShootingTimer


func _ready() -> void:
	world = get_parent()
	
	init_weapons()
	weapon = weapons[Enums.WEAPONS.SMALL]
	
	init_points_dict()
	
	score = world.find_child("Score")
	lifeBar = world.find_child("LifeBar")
	shieldBar = world.find_child("ShieldBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	informationBox = world.find_child("InformationBox")
	activePerk = world.find_child("ActivePerk")
	
	player = world.find_child("Player")
	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	player.connect("update_shield", _on_player_update_shield)
	
	activePerk.connect("timeout", _on_active_perk_timeout)
	
	lifeBar.value = player.MaxLife
	shieldBar.value = player.MaxShield
	afterburnerBar.value = player.MaxAfterburner
	
	enemy_spawn_timer.start()
	

func init_weapons():
	weapons[Enums.WEAPONS.SMALL] = SmallBullet.new()
	weapons[Enums.WEAPONS.SMALL].type = Enums.WEAPONS.SMALL
	weapons[Enums.WEAPONS.SMALL].set_owner(self)
	weapons[Enums.WEAPONS.BIG] = BigBullet.new()
	weapons[Enums.WEAPONS.BIG].type = Enums.WEAPONS.BIG
	weapons[Enums.WEAPONS.BIG].set_owner(self)
	weapons[Enums.WEAPONS.SMALL_WAVE] = SmallBulletWave.new()
	weapons[Enums.WEAPONS.SMALL_WAVE].type = Enums.WEAPONS.SMALL_WAVE
	weapons[Enums.WEAPONS.SMALL_WAVE].set_owner(self)
	weapons[Enums.WEAPONS.SMALL_HOMING] = SmallHomingBullet.new()
	weapons[Enums.WEAPONS.SMALL_HOMING].type = Enums.WEAPONS.SMALL_HOMING
	weapons[Enums.WEAPONS.SMALL_HOMING].set_owner(self)
	weapons[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY] = SmallHomingBulletWithDelay.new()
	weapons[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY].type = Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY
	weapons[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY].set_owner(self)
	
	for w in weapons.values():
		w.register_internal_nodes(self)
		w.connect("bulletNumerChange", _on_weapon_bullet_number_change)


func init_points_dict():
	points_dict["Enemy 1"] = 10
	points_dict["Enemy 2"] = 20


func _physics_process(_delta):
	if Input.is_action_pressed("ui_shoot"):
		weapon.shoot(self, player.getSatelitePosition(), player.getShootingVector())
	
	if Input.is_action_just_pressed("ui_weapon_change"):
		if weapon.type == Enums.WEAPONS.size() - 1:
			weapon = weapons[0]
		else:
			weapon = weapons[weapon.type + 1]
	
	if Input.is_action_just_pressed("ui_weapon_1"):
		change_weapon(0)
	
	if Input.is_action_just_pressed("ui_weapon_2"):
		change_weapon(1)
	
	if Input.is_action_just_pressed("ui_weapon_3"):
		change_weapon(2)
	
	if Input.is_action_just_pressed("ui_weapon_4"):
		change_weapon(3)
		
	if Input.is_action_just_pressed("ui_weapon_5"):
		change_weapon(4)
		
	if Input.is_action_just_pressed("ui_weapon_6"):
		change_weapon(5)
		
	if Input.is_action_just_pressed("ui_weapon_7"):
		change_weapon(6)
		
	if Input.is_action_just_pressed("ui_weapon_8"):
		change_weapon(7)
		
	if Input.is_action_just_pressed("ui_weapon_9"):
		change_weapon(8)

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

	var enemy = enemy_scenes[randi_range(0, 1)].instantiate()
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


class Weapon:
	var object_owner = null
	var canShoot = true
	var timer = Timer.new()
	var shooting_delay = 0
	var bullet_scene = null
	var bullet_number = 0
	var speed = 20
	var life_time = 0.5
	var type : Enums.WEAPONS
	signal bulletNumerChange
	
	func _init() -> void:
		setup()
		timer.wait_time = shooting_delay
		timer.connect("timeout", _on_timer_timeout)
	
	func setup():
		shooting_delay = 0.1
		bullet_scene = preload("res://scenes/bullet.tscn")
		
	func set_owner(owner):
		object_owner = owner
	
	func _on_timer_timeout():
		canShoot = true
	
	func register_internal_nodes(owner: Node):
		owner.add_child(timer)
	
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			canShoot = false
			var bullet = bullet_scene.instantiate()
			bullet.position = start_position
			bullet.velocity = direction
			bullet.Speed = speed
			bullet.LifeTime = life_time
			bullet.connect("freeing", _on_bullet_freeing)
			owner.add_child(bullet)
			timer.start()
				
			updateBulletNumber(1)
	
	func _on_bullet_freeing():
		updateBulletNumber(-1)

		
	func updateBulletNumber(diff):
		bullet_number += diff
		bulletNumerChange.emit(bullet_number)


class SmallBullet extends Weapon:
	pass
	
class SmallHomingBullet extends SmallBullet:
	func setup():
		super.setup()
		shooting_delay = 0.2
		speed = 5
		life_time = 1
		
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		var enemy = object_owner.find_nearest_enemy()
		if enemy != null:
			super.shoot(owner, start_position, enemy.position - start_position)
		else:
			super.shoot(owner, start_position, direction)

class SmallHomingBulletWithDelay extends SmallBullet:
	func setup():
		super.setup()
		shooting_delay = 0.2
		speed = 10
		life_time = 1
		
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			canShoot = false
			var bullet = bullet_scene.instantiate()
			bullet.position = start_position
			bullet.velocity = direction
			bullet.Speed = speed
			bullet.LifeTime = life_time
			bullet.connect("freeing", _on_bullet_freeing)
			
			var homing_timer = Timer.new()
			homing_timer.one_shot = true
			homing_timer.wait_time = 0.1
			homing_timer.connect("timeout", _homing_timer_on_timeout.bind(bullet))
			bullet.add_child(homing_timer)
			
			owner.add_child(bullet)
			timer.start()
			homing_timer.start()
				
			updateBulletNumber(1)
	
	func _homing_timer_on_timeout(bullet):
		var enemy = object_owner.find_nearest_enemy()
		if enemy != null:
			bullet.velocity = enemy.position - bullet.position

class BigBullet extends Weapon:
	func setup():
		shooting_delay = 0.2
		bullet_scene = preload("res://scenes/big_bullet.tscn")

class SmallBulletWave extends SmallBullet:
	var size = 30
	var min_damage = 25
	var max_damage = 50
	
	func setup():
		super.setup()
		shooting_delay = 1
		speed = 5
		
	func shoot(owner: Node, start_position: Vector2, _direction: Vector2):
		if canShoot:
			canShoot = false
			var radial_increment = (2.0 * PI) / float(size)
			for i in range (0, size):
				var bullet = bullet_scene.instantiate()
				bullet.Speed = speed
				bullet.MinDamage = min_damage
				bullet.MaxDamage = max_damage
				bullet.LifeTime = 1
				
				var radial_v = Vector2(0.1, 0).rotated(i * radial_increment)
				bullet.position = start_position + radial_v
				bullet.velocity = radial_v
				bullet.connect("freeing", _on_bullet_freeing)
				owner.add_child(bullet)
			
			timer.start()	
			updateBulletNumber(size)
