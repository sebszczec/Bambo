extends CanvasLayer

# "Pick 1 of 3" upgrade screen shown on level up and when a chest is taken.
# The game is paused while it is open, more level ups are queued.

const CHOICES = 3
const INPUT_DELAY = 0.35
const CARD_SIZE = Vector2(330, 400)

var _pending_level_ups = 0
var _pending_chests = 0
var _open = false
var _input_delay = 0.0
var _choices : Array = []
var _buttons : Array = []

var _dim : ColorRect
var _flash : ColorRect
var _title : Label
var _cards : HBoxContainer
var _sound = AudioStreamPlayer.new()
var _focus_sound = AudioStreamPlayer.new()

signal closed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build()
	_set_visible(false)

func _build():
	var font = load("res://resources/kenney_space-shooter-redux/Bonus/kenvector_future.ttf")

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0.05, 0.75)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)

	_title = Label.new()
	_title.text = "LEVEL UP!"
	_title.add_theme_font_override("font", font)
	_title.add_theme_font_size_override("font_size", 72)
	_title.add_theme_color_override("font_color", Color.GOLD)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 14)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 150
	_title.offset_bottom = 250
	add_child(_title)

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 40)
	_cards.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cards.offset_top = 300
	_cards.offset_bottom = -280
	add_child(_cards)

	for i in range(CHOICES):
		var button = _create_card(font, i)
		_cards.add_child(button)
		_buttons.append(button)

	_sound.stream = load("res://resources/kenney_space-shooter-redux/Bonus/sfx_twoTone.ogg")
	add_child(_sound)
	_focus_sound.stream = load("res://resources/sfx/Menu Selection Click.wav")
	_focus_sound.volume_db = -6
	add_child(_focus_sound)

func _create_card(font : Font, index : int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.pivot_offset = CARD_SIZE / 2

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.1, 0.2, 0.95)
	normal.border_color = Color(0.3, 0.4, 0.7)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(12)
	var focus = normal.duplicate()
	focus.bg_color = Color(0.15, 0.18, 0.35, 1)
	focus.border_color = Color.GOLD
	focus.set_border_width_all(6)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", focus)
	button.add_theme_stylebox_override("pressed", focus)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", normal)

	var box = VBoxContainer.new()
	box.name = "VBoxContainer"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 20
	box.offset_right = -20
	box.offset_top = 24
	box.offset_bottom = -20
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var level = Label.new()
	level.name = "Level"
	level.add_theme_font_override("font", font)
	level.add_theme_font_size_override("font_size", 22)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(level)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(0, 110)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)

	var title = Label.new()
	title.name = "Title"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)

	var desc = Label.new()
	desc.name = "Desc"
	desc.add_theme_font_size_override("font_size", 22)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)

	var key = Label.new()
	key.text = "[" + str(index + 1) + "]"
	key.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(key)

	for child in box.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	button.connect("pressed", _on_card_pressed.bind(index))
	button.connect("mouse_entered", _on_card_mouse_entered.bind(button))
	button.connect("focus_entered", _on_card_focused.bind(button))
	return button

func _set_visible(value : bool):
	visible = value

# public
func queue_level_up():
	_pending_level_ups += 1
	_try_open()

# public
func queue_chest():
	_pending_chests += 1
	_try_open()

# public
func is_open() -> bool:
	return _open

func _try_open():
	if _open:
		return

	if _pending_chests > 0:
		_pending_chests -= 1
		_show(Upgrades.roll(CHOICES, true), "SUPPLY CRATE!", Color.CYAN)
	elif _pending_level_ups > 0:
		_pending_level_ups -= 1
		_show(Upgrades.roll(CHOICES), "LEVEL UP!", Color.GOLD)

func _show(choices : Array, title : String, color : Color):
	if choices.size() == 0:
		choices = Upgrades.roll(CHOICES)

	_open = true
	_choices = choices
	_input_delay = INPUT_DELAY
	get_tree().paused = true
	_set_visible(true)
	_sound.play()

	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_title.pivot_offset = Vector2(960, 50)
	_title.scale = Vector2(1.6, 1.6)

	_flash.color = Color(1, 1, 1, 0.6)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash, "color:a", 0.0, 0.35)
	tween.tween_property(_title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for i in range(_buttons.size()):
		var button : Button = _buttons[i]
		if i >= choices.size():
			button.visible = false
			continue

		var entry = choices[i]
		button.visible = true
		button.disabled = true
		button.get_node("VBoxContainer/Level").text = Upgrades.get_level_text(entry)
		button.get_node("VBoxContainer/Level").add_theme_color_override("font_color",
			Color.ORANGE if entry["weapon"] else Color.LIGHT_SKY_BLUE)
		button.get_node("VBoxContainer/Icon").texture = entry["icon"]
		button.get_node("VBoxContainer/Title").text = entry["title"]
		button.get_node("VBoxContainer/Desc").text = Upgrades.get_description(entry)

		# cards drop in one after another
		button.scale = Vector2(0.2, 0.2)
		button.modulate.a = 0.0
		tween.tween_property(button, "scale", Vector2.ONE, 0.3).set_delay(0.08 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(0.08 * i)

func _process(delta: float) -> void:
	if !_open:
		return

	# the pause menu could unpause the game, keep it paused while choosing
	get_tree().paused = true

	if _input_delay > 0:
		_input_delay -= delta
		if _input_delay <= 0:
			for button in _buttons:
				button.disabled = false
			_buttons[0].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if !_open or _input_delay > 0:
		return

	if event is InputEventKey and event.pressed and !event.echo:
		var index = event.keycode - KEY_1
		if index >= 0 and index < _choices.size():
			_on_card_pressed(index)
			get_viewport().set_input_as_handled()

func _on_card_mouse_entered(button : Button):
	if !button.disabled:
		button.grab_focus()

func _on_card_focused(button : Button):
	if _open and _input_delay <= 0:
		_focus_sound.play()
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.06, 1.06), 0.08)
		tween.tween_property(button, "scale", Vector2.ONE, 0.08)

func _on_card_pressed(index : int):
	if !_open or _input_delay > 0 or index >= _choices.size():
		return

	Upgrades.choose(_choices[index])
	_open = false
	_set_visible(false)

	if _pending_chests > 0 or _pending_level_ups > 0:
		_try_open()
		return

	get_tree().paused = false
	closed.emit()
