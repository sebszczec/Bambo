extends Control

@onready var backButton = $GridContainer/QuitButton

var isPaused = false
var player = null

func _ready() -> void:
	player = owner.find_child("Player")
	player.connect("killed", _on_player_killed)

func setPause(value):
	isPaused = value
	get_tree().paused = isPaused
	visible = isPaused
	
	if isPaused:
		backButton.grab_focus()


func _on_quit_button_pressed() -> void:
	setPause(false)
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_player_killed():
	setPause(true)
