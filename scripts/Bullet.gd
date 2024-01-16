extends StaticBody2D

@export var Speed = 20

@onready var lifeTimer = $LifeTimer

var velocity = Vector2(0, 0)


func _ready():
	lifeTimer.start()


func _physics_process(delta):
	velocity = velocity.normalized() * Speed
	var collision = move_and_collide(velocity)
	
	if collision != null:
		velocity = velocity.bounce(collision.get_normal())


func _on_life_timer_timeout():
	queue_free()
