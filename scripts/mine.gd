extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var wait_timer = $WaitTimer
@onready var blink_timer = $BlinkTimer
@onready var death_timer = $DeathTimer
@onready var explosion = $Explosion

# public
@export var Damage = 0
# public
@export var IsDamageOverTime = false
# public
@export var DamageTickTime = 0.0
@export var BlinksNumber : int = 3

var _blinkCount: int = 0
var _detonating: bool = false

var floatTextScene = preload("res://scenes/floating_text.tscn")

func _ready() -> void:
	sprite.play("blink")


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var floatingText = floatTextScene.instantiate()
		floatingText.set_color(Color.WHITE)
		add_child(floatingText)
		return
	
	if area.is_in_group("Player"):
		if _detonating:
			return	
	
		_detonate()
		
		
func set_shader_blink_intensity(new_value: float):
	sprite.material.set_shader_parameter("blink_intensity", new_value);


func _detonate() -> void:
	_detonating = true	
	
	if _blinkCount < BlinksNumber:
		_blinkCount += 1
		_blink()
		blink_timer.start()
	

func _on_wait_timer_timeout() -> void:
	if _detonating:
		return
	
	_detonate()
	
func _blink() -> void:
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.75)


func _on_blink_timer_timeout() -> void:
	if _blinkCount < BlinksNumber:
		_blinkCount += 1
		_blink()
		blink_timer.start()
	else:
		_explode()
		death_timer.start()
		
func _explode() -> void:
	sprite.visible = false
	explosion.position = sprite.position
	explosion.SpriteTexture = sprite.get_sprite_frames().get_frame_texture(sprite.animation, sprite.get_frame())
	explosion.init()
	explosion.visible = true
	explosion.explode()


func _on_death_timer_timeout() -> void:
	queue_free()
