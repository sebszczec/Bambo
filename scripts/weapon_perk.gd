extends Perk

class_name WeaponPerk

var _type : Enums.WEAPONS

func _ready():
	super._ready()

func set_type(type : Enums.WEAPONS):
	_type = type
	
func get_type() -> Enums.WEAPONS:
	return _type
