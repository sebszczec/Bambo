class_name Overseer
extends RefCounted

# Keeps the screen busy. When the player clears enemies faster than they arrive, or kills them
# out of sight, pressure (intensity) rises: more enemies, closer spawns, a bit tougher ones.
# When the player is in trouble it eases off at once. Level-agnostic: reads only the live board,
# the kill log and player health, so every level and endless mode get it.

const MAX_INTENSITY = 3.0
const RAISE_RATE = 0.05
const EASE_RATE = 0.03
const STRESS_DROP = 0.2
# board fill against the (scaled) alive cap: below this the board is too empty
const FILL_LOW = 0.6
const FILL_HIGH = 0.9
# kills farther than this from the player happen off-screen (view is ~768 px to each side at zoom 1.25)
const VIEW_RADIUS = 800.0
const OFFSCREEN_HIGH = 0.35
const WINDOW = 10.0
const STRESS_LIFE = 0.35
# steps of intensity that show a banner
const STEP_SIZE = 0.5
# spawn ring shrinks from 1.0 to this scale at max intensity (950 px -> ~690 px)
const MIN_DISTANCE_SCALE = 0.72
# share of player damage absorbed by new spawns at max intensity (0 at base)
const MAX_ARMOR = 0.3
# enemy durability (HP x armour) may not exceed this many times the player's power, so
# a fully upgraded build always kills in a bounded time and the level stays winnable.
# Pressure beyond that comes as more enemies only.
const MAX_DURABILITY_PER_POWER = 2.5

var intensity : float = 1.0
var offscreen_ratio : float = 0.0
var board_fill : float = 1.0

var _kills : Array = []
var _step = 0


# public - a kill happened at distance from the player
func record_kill(now : float, distance : float) -> void:
	_kills.append([now, distance > VIEW_RADIUS])


# public - called once a second. Returns true when pressure crossed a banner step.
func tick(now : float, fill : float, life_fraction : float, boss_alive : bool) -> bool:
	while _kills.size() > 0 and now - _kills[0][0] > WINDOW:
		_kills.pop_front()

	var off = 0
	for kill in _kills:
		if kill[1]:
			off += 1
	offscreen_ratio = float(off) / _kills.size() if _kills.size() > 0 else 0.0
	board_fill = fill

	if life_fraction < STRESS_LIFE:
		# the player is in trouble, give room first
		intensity = max(1.0, intensity - STRESS_DROP)
	elif boss_alive:
		# boss fights stay as they are, no flooding the arena
		pass
	# an empty board only counts once the player is actually clearing it (not at level start)
	elif (fill < FILL_LOW and _kills.size() > 0) or offscreen_ratio > OFFSCREEN_HIGH:
		intensity = min(MAX_INTENSITY, intensity + RAISE_RATE)
	elif fill > FILL_HIGH and offscreen_ratio < OFFSCREEN_HIGH / 2.0:
		intensity = max(1.0, intensity - EASE_RATE)

	var step = int(floor((intensity - 1.0) / STEP_SIZE))
	if step != _step:
		_step = step
		return step > 0
	return false


# public - 1.0 at base, MAX_INTENSITY at the top; used for the alive cap and wave counts
func scale(value : int) -> int:
	var scaled = value * intensity
	var whole = int(scaled)
	# stochastic remainder so a 1.5x wave of 1 enemy spawns on average every other time
	if randf() < scaled - whole:
		whole += 1
	return whole


# public - spawn ring scale for EnemySpawner, closer as pressure rises
func distance_scale() -> float:
	var t = clamp((intensity - 1.0) / (MAX_INTENSITY - 1.0), 0.0, 1.0)
	return lerp(1.0, MIN_DISTANCE_SCALE, t)


# public - multiplier on enemy life and damage for new spawns
func toughness() -> float:
	return 1.0 + (intensity - 1.0) * 0.8


# public
func damage_multiplier() -> float:
	return 1.0 + (intensity - 1.0) * 0.4


# public - fraction of player damage a new spawn absorbs, rises with pressure
func armor() -> float:
	var t = clamp((intensity - 1.0) / (MAX_INTENSITY - 1.0), 0.0, 1.0)
	return MAX_ARMOR * t


# public - player damage output against the starting build: 1.0 at start, 2.0 at double the shots and damage
func power() -> float:
	var base_crit = 1.0 + PlayerStatus.DEFAULT_CRITICAL_HIT_CHANCE / 100.0 * (PlayerStatus.DEFAULT_CRITICAL_HIT_MULTIPLIER / 100.0 - 1.0)
	var crit = 1.0 + PlayerStatus.CriticalHitChance / 100.0 * (PlayerStatus.CriticalHitMultiplier / 100.0 - 1.0)
	return (PlayerStatus.BaseDamage / PlayerStatus.DEFAULT_BASE_DAMAGE) \
		* (PlayerStatus.FireRate / PlayerStatus.DEFAULT_FIRE_RATE) \
		* (1.0 + PlayerStatus.ProjectileCount) * (crit / base_crit)


# public - keeps toughness and armour inside the power cap, returns [toughness, armour].
# Armour is cut first; toughness only once armour is gone.
func clamp_defence(toughness_value : float, armor_value : float) -> Vector2:
	var cap = MAX_DURABILITY_PER_POWER * power()
	var armour = min(armor_value, max(0.0, 1.0 - toughness_value / cap))
	var tough = min(toughness_value, cap * (1.0 - armour))
	return Vector2(tough, armour)
