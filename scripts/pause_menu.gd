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

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_pause"):
		setPause(!isPaused)
	


func _on_resume_button_pressed() -> void:
	setPause(false)


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_player_killed():
	isPlayerKilled = true
