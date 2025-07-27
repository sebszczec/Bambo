extends Area2D

class_name Perk
var _perk_type : Enums.PERKS
signal taken

@export var Timeout = 5.0

var timeout = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeout.wait_time = Timeout
	timeout.one_shot = true
	timeout.connect("timeout", _on_timeout)
	add_child(timeout)
	timeout.start()
	
	var tween = create_tween()
	var degree = PI / 12
	tween.set_loops(0)
	tween.tween_property(self, "rotation", degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func _on_timeout():
	queue_free()

func set_perk_type(type: Enums.PERKS):
	_perk_type = type
	
func get_perk_type() -> Enums.PERKS:
	return _perk_type

func _foobar():
	taken.emit()
