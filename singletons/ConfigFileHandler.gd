extends Node

var config = ConfigFile.new()
var SETTINGS_FILE_PATH = "user://settings.ini"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("Visuals", "show_fps", true)
		config.set_value("Visuals", "show_player_lifebar", true)
		config.set_value("Visuals", "show_enemies_lifebar", true)
		config.set_value("Visuals", "show_damage_taken", true)
		config.set_value("Visuals", "show_damage_given", true)
		
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)

func save_visuals_setting(key : String, value):
	config.set_value("Visuals", key, value)
	config.save(SETTINGS_FILE_PATH)
	
func load_visuals():
	var visuals = {}
	
	for key in config.get_section_keys("Visuals"):
		visuals[key] = config.get_value("Visuals", key)
	
	return visuals
