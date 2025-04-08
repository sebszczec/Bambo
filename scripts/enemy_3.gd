extends CharacterBody2D

@export var Life = 200
@export var Damage = 30
@export var IsDamageOverTime = false
@export var DamageTickTime = 0.0
@export var ShootingDelay = 0.5
@export var MoveSpeed = 100
@export var AttackSpeed = 200
@export var Acceleration = 10
@export var Friction = 5
@export var RotationSpeed : float = TAU

var floatingTextScene = preload("res://scenes/floating_text.tscn")
var hitEffectScene = preload("res://scenes/hit_effect.tscn")

@onready var ship = $Ship
@onready var sprite = $Ship/Sprite2D
@onready var lifeBar = $LifeBar
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/CollisionShape2D
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D
@onready var aim = $Ship/Aim
@onready var raycast = $Ship/RayCast2D

var _theta = 0.0
var _halfPI : float = PI / 2
var _shoot = false
var _speed = Vector2(0, 0)

var _showDamage = false
var _deathTimer = Timer.new()
var _shootingTimer = Timer.new()
var _isDead = false
var _weapon = null
var _player = null
var _world = null

signal killed

func _ready() -> void:
	_world = get_tree().root
	_player = get_node("/root/World/Player")
	
	var visualSettings = ConfigHandler.load_visuals()
	_showDamage = visualSettings["show_damage_given"]
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	lifeBar.setColor(Color.GREEN)
	
	explosion.init()
	
	_weapon = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL, true, false)
	_weapon.set_owner(_world)
	_weapon.register_internal_nodes(self)
	
	_deathTimer.one_shot = true
	_deathTimer.wait_time = 2
	_deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(_deathTimer)
	
	_shootingTimer.one_shot = false
	_shootingTimer.wait_time = ShootingDelay
	_shootingTimer.connect("timeout", _on_shooting_timer_timeout)
	add_child(_shootingTimer)
	_shootingTimer.start()
	
	var dissolveTween = get_tree().create_tween()
	dissolveTween.tween_method(set_shader_dissolve_value, 0.0, 1.0, 1.0)

func set_shader_dissolve_value(value : float):
	sprite.material.set_shader_parameter("DissolveValue", value)


func _physics_process(delta: float) -> void:
	if raycast.is_colliding():
		_shoot = true
		_speed = AttackSpeed
	else:
		_shoot = false
		_speed = MoveSpeed
	
	var direction = global_position.direction_to(_player.get_global_position())
	velocity = velocity.move_toward(direction * _speed * delta, Acceleration)
	
	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)

	move_and_collide(velocity * delta)
	

# public
func get_enemy_name():
	return "Enemy 3"
	
# public
func setup_rotation(angle):
	ship.rotate(angle)

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return
		
		var hit_effect = hitEffectScene.instantiate()
		add_child(hit_effect)
		hit_effect.emitting = true
		
		if !_isDead and handleDamage(PlayerStatus.get_damage()) == false:
			_shootingTimer.stop()
			_isDead = true
			explode()

func handleDamage(damage):
	if _showDamage:
		var damageText = floatingTextScene.instantiate()
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

func _on_shooting_timer_timeout():
	if _shoot:
		_weapon.shoot(_world, aim.get_global_position(), aim.get_global_position() - get_global_position())

func _on_death_timer_timeout():
	dispose()

func dispose():
	if !is_queued_for_deletion():
		queue_free()

func explode():
	audio.play()
	ship.visible = false
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false
	explosion.visible = true
	explosion.rotation = ship.rotation
	explosion.explode()
	_deathTimer.start()
	killed.emit(get_instance_id())
