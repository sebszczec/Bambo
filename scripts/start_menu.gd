extends Control

@onready var newGameButton = $GridContainer/NewGame
@onready var settingsButton = $GridContainer/Settings
@onready var quitButton = $GridContainer/Quit
@onready var container = $GridContainer
@onready var warp = $Warp

var start_game_delay_1 : float = 1
var fade_step = 1 / start_game_delay_1
var fade : bool = false
var start_game_timer_1 = Timer.new()

var start_game_delay_2 : float = 1
var speed_step = 1 / start_game_delay_2
var brightness_step = 2.5 / start_game_delay_2
var warp_speed : float = 0
var warp_brightness : float = 0
var start_game_timer_2 = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_game_timer_1.one_shot = true
	start_game_timer_1.wait_time = start_game_delay_1
	start_game_timer_1.connect("timeout", _on_start_game_timer_1_timeout)
	add_child(start_game_timer_1)
	
	start_game_timer_2.one_shot = true
	start_game_timer_2.wait_time = start_game_delay_2
	start_game_timer_2.connect("timeout", _on_start_game_timer_2_timeout)
	add_child(start_game_timer_2)
	
	warp_speed = 3.0
	warp_brightness = 5.0
	container.modulate.a = 0.5
	print (warp_speed)
	
	newGameButton.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if fade:
		container.modulate.a = abs(container.modulate.a - fade_step * delta)
		warp_speed += speed_step * delta
		warp.set_speed(warp_speed)
		warp_brightness = abs(warp_brightness - brightness_step * delta)
		warp.set_brightness(warp_brightness)


func _on_start_game_timer_1_timeout() -> void:
	start_game_timer_2.start()

func _on_start_game_timer_2_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/count_down.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_new_game_pressed() -> void:
	fade = true
	start_game_timer_1.start()


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
