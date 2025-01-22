extends Node

@export_range (1, 400) var MaxEnemyCount : int = 100
@export_range (0, 100) var ChanceForLifePerk : int = 5

var enemy_count = 0
var world = null
var player = null
var informationBox = null
var lifeBar = null
var afterburnerBar = null
var canShoot = true
var weapon = null
var weapons = {}

enum WEAPONS {SMALL, BIG, SMALL_WAVE}
enum PERKS {Life}

var ball_enemy_scene = preload("res://scenes/ball_enemy.tscn")
var life_perk_scene = preload("res://scenes/life_perk.tscn")

@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var shootingTimer = $ShootingTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = get_parent()
	
	init_weapons()
	weapon = weapons[WEAPONS.SMALL]
	
	lifeBar = world.find_child("LifeBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	
	player = world.find_child("Player")
	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	
	informationBox = world.find_child("InformationBox")
	enemy_spawn_timer.start()

func init_weapons():
	weapons[WEAPONS.SMALL] = SmallBullet.new()
	weapons[WEAPONS.SMALL].type = WEAPONS.SMALL
	weapons[WEAPONS.BIG] = BigBullet.new()
	weapons[WEAPONS.BIG].type = WEAPONS.BIG
	weapons[WEAPONS.SMALL_WAVE] = SmallBulletWave.new()
	weapons[WEAPONS.SMALL_WAVE].type = WEAPONS.SMALL_WAVE
	
	for w in weapons.values():
		w.register_internal_nodes(self)
		w.connect("bulletNumerChange", _on_weapon_bullet_number_change)
	

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
	
func _on_enemy_killed(enemy_position : Vector2):
	enemy_count = enemy_count - 1
	informationBox.decreaseEnemyCount()
	
	addPerk(PERKS.Life, enemy_position)


func _on_player_damage_taken(value):
	lifeBar.value = value
	
func _on_player_update_afterburner(value):
	afterburnerBar.value = value

func addPerk(type: PERKS, pos : Vector2):
	if type == PERKS.Life:
		var chance = randi_range(0, 100)
		if chance > ChanceForLifePerk:
			return
		var perk = life_perk_scene.instantiate()
		perk.position = pos
		add_child(perk)

class Weapon:
	var canShoot = true
	var timer = Timer.new()
	var shooting_delay = 0
	var bulletScene = null
	var bulletNumber = 0
	var type : WEAPONS
	signal bulletNumerChange
	
	func _init() -> void:
		setup()
		timer.wait_time = shooting_delay
		timer.connect("timeout", _on_timer_timeout)
	
	func setup():
		shooting_delay = 0.1
		bulletScene = preload("res://scenes/bullet.tscn")
	
	func _on_timer_timeout():
		canShoot = true
	
	func register_internal_nodes(owner: Node):
		owner.add_child(timer)
	
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			canShoot = false
			var bullet = bulletScene.instantiate()
			bullet.position = start_position
			bullet.velocity = direction
			bullet.connect("freeing", _on_bullet_freeing)
			owner.add_child(bullet)
			timer.start()
				
			updateBulletNumber(1)
	
	func _on_bullet_freeing():
		updateBulletNumber(-1)

		
	func updateBulletNumber(diff):
		bulletNumber += diff
		bulletNumerChange.emit(bulletNumber)


class SmallBullet extends Weapon:
	pass

class BigBullet extends Weapon:
	func setup():
		shooting_delay = 0.2
		bulletScene = preload("res://scenes/BigBullet.tscn")

class SmallBulletWave extends SmallBullet:
	var size = 30
	var speed = 5
	var min_damage = 25
	var max_damage = 50
	var life_time = 1
	
	func setup():
		super.setup()
		shooting_delay = 1
		
	func shoot(owner: Node, start_position: Vector2, _direction: Vector2):
		if canShoot:
			canShoot = false
			var radial_increment = (2.0 * PI) / float(size)
			for i in range (0, size):
				var bullet = bulletScene.instantiate()
				bullet.Speed = speed
				bullet.MinDamage = min_damage
				bullet.MaxDamage = max_damage
				bullet.LifeTime = life_time
				
				var radial_v = Vector2(0.1, 0).rotated(i * radial_increment)
				bullet.position = start_position + radial_v
				bullet.velocity = radial_v
				bullet.connect("freeing", _on_bullet_freeing)
				owner.add_child(bullet)
			
			timer.start()	
			updateBulletNumber(size)
