extends Node2D

# Breaks a sprite into Grid x Grid fragments that fly apart and fade out.
# The fragments are drawn by this node (no child sprites) and the particle burst
# comes from the Juice pool - a nuke kills a hundred enemies in one frame.

# with many explosions at once the fragments get coarser, above the cap only particles are left
const BUSY_COUNT = 30
const BUSY_GRID = 2
const MAX_ALIVE = 80

static var alive_count = 0

@export var PathToSprite : String = "res://resources/kenney_particle_pack/window_04.png"
@export var SpriteTexture : Texture2D = null
# the sprite is cut into Grid x Grid fragments, smaller grid is cheaper
@export var Grid : int = 5

var _texture : Texture2D = null
var _cell_size = Vector2.ZERO
var _regions : Array[Rect2] = []
var _positions = PackedVector2Array()
var _velocity = PackedVector2Array()
var _angles = PackedFloat32Array()
var _rotation = PackedFloat32Array()
# all fragments fade at the same pace
var _transparency : float = 1.0
var _friction = 0.05
var _rad_fricton = 2
var _alpha_friciton = 1
var _speed = 5
var _effect_scale = Vector2(1.0, 1.0)
var _effect_amount = Juice.EXPLOSION_AMOUNT
var _particle_color = Color(1.75, 0, 0, 1)

var _initialized = false
var _counted = false

func _ready() -> void:
	# nothing to animate until explode() is called
	set_process(false)

func _exit_tree() -> void:
	_uncount()

# public - bosses ask for a bigger particle burst
func init(effect_scale : Vector2 = Vector2(1.0, 1.0), effect_amount : int = Juice.EXPLOSION_AMOUNT):
	if _initialized:
		return
	_initialized = true
	_effect_scale = effect_scale
	_effect_amount = effect_amount

	var grid = Grid
	if alive_count >= MAX_ALIVE:
		return
	if alive_count >= BUSY_COUNT:
		grid = min(Grid, BUSY_GRID)

	_texture = SpriteTexture if SpriteTexture != null else load(PathToSprite)
	var size = _texture.get_size()
	_cell_size = size / grid
	# fragment order and placement match a Sprite2D with hframes = vframes = grid
	for i in range(grid):
		for j in range(grid):
			_regions.append(Rect2(Vector2(j, i) * _cell_size, _cell_size))
			_positions.append(Vector2((j + 0.5) * _cell_size.x, (i + 0.5) * _cell_size.y) - size / 2)
			_velocity.append(Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 10.0 * _speed)
			_rotation.append(randf_range(-PI, PI))
			_angles.append(0.0)

func _process(delta: float) -> void:
	for i in range(_positions.size()):
		_velocity[i] = _velocity[i].move_toward(Vector2(0, 0), _friction)
		_positions[i] += _velocity[i] * delta
		_rotation[i] = move_toward(0, _rotation[i], _rad_fricton * delta)
		_angles[i] += _rotation[i]

	_transparency = move_toward(_transparency, 0, _alpha_friciton * delta)
	if _transparency <= 0:
		set_process(false)
		_uncount()
	queue_redraw()

func _draw() -> void:
	if _transparency <= 0:
		return

	var color = Color(1, 1, 1, _transparency)
	var rect = Rect2(-_cell_size / 2, _cell_size)
	for i in range(_positions.size()):
		draw_set_transform(_positions[i], _angles[i])
		draw_texture_rect_region(_texture, rect, _regions[i], color)
	draw_set_transform(Vector2.ZERO)

# public
func explode():
	init()
	Juice.explosion_effect(global_position, global_scale * _effect_scale, _particle_color, _effect_amount)
	if _positions.is_empty():
		return

	alive_count += 1
	_counted = true
	set_process(true)

func _uncount():
	if _counted:
		_counted = false
		alive_count -= 1

# public
func set_particle_color(color : Color) -> void:
	_particle_color = color
