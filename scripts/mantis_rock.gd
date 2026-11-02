extends Node2D

# One boulder of the Quarry Mantis rockfall. A warning ring marks the spot
# and closes in, then a stone plate of the mantis shell drops into it from
# above (big and faint -> its real size) and hurts the player inside the ring.
# Built in code, the boss adds it to the world: MantisRock.new() + setup().

const SHARDS = preload("res://resources/quarry_mantis/mantis_shards.png")
# atlas cells (4x4 of 128 px) that look like rock plates
const ROCK_CELLS = [2, 3, 4, 10, 15]
const WARN_COLOR = Color(0.35, 1.3, 1.6, 0.8)
const LOCK_COLOR = Color(1.8, 0.7, 0.4, 0.95)
const FALL_TIME = 0.28
const FADE_TIME = 0.6

var Radius = 70.0
var Damage = 40
var WarnTime = 1.0

var _rock : Sprite2D = null

signal landed
var _time = 0.0
var _landed = false

# public
func setup(radius : float, damage : int, warn_time : float):
	Radius = radius
	Damage = damage
	WarnTime = warn_time

func _ready() -> void:
	z_index = 1
	var texture = AtlasTexture.new()
	texture.atlas = SHARDS
	var cell = ROCK_CELLS.pick_random()
	texture.region = Rect2((cell % 4) * 128, (cell / 4) * 128, 128, 128)
	_rock = Sprite2D.new()
	_rock.texture = texture
	_rock.rotation = randf() * TAU
	_rock.visible = false
	add_child(_rock)

func _process(delta: float) -> void:
	_time += delta
	if !_landed and _time >= WarnTime - FALL_TIME and !_rock.visible:
		_drop()
	queue_redraw()

func _draw() -> void:
	if _landed:
		return
	var t = clamp(_time / WarnTime, 0.0, 1.0)
	var color = WARN_COLOR.lerp(LOCK_COLOR, t * t)
	# outer ring stays, the inner one closes in on it
	draw_arc(Vector2.ZERO, Radius, 0, TAU, 48, color, 3.0)
	draw_arc(Vector2.ZERO, Radius * t, 0, TAU, 40, Color(color, color.a * 0.6), 2.0)
	draw_circle(Vector2.ZERO, Radius, Color(color, 0.08 + 0.12 * t))

func _drop():
	var size = Radius * 2.2 / 128.0
	_rock.visible = true
	_rock.scale = Vector2.ONE * size * 2.4
	_rock.modulate = Color(1, 1, 1, 0.0)
	var tween = create_tween().set_parallel()
	tween.tween_property(_rock, "scale", Vector2.ONE * size, FALL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_rock, "modulate:a", 1.0, FALL_TIME * 0.6)
	tween.tween_property(_rock, "rotation", _rock.rotation + randf_range(-0.6, 0.6), FALL_TIME)
	tween.chain().tween_callback(_land)

func _land():
	_landed = true
	queue_redraw()
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.global_position.distance_to(global_position) < Radius:
		player.take_damage(Damage)
	Juice.explosion_effect(global_position, Vector2.ONE * Radius / 90.0, Color(0.6, 1.4, 1.7))
	Juice.shake(2.0)
	landed.emit()

	set_process(false)
	var tween = create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(_rock, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
