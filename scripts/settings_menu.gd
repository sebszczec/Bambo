extends Control

const RESET_CONFIRM_TIME = 2.5

@onready var options = $Options
@onready var scores = $Scores
@onready var resetScoresButton = $Scores/ResetScoresButton

var highScoreTable : HighScoreTable
var _reset_armed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	theme = MenuTheme.create()
	MenuTheme.style_title($Title)

	highScoreTable = HighScoreTable.new()
	highScoreTable.FontSize = 22
	highScoreTable.Title = "TOP 10"
	scores.add_child(highScoreTable)
	scores.move_child(highScoreTable, 0)

	# the scores are the last tab of the shared options panel
	options.add_page(scores)
	options.closed.connect(_on_back_button_pressed)

	resetScoresButton.connect("focus_exited", _disarm_reset)
	options.focus_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_button_pressed()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/start_menu.tscn")


func _on_button_focus_changed() -> void:
	$Sfx.play()


# first press arms the reset, second press within a moment wipes the table
func _on_reset_scores_button_pressed() -> void:
	if !_reset_armed:
		_reset_armed = true
		resetScoresButton.text = "Press again to confirm"
		get_tree().create_timer(RESET_CONFIRM_TIME).connect("timeout", _disarm_reset)
		return

	ConfigHandler.reset_high_scores()
	highScoreTable.refresh()
	_disarm_reset()

func _disarm_reset():
	_reset_armed = false
	resetScoresButton.text = "Reset high scores"
