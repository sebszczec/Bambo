extends Control

@onready var newGameButton = $GridContainer/NewGame
@onready var settingsButton = $GridContainer/Settings
@onready var quitButton = $GridContainer/Quit
@onready var container = $GridContainer
@onready var anim = $AnimationPlayer
@onready var warp = $Warp


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	newGameButton.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_new_game_pressed() -> void:
	newGameButton.disabled = true
	settingsButton.disabled = true
	quitButton.disabled = true
	anim.play("warp_speed")


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


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scenes/count_down.tscn")
