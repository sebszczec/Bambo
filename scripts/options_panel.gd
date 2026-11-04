extends Control

# Options shared by the start menu settings and the pause menu.
# Builds its tabs in code, every change is saved and applied at once.
# The owner handles ui_cancel and reacts to `closed` (Back), and can add its own tabs with add_page.

signal closed

const CLICK_SOUND = preload("res://resources/shared/audio/sfx/Menu Selection Click.wav")
const FPS_LIMITS = [0, 30, 60, 120, 144, 240]
const VISUAL_OPTIONS = [
	["show_fps", "Show FPS"],
	["show_bullets_count", "Show bullets count"],
	["show_enemies_count", "Show enemies count"],
	["show_player_lifebar", "Show player lifebar"],
	["show_enemies_lifebar", "Show enemies lifebar"],
	["show_damage_taken", "Show damage taken"],
	["show_damage_given", "Show damage given"],
]
const CONTROLS_HELP = """KEYBOARD + MOUSE
Move - WASD / arrows      Aim - mouse
Shoot - LMB / Space      Afterburner - RMB / Shift
Zoom - Z / MMB      Pause - Esc / P

GAMEPAD
Move - left stick / D-pad      Aim - right stick
Shoot - RT      Afterburner - LT
Zoom - Y      Pause - Start

Auto switches to the device you used last."""

var _window_modes : Array
var _input_modes : Array

var _tabs : TabContainer
var _sfx : AudioStreamPlayer
var _shoulder_left = false
var _shoulder_right = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = MenuTheme.create()

	_window_modes = [
		[ConfigHandler.WINDOW_MODE_WINDOWED, "Windowed"],
		[ConfigHandler.WINDOW_MODE_FULLSCREEN, "Fullscreen"],
		[ConfigHandler.WINDOW_MODE_BORDERLESS, "Borderless"],
	]
	_input_modes = [
		[ConfigHandler.INPUT_MODE_AUTO, "Auto"],
		[ConfigHandler.INPUT_MODE_GAMEPAD, "Gamepad"],
		[ConfigHandler.INPUT_MODE_KEYBOARD_MOUSE, "Keyboard + mouse"],
	]

	_sfx = AudioStreamPlayer.new()
	_sfx.stream = CLICK_SOUND
	_sfx.volume_db = 10.0
	add_child(_sfx)

	_tabs = TabContainer.new()
	_tabs.anchor_left = 0.5
	_tabs.anchor_top = 0.5
	_tabs.anchor_right = 0.5
	_tabs.anchor_bottom = 0.5
	_tabs.offset_left = -480.0
	_tabs.offset_top = -320.0
	_tabs.offset_right = 480.0
	_tabs.offset_bottom = 310.0
	_tabs.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tabs.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_tabs)

	_add_visuals_page()
	_add_graphics_page()
	_add_audio_page()
	_add_controls_page()
	_tabs.tab_changed.connect(_on_tab_changed)

	var back = Button.new()
	back.text = "Back"
	back.anchor_left = 0.5
	back.anchor_top = 1.0
	back.anchor_right = 0.5
	back.anchor_bottom = 1.0
	back.offset_left = -140.0
	back.offset_top = -200.0
	back.offset_right = 140.0
	back.offset_bottom = -140.0
	back.grow_horizontal = Control.GROW_DIRECTION_BOTH
	back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(back)
	back.pressed.connect(func(): closed.emit())
	_track(back)

	# the input root does not block the screen behind the panel
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# public - a tab the owner made, placed after the built in ones
func add_page(page : Control) -> void:
	if page.get_parent() != null:
		page.get_parent().remove_child(page)
	_tabs.add_child(page)


# public - moves the focus into the visible tab
func focus_current() -> void:
	_focus_page(_tabs.current_tab)


func _process(_delta: float) -> void:
	# gamepad shoulder buttons switch tabs
	if Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER) != _shoulder_left:
		_shoulder_left = !_shoulder_left
		if _shoulder_left:
			_tabs.current_tab = posmod(_tabs.current_tab - 1, _tabs.get_tab_count())
	if Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) != _shoulder_right:
		_shoulder_right = !_shoulder_right
		if _shoulder_right:
			_tabs.current_tab = posmod(_tabs.current_tab + 1, _tabs.get_tab_count())


func _on_tab_changed(tab : int) -> void:
	_focus_page(tab)


# keeps keyboard / gamepad focus inside the visible tab
func _focus_page(tab : int) -> void:
	var first = _first_focusable(_tabs.get_tab_control(tab))
	if first != null:
		first.grab_focus()


func _first_focusable(node : Node) -> Control:
	for child in node.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			return child
		var found = _first_focusable(child)
		if found != null:
			return found
	return null


# every control: click sound on focus, follows the mouse like the other menus
func _track(control : Control) -> void:
	control.focus_entered.connect(_on_focus_entered)
	control.mouse_entered.connect(control.grab_focus)


func _on_focus_entered() -> void:
	_sfx.play()


func _new_page(title : String) -> VBoxContainer:
	var page = VBoxContainer.new()
	page.name = title
	page.add_theme_constant_override("separation", 10)
	_tabs.add_child(page)
	return page


# a label on the left, the control on the right
func _row(page : Control, label_text : String, control : Control) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	page.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	control.custom_minimum_size.x = 380
	row.add_child(control)


func _option_button(items : Array, selected_id) -> OptionButton:
	var button = OptionButton.new()
	for i in items.size():
		button.add_item(items[i][1], i)
		if items[i][0] == selected_id:
			button.select(i)
	_track(button)
	return button


# ---- visuals ----

