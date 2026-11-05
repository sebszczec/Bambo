extends Node

# Pool of upgrades offered on level up ("pick 1 of 3").
# Stat upgrades change PlayerStatus, weapon upgrades are handed to game logic.

const MAX_WEAPONS = 5
const PERKS = "res://resources/shared/pickups/"

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
	# not offered in level 2 (index 1): replaced by Carbide Tips there
	_add_stat("damage", "Damage", "+15% damage", PERKS + "icon_damage.png", 10,
		func(): PlayerStatus.increase_damage(15), -1, 1)
	# not offered in level 2 (index 1): replaced by Seismic Sensor there
	_add_stat("crit_chance", "Precision", "+5% critical chance", PERKS + "icon_precision.png", 8,
		func(): PlayerStatus.increase_critic_chance(5), -1, 1)
	# not offered in level 2 (index 1): replaced by Fault Line there
	_add_stat("crit_mult", "Lethality", "+30% critical damage", PERKS + "icon_lethality.png", 8,
		func(): PlayerStatus.increase_critic_hit_multiplier(30), -1, 1)
	_add_stat("speed", "Thrusters", "+10% move speed", PERKS + "icon_thrusters.png", 5,
		func(): PlayerStatus.increase_speed(10))
	# not offered in level 2 (index 1): replaced by Pressure Valve there
	_add_stat("fire_rate", "Overclock", "+12% fire rate", PERKS + "icon_overclock.png", 6,
		func(): PlayerStatus.FireRate += 12, -1, 1)
	# not offered in level 2 (index 1): replaced by Extra Charges there
	_add_stat("projectile", "Multishot", "+1 projectile for every weapon", PERKS + "icon_multishot.png", 3,
		func(): PlayerStatus.ProjectileCount += 1, -1, 1)
	_add_stat("max_life", "Hull plating", "+20 max life, heals 20", PERKS + "icon_hull.png", 8,
		_apply_max_life)
	_add_stat("regen", "Nanobots", "+0.6 life per second", PERKS + "icon_nanobots.png", 5,
		func(): PlayerStatus.Regen += 0.6)
	_add_stat("armor", "Armor", "-2 damage from every hit", PERKS + "icon_armor.png", 5,
		func(): PlayerStatus.Armor += 2)
	_add_stat("shield", "Shield capacitor", "+25 max shield", PERKS + "icon_shield.png", 4,
		_apply_max_shield)
	_add_stat("magnet", "Tractor beam", "+40% pickup radius", PERKS + "icon_tractor.png", 5,
		func(): PlayerStatus.PickupRadius *= 1.4)
	# level 2 only (levels.gd index 1): Asteroid Siege stat card, see level2_bonuses.md 5.1
	_add_stat("carbide", "Carbide Tips", "+12% damage", PERKS + "icon_carbide.png", 10,
		func(): PlayerStatus.increase_damage(12), 1)
	# level 2 only: Asteroid Siege replacement for Precision
	_add_stat("seismic", "Seismic Sensor", "+6% critical chance", PERKS + "icon_seismic.png", 6,
		func(): PlayerStatus.increase_critic_chance(6), 1)
	# level 2 only: Asteroid Siege replacement for Lethality
	_add_stat("fault_line", "Fault Line", "+35% critical damage", PERKS + "icon_fault_line.png", 6,
		func(): PlayerStatus.increase_critic_hit_multiplier(35), 1)
	# level 2 only: Asteroid Siege replacement for Overclock
	_add_stat("pressure_valve", "Pressure Valve", "+10% fire rate", PERKS + "icon_pressure_valve.png", 6,
		func(): PlayerStatus.FireRate += 10, 1)
	# level 2 only: Asteroid Siege replacement for Multishot
	_add_stat("extra_charges", "Extra Charges", "+1 projectile for every weapon", PERKS + "icon_extra_charges.png", 3,
		func(): PlayerStatus.ProjectileCount += 1, 1)
	# level 2 only: new card, straight shots and drill shells bounce to the next enemy
	_add_stat("ricochet", "Ricochet Plates", "Straight shots and drill shells bounce to the nearest enemy. Each level: one more bounce", PERKS + "icon_ricochet.png", 3,
		func(): PlayerStatus.Ricochet += 1, 1)
	# level 2 only: every 6th hit on an enemy deals +60%, one hit sooner per level
	_add_stat("fracture", "Fracture", "Every 6th hit on an enemy: +60% damage, 1 hit sooner per level", PERKS + "icon_fracture.png", 4,
		func(): PlayerStatus.Fracture += 1, 1)
	# level 2 only: shots burn the enemy they hit for 15 % of the hit damage per level, over 2 s
	_add_stat("slag", "Slag Trails", "Shots burn enemies: 15% of hit damage over 2 s per level", PERKS + "icon_slag_trails.png", 4,
		func(): PlayerStatus.Slag += 1, 1)

	_add_weapon("w_blaster", "Blaster", "Main gun", "Faster and wider main gun",
		PERKS + "icon_blaster.png", Enums.WEAPONS.SMALL)
	_add_weapon("w_cannon", "Heavy cannon", "Auto-aimed heavy shells", "Faster, more shells",
		PERKS + "icon_cannon.png", Enums.WEAPONS.BIG)
	_add_weapon("w_nova", "Nova", "Ring of bullets around you", "More bullets, faster pulse",
		PERKS + "icon_nova.png", Enums.WEAPONS.SMALL_WAVE)
	_add_weapon("w_missiles", "Missiles", "Homing rockets", "More rockets, faster reload",
		PERKS + "icon_missiles.png", Enums.WEAPONS.SMALL_HOMING)
	_add_weapon("w_fireworks", "Fireworks", "Shell exploding into shrapnel", "Bigger explosions",
		PERKS + "icon_fireworks.png", Enums.WEAPONS.FIREWORKS)
	_add_weapon("w_orbit", "Orbit", "Blades circling your ship", "Bigger blades, wider orbit. Lv 6: outer ring",
		PERKS + "icon_orbit.png", Enums.WEAPONS.ORBIT)

