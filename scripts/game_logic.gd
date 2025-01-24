extends Node

@export_range (1, 400) var MaxEnemyCount : int = 100
@export_range (0, 100) var ChanceForLifePerk : int = 5
@export_range (0, 100) var ChanceForShieldPerk : int = 5

var enemy_count = 0
var world = null
var score = null
var player = null
var informationBox = null
var lifeBar = null
var shieldBar = null
var afterburnerBar = null
var canShoot = true
var weapon = null
var weapons : Dictionary = {}
var points_dict : Dictionary = {}
var active_enemies : Dictionary = {}

enum WEAPONS {SMALL, BIG, SMALL_WAVE, SMALL_HOMING}
enum PERKS {LIFE, SHIELD}

var ball_enemy_scene = preload("res://scenes/ball_enemy.tscn")
var life_perk_scene = preload("res://scenes/life_perk.tscn")
var shield_perk_scene = preload("res://scenes/shield_perk.tscn")

@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var shootingTimer = $ShootingTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = get_parent()
	
	init_weapons()
	weapon = weapons[WEAPONS.SMALL]
	
	init_points_dict()
	
	score = world.find_child("Score")
	lifeBar = world.find_child("LifeBar")
	shieldBar = world.find_child("ShieldBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	
	player = world.find_child("Player")
	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	player.connect("update_shield", _on_player_update_shield)
	
	lifeBar.value = player.MaxLife
	shieldBar.value = player.MaxShield
	afterburnerBar.value = player.MaxAfterburner
	
	informationBox = world.find_child("InformationBox")
	enemy_spawn_timer.start()

func init_weapons():
	weapons[WEAPONS.SMALL] = SmallBullet.new()
	weapons[WEAPONS.SMALL].type = WEAPONS.SMALL
	weapons[WEAPONS.SMALL].set_owner(self)
	weapons[WEAPONS.BIG] = BigBullet.new()
	weapons[WEAPONS.BIG].type = WEAPONS.BIG
	weapons[WEAPONS.BIG].set_owner(self)
	weapons[WEAPONS.SMALL_WAVE] = SmallBulletWave.new()
	weapons[WEAPONS.SMALL_WAVE].type = WEAPONS.SMALL_WAVE
	weapons[WEAPONS.SMALL_WAVE].set_owner(self)
	weapons[WEAPONS.SMALL_HOMING] = SmallHomingBullet.new()
	weapons[WEAPONS.SMALL_HOMING].type = WEAPONS.SMALL_HOMING
	weapons[WEAPONS.SMALL_HOMING].set_owner(self)
	
	
	for w in weapons.values():
		w.register_internal_nodes(self)
		w.connect("bulletNumerChange", _on_weapon_bullet_number_change)


func init_points_dict():
	points_dict["BallEnemy"] = 10


func _physics_process(_delta):
	if Input.is_action_pressed("ui_shoot"):
		weapon.shoot(self, player.getSatelitePosition(), player.getShootingVector())
	
	if Input.is_action_just_pressed("ui_weapon_change"):
		if weapon.type == WEAPONS.size() - 1:
			weapon = weapons[0]
		else:
			weapon = weapons[weapon.type + 1]


func _on_weapon_bullet_number_change(value):
	informationBox.setBulletCount(value)


func _on_shooting_timer_timeout() -> void:
	canShoot = true

func _on_enemy_spawn_timer_timeout() -> void:
	if enemy_count == MaxEnemyCount:
		return
	
	var enemy = ball_enemy_scene.instantiate()
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
	var type = randi_range(0, 1)
	
	if type == PERKS.LIFE:
		var chance = randi_range(0, 100)
		if chance > ChanceForLifePerk:
			return false
		var perk = life_perk_scene.instantiate()
		perk.position = pos
		call_deferred("add_child", perk)
		return true
		
	if type == PERKS.SHIELD:
		var chance = randi_range(0, 100)
		if chance > ChanceForLifePerk:
			return false
		var perk = shield_perk_scene.instantiate()
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
	var type : WEAPONS
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

class BigBullet extends Weapon:
	func setup():
		shooting_delay = 0.2
		bullet_scene = preload("res://scenes/BigBullet.tscn")

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
