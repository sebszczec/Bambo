extends Node

# Pool of upgrades offered on level up ("pick 1 of 3").
# Stat upgrades change PlayerStatus, weapon upgrades are handed to game logic.

const MAX_WEAPONS = 5
const PU = "res://resources/kenney_space-shooter-redux/PNG/Power-ups/"
const PERKS = "res://resources/perks/"

# game logic registers itself at the start of every run
var game = null

var _pool : Array = []
var _levels : Dictionary = {}

func _ready() -> void:
	_build_pool()

# public - called at the start of every run
func reset(game_logic):
	game = game_logic
	_levels.clear()
	# the main gun is owned from the start
	_levels["w_blaster"] = 1

func _build_pool():
	_add_stat("damage", "Damage", "+15% damage", PERKS + "damage_up.png", 10,
		func(): PlayerStatus.increase_damage(15))
	_add_stat("crit_chance", "Precision", "+5% critical chance", PERKS + "critic_chance_up.png", 8,
		func(): PlayerStatus.increase_critic_chance(5))
	_add_stat("crit_mult", "Lethality", "+30% critical damage", PERKS + "critic_damage_multiplier.png", 8,
		func(): PlayerStatus.increase_critic_hit_multiplier(30))
	_add_stat("speed", "Thrusters", "+10% move speed", PERKS + "seed_up.png", 5,
		func(): PlayerStatus.increase_speed(10))
	_add_stat("fire_rate", "Overclock", "+12% fire rate", PU + "powerupYellow_bolt.png", 6,
		func(): PlayerStatus.FireRate += 12)
	_add_stat("projectile", "Multishot", "+1 projectile for every weapon", PU + "things_gold.png", 3,
		func(): PlayerStatus.ProjectileCount += 1)
	_add_stat("max_life", "Hull plating", "+20 max life, heals 20", PERKS + "heart.png", 8,
		_apply_max_life)
	_add_stat("regen", "Nanobots", "+0.6 life per second", PU + "powerupGreen_bolt.png", 5,
		func(): PlayerStatus.Regen += 0.6)
	_add_stat("armor", "Armor", "-2 damage from every hit", PU + "shield_silver.png", 5,
		func(): PlayerStatus.Armor += 2)
	_add_stat("shield", "Shield capacitor", "+25 max shield", PERKS + "shield.png", 4,
		_apply_max_shield)
	_add_stat("magnet", "Tractor beam", "+40% pickup radius", PU + "star_gold.png", 5,
		func(): PlayerStatus.PickupRadius *= 1.4)

	_add_weapon("w_blaster", "Blaster", "Main gun", "Faster and wider main gun",
		PU + "powerupBlue_bolt.png", Enums.WEAPONS.SMALL)
	_add_weapon("w_cannon", "Heavy cannon", "Auto-aimed heavy shells", "Faster, more shells",
		PERKS + "big_gun.png", Enums.WEAPONS.BIG)
	_add_weapon("w_nova", "Nova", "Ring of bullets around you", "More bullets, faster pulse",
		PERKS + "fire_circle.png", Enums.WEAPONS.SMALL_WAVE)
	_add_weapon("w_missiles", "Missiles", "Homing rockets", "More rockets, faster reload",
		PERKS + "rocket.png", Enums.WEAPONS.SMALL_HOMING)
	_add_weapon("w_fireworks", "Fireworks", "Shell exploding into shrapnel", "Bigger explosions",
		PU + "powerupRed_star.png", Enums.WEAPONS.FIREWORKS)
	_add_weapon("w_orbit", "Orbit", "Blades circling your ship", "More blades, faster spin",
		PU + "star_silver.png", Enums.WEAPONS.ORBIT)

func _apply_max_life():
	PlayerStatus.increase_max_life(20)
	game.player.updateLife(20)

func _apply_max_shield():
	PlayerStatus.increase_max_shield(25)
	game.player.updateShield(25)

func _add_stat(id : String, title : String, desc : String, icon : String, max_level : int, apply : Callable):
	_pool.append({ "id" : id, "title" : title, "desc" : desc, "desc_up" : desc, "icon" : load(icon),
		"max_level" : max_level, "weapon" : false, "weight" : 10, "apply" : apply })

func _add_weapon(id : String, title : String, desc : String, desc_up : String, icon : String, type : Enums.WEAPONS):
	_pool.append({ "id" : id, "title" : title, "desc" : desc, "desc_up" : desc_up, "icon" : load(icon),
		"max_level" : 6, "weapon" : true, "weight" : 12, "type" : type,
		"apply" : func(): game.add_weapon(type) })

# public
func get_weapon_icon(type : Enums.WEAPONS) -> Texture2D:
	for entry in _pool:
		if entry["weapon"] and entry["type"] == type:
			return entry["icon"]
	return null

# public - dev console
func get_pool() -> Array:
	return _pool

# public - dev console, empty when there is no such upgrade
func get_entry(id : String) -> Dictionary:
	for entry in _pool:
		if entry["id"] == id:
			return entry
	return {}

# public
func get_level(id : String) -> int:
	return _levels.get(id, 0)

# public
func get_weapon_count() -> int:
	var count = 0
	for entry in _pool:
		if entry["weapon"] and get_level(entry["id"]) > 0:
			count += 1
	return count

func _is_available(entry : Dictionary, weapons_only : bool) -> bool:
	if weapons_only and !entry["weapon"]:
		return false

	var level = get_level(entry["id"])
	if level >= entry["max_level"]:
		return false

	# a new weapon only while there is a free slot
	if entry["weapon"] and level == 0 and get_weapon_count() >= MAX_WEAPONS:
		return false

	return true

# public - returns up to count different upgrades, weighted
func roll(count : int, weapons_only : bool = false) -> Array:
	var candidates = []
	for entry in _pool:
		if _is_available(entry, weapons_only):
			candidates.append(entry)

	var result = []
	while result.size() < count and candidates.size() > 0:
		var total = 0
		for entry in candidates:
			total += entry["weight"]

		var pick = randi_range(0, total - 1)
		for entry in candidates:
			pick -= entry["weight"]
			if pick < 0:
				result.append(entry)
				candidates.erase(entry)
				break

	# everything maxed - give something useful anyway
	if result.size() == 0:
		result.append({ "id" : "heal", "title" : "Repair kit", "desc" : "Restore 40 life", "desc_up" : "",
			"icon" : load(PERKS + "heart.png"), "max_level" : 999, "weapon" : false, "weight" : 1,
			"apply" : func(): game.player.updateLife(40) })

	return result

# public
func get_description(entry : Dictionary) -> String:
	if get_level(entry["id"]) == 0:
		return entry["desc"]
	return entry["desc_up"]

# public
func get_level_text(entry : Dictionary) -> String:
	var level = get_level(entry["id"])
	if level == 0:
		return "NEW!" if entry["weapon"] else "Lv 1"
	return "Lv " + str(level + 1)

# public
func choose(entry : Dictionary):
	_levels[entry["id"]] = get_level(entry["id"]) + 1
	entry["apply"].call()
