extends Node

# Applies the graphics and audio settings from ConfigHandler to the engine.
# Runs before the menus, so the saved values are in place from the first frame.

const MUSIC_BUS = "Music"

func _ready() -> void:
	_ensure_music_bus()
	apply_all()

# public
func apply_all() -> void:
	apply_graphics()
	apply_audio()

# public - called by the options panel right after a change
func apply_graphics() -> void:
	var graphics = ConfigHandler.load_graphics()

	var window_mode = graphics.get("window_mode", ConfigHandler.WINDOW_MODE_WINDOWED)
	match window_mode:
		ConfigHandler.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		ConfigHandler.WINDOW_MODE_BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen = DisplayServer.screen_get_size()
			DisplayServer.window_set_size(screen)
			DisplayServer.window_set_position(Vector2i.ZERO)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	var vsync = graphics.get("vsync", true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

	# 0 is unlimited
	Engine.max_fps = graphics.get("max_fps", 0)

	# HDR only goes on when the display can show it, the option is greyed out otherwise
	var hdr_supported = DisplayServer.window_is_hdr_output_supported(DisplayServer.MAIN_WINDOW_ID)
	DisplayServer.window_request_hdr_output(graphics.get("hdr_output", false) and hdr_supported, DisplayServer.MAIN_WINDOW_ID)
	DisplayServer.window_set_hdr_output_reference_luminance(graphics.get("hdr_paper_white", 200.0), DisplayServer.MAIN_WINDOW_ID)
	get_tree().root.use_hdr_2d = graphics.get("hdr_2d", true)

# public - whether this display can show HDR, the options panel asks before offering the switch
func is_hdr_supported() -> bool:
	return DisplayServer.window_is_hdr_output_supported(DisplayServer.MAIN_WINDOW_ID)

# public
func apply_audio() -> void:
	var audio = ConfigHandler.load_audio()
	_set_bus_percent(AudioServer.get_bus_index("Master"), audio.get("master_volume", 100))
	_set_bus_percent(AudioServer.get_bus_index(MUSIC_BUS), audio.get("music_volume", 100))

# the Music bus is made in code, there is no bus layout file to edit
func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) != -1:
		return
	AudioServer.add_bus()
	var index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, MUSIC_BUS)
	AudioServer.set_bus_send(index, "Master")

# a 0-100 slider value as bus volume, 0 is silence
func _set_bus_percent(index : int, percent : float) -> void:
	if index == -1:
		return
	var linear = clamp(percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(linear) if linear > 0.0 else -80.0)
