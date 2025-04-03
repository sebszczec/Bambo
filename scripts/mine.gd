extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var wait_timer = $WaitTimer
@onready var blink_timer = $BlinkTimer

@export var BlinksNumber : int = 3

var _blinkCount: int = 0

var floatTextScene = preload("res://scenes/floating_text.tscn")

func _ready() -> void:
	sprite.play("blink")


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var floatingText = floatTextScene.instantiate()
		floatingText.set_color(Color.WHITE)
		add_child(floatingText)
		

func set_shader_blink_intensity(new_value: float):
	sprite.material.set_shader_parameter("blink_intensity", new_value);


func _on_wait_timer_timeout() -> void:
	if _blinkCount < BlinksNumber:
		_blinkCount += 1
		_blink()
		blink_timer.start()
	
func _blink() -> void:
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.5)


func _on_blink_timer_timeout() -> void:
	if _blinkCount < BlinksNumber:
		_blinkCount += 1
		_blink()
		blink_timer.start()
