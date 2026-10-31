extends Node

# Game feel helpers: hit stop, camera shake and hit flash.

const HITSTOP_COOLDOWN_MS = 500
const FLASH_COLOR = Color(6, 6, 6, 1)
# particle count of explosion_effect.tscn, other amounts get their own emitter
const EXPLOSION_AMOUNT = 50
# pooled effects, when all are busy the oldest one is restarted
const EXPLOSION_POOL_SIZE = 24
const HIT_EFFECT_POOL_SIZE = 32
const SOUND_POOL_SIZE = 6
const SOUND_MIN_INTERVAL_MS = 40

var _hit_effect_scene = preload("res://scenes/hit_effect.tscn")
var _explosion_scene = preload("res://scenes/explosion_effect.tscn")

var _last_hitstop = -100000
var _hitstop_active = false
var _flashing : Dictionary = {}

# pools live in the current scene, they are rebuilt when the scene changes
var _pool_root : Node2D = null
var _explosions : Array = []
var _hit_effects : Array = []
var _sounds : Array = []
var _last_sound = -100000

# public - called at the start and the end of every run
func reset():
	Engine.time_scale = 1.0
	_hitstop_active = false
	_flashing.clear()

func _get_pool_root() -> Node2D:
	if is_instance_valid(_pool_root) and _pool_root.is_inside_tree():
		return _pool_root

	_explosions.clear()
	_hit_effects.clear()
	_sounds.clear()
	_pool_root = Node2D.new()
	_pool_root.name = "JuicePool"
	# effects are drawn above the ships, like when they were their children
	_pool_root.z_index = 1
	get_tree().current_scene.add_child(_pool_root)
	return _pool_root

# ring buffer - creates items up to size, then reuses the oldest one
func _from_pool(pool : Array, size : int, create : Callable) -> Node:
	var root = _get_pool_root()
	var item
	if pool.size() < size:
		item = create.call()
		root.add_child(item)
	else:
		item = pool.pop_front()
	pool.append(item)
	return item

# public - particle burst of a dying object
func explosion_effect(pos : Vector2, effect_scale : Vector2, color : Color, amount : int = EXPLOSION_AMOUNT):
	var effect
	if amount == EXPLOSION_AMOUNT:
		effect = _from_pool(_explosions, EXPLOSION_POOL_SIZE, func(): return _explosion_scene.instantiate())
	else:
		# big boss bursts are rare, changing amount on a pooled emitter reallocates it anyway
		effect = _explosion_scene.instantiate()
		effect.amount = amount
		effect.finished.connect(effect.queue_free)
		_get_pool_root().add_child(effect)

	effect.global_position = pos
	effect.scale = effect_scale
	effect.self_modulate = color
	effect.restart()

# public - death sounds go through a few shared players,
# a nuke would start a hundred copies of the same boom otherwise
func play_sound(source : AudioStreamPlayer2D):
	var now = Time.get_ticks_msec()
	if now - _last_sound < SOUND_MIN_INTERVAL_MS:
		return

	_last_sound = now
	var player = _from_pool(_sounds, SOUND_POOL_SIZE, func(): return AudioStreamPlayer2D.new())
	player.stream = source.stream
	player.volume_db = source.volume_db
	player.pitch_scale = source.pitch_scale
	player.bus = source.bus
	player.global_position = source.global_position
	player.play()

# public - freezes the game for a moment to make big hits feel heavy
func hitstop(duration : float = 0.05, time_scale : float = 0.05):
	var now = Time.get_ticks_msec()
	if _hitstop_active or now - _last_hitstop < HITSTOP_COOLDOWN_MS:
		return

	_last_hitstop = now
	_hitstop_active = true
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false

# public - hit particles come from a shared pool, creating one per hit
# (or per target) is too slow when a nuke hits the whole horde at once
func hit_effect(_target : Node, pos : Vector2):
	var effect = _from_pool(_hit_effects, HIT_EFFECT_POOL_SIZE, func(): return _hit_effect_scene.instantiate())
	effect.global_position = pos
	effect.restart()

# public
func shake(amount : float):
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.addShake(amount)

# public - white flash, the material is removed for a moment
# because the dissolve shader ignores modulate
func flash(item : CanvasItem, duration : float = 0.07):
	if !is_instance_valid(item):
		return

	var id = item.get_instance_id()
	if _flashing.has(id):
		return

	_flashing[id] = [item.material, item.modulate]
	item.material = null
	item.modulate = FLASH_COLOR
	get_tree().create_timer(duration, false).connect("timeout", _end_flash.bind(item, id))

# public - enemies check it before touching their shader material
func is_flashing(item : CanvasItem) -> bool:
	return _flashing.has(item.get_instance_id())

func _end_flash(item : CanvasItem, id : int):
	if !_flashing.has(id):
		return

	var saved = _flashing[id]
	_flashing.erase(id)
	if !is_instance_valid(item):
		return

	item.material = saved[0]
	item.modulate = saved[1]
