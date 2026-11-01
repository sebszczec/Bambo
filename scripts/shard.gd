extends Node2D

# Xenite shard dropped by enemies - the meta currency spent in the Hangar.
# Works like an xp gem: waits on the floor until the player comes into the
# pickup radius (or a magnet is taken), then flies into the player.

const MAX_SPEED = 1400.0
const ACCELERATION = 2200.0
const PICKUP_DISTANCE = 18.0
const IDLE_CHECK_FRAMES = 4

@export var Value : int = 1

var _player = null
var _attracted = false
var _speed = 0.0

func _ready() -> void:
	add_to_group("Shard")
	_player = get_tree().get_first_node_in_group("player")
	# bigger bundles from bosses look bigger
	var target_scale = Vector2.ONE * clamp(0.55 + 0.04 * Value, 0.55, 1.2)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# public
func attract():
	_attracted = true

func _physics_process(delta: float) -> void:
	if _player == null or _player.isDead:
		return

	var target = _player.global_position
	if !_attracted:
		if (Engine.get_physics_frames() + get_instance_id()) % IDLE_CHECK_FRAMES != 0:
			return
		if global_position.distance_squared_to(target) < PlayerStatus.PickupRadius * PlayerStatus.PickupRadius:
			_attracted = true
		return

	_speed = min(_speed + ACCELERATION * delta, MAX_SPEED)
	global_position = global_position.move_toward(target, _speed * delta)

	if global_position.distance_squared_to(target) < PICKUP_DISTANCE * PICKUP_DISTANCE:
		_player.collect_shard(Value)
		queue_free()
