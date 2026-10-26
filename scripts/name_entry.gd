extends VBoxContainer
class_name NameEntry

# Arcade initials entry: up / down changes the letter, left / right moves between slots,
# accept goes to the next slot and confirms on the last one. Letters can also be typed.

signal name_entered(player_name : String)

const CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789."
const LETTER_COLOR = Color(0.4, 0.8, 1.0)
const ACTIVE_COLOR = Color(1.0, 0.85, 0.2)
const BLINK_TIME = 0.2
const ARM_DELAY = 0.6
const REPEAT_DELAY = 0.35
const REPEAT_RATE = 0.08

var _font = null
var _letters : Array = []
var _cursor_labels : Array = []
var _indexes : Array = []
var _slot = 0
var _blink_time = 0.0
var _active = false
var _armed_time = 0.0
var _repeat_time = 0.0

@onready var _sfx = get_node_or_null("../../Sfx")

func _ready() -> void:
	_font = load("res://resources/kenney_space-shooter-redux/Bonus/kenvector_future.ttf")
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 12)

	var hint = _create_label(22, Color(0.8, 0.8, 0.9))
	hint.text = "ENTER YOUR INITIALS"
	add_child(hint)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	add_child(row)

	for i in ConfigHandler.HIGH_SCORE_NAME_LENGTH:
		var slot = VBoxContainer.new()
		slot.add_theme_constant_override("separation", 4)
		var up = _create_arrow(true)
		var letter = _create_label(72, LETTER_COLOR)
		letter.custom_minimum_size = Vector2(80, 0)
		var down = _create_arrow(false)
		slot.add_child(up)
		slot.add_child(letter)
		slot.add_child(down)
		row.add_child(slot)
		_letters.append(letter)
		_cursor_labels.append([up, down])
		_indexes.append(0)

	var controls = _create_label(16, Color(0.6, 0.6, 0.7))
	controls.text = "UP/DOWN letter   LEFT/RIGHT move   ACCEPT confirm"
	add_child(controls)

# public
func start():
	_slot = 0
	for i in _indexes.size():
		_indexes[i] = 0
	_active = true
	_armed_time = 0.0
	visible = true
	_update_letters()

func _process(delta: float) -> void:
	if !_active:
		return

	_blink_time += delta
	var on = int(_blink_time / BLINK_TIME) % 2 == 0
	_letters[_slot].modulate.a = 1.0 if on else 0.35

	# ignore the first moment, the player may still be mashing the shoot button
	_armed_time += delta
	if _armed_time < ARM_DELAY:
		return

	# polled instead of handled per event, so a held stick changes letters at a steady pace
	var vertical = 0
	if Input.is_action_pressed("ui_up"):
		vertical = 1
	elif Input.is_action_pressed("ui_down"):
		vertical = -1

	if vertical == 0:
		_repeat_time = 0.0
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		_repeat_time = REPEAT_DELAY
		_change_letter(vertical)
	else:
		_repeat_time -= delta
		if _repeat_time <= 0.0:
			_repeat_time = REPEAT_RATE
			_change_letter(vertical)

	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_cancel"):
		_move_slot(-1)
	elif Input.is_action_just_pressed("ui_right"):
		_move_slot(1)
	elif Input.is_action_just_pressed("ui_accept"):
		_next_slot()

func _input(event: InputEvent) -> void:
	if !_active:
		return

	# typing letters directly on the keyboard
	if event is InputEventKey and event.pressed and !event.echo and _armed_time >= ARM_DELAY:
		var typed = char(event.unicode).to_upper() if event.unicode > 0 else ""
		if typed != "" and CHARACTERS.contains(typed):
			_indexes[_slot] = CHARACTERS.find(typed)
			_next_slot()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE:
			_move_slot(-1)
			get_viewport().set_input_as_handled()

func _change_letter(step : int):
	_indexes[_slot] = posmod(_indexes[_slot] + step, CHARACTERS.length())
	_play_sfx()
	_update_letters()

func _move_slot(step : int):
	_slot = clampi(_slot + step, 0, _letters.size() - 1)
	_play_sfx()
	_update_letters()

func _next_slot():
	if _slot == _letters.size() - 1:
		_confirm()
	else:
		_move_slot(1)

func _confirm():
	_active = false
	var player_name = ""
	for i in _indexes:
		player_name += CHARACTERS[i]
	_play_sfx()
	name_entered.emit(player_name)

func _update_letters():
	_blink_time = 0.0
	for i in _letters.size():
		var active = i == _slot
		_letters[i].text = CHARACTERS[_indexes[i]]
		_letters[i].modulate.a = 1.0
		_letters[i].add_theme_color_override("font_color", ACTIVE_COLOR if active else LETTER_COLOR)
		for cursor in _cursor_labels[i]:
			cursor.modulate.a = 1.0 if active else 0.0

func _play_sfx():
	if _sfx != null:
		_sfx.play()

# the font has no arrow glyphs, so the cursor triangles are drawn into a small texture
func _create_arrow(pointing_up : bool) -> TextureRect:
	var width = 28
	var height = 14
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		var row = y if pointing_up else height - 1 - y
		var half = int(float(row + 1) / height * width / 2.0)
		image.fill_rect(Rect2i(width / 2 - half, y, half * 2, 1), ACTIVE_COLOR)

	var arrow = TextureRect.new()
	arrow.texture = ImageTexture.create_from_image(image)
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	return arrow

func _create_label(font_size : int, color : Color) -> Label:
	var label = Label.new()
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
