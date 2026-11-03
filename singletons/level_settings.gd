extends Node

@export var MinX = -1608
@export var MaxX = 3070
@export var MinY = -1304
@export var MaxY =  2192

var MaxEnemyCount : int = 10
var MaxMeteorCount : int = 12

# the banner that announces each boss, bosses are the only enemies with one
const BOSS_BANNERS : Dictionary = {
	Enums.ENEMIES.WORM_BOSS : ["THE DEVOURER RISES", Color.MEDIUM_PURPLE],
	Enums.ENEMIES.QUARRY_MANTIS : ["THE QUARRY MANTIS AWAKENS", Color(0.4, 0.85, 0.95)],
	Enums.ENEMIES.BEDROCK_QUEEN : ["THE BEDROCK QUEEN STIRS", Color(0.4, 0.85, 0.95)],
}
# every boss the levels can spawn, the phase logic and the dev console use it
const BOSS_KINDS : Array = [Enums.ENEMIES.BOSS, Enums.ENEMIES.WORM_BOSS, Enums.ENEMIES.QUARRY_MANTIS, Enums.ENEMIES.BEDROCK_QUEEN]

func is_boss(enemy : Enums.ENEMIES) -> bool:
	return enemy in BOSS_KINDS

# returns [text, color] of the boss banner, empty when the boss has none
func get_boss_banner(enemy : Enums.ENEMIES) -> Array:
	return BOSS_BANNERS.get(enemy, [])

var _points_dict : Dictionary = {
	Enums.ENEMIES.SCOUT : 10,
	Enums.ENEMIES.PEBBLE_MITE : 10,
	Enums.ENEMIES.BOULDER_BEETLE : 30,
	Enums.ENEMIES.SHARD_WASP : 30,
	Enums.ENEMIES.GUARD : 30,
	Enums.ENEMIES.HUNTER : 30,
	Enums.ENEMIES.BOSS : 10000,
	Enums.ENEMIES.WORM_BOSS : 15000,
	Enums.ENEMIES.QUARRY_MANTIS : 12500,
	Enums.ENEMIES.BEDROCK_QUEEN : 20000,
}

# xp given by the gem dropped from an enemy
var _xp_dict : Dictionary = {
	Enums.ENEMIES.SCOUT : 1,
	Enums.ENEMIES.PEBBLE_MITE : 1,
	Enums.ENEMIES.BOULDER_BEETLE : 5,
	Enums.ENEMIES.SHARD_WASP : 5,
	Enums.ENEMIES.GUARD : 5,
	Enums.ENEMIES.HUNTER : 5,
	Enums.ENEMIES.BOSS : 100,
	Enums.ENEMIES.WORM_BOSS : 150,
	Enums.ENEMIES.QUARRY_MANTIS : 120,
	Enums.ENEMIES.BEDROCK_QUEEN : 300,
}

# Xenite shards dropped by an enemy: [chance in %, value]
var _shard_drops : Dictionary = {
	Enums.ENEMIES.SCOUT : [4, 1],
	Enums.ENEMIES.PEBBLE_MITE : [4, 1],
	Enums.ENEMIES.BOULDER_BEETLE : [12, 1],
	Enums.ENEMIES.SHARD_WASP : [12, 1],
	Enums.ENEMIES.GUARD : [12, 1],
	Enums.ENEMIES.HUNTER : [12, 1],
	Enums.ENEMIES.BOSS : [100, 25],
	Enums.ENEMIES.WORM_BOSS : [100, 40],
	Enums.ENEMIES.QUARRY_MANTIS : [100, 30],
	Enums.ENEMIES.BEDROCK_QUEEN : [100, 60],
}

# chances are in 1/1000, stats and weapons come from level ups,
# only small floor pickups drop from enemies
var _perk_chances : Dictionary = {
	Enums.PERKS.LIFE : 25,
	Enums.PERKS.SHIELD : 15,
	Enums.PERKS.MAGNET : 8,
	Enums.PERKS.BOMB : 4
}

var _meteor_mine_chance = 50

var _perk_scenes : Dictionary = {
	Enums.PERKS.LIFE : preload("res://scenes/perks/life_perk.tscn"),
	Enums.PERKS.SHIELD : preload("res://scenes/perks/shield_perk.tscn"),
	Enums.PERKS.DAMAGE_UP : preload("res://scenes/perks/damage_up_perk.tscn"),
	Enums.PERKS.CRITIC_CHANCE_UP : preload("res://scenes/perks/critic_chance_up_perk.tscn"),
	Enums.PERKS.CRITIC_HIT_MULTIPLIER : preload("res://scenes/perks/critic_hit_multiplier_perk.tscn"),
	Enums.PERKS.SPEED_UP : preload("res://scenes/perks/speed_up_perk.tscn"),
	Enums.PERKS.BIG_GUN : preload("res://scenes/perks/big_gun_perk.tscn"),
	Enums.PERKS.WAVE : preload("res://scenes/perks/wave_perk.tscn"),
	Enums.PERKS.HOMING : preload("res://scenes/perks/homing_perk.tscn"),
	Enums.PERKS.BOMB : preload("res://scenes/perks/bomb_perk.tscn"),
	Enums.PERKS.MAGNET : preload("res://scenes/perks/magnet_perk.tscn")
}

var _xp_gem_scene = preload("res://scenes/shared/xp_gem.tscn")
var _shard_scene = preload("res://scenes/shared/shard.tscn")

