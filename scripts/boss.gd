extends CharacterBody2D

@export var MoveSpeed = 100
@export var Acceleration = 10
@export var Friction = 5
@export var RotationSpeed : float = TAU

@onready var ship = $Ship
@onready var sprite = $Ship/AnimatedSprite2D

var _player = null
var _theta = 0.0
var _halfPI : float = PI / 2
var _speed = Vector2(0, 0)

func _ready() -> void:
	_player = get_node("/root/World/Player")
	
	sprite.play("Idle")

func _physics_process(delta: float) -> void:
	_speed = MoveSpeed
	
	var direction = global_position.direction_to(_player.get_global_position())
	velocity = velocity.move_toward(direction * _speed * delta, Acceleration)
	
	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)

	move_and_collide(velocity)
