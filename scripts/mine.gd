extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var wait_timer = $WaitTimer
@onready var blink_timer = $BlinkTimer
@onready var death_timer = $DeathTimer
@onready var explosion = $Explosion
@onready var explosion_sound = $ExplosionSoundPlayer
@onready var blinking_sound = $BlinkingSoundPlayer
@onready var collision = $CollisionShape2D
@onready var hit_box_collision = $HitBox/CollisionShape2D

# public
@export var Damage = 0
# public
@export var IsDamageOverTime = false
# public
@export var DamageTickTime = 0.0
@export var BlinksNumber : int = 3
@export var TimeToDetonate : float = 3.0

var _blinkCount: int = 0
var _detonating: bool = false
var _world = null
var _weapon = null

var floatTextScene = preload("res://scenes/floating_text.tscn")

func _ready() -> void:
	_world = get_tree().root
	_weapon = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL_WAVE, true, true)
	_weapon.set_owner(_world)
	_weapon.register_internal_nodes(self)
	_weapon.set_modulate_color(Color.RED)
	
	wait_timer.wait_time = TimeToDetonate
	wait_timer.start()
	
	sprite.play("blink")


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return
			
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
	blinking_sound.play()
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.75)


func _on_blink_timer_timeout() -> void:
	if _blinkCount < BlinksNumber:
		_blinkCount += 1
		_blink()
		blink_timer.start()
	else:
		_explode()
		_weapon.shoot(_world, get_global_position(), get_global_position())
		death_timer.start()
		
func _explode() -> void:
	sprite.visible = false
	collision.disabled = true
	hit_box_collision.disabled = true
	explosion.position = sprite.position
	explosion.SpriteTexture = sprite.get_sprite_frames().get_frame_texture(sprite.animation, sprite.get_frame())
	explosion.init()
	explosion.visible = true
	explosion.explode()
	explosion_sound.play()


func _on_death_timer_timeout() -> void:
	queue_free()
