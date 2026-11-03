class_name LevelDef
extends Resource

# One level of the ladder, stored as resources/levels/levelN/level.tres.
# `data` holds the level's keys (see levels.gd for their meaning); a level that is a variant
# of another sets `inherits` and only lists what differs, the rest comes from the base.
# Enums are stored as their numbers: ENEMIES 0 SCOUT, 1 GUARD, 2 HUNTER, 3 BOSS, 4 WORM_BOSS,
# 5 PEBBLE_MITE, 6 BOULDER_BEETLE, 7 SHARD_WASP, 8 QUARRY_MANTIS, 9 BEDROCK_QUEEN.
# WEAPONS 0 SMALL, 1 BIG, 2 SMALL_WAVE, 3 SMALL_HOMING, 4 SMALL_HOMING_WIHT_DELAY,
# 5 FIREWORKS, 6 BOMB, 7 ORBIT, 8 WORM_SPIT.

@export var inherits : LevelDef
@export var data : Dictionary = {}

# public - the full level dictionary, base keys first, own keys override them
func to_dict() -> Dictionary:
	var result = inherits.to_dict() if inherits != null else {}
	for key in data:
		result[key] = data[key]
	return result
