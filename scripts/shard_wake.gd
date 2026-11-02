extends Node2D

# Shard Wasp lunge wake - the wasp sheds splinters of its flint wings along the path of its
# lunge, they hang in space as a crackling wall for a few seconds and cut the player who
# flies through. Lives in the world, so the wall stays when the wasp is shot down.
# Built while the wasp flies (extend_to), armed after the lunge (seal), then shatters.

const ATLAS = preload("res://resources/levels/level2/enemies/shard_wasp/wasp_shards.png")
# atlas cells of wing slivers and the stinger tip (4x4 grid of 128 px, cut_shards.py)
const SHARD_CELLS = [0, 2, 5, 6, 7]
const CELL = 128
const SHARD_SPACING = 24.0
const SHARD_SCALE = 0.3
const FLICKER_TIME = 0.045
const FADE_TIME = 0.45
# hdr colors, the bloom makes them glow
const SEAM_COLOR = Color(0.6, 2.0, 2.4)
const SHARD_COLOR = Color(1.2, 1.5, 1.6)

static var _additive : CanvasItemMaterial = null

# public
@export var Duration = 2.6
# public
@export var Radius = 18.0
# public
@export var Damage = 5
# public
@export var TickTime = 0.4

@onready var seam = $Seam
@onready var audio = $AudioStreamPlayer2D

var _start = Vector2.ZERO
var _end = Vector2.ZERO
var _shards : Array[Sprite2D] = []
var _side = 1.0
var _sealed = false
var _time = 0.0
var _tick = 0.0
var _inside = true
var _flicker = 0.0
var _fading = false
var _player = null

func _ready() -> void:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	seam.material = _additive
	seam.default_color = SEAM_COLOR
	_player = get_tree().get_first_node_in_group("player")

# public - the wasp starts the lunge here
func begin(start : Vector2):
	global_position = start
	_start = Vector2.ZERO
	_end = Vector2.ZERO
	seam.points = PackedVector2Array([_start, _end])

# public - the wasp moved on, the wall grows behind it
func extend_to(point : Vector2):
	_end = to_local(point)
	seam.set_point_position(1, _end)
	var length = _end.length()
	while (_shards.size() + 0.5) * SHARD_SPACING < length:
		_add_shard()

# public - the lunge is over, the wall cuts from now on
func seal():
	_sealed = true
	_time = 0.0

func _add_shard():
	var direction = _end.normalized()
	var shard = Sprite2D.new()
	var cell = SHARD_CELLS.pick_random()
	shard.texture = ATLAS
	shard.region_enabled = true
	shard.region_rect = Rect2((cell % 4) * CELL, (cell / 4) * CELL, CELL, CELL)
	# splinters lie along the path, alternating sides, a bit ragged
	shard.position = direction * (_shards.size() + 0.5) * SHARD_SPACING \
		+ direction.orthogonal() * _side * randf_range(3.0, 9.0)
	shard.rotation = direction.angle() + randf_range(-0.6, 0.6) + (PI if randf() < 0.5 else 0.0)
	shard.modulate = SHARD_COLOR
	_side = -_side
	add_child(shard)
	_shards.append(shard)
	# pops out of the wasp's wake
	shard.scale = Vector2.ONE * SHARD_SCALE * 0.3
	var tween = create_tween()
	tween.tween_property(shard, "scale", Vector2.ONE * SHARD_SCALE * randf_range(0.85, 1.15), 0.12)

func _physics_process(delta: float) -> void:
	_flicker -= delta
	if _flicker <= 0.0:
		# a crackling seam, re-randomized like the mite's lightning
		_flicker = FLICKER_TIME
		seam.width = randf_range(2.0, 5.0)
		seam.modulate.a = randf_range(0.55, 1.0)

	if !_sealed:
		return

	_time += delta
	if !_fading and _time >= Duration - FADE_TIME:
		_shatter()
	if _time >= Duration:
		dispose()
		return

	_tick -= delta
	if _fading or _player == null or !is_instance_valid(_player):
		return
	var point = to_local(_player.global_position)
	var closest = Geometry2D.get_closest_point_to_segment(point, _start, _end)
	var inside = point.distance_to(closest) <= Radius
	# cuts on the way in only - the player the lunge just hit sits on the wall, it should
	# fly out, not bleed while it hangs there
	if inside and !_inside and _tick <= 0.0 and _player.has_method("take_damage"):
		_player.take_damage(Damage)
		_tick = TickTime
	_inside = inside

func _shatter():
	_fading = true
	Juice.play_sound(audio)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(seam, "self_modulate:a", 0.0, FADE_TIME * 0.6)
	for shard in _shards:
		# the splinters break off and drift apart
		var drift = Vector2.from_angle(randf() * TAU) * randf_range(10.0, 26.0)
		tween.tween_property(shard, "position", shard.position + drift, FADE_TIME)
		tween.tween_property(shard, "rotation", shard.rotation + randf_range(-1.5, 1.5), FADE_TIME)
		tween.tween_property(shard, "modulate:a", 0.0, FADE_TIME)

func dispose():
	if !is_queued_for_deletion():
		queue_free()