func _apply_max_life():
	PlayerStatus.increase_max_life(20)
	game.player.updateLife(20)

func _apply_max_shield():
	PlayerStatus.increase_max_shield(25)
	game.player.updateShield(25)

func _add_stat(id : String, title : String, desc : String, icon : String, max_level : int, apply : Callable, only_level : int = -1, except_level : int = -1):
	_pool.append({ "id" : id, "title" : title, "desc" : desc, "desc_up" : desc, "icon" : load(icon),
		"max_level" : max_level, "weapon" : false, "weight" : 10, "apply" : apply,
		"only_level" : only_level, "except_level" : except_level })

func _add_weapon(id : String, title : String, desc : String, desc_up : String, icon : String, type : Enums.WEAPONS):
	_pool.append({ "id" : id, "title" : title, "desc" : desc, "desc_up" : desc_up, "icon" : load(icon),
		"max_level" : 6, "weapon" : true, "weight" : 12, "type" : type,
		"apply" : func(): game.add_weapon(type) })

# public
func get_weapon_icon(type : Enums.WEAPONS) -> Texture2D:
	for entry in _pool:
		if entry["weapon"] and entry["type"] == type:
			return _skinned(entry)["icon"]
	return null

# the level can rename a weapon and give it its own card icon ("weapon_skin" in levels.gd)
func _skinned(entry : Dictionary) -> Dictionary:
	if !entry["weapon"]:
		return entry
	var skin = Levels.get_current().get("weapon_skin", {}).get(entry["type"], {})
	if skin.is_empty():
		return entry
	var result = entry.duplicate()
	for key in ["title", "desc", "desc_up"]:
		if skin.has(key):
			result[key] = skin[key]
	if skin.has("icon"):
		result["icon"] = load(skin["icon"])
	return result

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

	# level-specific cards (only_level = index in Levels) are not offered in other levels
	if entry.get("only_level", -1) >= 0 and entry["only_level"] != Levels.current:
		return false
	# level 1 cards replaced by a level-specific card (except_level = index in Levels)
	if entry.get("except_level", -1) >= 0 and entry["except_level"] == Levels.current:
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
			"icon" : load(PERKS + "icon_repair.png"), "max_level" : 999, "weapon" : false, "weight" : 1,
			"apply" : func(): game.player.updateLife(40) })

	for i in range(result.size()):
		result[i] = _skinned(result[i])
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
