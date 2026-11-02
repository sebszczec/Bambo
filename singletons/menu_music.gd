extends AudioStreamPlayer

# one music player for all menu scenes, so the track keeps playing when switching
# between start menu, save slots, missions and hangar instead of starting over

const MENU_TRACK = preload("res://resources/shared/audio/music/Orbital Colossus.mp3")

func _ready() -> void:
	stream = MENU_TRACK
	# the old per scene AudioStreamPlayer2D sat at the screen corner, ~7 dB quieter
	volume_db = -7.0

# public - keeps playing when it already does
func play_menu():
	if !playing:
		play()

# public - leaving the menus for a run
func stop_menu():
	stop()
