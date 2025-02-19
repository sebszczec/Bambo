extends CharacterBody2D

var floatingTextScene = preload("res://scenes/floating_text.tscn")

@onready var sprite = $Ship/Sprite2D
@onready var resizeTimer = $ResizeTimer
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionshape = $HitBox/HitBoxCollisionShape
@onready var lifeBar = $LifeBar
@onready var ship = $Ship


@export var ResizeSpeed = 0.05
@export_category("Movemement")
@export var RotationSpeed : float = TAU
@export var Speed = 3000
@export var Acceleration = 0.1
@export var Damage = 20
@export var IsDamageOverTime = true
@export var DamageTickTime = 0.5
@export var Life = 100

@onready var agent = $NavigationAgent2D

signal killed

var resizeFactor = 1
var _theta : float = 0
var _halfPI : float = PI / 2
var showDamage = true

var player = null

func _ready():	
	set_physics_process(false)
	call_deferred("skip_frame")
	
	var visualSettings = ConfigHandler.load_visuals()
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	showDamage = visualSettings["show_damage_given"]
	lifeBar.setColor(Color(0, 255, 0))
	
	resizeTimer.start()

	player = get_node("/root/World/Player")
	
	make_path(Vector2(randf_range(0, get_viewport_rect().size.x), randf_range(0, get_viewport_rect().size.y)))

#
func get_enemy_name():
	return "Enemy 1"


func skip_frame():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	sprite.scale.x = sprite.scale.x + ResizeSpeed * resizeFactor * delta
	sprite.scale.y = sprite.scale.x
	collisionShape.scale.x = collisionShape.scale.x + ResizeSpeed * resizeFactor * delta * 5
	collisionShape.scale.y = collisionShape.scale.x
	hitBoxCollisionshape.scale.x = hitBoxCollisionshape.scale.x + ResizeSpeed * resizeFactor * delta * 5
	hitBoxCollisionshape.scale.y = hitBoxCollisionshape.scale.x
	
	
	var dist_to_player = player.position - global_position;
	var next_position = Vector2()
	if dist_to_player.length() < 200:
		next_position = player.position
	else:
		next_position = agent.get_next_path_position()
	
	var direction = global_position.direction_to(next_position)
	var vel = direction * Speed * delta

	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)
	
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


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		
		if handleDamage(bullet.Damage) == false:
			dispose()
			pass # handle enemy killed

func dispose():
	if !is_queued_for_deletion():
		killed.emit(get_instance_id())
		queue_free()


func handleDamage(damage):
	if showDamage:
		var damageText = floatingTextScene.instantiate()
		damageText.set_color(Color.WHITE)
		damageText.Amount = str(damage)
		add_child(damageText)
		
	Life = Life - damage
	lifeBar.setValue(Life)
	
	if Life <= 0:
		return false
	
	return true
