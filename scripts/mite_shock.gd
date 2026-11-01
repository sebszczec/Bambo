extends Node2D

# Pebble Mite discharge - a ring of flickering lightning around the mite,
# built from the Kenney spark sprites. Sprites are made on the first discharge
# so a swarm of mites that never got close costs nothing.

const BOLTS = [
	preload("res://resources/kenney_particle_pack/spark_05.png"),
	preload("res://resources/kenney_particle_pack/spark_06.png"),
]
const BURSTS = [
	preload("res://resources/kenney_particle_pack/spark_01.png"),
	preload("res://resources/kenney_particle_pack/spark_02.png"),
	preload("res://resources/kenney_particle_pack/spark_04.png"),
]
const RING_BOLTS = 14
const SPOKES = 5
const BURST_COUNT = 6
const TEXTURE_SIZE = 512.0
const FLICKER_TIME = 0.045
# hdr color, the bloom makes it glow
const COLOR = Color(0.7, 2.2, 2.6)

static var _additive : CanvasItemMaterial = null

var _ring : Array[Sprite2D] = []
var _spokes : Array[Sprite2D] = []
var _bursts : Array[Sprite2D] = []
var _radius = 70.0
var _time = 0.0
var _duration = 0.35
var _flicker = 0.0

func _ready() -> void:
	visible = false
	set_process(false)

# public
func fire(radius : float, duration : float):
	if _ring.is_empty():
		_build()
	_radius = radius
	_duration = duration
	_time = 0.0
	_flicker = 0.0
	_reshape()
	modulate.a = 1.0
	visible = true
	set_process(true)

# public
func stop():
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	_time += delta
	if _time >= _duration:
		stop()
		return

	_flicker -= delta
	if _flicker <= 0.0:
		_flicker = FLICKER_TIME
		_reshape()

	# full strength for the first half, then fade out
	modulate.a = clampf(2.0 - 2.0 * _time / _duration, 0.0, 1.0)

func _build():
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in range(RING_BOLTS):
		_ring.append(_add_sprite())
	for i in range(SPOKES):
		_spokes.append(_add_sprite())
	for i in range(BURST_COUNT):
		_bursts.append(_add_sprite())

func _add_sprite() -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.material = _additive
	sprite.modulate = COLOR
	add_child(sprite)
	return sprite

# new random bolts every few frames, that is what makes it crackle
func _reshape():
	var offset = randf() * TAU
	# the bolt textures are vertical, rotating by the angle lays them along the circle
	var arc = TAU * _radius / RING_BOLTS
	for i in range(RING_BOLTS):
		var sprite = _ring[i]
		var angle = offset + i * TAU / RING_BOLTS + randf_range(-0.1, 0.1)
		var r = _radius * randf_range(0.92, 1.08)
		sprite.texture = BOLTS.pick_random()
		sprite.position = Vector2(r, 0).rotated(angle)
		sprite.rotation = angle
		sprite.flip_h = randf() < 0.5
		sprite.scale = Vector2(randf_range(0.08, 0.13), arc * 1.3 / TEXTURE_SIZE)

	# spokes from the cracks of the shell out to the ring
	for i in range(SPOKES):
		var sprite = _spokes[i]
		var angle = offset + (i + randf()) * TAU / SPOKES
		sprite.texture = BOLTS.pick_random()
		sprite.position = Vector2(_radius * 0.55, 0).rotated(angle)
		sprite.rotation = angle + PI / 2
		sprite.flip_h = randf() < 0.5
		sprite.scale = Vector2(0.07, _radius * 0.8 / TEXTURE_SIZE)

	for sprite in _bursts:
		sprite.texture = BURSTS.pick_random()
		sprite.position = Vector2(_radius * randf_range(0.85, 1.05), 0).rotated(randf() * TAU)
		sprite.rotation = randf() * TAU
		var s = randf_range(0.1, 0.16)
		sprite.scale = Vector2(s, s)
