extends StaticBody2D

class_name Bullet

# Bullets are pooled per scene: dispose() parks a spent bullet, acquire() hands it out again.
# A weapon configures a bullet after acquire(); parking restores the scene's defaults
# (see _capture_defaults), so nothing from the previous shot survives.

@export var Speed = 20
@export var LifeTime = 0.5
@export var HitBox : Area2D
@export var Type : Enums.WEAPONS = Enums.WEAPONS.SMALL
# piercing bullets are not destroyed when they hit something (orbit blades)
@export var Piercing = false
# enemies a bullet passes through before it is destroyed (drill cannon shells from their piercing level)
@export var PierceCount = 0
# bounces left: after an enemy hit the bullet turns to the nearest other enemy (Ricochet Plates, level 2)
@export var BounceCount = 0
const BOUNCE_RANGE = 400.0
const POOL_LIMIT = 256

@onready var lifeTimer = $LifeTimer
@onready var bolid = $BulletEffect

static var _pools : Dictionary = {}

var velocity = Vector2(0, 0)
# set by the weapon: a mine's blast ring, rocks ignore it so a blast cannot start a chain of mines
var from_mine = false
var _pool_key = ""
var _parked = false
var _defaults = {}
var _effect_defaults = {}
var _sprite_visibility = []
var _skin_node = null

signal freeing

# public - a parked bullet of this scene, or a new one
static func acquire(scene : PackedScene) -> Bullet:
	var key = scene.resource_path
	var pool : Array = _pools.get(key, [])
	_pools[key] = pool
	if pool.is_empty():
		var fresh : Bullet = scene.instantiate()
		fresh._pool_key = key
		fresh._capture_defaults()
		return fresh
	var reused : Bullet = pool.pop_back()
	reused._reset()
	return reused


# the scene's own values, read before any weapon configures the bullet
func _capture_defaults() -> void:
	_defaults = {"Speed": Speed, "LifeTime": LifeTime, "Piercing": Piercing, "PierceCount": PierceCount, "BounceCount": BounceCount}
	var effect = get_node("BulletEffect")
	_effect_defaults = {"scale": effect.scale, "self_modulate": effect.self_modulate}
	for child in get_children():
		if child is Sprite2D:
			_sprite_visibility.append([child, child.visible])


func _reset() -> void:
	_parked = false
	Speed = _defaults["Speed"]
	LifeTime = _defaults["LifeTime"]
	Piercing = _defaults["Piercing"]
	PierceCount = _defaults["PierceCount"]
	BounceCount = _defaults["BounceCount"]
	velocity = Vector2.ZERO
	rotation = 0.0
	if _skin_node != null:
		_skin_node.queue_free()
		_skin_node = null
	for pair in _sprite_visibility:
		pair[0].visible = pair[1]
	var effect = get_node("BulletEffect")
	effect.scale = _effect_defaults["scale"]
	effect.self_modulate = _effect_defaults["self_modulate"]
	# a plain Sprite2D trail (worm spit, mantis shard) has no restart, it is just shown again
	if effect is GPUParticles2D:
		effect.restart()
	visible = true
	set_physics_process(true)


# every time the bullet enters the tree it is armed: its weapon has set LifeTime by then.
# POST_ENTER_TREE, not _enter_tree: a Timer cannot be started until its own node is in the tree
func _notification(what: int) -> void:
	if what == NOTIFICATION_POST_ENTER_TREE and _pool_key != "":
		var timer = get_node("LifeTimer")
		timer.wait_time = LifeTime
		timer.start()


func _ready():
	lifeTimer.connect("timeout", _on_life_timer_timeout)
	HitBox.connect("area_entered", _on_hit_box_area_entered)


func _physics_process(_delta):
	# bullets moved from outside (orbit blades) set their own rotation
	if Speed == 0:
		return

	rotation = PI / 2 + atan2(velocity.y, velocity.x)
	velocity = velocity.normalized() * Speed
	# no move_and_collide - hits are found by the HitBox areas, a physical stop on
	# a body bigger than its hit box (boss capsule) left bullets stuck on its hull
	global_position += velocity

func set_modulate_color(color : Color):
	bolid.self_modulate = color


# public - the weapon's skin: a slug sprite replaces the star sprite, the trail is tinted
func apply_skin(skin : Dictionary) -> void:
	if !skin.has("bullet"):
		return
	for pair in _sprite_visibility:
		pair[0].visible = false
	_skin_node = Sprite2D.new()
	_skin_node.texture = load(skin["bullet"])
	# the bullet flies along its local -Y, the slug art points right
	_skin_node.rotation = -PI / 2
	add_child(_skin_node)
	# the bullet may not be in the tree yet, so its @onready trail is not set
	get_node("BulletEffect").self_modulate = skin.get("trail", Color.WHITE)


func dispose():
	if _parked or is_queued_for_deletion():
		return

	_parked = true
	freeing.emit(self)
	if _pool_key == "":
		queue_free()
		return
	# parked after the physics step, the hit that asked for it may still be running
	call_deferred("_park")


func _park() -> void:
	if get_parent() != null:
		get_parent().remove_child(self)
	lifeTimer.stop()
	visible = false
	set_physics_process(false)
	var pool : Array = _pools[_pool_key]
	if pool.size() < POOL_LIMIT:
		pool.append(self)
	else:
		queue_free()


func _on_life_timer_timeout():
	dispose()

# turns the bullet to the nearest living enemy other than the one it just hit, false when there is none in range
func _bounce_to_next(hit: Area2D) -> bool:
	var game = get_tree().get_first_node_in_group("GameLogic")
	if game == null:
		return false
	var hit_enemy = hit.get_parent()
	var best = null
	var best_distance = BOUNCE_RANGE
	for enemy in game.active_enemies.values():
		if enemy == hit_enemy or enemy.isDead:
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	if best == null:
		return false
	velocity = (best.global_position - global_position).normalized() * velocity.length()
	return true

func is_damaging_player() -> bool:
	return collision_mask & Enums.MASKS.PLAYER == Enums.MASKS.PLAYER

func is_damaging_enemy() -> bool:
	return collision_mask & Enums.MASKS.ENEMY == Enums.MASKS.ENEMY

func _on_hit_box_area_entered(area: Area2D) -> void:
	# a parked bullet still has its hit box until the deferred park runs
	if _parked:
		return

	if area.is_in_group("Enemy"):
		if is_damaging_enemy() and !Piercing:
			# Slag Trails: the shot sets the enemy it hits on fire
			PlayerStatus.apply_burn(area.get_parent(), Type)
			if PierceCount > 0:
				PierceCount -= 1
			elif BounceCount > 0 and _bounce_to_next(area):
				BounceCount -= 1
			else:
				dispose()
		return

	if area.is_in_group("Player"):
		if is_damaging_player():
			dispose()
		return

	if area.is_in_group("Rock"):
		if !Piercing:
			dispose()
		return
