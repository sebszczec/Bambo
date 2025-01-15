extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var resizeTimer = $ResizeTimer
@onready var collisionShape = $CollisionShape2D

@export var ResizeSpeed = 0.05
@export_category("Movemement")
@export var Speed = 2
@export var Acceleration = 0.1
@export var Damage = 10
@export var IsDamageOverTime = true
@export var DamageTickTime = 0.5

@onready var agent = $NavigationAgent2D

var resizeFactor = 1
var collisionShapeResizeSpeed = 0

var player = null

func _ready():	
	set_physics_process(false)
	call_deferred("skip_frame")
	
	resizeTimer.start()
	collisionShapeResizeSpeed = 40 * ResizeSpeed

	player = get_node("/root/World/Player")
	
	make_path(Vector2(randf_range(0, get_viewport_rect().size.x), randf_range(0, get_viewport_rect().size.y)))


func skip_frame():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	sprite.scale.x = sprite.scale.x + ResizeSpeed * resizeFactor * delta
	sprite.scale.y = sprite.scale.x
	collisionShape.shape.radius = collisionShape.shape.radius + collisionShapeResizeSpeed * resizeFactor * delta
	
	var dist_to_player = player.position - global_position;
	var next_position = Vector2()
	if dist_to_player.length() < 200:
		next_position = player.position
	else:
		next_position = agent.get_next_path_position()
	
	var direction = global_position.direction_to(next_position)
	var vel = direction * 3000 * delta
	
	agent.velocity = vel
		

func _on_resize_timer_timeout():
	resizeFactor = resizeFactor * -1
	
func make_path(pos: Vector2):
	agent.target_position = pos


func _on_navigation_agent_2d_navigation_finished() -> void:
	make_path(Vector2(randf_range(0, get_viewport_rect().size.x), randf_range(0, get_viewport_rect().size.y)))


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = velocity.move_toward(safe_velocity, 100)
	move_and_slide()
