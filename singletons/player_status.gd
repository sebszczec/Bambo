extends Node

var MaxLife: float = 100.0
var MaxAfterburner : float = 100.0
var MaxShield : float = 100.0
var BaseDamage : float = 100
var CriticalHitChance : float = 10.0
var CriticalHitMultiplier : float = 200

var CurrentWeapon = Enums.WEAPONS.SMALL

signal base_damage_changed (value : float)
signal critical_hit_chance_changed (value : float)
signal critcal_hit_multipayer_changed (value : float)

func increase_critic_hit_multiplier(value: float):
	CriticalHitMultiplier += value
	
	critcal_hit_multipayer_changed.emit(CriticalHitMultiplier)

func increase_critic_chance(value: float):
	CriticalHitChance += value
	if CriticalHitChance > 100.0:
		CriticalHitChance = 100.0
	
	critical_hit_chance_changed.emit(CriticalHitChance)

func increase_damage(value : float):
	BaseDamage = BaseDamage + value
	base_damage_changed.emit(BaseDamage)

func get_damage():
	var damage = Damage.new()
	damage.Value = 0.01 * BaseDamage * DamageValues.get_damage(CurrentWeapon)
	damage.Critical = false
	
	if randf_range(0.0, 100.0) <= CriticalHitChance:
		damage.Value *= 0.01 * CriticalHitMultiplier
		damage.Critical = true
	
	return damage

class Damage:
	var Value : int
	var Critical : bool
