class_name EnemySpawner
extends RefCounted

# Owns the enemies of a run: spawns them around the player, keeps the registry of the living
# (by instance id) and the elites, and reports every kill to the game through on_killed.
# A dying enemy stays registered until its death sequence ends (see unregister).

const SPAWN_MIN_DISTANCE = 950.0
const SPAWN_MAX_DISTANCE = 1100.0

var active_enemies : Dictionary = {}
var elites : Dictionary = {}
var count = 0

var _world = null
var _info = null
var _phase_guard = null
var _player = null
var _on_killed : Callable
# set by GameLogic, scales spawn distance and enemy stats with the pressure
var overseer : Overseer = null


func _init(world, info_box, phase_guard, player, on_killed : Callable) -> void:
	_world = world
	_info = info_box
	_phase_guard = phase_guard
	_player = player
	_on_killed = on_killed


# public - levels share waves, a level can swap an enemy for its own (level 2: scout -> pebble mite)
func level_enemy(type : Enums.ENEMIES) -> Enums.ENEMIES:
	return Levels.get_current().get("replace", {}).get(type, type)


# public
func spawn(type : Enums.ENEMIES, pos : Vector2, life_factor : float = 1.0):
	# a spawn path skipped level_enemy(): the other level's enemy would be loaded
	assert(LevelSettings.is_level_enemy(type), "enemy %d is not part of the active level" % type)
	var enemy = LevelSettings.get_enemy(type)
	active_enemies[enemy.get_instance_id()] = enemy
	enemy.connect("killed", _on_killed)
	enemy.position = pos
	enemy.Life = int(enemy.Life * life_factor)

	# endless mode makes enemies stronger
	if _phase_guard.difficulty > 1.0:
		enemy.Life = int(enemy.Life * _phase_guard.difficulty)
		enemy.Damage = int(enemy.Damage * _phase_guard.difficulty)

	# the overseer makes enemies tougher while the screen is too empty
	if overseer != null:
		enemy.Life = int(enemy.Life * overseer.toughness())
		enemy.Damage = int(enemy.Damage * overseer.damage_multiplier())
		if "Speed" in enemy:
			enemy.Speed = enemy.Speed * (1.0 + (overseer.intensity - 1.0) * 0.1)

	_world.add_child(enemy)
	enemy.setup_rotation(deg_to_rad(randi_range(0, 360)))

	count = count + 1
	_info.increaseEnemyCount()
	return enemy


# public - a kill is over (called when the enemy reports it), returns the enemy
func unregister(id : int):
	count = count - 1
	_info.decreaseEnemyCount()
	var enemy = active_enemies[id]
	active_enemies.erase(id)
	if elites.has(id):
		elites.erase(id)
	return enemy


# public - dev console, every enemy explodes as if shot, returns how many
func kill_all() -> int:
	var killed = 0
	for enemy in active_enemies.values():
		if kill(enemy):
			killed += 1
	return killed


# public - the enemy explodes as if shot, false when it is already dying
func kill(enemy) -> bool:
	# the worm stays in active_enemies during its death animation
	if enemy.isDead:
		return false
	enemy.isDead = true
	enemy.explode()
	return true


# public - random point on a ring just outside the screen
func spawn_position() -> Vector2:
	var scale = overseer.distance_scale() if overseer != null else 1.0
	var near = SPAWN_MIN_DISTANCE * scale
	var far = SPAWN_MAX_DISTANCE * scale
	for i in range(8):
		var offset = Vector2(randf_range(near, far), 0).rotated(randf() * TAU)
		var pos = _player.global_position + offset
		if pos.x > LevelSettings.MinX and pos.x < LevelSettings.MaxX and pos.y > LevelSettings.MinY and pos.y < LevelSettings.MaxY:
			return pos

	return clamp_to_level(_player.global_position + Vector2(near, 0).rotated(randf() * TAU))


# public
func clamp_to_level(pos : Vector2) -> Vector2:
	return Vector2(clamp(pos.x, LevelSettings.MinX, LevelSettings.MaxX), clamp(pos.y, LevelSettings.MinY, LevelSettings.MaxY))
