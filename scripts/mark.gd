extends Node2D

@onready var sprite = $Sprite2D
@onready var timer = $ActivationPeriodTimer

@export var RotationSpeed = PI

var _angle = 0

func _process(delta: float) -> void:
	sprite.rotate(RotationSpeed * delta)
	_angle += 2 * delta
	var scale_factor = 0.1 + 0.05 * sin(_angle)
	sprite.scale = Vector2(scale_factor, scale_factor)

func activate(time: float):
	sprite.visible = true
	
	if timer.is_stopped():
		timer.wait_time = time
		timer.start()


func _on_activation_period_timer_timeout() -> void:
	sprite.visible = false
