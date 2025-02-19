extends Node2D

@export var RadarSpeed = 3

@onready var sprite = $Sprite2D

var _radarAngle = deg_to_rad(30)
var _halfPI = PI / 2
var _rotationSpeed = TAU
var _followPayer = false
var _player = null

signal player_detected
signal player_lost

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_node("/root/World/Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
var time : float = 0
func _process(delta: float) -> void:
	if _followPayer == true:
		var direction = global_position.direction_to(_player.position)
		var theta = wrapf(atan2(direction.y, direction.x) - rotation - get_parent().rotation - _halfPI, -PI, PI)
		var diff = clamp(_rotationSpeed * delta, 0, abs(theta) * sign(theta))
		rotation = move_toward(rotation, rotation + diff, 0.1)
	else:
		time += delta
		var theta = _radarAngle * sin(time * RadarSpeed) - rotation
		rotation += theta


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		sprite.modulate = Color.RED
		_followPayer = true
		player_detected.emit()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player"):
		sprite.modulate = Color.WHITE
		_followPayer = false
		player_lost.emit()
