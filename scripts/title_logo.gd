extends Control
class_name TitleLogo

# "SPACE THUNDER" title: glowing logo, lightning bolts striking the letters,
# small electric arcs crawling over the text, screen flash, shake and rumble.

const FONT_PATH = "res://resources/kenney_space-shooter-redux/Bonus/kenvector_future.ttf"
const THUNDER_SOUND = preload("res://resources/explode_sounds/350976__cabled_mess__boom_c_01.wav")

const SPACE_COLOR = Color(0.6, 1.4, 2.2)
const THUNDER_COLOR = Color(1.15, 1.05, 0.5)
const THUNDER_OUTLINE = Color(0.15, 0.35, 1.0)
const BOLT_GLOW_COLOR = Color(0.5, 0.7, 3.0, 0.55)
const BOLT_CORE_COLOR = Color(3.0, 3.0, 4.0)
const ARC_COLOR = Color(1.0, 1.6, 4.0)
const FLASH_COLOR = Color(0.75, 0.85, 1.0, 0.45)

const STRIKE_INTERVAL = Vector2(1.6, 4.5)
const ARC_INTERVAL = Vector2(0.06, 0.25)
const BOLT_LIFE = 0.4
const ARC_LIFE = 0.09

var _font = null
var _title : Control
var _space_label : Label
var _thunder_label : Label
var _ghosts : Array = []
var _flash : ColorRect
var _sound : AudioStreamPlayer

var _time = 0.0
var _strike_timer = 1.0
var _arc_timer = 0.0
var _shake = 0.0
var _glitch = 0.0
var _boost = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load(FONT_PATH)

	_flash = ColorRect.new()
	_flash.color = FLASH_COLOR
	_flash.modulate.a = 0.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)

	_title = Control.new()
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_title)

	_space_label = _create_label(64, 22, SPACE_COLOR, THUNDER_OUTLINE, 8)
	_space_label.text = "SPACE"
	_space_label.offset_top = 70
	_space_label.offset_bottom = 150
	_title.add_child(_space_label)

	# red / cyan copies behind the main text give the glitch effect on every strike
	for color in [Color(2.0, 0.2, 0.4, 0.7), Color(0.2, 1.5, 2.0, 0.7)]:
		var ghost = _create_label(170, 6, color, Color(0, 0, 0, 0), 0)
		ghost.text = "THUNDER"
		_place_thunder(ghost)
		_title.add_child(ghost)
		_ghosts.append(ghost)

	_thunder_label = _create_label(170, 6, THUNDER_COLOR, THUNDER_OUTLINE, 22)
	_thunder_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.2, 0.8))
	_thunder_label.add_theme_constant_override("shadow_offset_x", 0)
	_thunder_label.add_theme_constant_override("shadow_offset_y", 10)
	_thunder_label.text = "THUNDER"
	_place_thunder(_thunder_label)
	_title.add_child(_thunder_label)

	_sound = AudioStreamPlayer.new()
	_sound.stream = THUNDER_SOUND
	_sound.volume_db = -8.0
	add_child(_sound)

