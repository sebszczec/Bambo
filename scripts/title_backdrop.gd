extends Node2D

# Attract mode behind the title: meteors drift by and the player's UFO chases enemy ships across the screen.

const SCREEN = Vector2(1920, 1080)
const METEORS = [
	preload("res://resources/meteors/Meteor_02.png"),
	preload("res://resources/meteors/Meteor_05.png"),
	preload("res://resources/meteors/Meteor_07.png"),
	preload("res://resources/meteors/Meteor_10.png"),
]
const ENEMIES = [
	preload("res://resources/kenney_space-shooter-redux/PNG/Enemies/enemyGreen1.png"),
]
# animated enemy sprite sheets (see the json next to each png), drawn nose right
const SHEETS = [
	{ "texture" : preload("res://resources/basic_enemy1/scout_24fps.png"), "grid" : Vector2i(6, 10), "frames" : 59, "fps" : 24.0, "scale" : 1.0 },
	{ "texture" : preload("res://resources/scanning_enemy/guard_24fps.png"), "grid" : Vector2i(5, 16), "frames" : 80, "fps" : 24.0, "scale" : 0.9 },
]
const UFO = preload("res://resources/player_spritesheets/ufo/ufo_sample2_spritesheet.png")
const LASER = preload("res://resources/kenney_space-shooter-redux/PNG/Lasers/laserBlue01.png")

const SPAWN_INTERVAL = Vector2(2.0, 4.0)
const CHASE_GAP = 260.0
const SHOT_INTERVAL = 0.2
const SHOT_SPEED = 1400.0
const UFO_FRAMES = 20
const UFO_FPS = 20.0

var _spawn_timer = 0.5
var _movers : Array = []

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(SPAWN_INTERVAL.x, SPAWN_INTERVAL.y)
		if randf() < 0.5:
			_spawn_meteor()
		else:
			_spawn_chase()

	for mover in _movers.duplicate():
		var sprite : Sprite2D = mover["sprite"]
		sprite.position += mover["velocity"] * delta
		sprite.rotation += mover.get("spin", 0.0) * delta

		if mover.has("frame_time"):
			mover["frame_time"] += delta
			sprite.frame = int(mover["frame_time"] * mover["fps"]) % mover["frames"]
		if mover.has("shot_time"):
			mover["shot_time"] -= delta
			if mover["shot_time"] <= 0.0:
				mover["shot_time"] = SHOT_INTERVAL
				_spawn_shot(sprite.position, mover["velocity"].normalized())

		if !Rect2(Vector2.ZERO, SCREEN).grow(400).has_point(sprite.position):
			sprite.queue_free()
			_movers.erase(mover)

func _random_path() -> Array:
	# enter from the left or right edge and leave on the other side
	var from_left = randf() < 0.5
	var start = Vector2(-150 if from_left else SCREEN.x + 150, randf_range(SCREEN.y * 0.35, SCREEN.y * 0.95))
	var end = Vector2(SCREEN.x + 150 if from_left else -150, randf_range(SCREEN.y * 0.35, SCREEN.y * 0.95))
	return [start, (end - start).normalized()]

func _add_mover(texture : Texture2D, pos : Vector2, velocity : Vector2, alpha : float) -> Dictionary:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.modulate.a = alpha
	add_child(sprite)
	var mover = { "sprite" : sprite, "velocity" : velocity }
	_movers.append(mover)
	return mover

func _spawn_meteor():
	var path = _random_path()
	var mover = _add_mover(METEORS.pick_random(), path[0], path[1] * randf_range(60, 140), 0.6)
	mover["sprite"].scale = Vector2.ONE * randf_range(0.3, 0.7)
	mover["spin"] = randf_range(-0.8, 0.8)

func _spawn_chase():
	var path = _random_path()
	var dir : Vector2 = path[1]
	var velocity = dir * randf_range(260, 360)

	var enemy
	var pick = randi() % (SHEETS.size() + ENEMIES.size())
	if pick < SHEETS.size():
		var sheet = SHEETS[pick]
		enemy = _add_mover(sheet["texture"], path[0], velocity, 0.85)
		enemy["sprite"].hframes = sheet["grid"].x
		enemy["sprite"].vframes = sheet["grid"].y
		enemy["sprite"].rotation = dir.angle()
		enemy["sprite"].scale = Vector2.ONE * sheet["scale"]
		enemy["frame_time"] = randf() * sheet["frames"] / sheet["fps"]
		enemy["frames"] = sheet["frames"]
		enemy["fps"] = sheet["fps"]
	else:
		enemy = _add_mover(ENEMIES.pick_random(), path[0], velocity, 0.85)
		# kenney ships face down
		enemy["sprite"].rotation = dir.angle() - PI / 2
		enemy["sprite"].scale = Vector2(0.8, 0.8)

	var ufo = _add_mover(UFO, path[0] - dir * CHASE_GAP, velocity, 0.95)
	ufo["sprite"].hframes = 5
	ufo["sprite"].vframes = 4
	ufo["sprite"].scale = Vector2(0.9, 0.9)
	ufo["frame_time"] = 0.0
	ufo["frames"] = UFO_FRAMES
	ufo["fps"] = UFO_FPS
	ufo["shot_time"] = SHOT_INTERVAL

func _spawn_shot(pos : Vector2, dir : Vector2):
	var shot = _add_mover(LASER, pos + dir * 40, dir * SHOT_SPEED, 1.0)
	shot["sprite"].rotation = dir.angle() + PI / 2
	shot["sprite"].modulate = Color(1.5, 1.5, 2.5)
