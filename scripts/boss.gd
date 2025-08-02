extends CharacterBody2D

var floatingTextScene = preload("res://scenes/floating_text.tscn")
var hitEffectScene = preload("res://scenes/hit_effect.tscn")

@export var Life = 200
@export var Damage = 100
@export var IsDamageOverTime = true
@export var DamageTickTime = 0.5
@export var MoveSpeed = 100
@export var Acceleration = 10
@export var Friction = 5
@export var RotationSpeed : float = TAU

@onready var ship = $Ship
@onready var mainBody = $Ship/AnimatedSprite2D
@onready var lifeBar = $LifeBar
@onready var audio = $AudioStreamPlayer2D
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/CollisionPolygon2D
@onready var explosion = $Explosion

var _player = null
var _theta = 0.0
var _halfPI : float = PI / 2
var _speed = Vector2(0, 0)
var _is_dead = false
var _show_damage = true
var _deathTimer = Timer.new()

signal killed

func _ready() -> void:
	var visualSettings = ConfigHandler.load_visuals()
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	_show_damage = visualSettings["show_damage_given"]
	lifeBar.setColor(Color.GREEN)
	
	_player = get_node("/root/World/Player")
	
	_deathTimer.one_shot = true
	_deathTimer.wait_time = 2
	_deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(_deathTimer)
	
	mainBody.play("Idle")

func _physics_process(delta: float) -> void:
	_speed = MoveSpeed
	
	var direction = global_position.direction_to(_player.get_global_position())
	velocity = velocity.move_toward(direction * _speed * delta, Acceleration)
	
	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)
	collisionShape.rotation = move_toward(collisionShape.rotation, collisionShape.rotation + diff, 0.1)
	hitBoxCollisionShape.rotation = move_toward(hitBoxCollisionShape.rotation, hitBoxCollisionShape.rotation + diff, 0.1)

	move_and_collide(velocity)

func _on_death_timer_timeout():
	dispose()

func dispose():
	if !is_queued_for_deletion():
		queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return


		var hit_effect = hitEffectScene.instantiate()
		add_child(hit_effect)
		hit_effect.set_global_position(bullet.get_global_position())
		hit_effect.emitting = true
		
		if !_is_dead and handleDamage(PlayerStatus.get_damage_from_weapon(bullet.Type), bullet.get_global_position()) == false:
			_is_dead = true
			explode()

func explode():
	audio.play()
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false
	ship.visible = false
	explosion.position = mainBody.position
	explosion.SpriteTexture = mainBody.get_sprite_frames().get_frame_texture(mainBody.animation, mainBody.get_frame())
	explosion.scale = mainBody.scale
	explosion.rotation = ship.rotation
	explosion.init(Vector2(3.0, 3.0), 250)
	explosion.visible = true
	explosion.explode()
	_deathTimer.start()
	killed.emit(get_instance_id())

func handleDamage(damage, label_position : Vector2):
	if _show_damage:
		var damageText = floatingTextScene.instantiate()
		damageText.RoundNumber = true
		if damage.Critical:
			damageText.set_color(Color.YELLOW)
		else:
			damageText.set_color(Color.WHITE)
			
		damageText.Amount = str(damage.Value)
		add_child(damageText)
		damageText.set_global_position(label_position)
		
	Life = Life - damage.Value
	lifeBar.setValue(Life)
	
	if Life <= 0:
		return false
	
	return true
