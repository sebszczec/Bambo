extends Node2D

# Player stats box (damage, critical hits, speed) styled like the rest of the HUD.

const FONT_SIZE = 18
const PADDING = 14

var _font = null
var _base_damage_value : Label
var _critical_chance_value : Label
var _critical_multiplier_value : Label
var _speed_value : Label

func _ready() -> void:
	_font = load(MenuTheme.FONT_PATH)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(PADDING, PADDING)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)

	_base_damage_value = _add_row(grid, "DAMAGE")
	_critical_chance_value = _add_row(grid, "CRIT CHANCE")
	_critical_multiplier_value = _add_row(grid, "CRIT DAMAGE")
	_speed_value = _add_row(grid, "SPEED")

	_set_value(_base_damage_value, PlayerStatus.BaseDamage, false)
	_set_value(_critical_chance_value, PlayerStatus.CriticalHitChance, false)
	_set_value(_critical_multiplier_value, PlayerStatus.CriticalHitMultiplier, false)
	_set_value(_speed_value, PlayerStatus.Speed, false)

	_style_panel(grid)

	PlayerStatus.connect("base_damage_changed", on_base_damage_changed)
	PlayerStatus.connect("critical_hit_chance_changed", on_cirtic_chance_up_changed)
	PlayerStatus.connect("critcal_hit_multipayer_changed", on_critic_hit_multiplier_changed)
	PlayerStatus.connect("speed_changed", on_speed_changed)

func _create_label(color : Color) -> Label:
	var label = Label.new()
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label

# adds "NAME   value" row and returns the value label
func _add_row(grid : GridContainer, title : String) -> Label:
	var name_label = _create_label(MenuTheme.TEXT_COLOR)
	name_label.text = title
	grid.add_child(name_label)

	var value_label = _create_label(MenuTheme.ACCENT_COLOR)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(value_label)
	return value_label

# dark blue box with neon border, resized to the content and kept at the right screen edge
func _style_panel(grid : GridContainer):
	var panel = get_parent() as Panel
	if panel == null:
		return

	var style = MenuTheme.box(MenuTheme.PANEL_COLOR, MenuTheme.BORDER_COLOR)
	panel.add_theme_stylebox_override("panel", style)

	var content = grid.get_combined_minimum_size()
	var right = panel.offset_right
	var center_y = (panel.offset_top + panel.offset_bottom) / 2.0
	var height = content.y + PADDING * 2
	panel.offset_left = right - (content.x + PADDING * 2)
	panel.offset_top = center_y - height / 2.0
	panel.offset_bottom = center_y + height / 2.0

func _set_value(label : Label, value, flash : bool = true):
	label.text = str(int(value)) + "%"
	if flash:
		label.modulate = Color(2.5, 2.5, 2.5)
		var tween = create_tween()
		tween.tween_property(label, "modulate", Color.WHITE, 0.4)

func on_base_damage_changed(value):
	_set_value(_base_damage_value, value)

func on_cirtic_chance_up_changed(value):
	_set_value(_critical_chance_value, value)

func on_critic_hit_multiplier_changed(value):
	_set_value(_critical_multiplier_value, value)

func on_speed_changed(value):
	_set_value(_speed_value, value)
