extends Node2D

@onready var label = $Label
var score = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func add_score(value):
	score += value
	set_value(score)

func set_value(value : int):
	var text = ""
	if value < 10:
		text = "00000"
	elif value < 100:
		text = "0000"
	elif value < 1000:
		text = "000"
	elif value < 10000:
		text = "00"
	elif value < 100000:
		text = "0"
	else:
		text = ""
		
	label.text = text + str(value)
	
