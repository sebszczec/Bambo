extends Perk

class_name WeaponPerk

var _weapon_type : Enums.WEAPONS

func _ready():
	super._ready()

func set_weapon_type(type : Enums.WEAPONS):
	_weapon_type = type
	
func get_weapon_type() -> Enums.WEAPONS:
	return _weapon_type