func _add_visuals_page() -> void:
	var page = _new_page("Visuals")
	var visuals = ConfigHandler.load_visuals()

	for option in VISUAL_OPTIONS:
		var box = CheckBox.new()
		box.text = option[1]
		box.button_pressed = visuals[option[0]]
		box.toggled.connect(_on_visual_toggled.bind(option[0]))
		page.add_child(box)
		_track(box)


func _on_visual_toggled(toggled_on : bool, key : String) -> void:
	ConfigHandler.save_visuals_setting(key, toggled_on)


# ---- graphics ----

func _add_graphics_page() -> void:
	var page = _new_page("Graphics")
	var graphics = ConfigHandler.load_graphics()

	var window = _option_button(_window_modes, graphics["window_mode"])
	window.item_selected.connect(_on_window_mode_selected)
	_row(page, "Window mode", window)

	var vsync = CheckBox.new()
	vsync.text = "VSync"
	vsync.button_pressed = graphics["vsync"]
	vsync.toggled.connect(_on_vsync_toggled)
	page.add_child(vsync)
	_track(vsync)

	var fps_items = []
	for limit in FPS_LIMITS:
		fps_items.append([limit, "Unlimited" if limit == 0 else str(limit)])
	var fps = _option_button(fps_items, graphics["max_fps"])
	fps.item_selected.connect(_on_max_fps_selected)
	_row(page, "Max FPS", fps)

	# HDR needs a display that can show it, the rest of the HDR options follow the switch
	var hdr_supported = GameSettings.is_hdr_supported()
	var hdr = CheckBox.new()
	hdr.text = "HDR output" if hdr_supported else "HDR output (not supported by this display)"
	hdr.button_pressed = graphics["hdr_output"]
	hdr.disabled = !hdr_supported
	page.add_child(hdr)
	_track(hdr)

	var paper_white = _add_slider_row(page, "HDR paper white (nits)", 80, 400, 10, graphics["hdr_paper_white"], " nits", _on_paper_white_changed)
	paper_white.editable = hdr.button_pressed and hdr_supported
	hdr.toggled.connect(func(on): paper_white.editable = on)
	hdr.toggled.connect(_on_hdr_toggled)

	var hdr_2d = CheckBox.new()
	hdr_2d.text = "HDR 2D rendering"
	hdr_2d.button_pressed = graphics["hdr_2d"]
	hdr_2d.toggled.connect(_on_hdr_2d_toggled)
	page.add_child(hdr_2d)
	_track(hdr_2d)


func _on_window_mode_selected(index : int) -> void:
	ConfigHandler.save_graphics_setting("window_mode", _window_modes[index][0])
	GameSettings.apply_graphics()


func _on_vsync_toggled(toggled_on : bool) -> void:
	ConfigHandler.save_graphics_setting("vsync", toggled_on)
	GameSettings.apply_graphics()


func _on_max_fps_selected(index : int) -> void:
	ConfigHandler.save_graphics_setting("max_fps", FPS_LIMITS[index])
	GameSettings.apply_graphics()


func _on_hdr_toggled(toggled_on : bool) -> void:
	ConfigHandler.save_graphics_setting("hdr_output", toggled_on)
	GameSettings.apply_graphics()


func _on_paper_white_changed(value : float) -> void:
	ConfigHandler.save_graphics_setting("hdr_paper_white", value)
	GameSettings.apply_graphics()


func _on_hdr_2d_toggled(toggled_on : bool) -> void:
	ConfigHandler.save_graphics_setting("hdr_2d", toggled_on)
	GameSettings.apply_graphics()


# ---- audio ----

func _add_audio_page() -> void:
	var page = _new_page("Audio")
	var audio = ConfigHandler.load_audio()

	_add_slider_row(page, "Master volume", 0, 100, 5, audio["master_volume"], "%", _on_master_volume_changed)
	_add_slider_row(page, "Music volume", 0, 100, 5, audio["music_volume"], "%", _on_music_volume_changed)


# a label, a slider and its value; on_change gets the new value
func _add_slider_row(page : Control, label_text : String, min_value : float, max_value : float, step : float, value : float, unit : String, on_change : Callable) -> HSlider:
	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size.x = 320
	slider.size_flags_horizontal = Control.SIZE_SHRINK_END
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_track(slider)

	var shown = Label.new()
	shown.custom_minimum_size.x = 120
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shown.text = "%d%s" % [value, unit]

	slider.value_changed.connect(func(v : float):
		shown.text = "%d%s" % [v, unit]
		on_change.call(v))

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	page.add_child(row)

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(slider)
	row.add_child(shown)
	return slider


func _on_master_volume_changed(value : float) -> void:
	ConfigHandler.save_audio_setting("master_volume", int(value))
	GameSettings.apply_audio()


func _on_music_volume_changed(value : float) -> void:
	ConfigHandler.save_audio_setting("music_volume", int(value))
	GameSettings.apply_audio()


# ---- controls ----

func _add_controls_page() -> void:
	var page = _new_page("Controls")
	page.add_theme_constant_override("separation", 24)

	var input_mode = _option_button(_input_modes, ConfigHandler.load_controls()["input_mode"])
	input_mode.item_selected.connect(_on_input_mode_selected)
	_row(page, "Input device", input_mode)

	var help = Label.new()
	help.text = CONTROLS_HELP
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_constant_override("line_spacing", 8)
	page.add_child(help)


func _on_input_mode_selected(index : int) -> void:
	ConfigHandler.save_controls_setting("input_mode", _input_modes[index][0])
	InputManager.set_input_mode(_input_modes[index][0])
