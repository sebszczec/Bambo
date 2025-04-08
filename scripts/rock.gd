extends CharacterBody2D

var rock_scene = preload("res://scenes/rock.tscn")

@onready var sprite = $Sprite2D
@onready var explosion = $Explosion
@onready var death_timer = $DeathTimer
@onready var collision = $CollisionShape2D
@onready var hitbox_collision = $HitBox/CollisionShape2D
@onready var player = $AudioStreamPlayer2D

@export var MinRotationSpeed : float = 0.1
@export var MaxRotationSpeed : float = 5.0
@export var NumberOfPieces : int = 3


var is_dead : bool = false
var rotation_speed : float = 0.0
var r_direction : int = 1
var world = null

func _ready() -> void:
	world = get_tree().get_root()
	explosion.init()
	explosion.set_particle_color(Color.GRAY)
	
	rotation_speed = randf_range(MinRotationSpeed, MaxRotationSpeed)
	r_direction = randi_range(0, 1)
	if r_direction == 0:
		r_direction = -1
		

func explode():
	sprite.visible = false
	collision.set_deferred("disabled", true)
	hitbox_collision.set_deferred("disabled", true)
	explosion.visible = true
	explosion.scale = sprite.scale
	explosion.explode()
	player.play()
	death_timer.start()


func _rotate(delta: float) -> void:
	var diff = r_direction * rotation_speed * delta 
	sprite.rotation += diff
	collision.rotation += diff
	hitbox_collision.rotation += diff
	


func _physics_process(delta: float) -> void:
	if !is_dead and (get_global_position().x < LevelSettings.MinX \
	or get_global_position().x > LevelSettings.MaxX \
	or get_global_position().y < LevelSettings.MinY \
	or get_global_position().y > LevelSettings.MaxY): 
		handle_destruction()
	
	_rotate(delta)
	move_and_collide(velocity * delta)

func dispose():
	if !is_queued_for_deletion():
		queue_free()

func handle_destruction():
	var angle = 2 * PI / NumberOfPieces + randf_range(0, PI)
	var r = sprite.texture.get_width() * sprite.scale.x * 0.4
	for i in range(NumberOfPieces):
		var rock = rock_scene.instantiate()
		rock.scale = scale * 0.3
		rock.NumberOfPieces = 0
		var temp_pos = Vector2(0, 0)
		temp_pos.x = get_global_position().x + r * cos(i * angle)
		temp_pos.y = get_global_position().y + r * sin(i * angle)
		rock.set_global_position(temp_pos)
		rock.velocity = temp_pos - get_global_position()
		rock.z_index = z_index - 1
		world.call_deferred("add_child", rock)
		
	explode()
	is_dead = true


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		if is_dead:
			return
		
		handle_destruction()



func _on_death_timer_timeout() -> void:
	dispose()
