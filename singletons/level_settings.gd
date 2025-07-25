extends Node

@export var MinX = -1608
@export var MaxX = 3070
@export var MinY = -1304
@export var MaxY =  2192

var MaxEnemyCount : int = 10
var MaxMeteorCount : int = 20

var _points_dict : Dictionary = {
	"Enemy 1" : 10,
	"Enemy 2" : 20,
	"Enemy 3" : 20
}

var _perk_chances : Dictionary = {
	Enums.PERKS.LIFE : 25,
	Enums.PERKS.SHIELD : 25,
	Enums.PERKS.DAMAGE_UP : 50,
	Enums.PERKS.BIG_GUN : 50,
	Enums.PERKS.WAVE : 50,
	Enums.PERKS.HOMING : 50,
}

var _meteor_mine_chance = 50

var _perk_scenes : Dictionary = {
	Enums.PERKS.LIFE : preload("res://scenes/life_perk.tscn"),
	Enums.PERKS.SHIELD : preload("res://scenes/shield_perk.tscn"),
	Enums.PERKS.DAMAGE_UP : preload("res://scenes/damage_up_perk.tscn"),
 	Enums.PERKS.BIG_GUN : preload("res://scenes/big_gun_perk.tscn"),
 	Enums.PERKS.WAVE : preload("res://scenes/wave_perk.tscn"),
 	Enums.PERKS.HOMING : preload("res://scenes/homing_perk.tscn")
}

var _meteor_scenes = [
	preload("res://scenes/rock.tscn"),
	preload("res://scenes/rock_green.tscn"),
	preload("res://scenes/rock_red.tscn"),
	preload("res://scenes/rock_yellow.tscn")
]

var _enemy_scenes = [
	preload("res://scenes/enemy_1.tscn"), 
	preload("res://scenes/enemy_2.tscn"), 
	preload("res://scenes/enemy_3.tscn")
]

var _mine_scene = preload("res://scenes/mine.tscn")

func _ready() -> void:
	pass

func get_points(enemy: String) -> int:
	return _points_dict[enemy]
	
func get_chance(perk : Enums.PERKS) -> int:
	return _perk_chances[perk]
	
func drop_perk(perk : Enums.PERKS):
	var chance = randi_range(0, 100)
	
	if chance > LevelSettings.get_chance(perk):
			return null
	
	return _perk_scenes[perk].instantiate()

func get_random_enemy():
	return _enemy_scenes[randi_range(0, _enemy_scenes.size() - 1)].instantiate()
	#return _enemy_scenes[0].instantiate()
	
func get_random_meteor():
	return _meteor_scenes[randi_range(0, _meteor_scenes.size() - 1)].instantiate()
	
func get_random_mine_from_meteor():
	if randi_range(0, 100) < _meteor_mine_chance:
		return _mine_scene.instantiate()
	return null
