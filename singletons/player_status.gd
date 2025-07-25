extends Node

var MaxLife: float = 100.0
var MaxAfterburner : float = 100.0
var MaxShield : float = 100.0
var BaseDamage : float = 1
var CriticalHitChance : float = 10.0
var CriticalHitMultiplier : float = 2.0

var CurrentWeapon = Enums.WEAPONS.SMALL

signal base_damage_changed (value : float)
signal critical_hit_chance_changed (value : float)
signal ciritcal_hit_multipayer_changes (value : float)

func get_damage():
	var damage = Damage.new()
	damage.Value = BaseDamage * DamageValues.get_damage(CurrentWeapon)
	damage.Critical = false
	
	if randf_range(0.0, 100.0) <= CriticalHitChance:
		damage.Value *= CriticalHitMultiplier
		damage.Critical = true
	
	return damage

class Damage:
	var Value : int
	var Critical : bool
