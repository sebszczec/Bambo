extends Node

var config = ConfigFile.new()
var SETTINGS_FILE_PATH = "user://settings.ini"

const INPUT_MODE_AUTO = "auto"
const INPUT_MODE_GAMEPAD = "gamepad"
const INPUT_MODE_KEYBOARD_MOUSE = "keyboard_mouse"

var _defaults : Dictionary = {
	"Visuals" : {
		"show_fps" : true,
		"show_player_lifebar" : true,
		"show_enemies_lifebar" : true,
		"show_damage_taken" : true,
		"show_damage_given" : true,
		"show_bullets_count" : true,
		"show_enemies_count" : true,
	},
	"Controls" : {
		"input_mode" : INPUT_MODE_AUTO,
	},
	"Progress" : {
		"high_score" : 0,
		"best_phase" : "",
	},
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.load(SETTINGS_FILE_PATH)

	# migrate old checkbox setting
	if config.has_section_key("Controls", "use_gamepad"):
		if !config.has_section_key("Controls", "input_mode"):
			config.set_value("Controls", "input_mode", INPUT_MODE_AUTO)
		config.erase_section_key("Controls", "use_gamepad")

	# fill every missing key with its default value
	for section in _defaults:
		for key in _defaults[section]:
			if !config.has_section_key(section, key):
				config.set_value(section, key, _defaults[section][key])

	config.save(SETTINGS_FILE_PATH)

func save_visuals_setting(key : String, value):
	config.set_value("Visuals", key, value)
	config.save(SETTINGS_FILE_PATH)

func save_controls_setting(key : String, value):
	config.set_value("Controls", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_visuals():
	var visuals = {}

	for key in config.get_section_keys("Visuals"):
		visuals[key] = config.get_value("Visuals", key)

	return visuals

func load_controls():
	var controls = {}

	for key in config.get_section_keys("Controls"):
		controls[key] = config.get_value("Controls", key)

	return controls

func get_high_score() -> int:
	return config.get_value("Progress", "high_score", 0)

func get_best_phase() -> String:
	return config.get_value("Progress", "best_phase", "")

# returns true when a new record was set
func save_run_result(score : int, phase_name : String) -> bool:
	var new_record = score > get_high_score()
	if new_record:
		config.set_value("Progress", "high_score", score)
		config.set_value("Progress", "best_phase", phase_name)
		config.save(SETTINGS_FILE_PATH)

	return new_record
