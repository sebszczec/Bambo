extends WeaponPerk

func _ready() -> void:
	super._ready()
	super.set_type(Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		taken.emit(super.get_type())
		queue_free()
