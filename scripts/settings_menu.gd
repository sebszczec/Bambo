extends Control

const RESET_CONFIRM_TIME = 2.5

@onready var tabs = $TabContainer
@onready var fps = $TabContainer/Visuals/Fps
@onready var playerLifebar = $TabContainer/Visuals/PlayerLifeBar
@onready var enemyLifebar = $TabContainer/Visuals/EnemyLifeBar
@onready var playerDamage = $TabContainer/Visuals/PlayerDamage
@onready var enemyDamage = $TabContainer/Visuals/EnemyDamage
@onready var bulletsCount = $TabContainer/Visuals/BulletsCount
@onready var enemiesCount = $TabContainer/Visuals/EnemiesCount
@onready var inputMode = $TabContainer/Controls/InputModeRow/InputMode
@onready var resetScoresButton = $TabContainer/Scores/ResetScoresButton
@onready var backButton = $BackButton

var _input_modes = [ConfigHandler.INPUT_MODE_AUTO, ConfigHandler.INPUT_MODE_GAMEPAD, ConfigHandler.INPUT_MODE_KEYBOARD_MOUSE]
var highScoreTable : HighScoreTable
var _reset_armed = false
var _ready_done = false
var _shoulder_left = false
var _shoulder_right = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	theme = MenuTheme.create()
	MenuTheme.style_title($Title)

	highScoreTable = HighScoreTable.new()
	highScoreTable.FontSize = 22
	highScoreTable.Title = "TOP 10"
	$TabContainer/Scores.add_child(highScoreTable)
	$TabContainer/Scores.move_child(highScoreTable, 0)

	var visualSettings = ConfigHandler.load_visuals()
	var controlSettings = ConfigHandler.load_controls()

	fps.button_pressed = visualSettings["show_fps"]
	playerLifebar.button_pressed = visualSettings["show_player_lifebar"]
	enemyLifebar.button_pressed = visualSettings["show_enemies_lifebar"]
	playerDamage.button_pressed = visualSettings["show_damage_taken"]
	enemyDamage.button_pressed = visualSettings["show_damage_given"]
	bulletsCount.button_pressed = visualSettings["show_bullets_count"]
	enemiesCount.button_pressed = visualSettings["show_enemies_count"]
	inputMode.add_item("Auto")
	inputMode.add_item("Gamepad")
	inputMode.add_item("Keyboard + mouse")
	inputMode.select(max(0, _input_modes.find(controlSettings["input_mode"])))

	# click sound and mouse focus like in the other menus
	for button in [fps, bulletsCount, enemiesCount, playerLifebar, enemyLifebar, playerDamage, enemyDamage, inputMode, resetScoresButton, backButton]:
		button.connect("focus_entered", _on_button_focus_changed)
		button.connect("mouse_entered", button.grab_focus)
	resetScoresButton.connect("focus_exited", _disarm_reset)
	tabs.connect("tab_changed", _on_tab_changed)

	fps.grab_focus()
	_ready_done = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

	# gamepad shoulder buttons switch tabs
	if Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER) != _shoulder_left:
		_shoulder_left = !_shoulder_left
		if _shoulder_left:
			tabs.current_tab = posmod(tabs.current_tab - 1, tabs.get_tab_count())
	if Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) != _shoulder_right:
		_shoulder_right = !_shoulder_right
		if _shoulder_right:
			tabs.current_tab = posmod(tabs.current_tab + 1, tabs.get_tab_count())

func _on_tab_changed(tab : int):
	if !_ready_done:
		return

	# keep keyboard / gamepad focus inside the visible tab
	match tab:
		0: fps.grab_focus()
		1: inputMode.grab_focus()
		2: resetScoresButton.grab_focus()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


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


func _on_fps_toggled(toggled_on: bool) -> void:
	ConfigHandler.save_visuals_setting("show_fps", toggled_on)


func _on_player_life_bar_toggled(toggled_on: bool) -> void:
	ConfigHandler.save_visuals_setting("show_player_lifebar", toggled_on)


func _on_enemy_life_bar_toggled(toggled_on: bool) -> void:
	ConfigHandler.save_visuals_setting("show_enemies_lifebar", toggled_on)


func _on_player_damage_toggled(toggled_on: bool) -> void:
	ConfigHandler.save_visuals_setting("show_damage_taken", toggled_on)


func _on_enemy_damage_toggled(toggled_on: bool) -> void:
	ConfigHandler.save_visuals_setting("show_damage_given", toggled_on)


func _on_bullets_count_toggled(toggled_on: bool) -> void:
	ConfigHandler.save_visuals_setting("show_bullets_count", toggled_on)


func _on_enemies_count_toggled(toggled_on: bool) -> void:
	ConfigHandler.save_visuals_setting("show_enemies_count", toggled_on)


func _on_input_mode_selected(index: int) -> void:
	ConfigHandler.save_controls_setting("input_mode", _input_modes[index])
	InputManager.set_input_mode(_input_modes[index])
