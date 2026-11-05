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
# bounces of straight player shots after an enemy hit (Ricochet Plates)
var Ricochet : int = 0
# Fracture level: every (7 - Fracture)th hit on an enemy deals FRACTURE_BONUS (Fracture card)
var Fracture : int = 0
# Slag Trails level: shots burn the enemy they hit for Slag * 15 % of the hit damage over 2 s
var Slag : int = 0
var Armor : float = 0
var Regen : float = 0
var PickupRadius : float = 120

# Xenite collected in this run, banked by MetaProgress when the run ends
var Shards : int = 0

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
signal shards_changed (value : int)

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
	Ricochet = 0
	Fracture = 0
	Slag = 0
	Armor = 0
	Regen = 0
	PickupRadius = DEFAULT_PICKUP_RADIUS
	Shards = 0
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

func add_shards(value : int):
	Shards += value
	shards_changed.emit(Shards)

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

# target = the enemy that is hit, needed for Fracture (hits are counted per enemy)
# scale = the bullet's own damage multiplier (Tether Rocks grow with their level)
func get_damage_from_weapon(weapon : Enums.WEAPONS, target = null, scale : float = 1.0):
	var damage = Damage.new()
	damage.Value = 0.01 * BaseDamage * DamageValues.get_damage(weapon) * scale
	damage.Critical = false

	if randf_range(0.0, 100.0) <= CriticalHitChance:
		damage.Value *= 0.01 * CriticalHitMultiplier
		damage.Critical = true

	# Fracture: every hit-th hit on the same enemy deals +60 % (hit = 7 - Fracture, so 6 at level 1, 3 at level 4)
	if target != null and Fracture > 0:
		var hits = target.get_meta("fracture_hits", 0) + 1
		target.set_meta("fracture_hits", hits)
		if hits % (7 - Fracture) == 0:
			damage.Value *= FRACTURE_BONUS

	return damage

func get_damage():
	return get_damage_from_weapon(CurrentWeapon)

# Slag Trails: a shot that hits an enemy sets it burning. 4 ticks over 2 s, the burn does not stack,
# a new shot refreshes it. The tick goes through the enemy's own handleDamage, so death works as usual.
const SLAG_BURN_PART = 0.15
const BURN_TICKS = 4
const BURN_TICK_TIME = 0.5

func apply_burn(target : Node, weapon : Enums.WEAPONS):
	if Slag <= 0 or !target.has_method("handleDamage"):
		return
	var per_tick = max(1, roundi(0.01 * BaseDamage * DamageValues.get_damage(weapon) * SLAG_BURN_PART * Slag / BURN_TICKS))
	if target.has_meta("burn_timer") and is_instance_valid(target.get_meta("burn_timer")):
		target.set_meta("burn_ticks", BURN_TICKS)
		target.set_meta("burn_damage", max(target.get_meta("burn_damage"), per_tick))
		return
	var timer = Timer.new()
	timer.wait_time = BURN_TICK_TIME
	target.add_child(timer)
	target.set_meta("burn_timer", timer)
	target.set_meta("burn_ticks", BURN_TICKS)
	target.set_meta("burn_damage", per_tick)
	timer.timeout.connect(_burn_tick.bind(target, timer))
	timer.start()

func _burn_tick(target : Node, timer : Timer):
	# a dying enemy (nuke, dev kill) is already reported, the burn must not explode it again
	if !is_instance_valid(target) or target.is_queued_for_deletion() or target.get("isDead") or target.get("Life") <= 0:
		_end_burn(target, timer)
		return
	target.set_meta("burn_ticks", target.get_meta("burn_ticks") - 1)
	var damage = Damage.new()
	damage.Value = target.get_meta("burn_damage")
	damage.Critical = false
	var alive = target.handleDamage(damage, target.global_position)
	if !alive:
		# same death flag as the bullet path, so the enemy is not exploded twice
		target.isDead = true
		target.explode()
	if !alive or target.get_meta("burn_ticks") <= 0:
		_end_burn(target, timer)

func _end_burn(target : Node, timer : Timer):
	if is_instance_valid(timer):
		timer.queue_free()
	if is_instance_valid(target) and target.has_meta("burn_timer"):
		target.remove_meta("burn_timer")
		target.remove_meta("burn_ticks")
		target.remove_meta("burn_damage")

# the nuke wipes the horde but only takes a slice of a boss's life
const BOMB_BOSS_LIFE_PART = 0.1
const FRACTURE_BONUS = 1.6

func get_boss_damage_from_weapon(weapon : Enums.WEAPONS, max_life, target = null, scale : float = 1.0):
	if weapon != Enums.WEAPONS.BOMB:
		return get_damage_from_weapon(weapon, target, scale)

	var damage = Damage.new()
	damage.Value = ceili(max_life * BOMB_BOSS_LIFE_PART)
	damage.Critical = false
	return damage

class Damage:
	var Value : int
	var Critical : bool
