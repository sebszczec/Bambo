extends Control

@onready var retryButton = $GridContainer/RetryButton
@onready var backButton = $GridContainer/QuitButton
@onready var scoreLabel = $GridContainer/ScoreLabel
@onready var phaseLabel = $GridContainer/PhaseLabel
@onready var highScoreLabel = $GridContainer/HighScoreLabel

var isPaused = false

func _ready() -> void:
	visible = false

func setPause(value):
	isPaused = value
	get_tree().paused = isPaused
	visible = isPaused

	if isPaused:
		retryButton.grab_focus()

# public - called by game logic when the player is dead
func show_result(score : int, phase_name : String, high_score : int, new_record : bool):
	scoreLabel.text = "Score: " + str(score)
	phaseLabel.text = "Survived: " + phase_name
	if new_record:
		highScoreLabel.text = "NEW RECORD!"
		highScoreLabel.add_theme_color_override("font_color", Color.GOLD)
	else:
		highScoreLabel.text = "High score: " + str(high_score)
	setPause(true)


func _on_retry_button_pressed() -> void:
	setPause(false)
	get_tree().change_scene_to_file("res://scenes/count_down.tscn")


func _on_quit_button_pressed() -> void:
	setPause(false)
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_button_focus_changed() -> void:
	$Sfx.play()


func _on_retry_button_mouse_entered() -> void:
	retryButton.grab_focus()


func _on_quit_button_mouse_entered() -> void:
	backButton.grab_focus()
