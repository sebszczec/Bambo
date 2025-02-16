extends Area2D

class_name Perk
signal taken

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	var degree = PI / 12
	tween.set_loops(0)
	tween.tween_property(self, "rotation", degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func _foobar():
	taken.emit()
