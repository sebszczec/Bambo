extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var explosion = $Explosion
@onready var death_timer = $DeathTimer
@onready var collision = $CollisionShape2D
@onready var hitbox_collision = $HitBox/CollisionShape2D

var is_dead : bool = false

func _ready() -> void:
	explosion.init()

func explode():
	sprite.visible = false
	collision.set_deferred("disabled", true)
	hitbox_collision.set_deferred("disabled", true)
	explosion.visible = true
	explosion.scale = sprite.scale
	explosion.explode()
	death_timer.start()


func dispose():
	if !is_queued_for_deletion():
		queue_free()


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		if !is_dead:
			explode()
			is_dead = true



func _on_death_timer_timeout() -> void:
	dispose()
