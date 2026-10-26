extends Control

@onready var resumeButton = $GridContainer/ResumeButton

var isPaused = false
var isPlayerKilled = false

var player = null

func _ready() -> void:
	player = owner.find_child("Player")
	player.connect("killed", _on_player_killed)

func setPause(value):
	if isPlayerKilled:
		return

	isPaused = value
	get_tree().paused = isPaused
	visible = isPaused

	if isPaused:
		resumeButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		setPause(!isPaused)
		get_viewport().set_input_as_handled()
	elif isPaused and event.is_action_pressed("ui_cancel"):
		setPause(false)
		get_viewport().set_input_as_handled()


func _on_resume_button_pressed() -> void:
	setPause(false)


func _on_restart_button_pressed() -> void:
	setPause(false)
	get_tree().change_scene_to_file("res://scenes/count_down.tscn")


func _on_menu_button_pressed() -> void:
	setPause(false)
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_player_killed():
	isPlayerKilled = true

func _on_button_focus_changed() -> void:
	$Sfx.play()


func _on_resume_button_mouse_entered() -> void:
	resumeButton.grab_focus()


func _on_restart_button_mouse_entered() -> void:
	$GridContainer/RestartButton.grab_focus()


func _on_menu_button_mouse_entered() -> void:
	$GridContainer/MenuButton.grab_focus()


func _on_quit_button_mouse_entered() -> void:
	$GridContainer/QuitButton.grab_focus()
