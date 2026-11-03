class_name MeteorSpawner
extends RefCounted

# Drifting rocks of the run: a random one spawns on each timer tick, up to MaxMeteorCount alive.

var count = 0
var _world = null
var _info = null


func _init(world, info_box) -> void:
	_world = world
	_info = info_box


# public - timer tick
func spawn() -> void:
	if count >= LevelSettings.MaxMeteorCount:
		return

	count += 1

	var meteor = LevelSettings.get_random_meteor()
	var tmp_pos = Vector2(randf_range(LevelSettings.MinX, LevelSettings.MaxX), randf_range(LevelSettings.MinY, LevelSettings.MaxY))
	meteor.set_global_position(tmp_pos)
	var temp_vel = Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
	meteor.velocity = temp_vel
	meteor.connect("destroyed", on_destroyed)
	_world.add_child(meteor)

	_info.increaseMeteorCount()


# public - a rock was shot apart or left the level
func on_destroyed() -> void:
	count = count - 1
	_info.decreaseMeteorCount()
