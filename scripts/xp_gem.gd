extends Node2D

# Experience gem dropped by enemies. It waits on the floor until the player
# comes into the pickup radius (or a magnet is taken), then flies into the player.

const MAX_SPEED = 1400.0
const ACCELERATION = 2200.0
const PICKUP_DISTANCE = 18.0

static var alive_count = 0

@export var Value : int = 1

@onready var sprite = $Sprite2D

var _blue = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_blue.png")
var _green = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_green.png")
var _red = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_red.png")
var _gold = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_yellow.png")

var _player = null
var _attracted = false
var _speed = 0.0

func _ready() -> void:
	alive_count += 1
	add_to_group("XpGem")
	_player = get_tree().get_first_node_in_group("player")
	_update_look()

	# small pop when dropped
	var target_scale = scale
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _exit_tree() -> void:
	alive_count -= 1

# public
func attract():
	_attracted = true

# public - used to merge gems when there are too many on the floor
func add_value(value : int):
	Value += value
	_update_look()

# public
func is_attracted() -> bool:
	return _attracted

func _update_look():
	if Value >= 50:
		sprite.texture = _gold
		scale = Vector2(1.0, 1.0)
	elif Value >= 10:
		sprite.texture = _red
		scale = Vector2(0.85, 0.85)
	elif Value >= 5:
		sprite.texture = _green
		scale = Vector2(0.7, 0.7)
	else:
		sprite.texture = _blue
		scale = Vector2(0.55, 0.55)

func _physics_process(delta: float) -> void:
	if _player == null or _player.isDead:
		return

	var target = _player.global_position
	if !_attracted:
		if global_position.distance_squared_to(target) < PlayerStatus.PickupRadius * PlayerStatus.PickupRadius:
			_attracted = true
		return

	_speed = min(_speed + ACCELERATION * delta, MAX_SPEED)
	global_position = global_position.move_toward(target, _speed * delta)

	if global_position.distance_squared_to(target) < PICKUP_DISTANCE * PICKUP_DISTANCE:
		_player.collect_xp(Value)
		queue_free()
