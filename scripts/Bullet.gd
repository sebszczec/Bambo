extends StaticBody2D

@export var Speed = 20

@onready var lifeTimer = $LifeTimer

var velocity = Vector2(0, 0)

signal freeing


func _ready():
	lifeTimer.start()


@warning_ignore("unused_parameter")
func _physics_process(delta):
	velocity = velocity.normalized() * Speed
	var collision = move_and_collide(velocity)
	
	if collision != null:
		velocity = velocity.bounce(collision.get_normal())

func dispose():
	freeing.emit()
	queue_free()

func _on_life_timer_timeout():
	dispose()


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		dispose()
