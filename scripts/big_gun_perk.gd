extends Perk

func _ready() -> void:
	super._ready()
	

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		queue_free()
