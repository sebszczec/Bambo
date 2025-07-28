extends WeaponPerk

func _ready() -> void:
	super._ready()
	super.set_perk_type(Enums.PERKS.BOMB)
	super.set_weapon_type(Enums.WEAPONS.BOMB)
	

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		taken.emit(super.get_weapon_type())
		queue_free()
