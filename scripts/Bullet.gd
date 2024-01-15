extends StaticBody2D

@export var Speed = 20

var velocity = Vector2(0, 0)

func _physics_process(delta):
	velocity = velocity.normalized() * Speed
	move_and_collide(velocity)
