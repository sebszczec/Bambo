extends Node

# Game feel helpers: hit stop, camera shake and hit flash.

const HITSTOP_COOLDOWN_MS = 150
const FLASH_COLOR = Color(6, 6, 6, 1)

var _last_hitstop = -100000
var _hitstop_active = false
var _flashing : Dictionary = {}

# public - called at the start and the end of every run
func reset():
	Engine.time_scale = 1.0
	_hitstop_active = false
	_flashing.clear()

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
