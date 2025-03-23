extends Control

@onready var newGameButton = $GridContainer/NewGame
@onready var settingsButton = $GridContainer/Settings
@onready var quitButton = $GridContainer/Quit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	newGameButton.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/count_down.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")


func _on_button_focus_changed() -> void:
	$Sfx.play()
	

func _on_new_game_mouse_entered() -> void:
	newGameButton.grab_focus()


func _on_settings_mouse_entered() -> void:
	settingsButton.grab_focus()


func _on_quit_mouse_entered() -> void:
	quitButton.grab_focus()
