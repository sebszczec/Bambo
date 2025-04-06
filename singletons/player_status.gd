extends Node

var MaxLife: float = 100.0
var MaxAfterburner : float = 100.0
var MaxShield : float = 100.0
var CriticalHitChance : float = 10.0
var CriticalHitMultiplier : float = 2.0

var CurrentWeapon = Enums.WEAPONS.SMALL

func get_damage():
	var damage = Damage.new()
	damage.Value = DamageValues.get_damage(CurrentWeapon)
	damage.Critical = false
	
	if randf_range(0.0, 100.0) <= CriticalHitChance:
		damage.Value *= CriticalHitMultiplier
		damage.Critical = true
	
	return damage

class Damage:
	var Value : int
	var Critical : bool
