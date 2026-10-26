extends Node

# Tracks which device the player uses (gamepad or keyboard+mouse)
# and gives gameplay code device independent move / aim vectors.

enum DEVICE { KEYBOARD_MOUSE, GAMEPAD }

const JOY_DEADZONE = 0.3
const MOUSE_MOTION_THRESHOLD = 4.0

var active_device : DEVICE = DEVICE.KEYBOARD_MOUSE
var input_mode : String = ConfigHandler.INPUT_MODE_AUTO
var hide_cursor_for_gamepad = false

signal device_changed(device : DEVICE)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_input_mode(ConfigHandler.load_controls()["input_mode"])

	if input_mode == ConfigHandler.INPUT_MODE_AUTO and Input.get_connected_joypads().size() > 0:
		_set_device(DEVICE.GAMEPAD)

func set_input_mode(mode : String):
	input_mode = mode
	if input_mode == ConfigHandler.INPUT_MODE_GAMEPAD:
		_set_device(DEVICE.GAMEPAD)
	elif input_mode == ConfigHandler.INPUT_MODE_KEYBOARD_MOUSE:
		_set_device(DEVICE.KEYBOARD_MOUSE)

func is_gamepad() -> bool:
	return active_device == DEVICE.GAMEPAD

# gameplay scenes call this so the cursor is hidden only while playing with a gamepad
func set_gameplay_cursor(value : bool):
	hide_cursor_for_gamepad = value
	_update_cursor()

func _input(event: InputEvent) -> void:
	if input_mode != ConfigHandler.INPUT_MODE_AUTO:
		return

	if event is InputEventJoypadButton:
		_set_device(DEVICE.GAMEPAD)
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > JOY_DEADZONE:
			_set_device(DEVICE.GAMEPAD)
	elif event is InputEventKey or event is InputEventMouseButton:
		_set_device(DEVICE.KEYBOARD_MOUSE)
	elif event is InputEventMouseMotion:
		if event.relative.length() > MOUSE_MOTION_THRESHOLD:
			_set_device(DEVICE.KEYBOARD_MOUSE)

func _set_device(device : DEVICE):
	if device == active_device:
		return

	active_device = device
	_update_cursor()
	device_changed.emit(active_device)

func _update_cursor():
	if hide_cursor_for_gamepad and active_device == DEVICE.GAMEPAD:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

# returns Vector2.ZERO when there is no aim input (gamepad stick released)
func get_aim_vector(node : CanvasItem) -> Vector2:
	if active_device == DEVICE.GAMEPAD:
		return Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")

	return node.get_global_mouse_position() - node.get_global_position()

func vibrate(weak : float, strong : float, duration : float):
	if active_device != DEVICE.GAMEPAD:
		return

	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration)
