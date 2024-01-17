extends Path2D

@onready var path = $PathFollow2D

@export var Speed = 100

# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	path.progress = path.progress + Speed * delta
