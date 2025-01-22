extends Area2D

@export var Life = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		queue_free()
