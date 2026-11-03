class_name DropService
extends RefCounted

# Everything an enemy or a rock leaves behind: xp gems, xenite shards and perk pickups.
# Gems over MAX_GEMS merge into an existing one instead of piling up on the floor.

const MAX_GEMS = 200
const XpGemScript = preload("res://scripts/xp_gem.gd")

var _host = null
var _on_bomb_taken : Callable


func _init(host : Node, on_bomb_taken : Callable) -> void:
	_host = host
	_on_bomb_taken = on_bomb_taken


# public
func drop_xp(pos : Vector2, value : int) -> void:
	# too many gems on the floor - add the value to an existing one
	if XpGemScript.alive_count >= MAX_GEMS and XpGemScript.all.size() > 0:
		XpGemScript.all.pick_random().add_value(value)
		return

	var gem = LevelSettings.get_xp_gem(value)
	gem.position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	_host.call_deferred("add_child", gem)


# public
func drop_shard(pos : Vector2, value : int) -> void:
	var shard = LevelSettings.get_shard(value)
	shard.position = pos + Vector2(randf_range(-12, 12), randf_range(-12, 12))
	_host.call_deferred("add_child", shard)


# public - a random perk, false when none rolls
func add_random_perk(pos : Vector2) -> bool:
	var perk = LevelSettings.get_random_perk()
	if perk == null:
		return false
	_place_perk(perk, pos)
	return true


# public - dev console
func drop_perk(type : Enums.PERKS, pos : Vector2) -> void:
	_place_perk(LevelSettings.get_perk(type), pos)


func _place_perk(perk, pos : Vector2) -> void:
	if perk.get_perk_type() == Enums.PERKS.BOMB:
		perk.connect("taken", _on_bomb_taken)

	perk.position = pos
	_host.call_deferred("add_child", perk)
