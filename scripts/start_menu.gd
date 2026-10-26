extends Control

const TitleBackdrop = preload("res://scripts/title_backdrop.gd")

@onready var newGameButton = $GridContainer/NewGame
@onready var settingsButton = $GridContainer/Settings
@onready var quitButton = $GridContainer/Quit
@onready var container = $GridContainer
@onready var anim = $AnimationPlayer
@onready var warp = $Warp

var logo : TitleLogo
var highScoreTable : HighScoreTable
var backdrop : Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false
	theme = MenuTheme.create(32)

	# drawn above the warp stars but below the menu
	backdrop = TitleBackdrop.new()
	add_child(backdrop)
	move_child(backdrop, warp.get_index() + 1)

	logo = TitleLogo.new()
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(logo)
	move_child(logo, backdrop.get_index() + 1)

	highScoreTable = HighScoreTable.new()
	highScoreTable.set_anchors_preset(Control.PRESET_CENTER)
	highScoreTable.offset_left = 80
	highScoreTable.offset_right = 760
	highScoreTable.offset_top = -10
	highScoreTable.offset_bottom = 500
	highScoreTable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highScoreTable)
	move_child(highScoreTable, container.get_index())

	newGameButton.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_new_game_pressed() -> void:
	newGameButton.disabled = true
	settingsButton.disabled = true
	quitButton.disabled = true
	logo.strike(1.5)
	var tween = create_tween().set_parallel(true)
	for node in [logo, highScoreTable, backdrop]:
		tween.tween_property(node, "modulate:a", 0.0, 1.0)
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
