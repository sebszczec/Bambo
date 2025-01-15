extends Node

@export_range (1, 400) var MaxEnemyCount : = 100

var enemy_count = 0
var world = null
var player = null
var enemy_counter_label = null

var ball_enemy_scene = preload("res://scenes/ball_enemy.tscn")

@onready var enemy_spawn_timer = $EnemySpawnTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world = get_parent()
	player = world.find_child("Player")
	enemy_counter_label = world.find_child("EnemyCounter")
	enemy_spawn_timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_enemy_spawn_timer_timeout() -> void:
	if enemy_count == MaxEnemyCount:
		return
	
	var enemy = ball_enemy_scene.instantiate()
	
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
	enemy_counter_label.text = "Enemies: " + str(enemy_count)
	
