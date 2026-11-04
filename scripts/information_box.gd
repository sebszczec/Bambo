extends Control

var showFps = true
var showEnemyCount= true
var showBulletCount = true
var showMeteorCount = true

@onready var fps_counter = $CanvasLayer/BoxContainer/FpsCounter
@onready var enemy_counter = $CanvasLayer/BoxContainer/EnemyCounter
@onready var bullet_counter = $CanvasLayer/BoxContainer/BulletCounter
@onready var meteor_counter = $CanvasLayer/BoxContainer/MeteorCounter

var enemyCount = 0
var bulletCount = 0
var meteorCount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_visuals()
	ConfigHandler.visuals_changed.connect(_apply_visuals)
	meteor_counter.visible = true

# the pause menu can change these mid run
func _apply_visuals() -> void:
	var visualSettings = ConfigHandler.load_visuals()

	showFps = visualSettings["show_fps"]
	showEnemyCount = visualSettings["show_enemies_count"]
	showBulletCount = visualSettings["show_bullets_count"]

	fps_counter.visible = showFps
	enemy_counter.visible = showEnemyCount
	bullet_counter.visible = showBulletCount

const FPS_REFRESH = 0.25
var _fps_time = 0.0
var _shown_enemies = -1
var _shown_bullets = -1
var _shown_meteors = -1

# only the counters that changed get new text, a label relayouts on every write.
# The FPS readout is refreshed a few times a second, it would flicker otherwise.
func _process(delta: float) -> void:
	if showFps == true:
		_fps_time += delta
		if _fps_time >= FPS_REFRESH:
			_fps_time = 0.0
			fps_counter.text = "FPS: " + str(Engine.get_frames_per_second())
	if showEnemyCount == true and enemyCount != _shown_enemies:
		_shown_enemies = enemyCount
		enemy_counter.text = "Enemies: " + str(enemyCount)
	if showBulletCount == true and bulletCount != _shown_bullets:
		_shown_bullets = bulletCount
		bullet_counter.text = "Bullets: " + str(bulletCount)
	if showMeteorCount == true and meteorCount != _shown_meteors:
		_shown_meteors = meteorCount
		meteor_counter.text = "Meteors: " + str(meteorCount)

func increaseMeteorCount():
	meteorCount += 1


func decreaseMeteorCount():
	meteorCount -= 1


func increaseEnemyCount():
	enemyCount = enemyCount + 1


func decreaseEnemyCount():
	enemyCount = enemyCount - 1


func increaseBulletCount():
	bulletCount = bulletCount + 1


func decreaseBulletCount():
	bulletCount = bulletCount - 1


func setBulletCount(value):
	bulletCount = value
