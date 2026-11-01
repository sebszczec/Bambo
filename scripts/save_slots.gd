extends Control

# Save slot list shown after New game: pick an empty slot to start a new pilot,
# a used one to load it. Delete asks for a second press instead of a dialog.

const EMPTY_COLOR = Color(0.4, 0.45, 0.6)
const DELETE_COLOR = Color(1.0, 0.35, 0.3)
const FADE_TIME = 0.8
const CONFIRM_TIME = 3.0

@onready var warp = $Warp

var _ui : Control
var _slot_buttons : Array = []
var _delete_buttons : Array = []
var _back_button : Button
var _confirm_slot = -1
var _confirm_timer : Timer
var _leaving = false

func _ready() -> void:
	get_tree().paused = false
	MenuMusic.play_menu()
	theme = MenuTheme.create()

	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)

	var title = Label.new()
	title.text = "SAVE SLOTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -600
	title.offset_right = 600
	title.offset_top = 50
	MenuTheme.style_title(title, 72, 20)
	_ui.add_child(title)

	var column = VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -600
	column.offset_right = 600
	column.offset_top = -240
	column.offset_bottom = 300
	column.add_theme_constant_override("separation", 20)
	_ui.add_child(column)

	for slot in ConfigHandler.SAVE_SLOT_COUNT:
		column.add_child(_create_slot_row(slot))

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.connect("pressed", _on_back_pressed)
	_back_button.connect("focus_entered", _on_button_focus_changed)
	_back_button.connect("mouse_entered", _back_button.grab_focus)
	buttons.add_child(_back_button)

	_confirm_timer = Timer.new()
	_confirm_timer.one_shot = true
	_confirm_timer.connect("timeout", _cancel_delete)
	add_child(_confirm_timer)

	for slot in ConfigHandler.SAVE_SLOT_COUNT:
		_refresh_slot(slot)

	var last = ConfigHandler.get_last_slot()
	_slot_buttons[max(last, 0)].grab_focus()

	# the start menu leaves the warp dark, fade the stars and the menu back in
	var target = warp.Brightness
	warp.Brightness = 0.0
	_ui.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(warp, "Brightness", target, FADE_TIME)
	tween.tween_property(_ui, "modulate:a", 1.0, FADE_TIME * 0.6)

func _process(_delta: float) -> void:
	if !_leaving and Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()

func _create_slot_row(slot : int) -> Control:
	var panel = PanelContainer.new()
	var style = MenuTheme.box(MenuTheme.PANEL_COLOR, MenuTheme.BORDER_COLOR)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)

	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.connect("focus_entered", _on_button_focus_changed)
	button.connect("mouse_entered", button.grab_focus)
	button.connect("pressed", _on_slot_pressed.bind(slot))
	row.add_child(button)
	_slot_buttons.append(button)

	var delete = Button.new()
	delete.custom_minimum_size = Vector2(220, 0)
	delete.add_theme_color_override("font_focus_color", DELETE_COLOR)
	delete.add_theme_color_override("font_hover_color", DELETE_COLOR)
	delete.connect("focus_entered", _on_button_focus_changed)
	delete.connect("focus_exited", _cancel_delete)
	delete.connect("mouse_entered", delete.grab_focus)
	delete.connect("pressed", _on_delete_pressed.bind(slot))
	row.add_child(delete)
	_delete_buttons.append(delete)

	return panel

func _refresh_slot(slot : int):
	var button = _slot_buttons[slot]
	var delete = _delete_buttons[slot]
	delete.text = "Delete"

	if !ConfigHandler.slot_exists(slot):
		button.text = "SLOT %d   EMPTY" % (slot + 1)
		for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(state, EMPTY_COLOR)
		delete.disabled = true
		delete.focus_mode = Control.FOCUS_NONE
		return

	var summary = ConfigHandler.get_slot_summary(slot)
	var date = Time.get_datetime_string_from_unix_time(summary.get("updated", 0) + _utc_offset(), true)
	button.text = "SLOT %d   %d/%d cleared   Xenite %d\n%s" % [
		slot + 1, summary.get("cleared", 0), Levels.get_count(), summary.get("shards", 0), date.substr(0, 16)]
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.remove_theme_color_override(state)
	delete.disabled = false
	delete.focus_mode = Control.FOCUS_ALL

# save times are stored in UTC, show them in local time
func _utc_offset() -> int:
	return Time.get_time_zone_from_system().get("bias", 0) * 60

func _on_slot_pressed(slot : int):
	if _leaving:
		return

	if ConfigHandler.slot_exists(slot):
		if !ConfigHandler.load_slot(slot):
			return
	else:
		ConfigHandler.create_slot(slot)

	_leaving = true
	var tween = create_tween()
	tween.tween_property(_ui, "modulate:a", 0.0, FADE_TIME * 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/level_select.tscn"))

func _on_delete_pressed(slot : int):
	if _leaving or !ConfigHandler.slot_exists(slot):
		return

	if _confirm_slot != slot:
		_cancel_delete()
		_confirm_slot = slot
		_delete_buttons[slot].text = "Confirm?"
		_confirm_timer.start(CONFIRM_TIME)
		return

	_confirm_timer.stop()
	_confirm_slot = -1
	ConfigHandler.delete_slot(slot)
	# the delete button stops being focusable, keep the focus on the row
	_slot_buttons[slot].grab_focus()
	_refresh_slot(slot)

func _cancel_delete():
	if _confirm_slot >= 0:
		_delete_buttons[_confirm_slot].text = "Delete"
	_confirm_slot = -1

func _on_back_pressed():
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _on_button_focus_changed() -> void:
	$Sfx.play()
