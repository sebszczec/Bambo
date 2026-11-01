extends Label

@export var ShowTime : float = 1.2
@export var FadeTime : float = 0.5
@export var DissolveTime : float = 0.7
@export var ShownAlpha : float = 0.55

const SHINE_TIME = 0.6
const DISSOLVE_SPREAD = 80.0

var _tween : Tween = null

var _band : TextureRect = null
var _line_top : TextureRect = null
var _line_bottom : TextureRect = null
var _dust : CPUParticles2D = null

func _ready() -> void:
	modulate.a = 0.0
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/banner_text.gdshader")
	material.set_shader_parameter("dissolve_spread", DISSOLVE_SPREAD)

	# horizontal strip fading out to both sides, reused by the dark band and the colored lines
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var strip = GradientTexture2D.new()
	strip.gradient = gradient
	strip.width = 256
	strip.height = 1

	_band = _make_strip(strip, 0.0, size.y)
	_line_top = _make_strip(strip, 6.0, 2.0)
	_line_bottom = _make_strip(strip, size.y - 8.0, 2.0)
	_dust = _make_dust()

func _make_strip(texture : Texture2D, top : float, height : float) -> TextureRect:
	var rect = TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.show_behind_parent = true
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2(0, top)
	rect.size = Vector2(size.x, height)
	rect.pivot_offset = rect.size / 2
	add_child(rect)
	return rect

# specks flying off the dissolve front, the emitter follows the front
func _make_dust() -> CPUParticles2D:
	var dust = CPUParticles2D.new()
	dust.emitting = false
	dust.amount = 120
	dust.lifetime = 0.8
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(DISSOLVE_SPREAD / 2, 34)
	dust.direction = Vector2(1, -0.5)
	dust.spread = 35.0
	dust.gravity = Vector2(0, -60)
	dust.initial_velocity_min = 40.0
	dust.initial_velocity_max = 150.0
	dust.damping_min = 20.0
	dust.damping_max = 40.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 4.5
	var ramp = Gradient.new()
	ramp.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	dust.color_ramp = ramp
	dust.position = Vector2(0, size.y / 2)
	add_child(dust)
	return dust

# public
func show_text(value : String, color : Color = Color.WHITE):
	text = value
	add_theme_color_override("font_color", color)
	_band.modulate = Color(0, 0, 0, 0.45)
	_line_top.modulate = Color(color, 0.8)
	_line_bottom.modulate = Color(color, 0.8)
	_dust.color = color
	_dust.emitting = false

	if _tween != null:
		_tween.kill()

	# shine and dissolve travel only over the letters, not the whole screen width
	var width = get_theme_font("font").get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x
	var left = (size.x - width) / 2
	var right = left + width
	_dust.position.x = left - DISSOLVE_SPREAD / 2
	material.set_shader_parameter("sweep_x", -10000.0)
	material.set_shader_parameter("dissolve_x", -10000.0)
	material.set_shader_parameter("edge_color", color.lightened(0.6))
	material.set_shader_parameter("flash", 0.6)

	pivot_offset = size / 2
	scale = Vector2(1.3, 1.3)
	_band.scale.x = 0.0
	_line_top.scale.x = 0.0
	_line_bottom.scale.x = 0.0

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, FadeTime * 0.5)
	_tween.tween_property(self, "scale", Vector2(1, 1), FadeTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(material, "shader_parameter/flash", 0.0, FadeTime)
	_tween.tween_property(_band, "scale:x", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for line in [_line_top, _line_bottom]:
		_tween.tween_property(line, "scale:x", 1.0, 0.5).set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(material, "shader_parameter/sweep_x", right + 150.0, SHINE_TIME).from(left - 150.0).set_delay(FadeTime * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# fade back while shown so the text does not cover the fight
	_tween.chain().tween_property(self, "modulate:a", ShownAlpha, ShowTime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# disintegrate from left to right, specks blow away from the crumbling edge,
	# everything is fully transparent when the dissolve ends
	_tween.chain().tween_callback(_dust.set_emitting.bind(true))
	_tween.tween_property(self, "modulate:a", 0.0, DissolveTime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(material, "shader_parameter/dissolve_x", right + DISSOLVE_SPREAD + 20.0, DissolveTime).from(left - 20.0)
	_tween.tween_property(_dust, "position:x", right + DISSOLVE_SPREAD / 2, DissolveTime).from(left - DISSOLVE_SPREAD / 2)
	for strip in [_band, _line_top, _line_bottom]:
		_tween.tween_property(strip, "modulate:a", 0.0, DissolveTime)
	_tween.chain().tween_callback(_dust.set_emitting.bind(false))
