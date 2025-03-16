extends StaticBody2D

class_name Bullet

@export var Speed = 20
@export var MinDamage = 10
@export var MaxDamage = 20
@export var LifeTime = 0.5
@export var HitBox : Area2D

@onready var lifeTimer = $LifeTimer

var velocity = Vector2(0, 0)
var Damage = 0

signal freeing


func _ready():
	lifeTimer.connect("timeout", _on_life_timer_timeout)
	lifeTimer.wait_time = LifeTime
	lifeTimer.start()
	HitBox.connect("area_entered", _on_hit_box_area_entered)
	Damage = randi_range(MinDamage, MaxDamage)


func _physics_process(_delta):
	velocity = velocity.normalized() * Speed
	var collision = move_and_collide(velocity)
	
	if collision != null:
		velocity = velocity.bounce(collision.get_normal())

func dispose():
	if is_queued_for_deletion():
		return
	
	freeing.emit(self)
	queue_free()

func _on_life_timer_timeout():
	dispose()


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy") or area.is_in_group("Player"):
		dispose()
