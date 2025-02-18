extends CharacterBody2D

@export var Speed = 300
@export var RotationSpeed : float = TAU

var _halfPI : float = PI / 2
var _player = null

var _direction = Vector2(0, 0);

func _ready() -> void:
	_player = get_node("/root/World/Player")

func _physics_process(delta: float) -> void:
	var dist_to_player = _player.position - global_position;
	if dist_to_player.length() < 200:
		var d = global_position.direction_to(_player.position)
		var theta = wrapf(atan2(d.y, d.x) - rotation - _halfPI, -PI, PI)
		rotation += clamp(RotationSpeed * delta, 0, abs(theta) * sign(theta))
	
	velocity = _direction * Speed
#
	move_and_slide()
