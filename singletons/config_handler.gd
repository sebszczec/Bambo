extends Node

var config = ConfigFile.new()
var SETTINGS_FILE_PATH = "user://settings.ini"

const INPUT_MODE_AUTO = "auto"
const INPUT_MODE_GAMEPAD = "gamepad"
const INPUT_MODE_KEYBOARD_MOUSE = "keyboard_mouse"

const OLD_USER_DIR_NAME = "Bambo"

const HIGH_SCORE_COUNT = 10
const HIGH_SCORE_NAME_LENGTH = 3
# arcade style table filled on the first run, so there is always something to beat
const DEFAULT_HIGH_SCORES = [
	["ACE", 50000], ["SPC", 40000], ["THN", 30000], ["ZAP", 25000], ["UFO", 20000],
	["BOO", 15000], ["RKT", 10000], ["SKY", 7500], ["STR", 5000], ["NOV", 2500],
]

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
		"high_scores" : [],
	},
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_copy_settings_from_old_project_name()

	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.load(SETTINGS_FILE_PATH)

	# migrate old checkbox setting
	if config.has_section_key("Controls", "use_gamepad"):
		if !config.has_section_key("Controls", "input_mode"):
			config.set_value("Controls", "input_mode", INPUT_MODE_AUTO)
		config.erase_section_key("Controls", "use_gamepad")

	_migrate_high_scores()

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

# the project was renamed from Bambo to Space Thunder, which moved the user:// folder
func _copy_settings_from_old_project_name():
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		return

	var old_path = OS.get_user_data_dir().get_base_dir().path_join(OLD_USER_DIR_NAME).path_join("settings.ini")
	if FileAccess.file_exists(old_path):
		DirAccess.copy_absolute(old_path, ProjectSettings.globalize_path(SETTINGS_FILE_PATH))

# old saves kept only a single best score, move it into the table
func _migrate_high_scores():
	if config.has_section_key("Progress", "high_scores"):
		return

	var table = _default_high_scores()
	var old_score = config.get_value("Progress", "high_score", 0)
	if old_score > 0:
		table.append({ "name" : "YOU", "score" : old_score, "summary" : config.get_value("Progress", "best_phase", "") })

	config.set_value("Progress", "high_scores", _sorted_table(table))
	if config.has_section_key("Progress", "high_score"):
		config.erase_section_key("Progress", "high_score")
	if config.has_section_key("Progress", "best_phase"):
		config.erase_section_key("Progress", "best_phase")

func _default_high_scores() -> Array:
	var table = []
	for entry in DEFAULT_HIGH_SCORES:
		table.append({ "name" : entry[0], "score" : entry[1], "summary" : "" })
	return table

# public - brings back the default arcade table
func reset_high_scores():
	config.set_value("Progress", "high_scores", _default_high_scores())
	config.save(SETTINGS_FILE_PATH)

func _sorted_table(table : Array) -> Array:
	table.sort_custom(func(a, b): return a["score"] > b["score"])
	return table.slice(0, HIGH_SCORE_COUNT)

# returns entries { name, score, summary } sorted from the best one
func get_high_scores() -> Array:
	return config.get_value("Progress", "high_scores", [])

func get_high_score() -> int:
	var table = get_high_scores()
	return table[0]["score"] if table.size() > 0 else 0

func is_high_score(score : int) -> bool:
	if score <= 0:
		return false

	var table = get_high_scores()
	return table.size() < HIGH_SCORE_COUNT or score > table[-1]["score"]

# returns the rank (0 based) of the new entry or -1 when it did not make it to the table
func add_high_score(player_name : String, score : int, summary : String) -> int:
	if !is_high_score(score):
		return -1

	var entry = { "name" : player_name.substr(0, HIGH_SCORE_NAME_LENGTH), "score" : score, "summary" : summary }
	var table = get_high_scores().duplicate()
	table.append(entry)
	table = _sorted_table(table)
	config.set_value("Progress", "high_scores", table)
	config.save(SETTINGS_FILE_PATH)

	return table.find(entry)
