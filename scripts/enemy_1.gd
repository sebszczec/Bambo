extends EnemyBase

# Scout - weak and fast horde enemy, flies straight at the player
# and explodes on contact.

@onready var resizeTimer = $ResizeTimer

@export var ResizeSpeed = 0.05
@export_category("Movemement")
@export var Speed = 110
@export var Acceleration = 500

var resizeFactor = 1


func _init() -> void:
	enemy_name = "Enemy 1"
	Life = 30
	Knockback = 260
	Damage = 8


func _on_ready() -> void:
	resizeTimer.start()
	Speed *= randf_range(0.85, 1.2)


func _physics_process(delta):
	sprite.scale.x = sprite.scale.x + ResizeSpeed * resizeFactor * delta
	sprite.scale.y = sprite.scale.x
	# collision shapes are not resized with the sprite, changing them every frame is expensive

	if isDead:
		return

	var direction = global_position.direction_to(player.global_position)
	velocity = velocity.move_toward(direction * Speed, Acceleration * delta)
	_turn_towards(direction, delta)
	move_and_slide()


func _on_resize_timer_timeout():
	resizeFactor = resizeFactor * -1


func _on_died() -> void:
	resizeTimer.stop()


# flying into the player is the scout's attack
func _on_player_contact() -> void:
	if !isDead:
		explode()


func _show_life_bar(_visualSettings: Dictionary) -> bool:
	return false
