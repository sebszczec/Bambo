extends Control

@onready var showFspCB = $GridContainer/HBoxContainer/Checks/ShowFpsCB
@onready var showPlayerLifebarCB = $GridContainer/HBoxContainer/Checks/ShowPlayerLifebarCB
@onready var showEnemiesLifebarCB = $GridContainer/HBoxContainer/Checks/ShowEnemiesLifebarCB
@onready var showDamageTakenCB = $GridContainer/HBoxContainer/Checks/ShowDamageTakenCB
@onready var showDamageGivenCB = $GridContainer/HBoxContainer/Checks/ShowDamageGivenCB


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	showFspCB.grab_focus()
	
	var visualSettings = ConfigFIleHandler.load_visuals()
	showFspCB.button_pressed = visualSettings["show_fps"]
	showPlayerLifebarCB.button_pressed = visualSettings["show_player_lifebar"]
	showEnemiesLifebarCB.button_pressed = visualSettings["show_enemies_lifebar"]
	showDamageTakenCB.button_pressed = visualSettings["show_damage_taken"]
	showDamageGivenCB.button_pressed = visualSettings["show_damage_given"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_show_fps_cb_toggled(toggled_on: bool) -> void:
	ConfigFIleHandler.save_visuals_setting("show_fps", toggled_on)


func _on_show_player_lifebar_cb_toggled(toggled_on: bool) -> void:
	ConfigFIleHandler.save_visuals_setting("show_player_lifebar", toggled_on)


func _on_show_enemies_lifebar_cb_toggled(toggled_on: bool) -> void:
	ConfigFIleHandler.save_visuals_setting("show_enemies_lifebar", toggled_on)


func _on_show_damage_taken_cb_toggled(toggled_on: bool) -> void:
	ConfigFIleHandler.save_visuals_setting("show_damage_taken", toggled_on)


func _on_show_damage_given_cb_toggled(toggled_on: bool) -> void:
	ConfigFIleHandler.save_visuals_setting("show_damage_given", toggled_on)
