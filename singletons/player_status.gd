extends Node

var MaxLife: float = 100.0
var MaxAfterburner : float = 100.0
var MaxShield : float = 100.0
var BaseDamage : float = 100
var CriticalHitChance : float = 10.0
var CriticalHitMultiplier : float = 200
var Speed : float = 100

var CurrentWeapon = Enums.WEAPONS.SMALL

const DEFAULT_MAX_LIFE : float = 100.0
const DEFAULT_MAX_AFTERBURNER : float = 100.0
const DEFAULT_MAX_SHIELD : float = 100.0
const DEFAULT_BASE_DAMAGE : float = 100
const DEFAULT_CRITICAL_HIT_CHANCE : float = 10.0
const DEFAULT_CRITICAL_HIT_MULTIPLIER : float = 200
const DEFAULT_SPEED : float = 100

signal base_damage_changed (value : float)
signal critical_hit_chance_changed (value : float)
signal critcal_hit_multipayer_changed (value : float)
signal speed_changed (value : float)

# called at the start of every run, so perks do not leak between runs
func reset():
	MaxLife = DEFAULT_MAX_LIFE
	MaxAfterburner = DEFAULT_MAX_AFTERBURNER
	MaxShield = DEFAULT_MAX_SHIELD
	BaseDamage = DEFAULT_BASE_DAMAGE
	CriticalHitChance = DEFAULT_CRITICAL_HIT_CHANCE
	CriticalHitMultiplier = DEFAULT_CRITICAL_HIT_MULTIPLIER
	Speed = DEFAULT_SPEED
	CurrentWeapon = Enums.WEAPONS.SMALL

func increase_critic_hit_multiplier(value: float):
	CriticalHitMultiplier += value
	
	critcal_hit_multipayer_changed.emit(CriticalHitMultiplier)

func increase_critic_chance(value: float):
	CriticalHitChance += value
	if CriticalHitChance > 100.0:
		CriticalHitChance = 100.0
	
	critical_hit_chance_changed.emit(CriticalHitChance)

func increase_speed(value : float):
	Speed += value
	speed_changed.emit(Speed)

func increase_damage(value : float):
	BaseDamage = BaseDamage + value
	base_damage_changed.emit(BaseDamage)

func get_damage_from_weapon(weapon : Enums.WEAPONS):
	var damage = Damage.new()
	damage.Value = 0.01 * BaseDamage * DamageValues.get_damage(weapon)
	damage.Critical = false
	
	if randf_range(0.0, 100.0) <= CriticalHitChance:
		damage.Value *= 0.01 * CriticalHitMultiplier
		damage.Critical = true
	
	return damage

func get_damage():
	return get_damage_from_weapon(CurrentWeapon)

class Damage:
	var Value : int
	var Critical : bool
