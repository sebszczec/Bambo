extends Area2D


func _ready() -> void:
	var tween = create_tween()
	var degree = PI / 12
	tween.set_loops(0)
	tween.tween_property(self, "rotation", degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", -degree, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		queue_free()
