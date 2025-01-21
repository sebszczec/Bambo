extends Control

var delays = [0.1, 0.5, 0.1, 0.5, 0.1, 0.5, 0.1, 0.5]
var numbers = ["3", "3", "2", "2", "1", "1", "START!", "START!"]
var visibility = [false, true, false, true, false, true, false, true]
var step = 0

var timer = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().paused = false
	timer.connect("timeout", _on_timer_timeout)
	add_child(timer)
	prepareTimer()


func prepareTimer():
	if step == 8:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/world.tscn")
		return
		
	$Label.visible = visibility[step]
	$Label.text = numbers[step]
	timer.one_shot = true
	timer.wait_time = delays[step]
	step = step + 1
	
	timer.start()


func _on_timer_timeout():
	prepareTimer()
