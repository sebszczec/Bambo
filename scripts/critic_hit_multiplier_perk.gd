extends Perk

@export var CriticHitMultiplier = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	super.set_perk_type(Enums.PERKS.CRITIC_HIT_MULTIPLIER)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		taken.emit()
		queue_free()
