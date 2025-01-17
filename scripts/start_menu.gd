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
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")
