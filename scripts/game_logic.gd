extends Node

@export_range (1, 400) var MaxEnemyCount : = 100

var enemy_count = 0
var world = null
var player = null
var informationBox = null
var lifeBar = null
var afterburnerBar = null
var canShoot = true

var ball_enemy_scene = preload("res://scenes/ball_enemy.tscn")
#var bulletScene = preload("res://scenes/bullet.tscn")
var bulletScene = preload("res://scenes/BigBullet.tscn")

@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var shootingTimer = $ShootingTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = get_parent()
	
	lifeBar = world.find_child("LifeBar")
	afterburnerBar = world.find_child("AfterburnerBar")
	
	player = world.find_child("Player")
	player.connect("update_life", _on_player_damage_taken)
	player.connect("update_afterburner", _on_player_update_afterburner)
	
	informationBox = world.find_child("InformationBox")
	enemy_spawn_timer.start()

func _physics_process(_delta):
	if Input.is_action_pressed("ui_shoot"):
		if canShoot:
			canShoot = false
			var bullet = bulletScene.instantiate()
			bullet.position = player.getSatelitePosition()
			bullet.velocity = player.getShootingVector()
			bullet.connect("freeing", _on_bullet_freeing)
			add_child(bullet)
			shootingTimer.start()
			
			informationBox.increaseBulletCount()


func _on_shooting_timer_timeout() -> void:
	canShoot = true

func _on_bullet_freeing():
	informationBox.decreaseBulletCount()

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
	
func _on_enemy_killed():
	enemy_count = enemy_count - 1
	informationBox.decreaseEnemyCount()


func _on_player_damage_taken(value):
	lifeBar.value = value
	
func _on_player_update_afterburner(value):
	afterburnerBar.value = value
