extends Node2D

@onready var shader_material = $ColorRect.material

func set_speed(value : float) -> void:
	shader_material.set_shader_parameter("speed", value)

func get_speed() -> float:
	return shader_material.get_shader_parameter("speed")
	
func set_brightness(value : float) -> void:
	shader_material.set_shader_parameter("brightness", value)

func get_brightness() -> float:
	return shader_material.get_shader_parameter("brightness")
