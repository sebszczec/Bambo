extends Control

var showFps = true
var showEnemyCount= true
var showBulletCount = true

@onready var fps_counter = $CanvasLayer/BoxContainer/FpsCounter
@onready var enemy_counter = $CanvasLayer/BoxContainer/EnemyCounter
@onready var bullet_counter = $CanvasLayer/BoxContainer/BulletCounter

var enemyCount = 0
var bulletCount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var visualSettings = ConfigHandler.load_visuals()
	
	showFps = visualSettings["show_fps"]
	
	fps_counter.visible = showFps
	enemy_counter.visible = showEnemyCount
	bullet_counter.visible = showBulletCount


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if showFps == true:
		fps_counter.text = "FPS: " + str(Engine.get_frames_per_second())
	if showEnemyCount == true:
		enemy_counter.text = "Enemies: " + str(enemyCount)
	if showBulletCount == true:
		bullet_counter.text = "Bullets: " + str(bulletCount)


func increaseEnemyCount():
	enemyCount = enemyCount + 1


func decreaseEnemyCount():
	enemyCount = enemyCount - 1


func increaseBulletCount():
	bulletCount = bulletCount + 1


func decreaseBulletCount():
	bulletCount = bulletCount - 1
