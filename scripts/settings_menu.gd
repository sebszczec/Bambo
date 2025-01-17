extends Control

@onready var showFspCB = $GridContainer/HBoxContainer/Checks/ShowFpsCB
@onready var showPlayerLifebarCB = $GridContainer/HBoxContainer/Checks/ShowPlayerLifebarCB
@onready var showEnemiesLifebarCB = $GridContainer/HBoxContainer/Checks/ShowEnemiesLifebarCB
@onready var showDamageTakenCB = $GridContainer/HBoxContainer/Checks/ShowDamageTakenCB
@onready var showDamageGivenCB = $GridContainer/HBoxContainer/Checks/ShowDamageGivenCB


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	showFspCB.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
