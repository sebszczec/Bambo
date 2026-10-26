extends Control

@onready var container = $GridContainer
@onready var retryButton = $GridContainer/RetryButton
@onready var backButton = $GridContainer/QuitButton
@onready var scoreLabel = $GridContainer/ScoreLabel
@onready var phaseLabel = $GridContainer/PhaseLabel
@onready var highScoreLabel = $GridContainer/HighScoreLabel

var isPaused = false
var nameEntry : NameEntry
var highScoreTable : HighScoreTable

var _score = 0
var _summary = ""

func _ready() -> void:
	visible = false
	theme = MenuTheme.create()

	nameEntry = NameEntry.new()
	nameEntry.visible = false
	nameEntry.connect("name_entered", _on_name_entered)
	container.add_child(nameEntry)
	container.move_child(nameEntry, retryButton.get_index())

	highScoreTable = HighScoreTable.new()
	highScoreTable.FontSize = 22
	highScoreTable.visible = false
	container.add_child(highScoreTable)
	container.move_child(highScoreTable, retryButton.get_index())

func setPause(value):
	isPaused = value
	get_tree().paused = isPaused
	visible = isPaused

	if isPaused and retryButton.visible:
		retryButton.grab_focus()

# public - called by game logic when the player is dead
func show_result(score : int, phase_name : String):
	_score = score
	_summary = phase_name
	scoreLabel.text = "Score: " + str(score)
	phaseLabel.text = "Survived: " + phase_name

	if ConfigHandler.is_high_score(score):
		var is_best = score > ConfigHandler.get_high_score()
		highScoreLabel.text = "NEW RECORD!" if is_best else "NEW HIGH SCORE!"
		highScoreLabel.add_theme_color_override("font_color", Color.GOLD)
		_set_buttons_visible(false)
		nameEntry.start()
	else:
		highScoreLabel.text = "High score: " + str(ConfigHandler.get_high_score())
		_show_table(-1)

	setPause(true)

func _on_name_entered(player_name : String):
	var rank = ConfigHandler.add_high_score(player_name, _score, _summary)
	nameEntry.visible = false
	_show_table(rank)
	retryButton.grab_focus()

func _show_table(highlight_rank : int):
	highScoreTable.refresh(highlight_rank)
	highScoreTable.visible = true
	_set_buttons_visible(true)

func _set_buttons_visible(value : bool):
	retryButton.visible = value
	backButton.visible = value


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
