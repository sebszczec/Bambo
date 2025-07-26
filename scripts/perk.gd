extends Area2D

class_name Perk
var _perk_type : Enums.PERKS
signal taken

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween()
	var degree = PI / 12
	tween.set_loops(0)
	tween.tween_property(self, "rotation", degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func set_perk_type(type: Enums.PERKS):
	_perk_type = type
	
func get_perk_type() -> Enums.PERKS:
	return _perk_type

func _foobar():
	taken.emit()