func _create_label(font_size : int, spacing : int, color : Color, outline : Color, outline_size : int) -> Label:
	var font = FontVariation.new()
	font.base_font = _font
	font.spacing_glyph = spacing

	var label = Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline)
	label.add_theme_constant_override("outline_size", outline_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	return label

func _place_thunder(label : Label):
	label.offset_top = 140
	label.offset_bottom = 340

func _process(delta: float) -> void:
	_time += delta
	_shake = move_toward(_shake, 0.0, delta * 40.0)
	_glitch = move_toward(_glitch, 0.0, delta * 60.0)
	_boost = move_toward(_boost, 0.0, delta * 3.0)

	_title.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake

	# electric hum: slow pulse plus a random flicker now and then
	var pulse = 1.0 + 0.12 * sin(_time * 3.0) + _boost
	if randf() < 0.02:
		pulse *= 0.7
	_thunder_label.modulate = Color(pulse, pulse, pulse)
	_space_label.modulate.a = 0.85 + 0.15 * sin(_time * 1.7)

	_ghosts[0].position.x = -_glitch
	_ghosts[1].position.x = _glitch
	for ghost in _ghosts:
		ghost.visible = _glitch > 0.5

	_strike_timer -= delta
	if _strike_timer <= 0.0:
		_strike_timer = randf_range(STRIKE_INTERVAL.x, STRIKE_INTERVAL.y)
		strike()

	_arc_timer -= delta
	if _arc_timer <= 0.0:
		_arc_timer = randf_range(ARC_INTERVAL.x, ARC_INTERVAL.y)
		_spawn_arc()

# public - big lightning bolt from the sky hitting the title, power scales flash and shake
func strike(power : float = 1.0):
	var rect = _thunder_rect()
	var target = Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y + rect.size.y * 0.4)
	var from = Vector2(target.x + randf_range(-400, 400), -20)

	var bolt = Node2D.new()
	var points = _bolt_points(from, target, 120.0)
	_add_bolt_lines(bolt, points, 18.0, 4.0)
	# a few branches splitting off the main bolt
	for i in randi_range(1, 3):
		var start = points[randi_range(2, points.size() - 3)]
		var end = start + Vector2(randf_range(-260, 260), randf_range(80, 220))
		_add_bolt_lines(bolt, _bolt_points(start, end, 50.0), 8.0, 2.0)
	add_child(bolt)

	# lightning flickers a couple of times before fading out
	var tween = bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.2, BOLT_LIFE * 0.15)
	tween.tween_property(bolt, "modulate:a", 1.0, BOLT_LIFE * 0.1)
	tween.tween_property(bolt, "modulate:a", 0.0, BOLT_LIFE * 0.75)
	tween.tween_callback(bolt.queue_free)

	var flash = create_tween()
	_flash.modulate.a = power
	flash.tween_property(_flash, "modulate:a", 0.0, 0.35 * power)

	_shake = 14.0 * power
	_glitch = 18.0 * power
	_boost = 0.35 * power

	_sound.pitch_scale = randf_range(0.45, 0.7)
	_sound.play()

func _spawn_arc():
	var rect = _thunder_rect().grow(-20)
	var from = Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))
	var to = from + Vector2(randf_range(-90, 90), randf_range(-50, 50))

	var arc = Line2D.new()
	arc.points = _bolt_points(from, to, 18.0)
	arc.width = 2.0
	arc.default_color = ARC_COLOR
	_title.add_child(arc)
	get_tree().create_timer(ARC_LIFE).connect("timeout", arc.queue_free)

func _add_bolt_lines(parent : Node2D, points : PackedVector2Array, glow_width : float, core_width : float):
	var glow = Line2D.new()
	glow.points = points
	glow.width = glow_width
	glow.default_color = BOLT_GLOW_COLOR
	glow.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(glow)

	var core = Line2D.new()
	core.points = points
	core.width = core_width
	core.default_color = BOLT_CORE_COLOR
	parent.add_child(core)

# midpoint displacement: every pass splits each segment and pushes the middle sideways
func _bolt_points(from : Vector2, to : Vector2, displace : float) -> PackedVector2Array:
	var points = PackedVector2Array([from, to])
	while displace > 4.0:
		var result = PackedVector2Array()
		for i in points.size() - 1:
			var a = points[i]
			var b = points[i + 1]
			var normal = (b - a).orthogonal().normalized()
			result.append(a)
			result.append((a + b) / 2.0 + normal * randf_range(-displace, displace))
		result.append(points[-1])
		points = result
		displace /= 2.0
	return points

# area covered by the THUNDER letters, not the whole label which spans the screen width
func _thunder_rect() -> Rect2:
	var font = _thunder_label.get_theme_font("font")
	var font_size = _thunder_label.get_theme_font_size("font_size")
	var text_size = font.get_string_size(_thunder_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var center = _thunder_label.position + _thunder_label.size / 2.0
	return Rect2(center - text_size / 2.0, text_size).grow_individual(0, -30, 0, -30)
