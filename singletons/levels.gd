extends Node

# Level ladder: every level is a survival run with its own stages, bosses and story.
# Only available levels carry gameplay data, the others are shown as under development.
# A level is won when its final boss is killed, and that unlocks the next level.

const MAX_LEVELS = 10

var current : int = 0
# hangar opened from the game over screen: it offers retry or main menu instead of launch / back
var hangar_after_death = false

# the playable levels are data, resources/levels/levelN/level.tres (see LevelDef):
# stage entry = { delay, max_alive, wave }, wave entry = [enemy, count, chance in %]
# boss entry = { at (seconds), type, final }
# level 2 inherits the waves, bosses and tuning of level 1 and only lists what differs
const LEVEL_DEFS : Array = [
	preload("res://resources/levels/level1/level.tres"),
	preload("res://resources/levels/level2/level.tres"),
]

# levels not built yet: only their name is shown in the ladder
const _UNBUILT_LEVELS : Array = [
	{ "name" : "The Red Nebula", "available" : false },
	{ "name" : "Hive Outpost", "available" : false },
	{ "name" : "Silent Moons", "available" : false },
	{ "name" : "Graveyard Belt", "available" : false },
	{ "name" : "Brood Mother", "available" : false },
	{ "name" : "Rift Crossing", "available" : false },
	{ "name" : "Alien Homeworld", "available" : false },
	{ "name" : "Heart of the Swarm", "available" : false },
]

var _levels : Array = _build_ladder()

func _build_ladder() -> Array:
	var ladder : Array = []
	for def in LEVEL_DEFS:
		ladder.append(def.to_dict())
	ladder.append_array(_UNBUILT_LEVELS)
	return ladder

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
