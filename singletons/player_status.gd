extends Node

var MaxLife: float = 100.0
var MaxAfterburner : float = 100.0
var MaxShield : float = 100.0
var BaseDamage : float = 100
var CriticalHitChance : float = 10.0
var CriticalHitMultiplier : float = 200
var Speed : float = 100
var FireRate : float = 100
var ProjectileCount : int = 0
var Armor : float = 0
var Regen : float = 0
var PickupRadius : float = 120

var Level : int = 1
var Xp : int = 0
var XpToNext : int = 0

var CurrentWeapon = Enums.WEAPONS.SMALL

const DEFAULT_MAX_LIFE : float = 100.0
const DEFAULT_MAX_AFTERBURNER : float = 100.0
const DEFAULT_MAX_SHIELD : float = 100.0
const DEFAULT_BASE_DAMAGE : float = 100
const DEFAULT_CRITICAL_HIT_CHANCE : float = 10.0
const DEFAULT_CRITICAL_HIT_MULTIPLIER : float = 200
const DEFAULT_SPEED : float = 100
const DEFAULT_FIRE_RATE : float = 100
const DEFAULT_PICKUP_RADIUS : float = 120

signal base_damage_changed (value : float)
signal critical_hit_chance_changed (value : float)
signal critcal_hit_multipayer_changed (value : float)
signal speed_changed (value : float)
signal max_life_changed (value : float)
signal max_shield_changed (value : float)
signal xp_changed (value : int, max_value : int)
signal leveled_up (level : int)

# called at the start of every run, so perks do not leak between runs
func reset():
	MaxLife = DEFAULT_MAX_LIFE
	MaxAfterburner = DEFAULT_MAX_AFTERBURNER
	MaxShield = DEFAULT_MAX_SHIELD
	BaseDamage = DEFAULT_BASE_DAMAGE
	CriticalHitChance = DEFAULT_CRITICAL_HIT_CHANCE
	CriticalHitMultiplier = DEFAULT_CRITICAL_HIT_MULTIPLIER
	Speed = DEFAULT_SPEED
	FireRate = DEFAULT_FIRE_RATE
	ProjectileCount = 0
	Armor = 0
	Regen = 0
	PickupRadius = DEFAULT_PICKUP_RADIUS
	Level = 1
	Xp = 0
	XpToNext = get_xp_for_level(Level)
	CurrentWeapon = Enums.WEAPONS.SMALL

func _ready() -> void:
	XpToNext = get_xp_for_level(Level)

func get_xp_for_level(level : int) -> int:
	if level < 20:
		return 5 + 10 * level
	return 5 + 10 * level + 15 * (level - 20)

func add_xp(value : int):
	Xp += value
	while Xp >= XpToNext:
		Xp -= XpToNext
		Level += 1
		XpToNext = get_xp_for_level(Level)
		leveled_up.emit(Level)

	xp_changed.emit(Xp, XpToNext)

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

func increase_max_life(value : float):
	MaxLife += value
	max_life_changed.emit(MaxLife)

func increase_max_shield(value : float):
	MaxShield += value
	max_shield_changed.emit(MaxShield)

# returns multiplier for weapon delays, more fire rate = shorter delay
func get_delay_factor() -> float:
	return 100.0 / FireRate

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
