extends Node2D

@onready var shader_material = $ColorRect.material

@export var Speed : float = 3.0
@export var Brightness : float = 5.0

func _physics_process(_delta: float) -> void:
	shader_material.set_shader_parameter("speed", Speed)
	shader_material.set_shader_parameter("brightness", Brightness)

#func set_speed(value : float) -> void:
	#shader_material.set_shader_parameter("speed", value)
#
#func get_speed() -> float:
	#return shader_material.get_shader_parameter("speed")
	#
#func set_brightness(value : float) -> void:
	#shader_material.set_shader_parameter("brightness", value)
#
#func get_brightness() -> float:
	#return shader_material.get_shader_parameter("brightness")
