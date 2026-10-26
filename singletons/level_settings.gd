extends Node

@export var MinX = -1608
@export var MaxX = 3070
@export var MinY = -1304
@export var MaxY =  2192

var MaxEnemyCount : int = 10
var MaxMeteorCount : int = 12

var _points_dict : Dictionary = {
	"Enemy 1" : 10,
	"Enemy 2" : 30,
	"Enemy 3" : 30,
	"Boss" : 10000,
}

# xp given by the gem dropped from an enemy
var _xp_dict : Dictionary = {
	"Enemy 1" : 1,
	"Enemy 2" : 5,
	"Enemy 3" : 5,
	"Boss" : 100,
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
	Enums.PERKS.LIFE : preload("res://scenes/life_perk.tscn"),
	Enums.PERKS.SHIELD : preload("res://scenes/shield_perk.tscn"),
	Enums.PERKS.DAMAGE_UP : preload("res://scenes/damage_up_perk.tscn"),
	Enums.PERKS.CRITIC_CHANCE_UP : preload("res://scenes/critic_chance_up_perk.tscn"),
	Enums.PERKS.CRITIC_HIT_MULTIPLIER : preload("res://scenes/critic_hit_multiplier_perk.tscn"),
	Enums.PERKS.SPEED_UP : preload("res://scenes/speed_up_perk.tscn"),
	Enums.PERKS.BIG_GUN : preload("res://scenes/big_gun_perk.tscn"),
	Enums.PERKS.WAVE : preload("res://scenes/wave_perk.tscn"),
	Enums.PERKS.HOMING : preload("res://scenes/homing_perk.tscn"),
	Enums.PERKS.BOMB : preload("res://scenes/bomb_perk.tscn"),
	Enums.PERKS.MAGNET : preload("res://scenes/magnet_perk.tscn")
}

var _xp_gem_scene = preload("res://scenes/xp_gem.tscn")

var _meteor_scenes = [
	preload("res://scenes/rock.tscn"),
	preload("res://scenes/rock_green.tscn"),
	preload("res://scenes/rock_red.tscn"),
	preload("res://scenes/rock_yellow.tscn")
]

var _enemy_scenes : Dictionary = {
	Enums.ENEMIES.SCOUT : preload("res://scenes/enemy_1.tscn"), 
	Enums.ENEMIES.GUARD : preload("res://scenes/enemy_2.tscn"), 
	Enums.ENEMIES.HUNTER : preload("res://scenes/enemy_3.tscn"),
	Enums.ENEMIES.BOSS : preload("res://scenes/boss.tscn"),
}

var _mine_scene = preload("res://scenes/mine.tscn")

func get_points(enemy: String) -> int:
	return _points_dict[enemy]

func get_xp(enemy: String) -> int:
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

func get_enemy(enemy : Enums.ENEMIES):
	return _enemy_scenes[enemy].instantiate()

# boss is never returned here, it is spawned only by the phase logic
func get_random_enemy():
	var types = [Enums.ENEMIES.SCOUT, Enums.ENEMIES.GUARD, Enums.ENEMIES.HUNTER]
	return _enemy_scenes[types.pick_random()].instantiate()
	
func get_random_meteor():
	return _meteor_scenes[randi_range(0, _meteor_scenes.size() - 1)].instantiate()
	
func get_random_mine_from_meteor():
	if randi_range(0, 99) < _meteor_mine_chance:
		return _mine_scene.instantiate()
	return null
