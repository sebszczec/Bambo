extends Control

# Hangar: spends the Xenite banked on the selected level on permanent upgrades.
# Every level has its own bank and upgrades.

const SHARD_COLOR = Color(0.85, 0.55, 1.0)
const PIP_SIZE = Vector2(22, 22)
const ICON_SIZE = Vector2(48, 48)
const PIP_EMPTY_COLOR = Color(0.22, 0.27, 0.5)
const FADE_TIME = 0.6

@onready var warp = $Warp

var _level = 0
var _leaving = false
var _ui : Control
var _shards_label : Label
var _record_label : Label
var _rows : Array = []
var _back_button : Button
var _launch_button : Button
var _buy_sound = AudioStreamPlayer.new()

func _ready() -> void:
	get_tree().paused = false
	MenuMusic.play_menu()
	theme = MenuTheme.create()
	_level = Levels.current
	_buy_sound.stream = load("res://resources/vendor/kenney/space_shooter_redux/Bonus/sfx_shieldUp.ogg")
	add_child(_buy_sound)

	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)

	var title = Label.new()
	title.text = "HANGAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -600
	title.offset_right = 600
	title.offset_top = 40
	MenuTheme.style_title(title, 72, 20)
	_ui.add_child(title)

	var column = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -760
	column.offset_right = 760
	column.offset_top = -370
	column.offset_bottom = 470
	column.add_theme_constant_override("separation", 16)
	_ui.add_child(column)

	var header = HBoxContainer.new()
	var level_label = _create_label(30, MenuTheme.ACCENT_COLOR)
	level_label.text = Levels.get_title(_level)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shards_label = _create_label(30, SHARD_COLOR)
	header.add_child(level_label)
	header.add_child(_shards_label)
	column.add_child(header)

	_record_label = _create_label(20, MenuTheme.TEXT_COLOR)
	column.add_child(_record_label)

	var panel = PanelContainer.new()
	var style = MenuTheme.box(MenuTheme.PANEL_COLOR, MenuTheme.BORDER_COLOR)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(grid)

	for upgrade in MetaProgress.UPGRADES:
		_rows.append(_create_row(grid, upgrade))

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 20)
	column.add_child(buttons)

	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.connect("pressed", _on_back_pressed)
	_launch_button = Button.new()
	_launch_button.text = "Launch"
	_launch_button.add_theme_font_size_override("font_size", 32)
	_launch_button.connect("pressed", _on_launch_pressed)
	if Levels.hangar_after_death:
		_back_button.text = "Main menu"
		_launch_button.text = "Retry"
	for button in [_back_button, _launch_button]:
		_connect_focus(button)
		buttons.add_child(button)

	_refresh()
	_rows[0]["button"].grab_focus()

	var target = warp.Brightness
	warp.Brightness = 0.0
	_ui.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(warp, "Brightness", target, FADE_TIME)
	tween.tween_property(_ui, "modulate:a", 1.0, FADE_TIME)

func _process(_delta: float) -> void:
	if !_leaving and Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()

func _create_row(grid : GridContainer, upgrade : Dictionary) -> Dictionary:
	var icon = TextureRect.new()
	icon.texture = load(upgrade["icon"])
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var name_label = _create_label(24, Color.WHITE)
	name_label.text = upgrade["name"]
	var desc_label = _create_label(20, MenuTheme.TEXT_COLOR)
	desc_label.text = upgrade["desc"]
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var pips = HBoxContainer.new()
	pips.add_theme_constant_override("separation", 6)
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(upgrade["max_rank"]):
		var pip = ColorRect.new()
		pip.custom_minimum_size = PIP_SIZE
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pips.add_child(pip)

	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 0)
	button.connect("pressed", _on_buy_pressed.bind(upgrade["id"]))
	_connect_focus(button)

	for control in [icon, name_label, desc_label, pips, button]:
		grid.add_child(control)

	return { "id" : upgrade["id"], "pips" : pips, "button" : button }

func _connect_focus(button : Button):
	button.connect("focus_entered", _on_button_focus_changed)
	button.connect("mouse_entered", button.grab_focus)

func _create_label(font_size : int, color : Color) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _refresh():
	_shards_label.text = "XENITE  %d" % MetaProgress.get_shards(_level)
	_record_label.text = "Runs: %d   Deaths: %d   -   every run banks the Xenite it collected, won or lost" % [MetaProgress.get_runs(_level), MetaProgress.get_deaths(_level)]

	for row in _rows:
		var rank = MetaProgress.get_rank(_level, row["id"])
		var pips = row["pips"].get_children()
		for i in pips.size():
			pips[i].color = SHARD_COLOR if i < rank else PIP_EMPTY_COLOR

		# disabled buttons lose focus, keep them focusable to walk the list with a gamepad
		var button : Button = row["button"]
		var cost = MetaProgress.get_cost(_level, row["id"])
		if cost < 0:
			button.text = "MAX"
			button.modulate = Color(0.6, 1.0, 0.6)
		else:
			button.text = "%d" % cost
			button.modulate = Color.WHITE if MetaProgress.can_buy(_level, row["id"]) else Color(1, 1, 1, 0.4)

func _on_buy_pressed(id : String):
	if MetaProgress.buy(_level, id):
		_buy_sound.play()
		_refresh()

func _on_launch_pressed():
	_leave("res://scenes/effects/count_down.tscn")

func _on_back_pressed():
	_leave("res://scenes/menus/start_menu.tscn" if Levels.hangar_after_death else "res://scenes/menus/level_select.tscn")

func _leave(scene : String):
	if _leaving:
		return
	_leaving = true
	Levels.hangar_after_death = false
	var tween = create_tween()
	tween.tween_property(_ui, "modulate:a", 0.0, FADE_TIME * 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene))

func _on_button_focus_changed() -> void:
	$Sfx.play()
