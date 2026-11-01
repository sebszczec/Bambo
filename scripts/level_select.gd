extends Control

# Level ladder: one button per level on the left, briefing of the focused level
# on the right. Levels without gameplay data are shown as under development.

const LOCKED_COLOR = Color(0.4, 0.45, 0.6)
const CLEARED_COLOR = Color(0.4, 1.0, 0.5)
const LAUNCH_TIME = 0.8

@onready var warp = $Warp

var _level_buttons : Array = []
var _selected = 0
var _launching = false
var _ui : Control
var _launch_button : Button
var _back_button : Button
var _name_label : Label
var _tagline_label : Label
var _story_label : Label
var _objective_label : Label
var _status_label : Label

func _ready() -> void:
	get_tree().paused = false
	theme = MenuTheme.create()

	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)

	var title = Label.new()
	title.text = "MISSIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -600
	title.offset_right = 600
	title.offset_top = 50
	MenuTheme.style_title(title, 72, 20)
	_ui.add_child(title)

	var columns = HBoxContainer.new()
	columns.set_anchors_preset(Control.PRESET_CENTER)
	columns.offset_left = -820
	columns.offset_right = 820
	columns.offset_top = -340
	columns.offset_bottom = 420
	columns.add_theme_constant_override("separation", 40)
	_ui.add_child(columns)

	columns.add_child(_create_ladder())
	columns.add_child(_create_briefing())

	_level_buttons[Levels.current].grab_focus()
	_show_level(Levels.current)

	# the start menu leaves the warp dark, fade the stars and the menu back in
	var target = warp.Brightness
	warp.Brightness = 0.0
	_ui.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(warp, "Brightness", target, LAUNCH_TIME)
	tween.tween_property(_ui, "modulate:a", 1.0, LAUNCH_TIME * 0.6)

func _process(_delta: float) -> void:
	if !_launching and Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()

func _create_ladder() -> Control:
	var ladder = VBoxContainer.new()
	ladder.custom_minimum_size = Vector2(620, 0)
	ladder.add_theme_constant_override("separation", 10)

	for i in Levels.get_count():
		var button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _button_text(i)
		button.custom_minimum_size = Vector2(0, 58)
		# locked levels stay focusable so their briefing can be read
		if !Levels.is_available(i):
			for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
				button.add_theme_color_override(state, LOCKED_COLOR)
		elif Levels.is_completed(i):
			button.add_theme_color_override("font_color", CLEARED_COLOR)
		button.connect("focus_entered", _on_level_focused.bind(i))
		button.connect("mouse_entered", button.grab_focus)
		button.connect("pressed", _on_level_pressed.bind(i))
		ladder.add_child(button)
		_level_buttons.append(button)

	return ladder

func _button_text(index : int) -> String:
	var number = "%02d   " % (index + 1)
	if !Levels.is_available(index):
		return number + "UNDER DEVELOPMENT"
	var text = number + Levels.get_level(index)["name"].to_upper()
	if Levels.is_completed(index):
		text += "   CLEARED"
	return text

func _create_briefing() -> Control:
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 20)

	var panel = PanelContainer.new()
	var style = MenuTheme.box(MenuTheme.PANEL_COLOR, MenuTheme.BORDER_COLOR)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel)

	var text = VBoxContainer.new()
	text.add_theme_constant_override("separation", 14)
	panel.add_child(text)

	_name_label = _create_label(40, MenuTheme.ACCENT_COLOR)
	_tagline_label = _create_label(22, MenuTheme.TITLE_COLOR)
	_story_label = _create_label(20, MenuTheme.TEXT_COLOR)
	_objective_label = _create_label(20, Color.WHITE)
	_status_label = _create_label(20, CLEARED_COLOR)
	for label in [_name_label, _tagline_label, _story_label, _objective_label, _status_label]:
		text.add_child(label)

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
	for button in [_back_button, _launch_button]:
		button.connect("focus_entered", _on_button_focus_changed)
		button.connect("mouse_entered", button.grab_focus)
		buttons.add_child(button)

	return column

func _create_label(font_size : int, color : Color) -> Label:
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _show_level(index : int):
	var level = Levels.get_level(index)
	_name_label.text = "LEVEL %d - %s" % [index + 1, level["name"].to_upper()]

	if !Levels.is_available(index):
		_tagline_label.text = "Sector under development"
		_story_label.text = "Intel unavailable. Command is still charting this sector - check back after the next update."
		_objective_label.text = ""
		_status_label.text = ""
		_launch_button.disabled = true
		return

	_tagline_label.text = level.get("tagline", "")
	_story_label.text = "\n\n".join(level.get("story", []))
	_objective_label.text = "Objective: " + level.get("objective", "")
	_status_label.text = "Status: CLEARED" if Levels.is_completed(index) else ""
	_launch_button.disabled = false

func _on_level_focused(index : int):
	_selected = index
	_show_level(index)
	_on_button_focus_changed()

func _on_level_pressed(index : int):
	if Levels.is_available(index):
		_on_launch_pressed()

func _on_launch_pressed():
	if _launching or !Levels.is_available(_selected):
		return

	_launching = true
	Levels.select(_selected)
	var tween = create_tween()
	tween.tween_property(_ui, "modulate:a", 0.0, LAUNCH_TIME)
	tween.tween_property(warp, "Brightness", 0.0, LAUNCH_TIME)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/count_down.tscn"))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _on_button_focus_changed() -> void:
	$Sfx.play()
