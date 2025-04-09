extends Rock

func _ready() -> void:
	super._ready()
	rock_scene = preload("res://scenes/rock_yellow.tscn")
	explosion.set_particle_color(Color.YELLOW)
	
