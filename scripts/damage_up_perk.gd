extends Perk

@export var DamageUp = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	super.set_perk_type(Enums.PERKS.DAMAGE_UP)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		taken.emit()
		queue_free()
