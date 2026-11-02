extends Node

# Level ladder: every level is a survival run with its own stages, bosses and story.
# Only available levels carry gameplay data, the others are shown as under development.
# A level is won when its final boss is killed, and that unlocks the next level.

const MAX_LEVELS = 10

var current : int = 0
# hangar opened from the game over screen: it offers retry or main menu instead of launch / back
var hangar_after_death = false

# stage entry = { delay, max_alive, wave }, wave entry = [enemy, count, chance in %]
# boss entry = { at (seconds), type, final }
# level 2 reuses the level 1 waves and bosses until it gets its own
const _LEVEL1_STAGES = [
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
]

const _LEVEL1_BOSSES = [
	{ "at" : 300.0, "type" : Enums.ENEMIES.BOSS, "final" : false },
	{ "at" : 600.0, "type" : Enums.ENEMIES.WORM_BOSS, "final" : true },
]

# optional "background" = { base, brightness, far, mid, near }, layer entry = [texture, position, scale],
# brightness = layer modulate per layer (optional)
# optional "replace" = { enemy : enemy } swaps enemies of the shared waves, swarms, bosses and boss minions
# without it the level keeps the planets of world.tscn
# optional "music" = in-level track (looped), without it the level keeps the track of world.tscn
# optional "music_db" = volume of the in-level track (default 0)
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
		"stages" : _LEVEL1_STAGES,
		"bosses" : _LEVEL1_BOSSES,
		"elite_at" : 450.0,
		"swarm_every" : 120.0,
		"swarm_base" : 15,
		"swarm_per_stage" : 2,
		"boss_life_factor" : 0.8,
		"victory_bonus" : 5000,
	},
	{
		"name" : "Asteroid Siege",
		"tagline" : "The rocks are alive now.",
		"story" : [
			"The swarm did not retreat. It dug in. Three weeks after First Contact, the mining colonies of the Hilda asteroid belt stopped answering, and survey drones came back with images of black, root-like growths spreading across the rocks, pulsing with cold blue light.",
			"The hive is turning the belt into a fortress. Every asteroid it touches becomes a nest, and every nest pours out more drones. If the growth reaches the refinery stations, the colonies lose their only fuel supply.",
			"Your orders: fly into the belt, break the siege and kill whatever is commanding it from inside the rock. Watch the debris, pilot - out here even the scenery can hit back.",
		],
		"objective" : "Break the hive siege of the asteroid belt and destroy both alien flagships.",
		"win_text" : "ASTEROID SIEGE BROKEN",
		"available" : true,
		"stages" : _LEVEL1_STAGES,
		"bosses" : _LEVEL1_BOSSES,
		"elite_at" : 450.0,
		"swarm_every" : 120.0,
		"swarm_base" : 15,
		"swarm_per_stage" : 2,
		"boss_life_factor" : 0.8,
		"victory_bonus" : 5000,
		"music" : "res://resources/levels/level2/music/level2_asteroid_siege.ogg",
		"music_db" : 6.0,
		"replace" : {
			Enums.ENEMIES.SCOUT : Enums.ENEMIES.PEBBLE_MITE,
			Enums.ENEMIES.GUARD : Enums.ENEMIES.BOULDER_BEETLE,
			Enums.ENEMIES.HUNTER : Enums.ENEMIES.SHARD_WASP,
			Enums.ENEMIES.BOSS : Enums.ENEMIES.QUARRY_MANTIS,
			Enums.ENEMIES.WORM_BOSS : Enums.ENEMIES.BEDROCK_QUEEN,
		},
		"background" : {
			"base" : "res://resources/levels/level2/background/bg.jpg",
			# the painted rocks are darker than the planets, the scene dimming hides them
			"brightness" : { "far" : 0.5, "mid" : 0.65, "near" : 0.75 },
			"far" : [
				["res://resources/levels/level2/background/asteroid_small_1.png", Vector2(230, 190), 0.18],
				["res://resources/levels/level2/background/asteroid_small_2.png", Vector2(1010, 470), 0.14],
				["res://resources/levels/level2/background/asteroid_small_3.png", Vector2(1500, 860), 0.16],
				["res://resources/levels/level2/background/asteroid_small_4.png", Vector2(1640, 140), 0.12],
			],
			"mid" : [
				["res://resources/levels/level2/background/asteroid_small_4.png", Vector2(320, 470), 0.5],
				["res://resources/levels/level2/background/asteroid_medium.png", Vector2(1900, 1100), 0.45],
			],
			"near" : [
				["res://resources/levels/level2/background/asteroid_huge.png", Vector2(900, 350), 0.9],
			],
		},
		# optional "weapon_skin" = { weapon : skin } renames a weapon of the level and swaps its card icon
		# and its bullet art (the weapon id, damage and levels stay the same). bullet = slug texture,
		# trail = tint of the engine trail behind it
		"weapon_skin" : {
			Enums.WEAPONS.SMALL : {
				"title" : "Rivet Gun",
				"desc" : "Main gun",
				"desc_up" : "Faster and wider main gun",
				"icon" : "res://resources/levels/level2/weapons/rivet_gun/rivet_gun_icon.png",
				"bullet" : "res://resources/levels/level2/weapons/rivet_gun/rivet_gun_slug.png",
				"trail" : Color(1.6, 0.9, 0.4),
			},
			Enums.WEAPONS.BIG : {
				"title" : "Drill Cannon",
				"desc" : "Auto-aimed drill shells",
				"desc_up" : "Faster, more shells. Lv 4: shells pierce one enemy",
				"icon" : "res://resources/levels/level2/weapons/drill_cannon/drill_cannon_icon.png",
				"bullet" : "res://resources/levels/level2/weapons/drill_cannon/drill_cannon_bit.png",
				"trail" : Color(1.8, 1.0, 0.5),
				# shells pass through one extra enemy from this weapon level on
				"pierce" : 1,
				"pierce_level" : 4,
			},
			Enums.WEAPONS.SMALL_WAVE : {
				"title" : "Quake Charge",
				"desc" : "Ring of rock shards around you",
				"desc_up" : "More shards, faster pulse",
				"icon" : "res://resources/levels/level2/weapons/quake_charge/quake_charge_icon.png",
				"bullet" : "res://resources/levels/level2/weapons/quake_charge/quake_charge_shard.png",
				"trail" : Color(1.5, 0.8, 0.2),
			},
		},
	},
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
	if is_unlocked(index):
		current = index
		ConfigHandler.save_last_level(index)

# public
func is_available(index : int) -> bool:
	return index >= 0 and index < get_count() and _levels[index].get("available", false)

# public - level n opens when level n-1 is cleared
func is_unlocked(index : int) -> bool:
	return is_available(index) and (index == 0 or is_completed(index - 1))

# public
func is_completed(index : int) -> bool:
	return ConfigHandler.get_completed_levels().has(index)

# public
func mark_completed(index : int):
	ConfigHandler.add_completed_level(index)

# public - "LEVEL 1 - FIRST CONTACT"
func get_title(index : int = current) -> String:
	return "LEVEL %d - %s" % [index + 1, _levels[index]["name"].to_upper()]
