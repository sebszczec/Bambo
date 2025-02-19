extends CharacterBody2D

@export var Speed = 0
@export var MaxSpeed = 300
@export var Acceleration = 10
@export var Friction = 5
@export var RotationSpeed : float = TAU
@export var StrikeDelay : float = 1.0
@export var StrikeDuration : float = 1.0

var _halfPI : float = PI / 2
var _accelerate = false
var _player = null

var _direction = Vector2(0, 0);
var _prepareingStrikeTimer = Timer.new()
var _strikeDurationTimer = Timer.new()

func _ready() -> void:
	_player = get_node("/root/World/Player")
	
	_prepareingStrikeTimer.one_shot = true;
	_prepareingStrikeTimer.wait_time = StrikeDelay
	_prepareingStrikeTimer.connect("timeout", _on_preparing_strike_timer_timeout)
	add_child(_prepareingStrikeTimer)
	
	_strikeDurationTimer.one_shot = true
	_strikeDurationTimer.wait_time = StrikeDuration
	_strikeDurationTimer.connect("timeout", _on_strike_duration_timer_timeout)
	add_child(_strikeDurationTimer)

func _physics_process(delta: float) -> void:
	var dist_to_player = _player.position - global_position;
	if dist_to_player.length() < 200:
		_direction = global_position.direction_to(_player.position)
		var theta = wrapf(atan2(_direction.y, _direction.x) - rotation - _halfPI, -PI, PI)
		var diff = clamp(RotationSpeed * delta, 0, abs(theta) * sign(theta))
		rotation = move_toward(rotation, rotation + diff, 0.1)
		
		if _prepareingStrikeTimer.is_stopped():
			_prepareingStrikeTimer.start()
	else:
		if !_prepareingStrikeTimer.is_stopped():
			_prepareingStrikeTimer.stop()
	
	if _accelerate:
		velocity = velocity.move_toward(_direction * MaxSpeed, Acceleration)
	else:
		velocity = velocity.move_toward(Vector2(0, 0), Friction)
#
	move_and_collide(velocity * delta)

func _on_preparing_strike_timer_timeout():
	_accelerate = true
	_strikeDurationTimer.start()
	
func _on_strike_duration_timer_timeout():
	_accelerate = false
