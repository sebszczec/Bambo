extends Node2D

@export var ShowFps = true

@onready var fps_counter = $Control/CanvasLayer/BoxContainer/FpsCounter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Engine.max_fps = 60
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ShowFps == true:
		fps_counter.text = "FPS: " + str(Engine.get_frames_per_second())
