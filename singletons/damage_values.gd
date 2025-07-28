extends Node

var _values : Dictionary = {}

func _ready() -> void:
	for i in range(Enums.WEAPONS.size()):
		_values[i] = DamageRange.new()
		
	_values[Enums.WEAPONS.SMALL].MinValue = 10
	_values[Enums.WEAPONS.SMALL].MaxValue = 20
	_values[Enums.WEAPONS.BIG].MinValue = 30
	_values[Enums.WEAPONS.BIG].MaxValue = 50
	_values[Enums.WEAPONS.SMALL_WAVE].MinValue = 25
	_values[Enums.WEAPONS.SMALL_WAVE].MaxValue = 40
	_values[Enums.WEAPONS.SMALL_HOMING].MinValue = 10
	_values[Enums.WEAPONS.SMALL_HOMING].MaxValue = 20
	_values[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY].MinValue = 10
	_values[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY].MaxValue = 20
	_values[Enums.WEAPONS.FIREWORKS].MinValue = 25
	_values[Enums.WEAPONS.FIREWORKS].MaxValue = 40
	_values[Enums.WEAPONS.BOMB].MinValue = 10000
	_values[Enums.WEAPONS.BOMB].MaxValue = 20000

func get_damage(weapon : Enums.WEAPONS):
	return randi_range(_values[weapon].MinValue, _values[weapon].MaxValue)


class DamageRange:
	var MinValue: int
	var MaxValue: int
