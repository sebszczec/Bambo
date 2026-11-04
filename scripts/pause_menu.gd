extends Control

@onready var resumeButton = $GridContainer/ResumeButton
@onready var optionsButton = $GridContainer/OptionsButton
@onready var grid = $GridContainer
@onready var options = $OptionsPanel

var isPaused = false
var isPlayerKilled = false

var player = null

func _ready() -> void:
	player = owner.find_child("Player")
	player.connect("killed", _on_player_killed)
	options.closed.connect(_close_options)

func setPause(value):
	if isPlayerKilled:
		return

	isPaused = value
	get_tree().paused = isPaused
	visible = isPaused
	_hide_options()

	if isPaused:
		resumeButton.grab_focus()

func _is_level_up_open() -> bool:
	for menu in get_tree().get_nodes_in_group("level_up_menu"):
		if menu.is_open():
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	# the options panel is closed first, the game stays paused
	if options.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_close_options()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		# the upgrade cards already pause the game and would unpause it on pick
		if !isPaused and _is_level_up_open():
			return
		setPause(!isPaused)
		get_viewport().set_input_as_handled()
	elif isPaused and event.is_action_pressed("ui_cancel"):
		setPause(false)
		get_viewport().set_input_as_handled()


func _on_resume_button_pressed() -> void:
	setPause(false)


func _on_options_button_pressed() -> void:
	grid.visible = false
	options.visible = true
	options.focus_current()


# back in the pause grid, focus returns to the button that opened the panel
func _close_options() -> void:
	_hide_options()
	optionsButton.grab_focus()


func _hide_options() -> void:
	options.visible = false
	grid.visible = true


func _on_options_button_mouse_entered() -> void:
	optionsButton.grab_focus()


func _on_restart_button_pressed() -> void:
	setPause(false)
	get_tree().change_scene_to_file("res://scenes/effects/count_down.tscn")


func _on_menu_button_pressed() -> void:
	setPause(false)
	get_tree().change_scene_to_file("res://scenes/menus/level_select.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_player_killed():
	isPlayerKilled = true

# public - the run is over (level won), the result screen owns the pause
func lock():
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
