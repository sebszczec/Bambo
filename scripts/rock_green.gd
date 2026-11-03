extends Rock

func _ready() -> void:
	super._ready()
	rock_scene = preload("res://scenes/shared/rock_green.tscn")
	explosion.set_particle_color(Color.GREEN)
	
