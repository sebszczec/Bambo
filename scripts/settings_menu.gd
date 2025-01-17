extends Control

@onready var fps = $GridContainer/HBoxContainer/Checks/Fps
@onready var playerLifebar = $GridContainer/HBoxContainer/Checks/PlayerLifeBar
@onready var enemyLifebar = $GridContainer/HBoxContainer/Checks/EnemyLifeBar
@onready var playerDamage = $GridContainer/HBoxContainer/Checks/PlayerDamage
@onready var enemyDamage = $GridContainer/HBoxContainer/Checks/EnemyDamage
@onready var bulletsCount = $GridContainer/HBoxContainer/Checks/BulletsCount
@onready var enemiesCount = $GridContainer/HBoxContainer/Checks/EnemiesCount

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	var visualSettings = ConfigHandler.load_visuals()
	fps.button_pressed = visualSettings["show_fps"]
	playerLifebar.button_pressed = visualSettings["show_player_lifebar"]
	enemyLifebar.button_pressed = visualSettings["show_enemies_lifebar"]
	playerDamage.button_pressed = visualSettings["show_player_lifebar"]
	enemyDamage.button_pressed = visualSettings["show_damage_given"]
	bulletsCount.button_pressed = visualSettings["show_bullets_count"]
	enemiesCount.button_pressed = visualSettings["show_enemies_count"]

	fps.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")


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
