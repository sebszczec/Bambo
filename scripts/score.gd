extends Node2D

@onready var label = $Label
var score = 0

signal reached_1000_points
signal reached_2000_points
signal reached_4000_points
signal reached_7000_points

func _ready() -> void:
	pass 

func add_score(value):
	if score < 1000 and score + value >= 1000:
		reached_1000_points.emit()
	elif score < 2000 and score + value >= 2000:
		reached_2000_points.emit()
	elif score < 4000 and score + value >= 4000:
		reached_4000_points.emit()
	elif score < 7000 and score + value >= 7000:
		reached_7000_points.emit()
	
	score += value
	set_value(score)

func get_score():
	return score

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
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	
