extends CanvasLayer

# Run HUD: experience bar, level, survival timer, kills, combo and owned weapons.

const XP_BAR_HEIGHT = 18

var _xp_bar : ProgressBar
var _level_label : Label
var _time_label : Label
var _kills_label : Label
var _combo_label : Label
var _weapons_box : HBoxContainer
var _font = null
var _combo_tween : Tween = null

func _ready() -> void:
	_font = load("res://resources/kenney_space-shooter-redux/Bonus/kenvector_future.ttf")

	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = XP_BAR_HEIGHT
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.12, 0.85)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.6, 1.0)
	_xp_bar.add_theme_stylebox_override("background", bg)
	_xp_bar.add_theme_stylebox_override("fill", fill)
	add_child(_xp_bar)

	_level_label = _create_label(26, Color.WHITE)
	_level_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_level_label.offset_left = -200
	_level_label.offset_right = -16
	_level_label.offset_top = XP_BAR_HEIGHT + 4
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_level_label)

	_kills_label = _create_label(22, Color(1, 0.6, 0.6))
	_kills_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_kills_label.offset_left = -300
	_kills_label.offset_right = -16
	_kills_label.offset_top = XP_BAR_HEIGHT + 40
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_kills_label)

	_combo_label = _create_label(44, Color.ORANGE)
	_combo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_combo_label.offset_left = -420
	_combo_label.offset_right = -16
	_combo_label.offset_top = XP_BAR_HEIGHT + 72
	_combo_label.offset_bottom = XP_BAR_HEIGHT + 140
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.pivot_offset = Vector2(404, 34)
	add_child(_combo_label)

	_time_label = _create_label(40, Color.WHITE)
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.offset_left = -150
	_time_label.offset_right = 150
	_time_label.offset_top = 100
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_time_label)

	_weapons_box = HBoxContainer.new()
	_weapons_box.offset_left = 16
	_weapons_box.offset_top = XP_BAR_HEIGHT + 8
	_weapons_box.add_theme_constant_override("separation", 10)
	add_child(_weapons_box)

	set_level(1)
	set_kills(0)
	set_combo(0, 1)
	set_time("00:00")

func _create_label(font_size : int, color : Color) -> Label:
	var label = Label.new()
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	return label

# public
func set_xp(value : int, max_value : int):
	_xp_bar.max_value = max_value
	_xp_bar.value = value

# public
func set_level(level : int):
	_level_label.text = "LV " + str(level)
	_level_label.pivot_offset = Vector2(184, 18)
	var tween = create_tween()
	tween.tween_property(_level_label, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(_level_label, "scale", Vector2.ONE, 0.2)

# public
func set_time(text : String):
	_time_label.text = text

# public - the last minute before the boss is shown in red
func set_time_color(color : Color):
	_time_label.add_theme_color_override("font_color", color)

# public
func set_kills(value : int):
	_kills_label.text = "KILLS " + str(value)

# public
func set_combo(count : int, multiplier : int):
	if count < 2:
		_combo_label.text = ""
		return

	_combo_label.text = str(count) + " COMBO"
	if multiplier > 1:
		_combo_label.text += "  x" + str(multiplier)

	var colors = [Color.WHITE, Color.ORANGE, Color.ORANGE_RED, Color.DEEP_PINK, Color.MAGENTA]
	_combo_label.add_theme_color_override("font_color", colors[clamp(multiplier - 1, 0, colors.size() - 1)])

	if _combo_tween != null:
		_combo_tween.kill()
	_combo_label.scale = Vector2(1.25, 1.25)
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.15)

# public - fades the combo out when it is about to break
func set_combo_alpha(value : float):
	_combo_label.modulate.a = value

# public - list of [icon, level]
func set_weapons(weapons : Array):
	for child in _weapons_box.get_children():
		child.queue_free()

	for weapon in weapons:
		var slot = VBoxContainer.new()
		slot.add_theme_constant_override("separation", 0)
		var icon = TextureRect.new()
		icon.texture = weapon[0]
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon)
		var level = _create_label(16, Color.GOLD)
		level.text = str(weapon[1])
		level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(level)
		_weapons_box.add_child(slot)
