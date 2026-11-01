extends Node2D

# Boulder Beetle self destruct - a shock wave racing out to the blast radius,
# drawn with _draw (one ring and a flash disc), additive so the bloom makes it glow.
# Lives on the beetle, which stays alive until the wave has faded.

# hdr colors, cyan core of the hive glow with an amber edge
const RING_COLOR = Color(1.6, 1.1, 0.7)
const CORE_COLOR = Color(0.8, 2.4, 2.8)
const POINTS = 64

var _radius = 190.0
var _time = 0.0
var _duration = 0.45

func _ready() -> void:
	visible = false
	set_process(false)
	var additive = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive

# public
func fire(radius : float, duration : float):
	_radius = radius
	_duration = duration
	_time = 0.0
	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	if _time >= _duration:
		visible = false
		set_process(false)
		return
	queue_redraw()

func _draw() -> void:
	var t = clampf(_time / _duration, 0.0, 1.0)
	# fast start, slows down at the edge
	var grow = 1.0 - pow(1.0 - t, 3.0)
	var r = lerpf(0.2, 1.0, grow) * _radius
	var fade = 1.0 - t

	# the flash at the center is gone in the first third
	var core = clampf(1.0 - t * 3.0, 0.0, 1.0)
	if core > 0.0:
		draw_circle(Vector2.ZERO, r * 0.7, Color(CORE_COLOR, 0.18 * core))

	draw_circle(Vector2.ZERO, r, Color(CORE_COLOR, 0.06 * fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, POINTS, Color(RING_COLOR, fade), lerpf(14.0, 3.0, t))
	draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, POINTS, Color(CORE_COLOR, 0.5 * fade), lerpf(6.0, 1.5, t))
