extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var resizeTimer = $ResizeTimer
@onready var collisionShape = $CollisionShape2D

@export var ResizeSpeed = 0.05

var resizeFactor = 1
var collisionShapeResizeSpeed = 0

func _ready():
	resizeTimer.start()
	collisionShapeResizeSpeed = 140 * ResizeSpeed


func _physics_process(delta):
	sprite.scale.x = sprite.scale.x + ResizeSpeed * resizeFactor * delta
	sprite.scale.y = sprite.scale.x
	
	collisionShape.shape.radius = collisionShape.shape.radius + collisionShapeResizeSpeed * resizeFactor * delta


func _on_resize_timer_timeout():
	resizeFactor = resizeFactor * -1
