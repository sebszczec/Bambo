extends Rock

func _ready() -> void:
	super._ready()
	rock_scene = preload("res://scenes/rock_red.tscn")
	explosion.set_particle_color(Color.RED)
	
