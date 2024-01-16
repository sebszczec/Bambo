extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var resizeTimer = $ResizeTimer
@onready var collisionShape = $CollisionShape2D

@export var ResizeSpeed = 0.05
@export_category("Movemement")
@export var Speed = 2
@export var Acceleration = 0.1


var resizeFactor = 1
var collisionShapeResizeSpeed = 0

func _ready():
	resizeTimer.start()
	collisionShapeResizeSpeed = 140 * ResizeSpeed
	
	velocity.x = 1
	velocity.y = 1


func _physics_process(delta):
	sprite.scale.x = sprite.scale.x + ResizeSpeed * resizeFactor * delta
	sprite.scale.y = sprite.scale.x
	
	collisionShape.shape.radius = collisionShape.shape.radius + collisionShapeResizeSpeed * resizeFactor * delta
	
	velocity = velocity.move_toward(velocity.normalized() * Speed, Acceleration)
	var collision = move_and_collide(velocity)
	
	if collision != null:
		velocity = velocity.bounce(collision.get_normal())


func _on_resize_timer_timeout():
	resizeFactor = resizeFactor * -1
