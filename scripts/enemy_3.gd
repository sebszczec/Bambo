extends EnemyBase

# Hunter - keeps its distance and shoots at the player whenever the ray sees him.

@export var ShootingDelay = 0.5
@export var MoveSpeed = 100
@export var AttackSpeed = 200
@export var Acceleration = 10
@export var Friction = 5

@onready var aim = $Ship/Aim
@onready var raycast = $Ship/RayCast2D

var _theta = 0.0
var _shoot = false
var _speed = Vector2(0, 0)

var _shootingTimer = Timer.new()
var _world = null
var _weapon = null


func _init() -> void:
	enemy_name = "Enemy 3"
	shapesFollowShip = true
	Life = 100
	Knockback = 150
	Damage = 12
	IsDamageOverTime = false
	DamageTickTime = 0.0


func _on_ready() -> void:
	_world = get_tree().current_scene

	_weapon = WeaponFactory.get_weapon(Enums.WEAPONS.SMALL, true, false)
	_weapon.set_owner(_world)
	_weapon.register_internal_nodes(self)

	_shootingTimer.one_shot = false
	_shootingTimer.wait_time = ShootingDelay
	_shootingTimer.connect("timeout", _on_shooting_timer_timeout)
	add_child(_shootingTimer)
	_shootingTimer.start()


func _physics_process(delta: float) -> void:
	if raycast.is_colliding():
		_shoot = true
		_speed = AttackSpeed
	else:
		_shoot = false
		_speed = MoveSpeed

	var direction = global_position.direction_to(player.get_global_position())
	velocity = velocity.move_toward(direction * _speed, Acceleration * 60 * delta)
	_turn_towards(direction, delta)

	if !isDead:
		move_and_collide(velocity * delta)


func _on_shooting_timer_timeout():
	if _shoot:
		_weapon.shoot(_world, aim.get_global_position(), aim.get_global_position() - get_global_position())


# a dead ship only shows its explosion and does not shoot any more
func _on_died() -> void:
	_shootingTimer.stop()
	_shoot = false
