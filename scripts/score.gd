extends Node2D

@onready var label = $Label
var score = 0

signal score_changed(value : int)

func _ready() -> void:
	pass

func add_score(value):
	score += value
	set_value(score)
	score_changed.emit(score)

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
