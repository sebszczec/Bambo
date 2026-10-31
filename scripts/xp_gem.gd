extends Node2D

# Experience gem dropped by enemies. It waits on the floor until the player
# comes into the pickup radius (or a magnet is taken), then flies into the player.

const MAX_SPEED = 1400.0
const ACCELERATION = 2200.0
const PICKUP_DISTANCE = 18.0
# gems on the floor look for the player only every few physics frames
const IDLE_CHECK_FRAMES = 4

static var alive_count = 0
# public - every gem on the floor, cheaper than searching the group
static var all : Array = []

@export var Value : int = 1

@onready var sprite = $Sprite2D

var _blue = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_blue.png")
var _green = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_green.png")
var _red = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_red.png")
var _gold = preload("res://resources/kenney_space-shooter-redux/PNG/Power-ups/pill_yellow.png")

var _player = null
var _attracted = false
var _speed = 0.0
var _registered = false

# counted when created, not in _ready - a nuke drops all its gems
# in one frame with a deferred add_child and they must hit the cap too
func _init() -> void:
	alive_count += 1
	all.append(self)
	_registered = true

func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_unregister()

func _unregister():
	if _registered:
		_registered = false
		alive_count -= 1
		all.erase(self)

func _ready() -> void:
	add_to_group("XpGem")
	_player = get_tree().get_first_node_in_group("player")
	_update_look()

	# small pop when dropped
	var target_scale = scale
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# public
func attract():
	_attracted = true

# public - used to merge gems when there are too many on the floor
func add_value(value : int):
	Value += value
	# the gem may not be in the tree yet, _ready updates the look then
	if is_node_ready():
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
		# staggered, so the gems do not all check in the same frame
		if (Engine.get_physics_frames() + get_instance_id()) % IDLE_CHECK_FRAMES != 0:
			return
		if global_position.distance_squared_to(target) < PlayerStatus.PickupRadius * PlayerStatus.PickupRadius:
			_attracted = true
		return

	_speed = min(_speed + ACCELERATION * delta, MAX_SPEED)
	global_position = global_position.move_toward(target, _speed * delta)

	if global_position.distance_squared_to(target) < PICKUP_DISTANCE * PICKUP_DISTANCE:
		_player.collect_xp(Value)
		# no more merging into a collected gem
		_unregister()
		queue_free()
