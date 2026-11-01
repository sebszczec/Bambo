extends Node

# Level ladder: every level is a survival run with its own stages, bosses and story.
# Only available levels carry gameplay data, the others are shown as under development.
# A level is won when its final boss is killed.

const MAX_LEVELS = 10

var current : int = 0

# stage entry = { delay, max_alive, wave }, wave entry = [enemy, count, chance in %]
# boss entry = { at (seconds), type, final }
var _levels : Array = [
	{
		"name" : "First Contact",
		"tagline" : "They were never coming in peace.",
		"story" : [
			"2189. The deep-space array at the edge of the Kuiper Belt went silent nineteen minutes ago. Its last transmission showed a single image: a wall of bio-mechanical ships, swarming like insects, pouring out of a tear in space.",
			"Earth's fleet is still three days out. The only thing between the swarm and the inner colonies is the Thunder-class interceptor on patrol in this sector. That's you.",
			"Command's orders are simple: hold the line. Scout drones will come first, then their guardians and hunters. Long-range scans picked up two massive signatures behind the swarm - a carrier-class Hive Beetle and something even bigger, burrowing through the debris field.",
			"Bring them down, pilot. Show them that this system bites back.",
		],
		"objective" : "Survive the invasion and destroy both alien flagships.",
		"win_text" : "FIRST CONTACT REPELLED",
		"available" : true,
		"stages" : [
			{ "delay" : 1.1, "max_alive" : 25,
				"wave" : [[Enums.ENEMIES.SCOUT, 3, 100]] },
			{ "delay" : 1.0, "max_alive" : 35,
				"wave" : [[Enums.ENEMIES.SCOUT, 3, 100], [Enums.ENEMIES.GUARD, 1, 15]] },
			{ "delay" : 0.9, "max_alive" : 45,
				"wave" : [[Enums.ENEMIES.SCOUT, 4, 100], [Enums.ENEMIES.GUARD, 1, 25]] },
			{ "delay" : 0.8, "max_alive" : 55,
				"wave" : [[Enums.ENEMIES.SCOUT, 4, 100], [Enums.ENEMIES.GUARD, 1, 30], [Enums.ENEMIES.HUNTER, 1, 10]] },
			{ "delay" : 0.75, "max_alive" : 60,
				"wave" : [[Enums.ENEMIES.SCOUT, 4, 100], [Enums.ENEMIES.GUARD, 1, 35], [Enums.ENEMIES.HUNTER, 1, 15]] },
			{ "delay" : 0.7, "max_alive" : 70,
				"wave" : [[Enums.ENEMIES.SCOUT, 5, 100], [Enums.ENEMIES.GUARD, 1, 40], [Enums.ENEMIES.HUNTER, 1, 20]] },
			{ "delay" : 0.65, "max_alive" : 80,
				"wave" : [[Enums.ENEMIES.SCOUT, 5, 100], [Enums.ENEMIES.GUARD, 1, 45], [Enums.ENEMIES.HUNTER, 1, 25]] },
			{ "delay" : 0.6, "max_alive" : 90,
				"wave" : [[Enums.ENEMIES.SCOUT, 5, 100], [Enums.ENEMIES.GUARD, 2, 50], [Enums.ENEMIES.HUNTER, 1, 30]] },
			{ "delay" : 0.55, "max_alive" : 100,
				"wave" : [[Enums.ENEMIES.SCOUT, 6, 100], [Enums.ENEMIES.GUARD, 2, 55], [Enums.ENEMIES.HUNTER, 1, 35]] },
			{ "delay" : 0.5, "max_alive" : 110,
				"wave" : [[Enums.ENEMIES.SCOUT, 6, 100], [Enums.ENEMIES.GUARD, 2, 60], [Enums.ENEMIES.HUNTER, 1, 40]] },
		],
		"bosses" : [
			{ "at" : 300.0, "type" : Enums.ENEMIES.BOSS, "final" : false },
			{ "at" : 600.0, "type" : Enums.ENEMIES.WORM_BOSS, "final" : true },
		],
		"elite_at" : 450.0,
		"swarm_every" : 120.0,
		"swarm_base" : 15,
		"swarm_per_stage" : 2,
		"boss_life_factor" : 0.8,
		"victory_bonus" : 5000,
	},
	{ "name" : "Asteroid Siege", "available" : false },
	{ "name" : "The Red Nebula", "available" : false },
	{ "name" : "Hive Outpost", "available" : false },
	{ "name" : "Silent Moons", "available" : false },
	{ "name" : "Graveyard Belt", "available" : false },
	{ "name" : "Brood Mother", "available" : false },
	{ "name" : "Rift Crossing", "available" : false },
	{ "name" : "Alien Homeworld", "available" : false },
	{ "name" : "Heart of the Swarm", "available" : false },
]

# public
func get_current() -> Dictionary:
	return _levels[current]

# public
func get_level(index : int) -> Dictionary:
	return _levels[index]

# public
func get_count() -> int:
	return min(_levels.size(), MAX_LEVELS)

# public
func select(index : int):
	if is_available(index):
		current = index

# public
func is_available(index : int) -> bool:
	return index >= 0 and index < get_count() and _levels[index].get("available", false)

# public
func is_completed(index : int) -> bool:
	return ConfigHandler.get_completed_levels().has(index)

# public
func mark_completed(index : int):
	ConfigHandler.add_completed_level(index)

# public - "LEVEL 1 - FIRST CONTACT"
func get_title(index : int = current) -> String:
	return "LEVEL %d - %s" % [index + 1, _levels[index]["name"].to_upper()]
