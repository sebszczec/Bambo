extends CharacterBody2D

# Scout - weak and fast horde enemy, flies straight at the player
# and explodes on contact.

var floatingTextScene = preload("res://scenes/floating_text.tscn")

@onready var sprite = $Ship/AnimatedSprite2D
@onready var resizeTimer = $ResizeTimer
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionshape = $HitBox/HitBoxCollisionShape
@onready var lifeBar = $LifeBar
@onready var ship = $Ship
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D
@onready var mark = $Mark


@export var ResizeSpeed = 0.05
@export_category("Movemement")
@export var RotationSpeed : float = TAU
@export var Speed = 110
@export var Acceleration = 500
@export var Knockback = 260
# public
@export var Damage = 8
# public
@export var IsDamageOverTime = true
# public
@export var DamageTickTime = 0.5
@export var Life = 30

signal killed

var resizeFactor = 1
var _theta : float = 0
var _halfPI : float = PI / 2
var showDamage = true
var isDead = false

var player = null
var deathTimer = Timer.new()

func _ready():
	set_physics_process(false)
	call_deferred("skip_frame")

	var visualSettings = ConfigHandler.load_visuals()
	lifeBar.visible = false
	showDamage = visualSettings["show_damage_given"]
	lifeBar.setColor(Color.GREEN)
	lifeBar.setMaxValue(Life)
	lifeBar.setValue(Life)

	resizeTimer.start()

	player = get_tree().get_first_node_in_group("player")
	Speed *= randf_range(0.85, 1.2)

	deathTimer.one_shot = true
	# the fragments fade out in a second, sound and particles are pooled in Juice
	deathTimer.wait_time = 1.2
	deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(deathTimer)

	# random start frame, a swarm should not flap its legs in sync
	sprite.play(&"Fly")
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count(&"Fly")

	var dissolveTween = get_tree().create_tween()
	dissolveTween.tween_method(set_shader_dissolve_value, 0.0, 1.0, 0.5)

func set_shader_dissolve_value(value : float):
	if Juice.is_flashing(sprite):
		return
	sprite.material.set_shader_parameter("DissolveValue", value)

# public
func get_enemy_name():
	return "Enemy 1"

# public
func setup_rotation(angle):
	ship.rotate(angle)

# public
func set_mark():
	mark.activate(1.0)

func skip_frame():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	sprite.scale.x = sprite.scale.x + ResizeSpeed * resizeFactor * delta
	sprite.scale.y = sprite.scale.x
	# collision shapes are not resized with the sprite, changing them every frame is expensive

	if isDead:
		return

	var direction = global_position.direction_to(player.global_position)
	velocity = velocity.move_toward(direction * Speed, Acceleration * delta)

	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)

	move_and_slide()

func _on_resize_timer_timeout():
	resizeFactor = resizeFactor * -1

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		if !isDead:
			isDead = true
			explode()
	elif area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return

		Juice.hit_effect(self, bullet.get_global_position())

		if isDead:
			return

		velocity += bullet.global_position.direction_to(global_position) * Knockback
		Juice.flash(sprite)

		if handleDamage(PlayerStatus.get_damage_from_weapon(bullet.Type)) == false:
			isDead = true
			explode()

func explode():
	Juice.play_sound(audio)
	# a dead ship only shows its explosion
	set_physics_process(false)
	resizeTimer.stop()
	ship.visible = false
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionshape.set_deferred("disabled", true)
	lifeBar.visible = false
	explosion.visible = true
	# the explosion breaks the frame that was shown into fragments
	explosion.SpriteTexture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.scale = sprite.scale
	explosion.explode()
	deathTimer.start()
	killed.emit(get_instance_id())

func _on_death_timer_timeout():
	dispose()

func dispose():
	if !is_queued_for_deletion():
		queue_free()


func handleDamage(damage):
	if showDamage and FloatingText.can_spawn(damage.Critical):
		var damageText = floatingTextScene.instantiate()
		damageText.RoundNumber = true
		damageText.Big = damage.Critical
		if damage.Critical:
			damageText.set_color(Color.YELLOW)
		else:
			damageText.set_color(Color.WHITE)

		damageText.Amount = str(damage.Value)
		add_child(damageText)

	Life = Life - damage.Value
	lifeBar.setValue(Life)

	if Life <= 0:
		return false

	return true