var _meteor_scenes = [
	preload("res://scenes/shared/rock.tscn"),
	preload("res://scenes/shared/rock_green.tscn"),
	preload("res://scenes/shared/rock_red.tscn"),
	preload("res://scenes/shared/rock_yellow.tscn")
]

# enemy scenes are loaded per level, see activate_level(). Level 1 spawns the first five,
# level 2 spawns the replacements from its "replace" map (see levels.gd).
const ENEMY_SCENE_PATHS : Dictionary = {
	Enums.ENEMIES.SCOUT : "res://scenes/levels/level1/enemy_1.tscn",
	Enums.ENEMIES.GUARD : "res://scenes/levels/level1/enemy_2.tscn",
	Enums.ENEMIES.HUNTER : "res://scenes/levels/level1/enemy_3.tscn",
	Enums.ENEMIES.BOSS : "res://scenes/levels/level1/boss.tscn",
	Enums.ENEMIES.WORM_BOSS : "res://scenes/levels/level1/worm_boss.tscn",
	Enums.ENEMIES.PEBBLE_MITE : "res://scenes/levels/level2/pebble_mite.tscn",
	Enums.ENEMIES.BOULDER_BEETLE : "res://scenes/levels/level2/boulder_beetle.tscn",
	Enums.ENEMIES.SHARD_WASP : "res://scenes/levels/level2/shard_wasp.tscn",
	Enums.ENEMIES.QUARRY_MANTIS : "res://scenes/levels/level2/quarry_mantis.tscn",
	Enums.ENEMIES.BEDROCK_QUEEN : "res://scenes/levels/level2/bedrock_queen.tscn",
}
const LEVEL_ENEMIES : Array = [
	[Enums.ENEMIES.SCOUT, Enums.ENEMIES.GUARD, Enums.ENEMIES.HUNTER, Enums.ENEMIES.BOSS, Enums.ENEMIES.WORM_BOSS],
	[Enums.ENEMIES.PEBBLE_MITE, Enums.ENEMIES.BOULDER_BEETLE, Enums.ENEMIES.SHARD_WASP, Enums.ENEMIES.QUARRY_MANTIS, Enums.ENEMIES.BEDROCK_QUEEN],
]
# loaded enemy scenes by path, only the active level's enemies stay in here
var _scene_cache : Dictionary = {}
var _active_level : int = -1

var _mine_scene = preload("res://scenes/shared/mine.tscn")

func get_points(enemy : Enums.ENEMIES) -> int:
	return _points_dict[enemy]

func get_xp(enemy : Enums.ENEMIES) -> int:
	return _xp_dict[enemy]

func get_chance(perk : Enums.PERKS) -> int:
	return _perk_chances[perk]

func get_perk(perk : Enums.PERKS):
	var result = _perk_scenes[perk].instantiate()
	result.set_perk_type(perk)
	return result

func get_random_perk():
	var chance = randi_range(0, 999)
	var _temp_sum = 0
	for perk in _perk_chances:
		if chance >= _temp_sum and chance < _temp_sum + _perk_chances[perk]:
			return get_perk(perk)

		_temp_sum += _perk_chances[perk]

	return null

func get_xp_gem(value : int):
	var gem = _xp_gem_scene.instantiate()
	gem.Value = value
	return gem

# returns the shard value to drop, 0 when nothing drops
func get_shard_drop(enemy : Enums.ENEMIES) -> int:
	var drop = _shard_drops.get(enemy, [0, 0])
	if randf_range(0.0, 100.0) < drop[0] * MetaProgress.get_shard_chance_factor():
		return drop[1]
	return 0

func get_shard(value : int):
	var shard = _shard_scene.instantiate()
	shard.Value = value
	return shard

# public - loads the enemies of a level in the background and frees the other level's enemies.
# Replaying the same level keeps everything cached, nothing is loaded again.
func activate_level(index : int) -> void:
	if index == _active_level:
		return
	_active_level = index
	for path in _scene_cache.keys():
		if !_is_enemy_of_level(path, index):
			_scene_cache.erase(path)
	if index >= 0 and index < LEVEL_ENEMIES.size():
		for enemy in LEVEL_ENEMIES[index]:
			var path = ENEMY_SCENE_PATHS[enemy]
			if !_scene_cache.has(path):
				ResourceLoader.load_threaded_request(path)


func _is_enemy_of_level(path : String, index : int) -> bool:
	if index < 0 or index >= LEVEL_ENEMIES.size():
		return false
	for enemy in LEVEL_ENEMIES[index]:
		if ENEMY_SCENE_PATHS[enemy] == path:
			return true
	return false


# the threaded load requested by activate_level() is used when it finished, otherwise loads now
func _enemy_scene(path : String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path]
	var scene = null
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		scene = ResourceLoader.load_threaded_get(path)
	else:
		scene = load(path)
	_scene_cache[path] = scene
	return scene


func get_enemy(enemy : Enums.ENEMIES):
	var instance = _enemy_scene(ENEMY_SCENE_PATHS[enemy]).instantiate()
	instance.enemy_kind = enemy
	return instance

func get_random_meteor():
	return _meteor_scenes[randi_range(0, _meteor_scenes.size() - 1)].instantiate()
	
func get_random_mine_from_meteor():
	if randi_range(0, 99) < _meteor_mine_chance:
		return _mine_scene.instantiate()
	return null
