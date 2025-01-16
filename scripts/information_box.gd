extends Control

@export var ShowFps = true
@export var ShowEnemyCount= true
@export var ShowBulletCount = true

@onready var fps_counter = $CanvasLayer/BoxContainer/FpsCounter
@onready var enemy_counter = $CanvasLayer/BoxContainer/EnemyCounter
@onready var bullet_counter = $CanvasLayer/BoxContainer/BulletCounter

var enemyCount = 0
var bulletCount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fps_counter.visible = ShowFps
	enemy_counter.visible = ShowEnemyCount
	bullet_counter.visible = ShowBulletCount


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if ShowFps == true:
		fps_counter.text = "FPS: " + str(Engine.get_frames_per_second())
	if ShowEnemyCount == true:
		enemy_counter.text = "Enemies: " + str(enemyCount)
	if ShowBulletCount == true:
		bullet_counter.text = "Bullets: " + str(bulletCount)


func enableShowFps():
	fps_counter.visible = true
	ShowFps = true


func disableShowFps():
	fps_counter.visible = false
	ShowFps = false


func enableShowEnemyCount():
	enemy_counter.visible = true
	ShowEnemyCount = true


func disableShowEnemyCount():
	enemy_counter.visible = false
	ShowEnemyCount = false


func enableShowBulletCount():
	bullet_counter.visible = true
	ShowBulletCount = true


func disableShowBulletCount():
	bullet_counter.visible = false
	ShowBulletCount = false


func increaseEnemyCount():
	enemyCount = enemyCount + 1


func decreaseEnemyCount():
	enemyCount = enemyCount - 1


func increaseBulletCount():
	bulletCount = bulletCount + 1


func decreaseBulletCount():
	bulletCount = bulletCount - 1
