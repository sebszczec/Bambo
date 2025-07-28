extends CharacterBody2D

@export var Speed = 0
@export var MaxSpeed = 300
@export var Acceleration = 10
@export var Friction = 5
@export var RotationSpeed : float = TAU
@export var StrikeDelay : float = 0.25
@export var StrikeDuration : float = 1.0
@export var Life = 200
# public
@export var Damage = 50
# public
@export var IsDamageOverTime = true
# public
@export var DamageTickTime = 0.5

var floatingTextScene = preload("res://scenes/floating_text.tscn")
var hitEffectScene = preload("res://scenes/hit_effect.tscn")

@onready var ship = $Ship
@onready var sprite = $Ship/Sprite2D
@onready var beamSprite = $Ship/RadarBeam/Sprite2D
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/CollisionShape2D
@onready var radar = $Ship/RadarBeam
@onready var burst1 = $Ship/EngineBurst1
@onready var burst2 = $Ship/EngineBurst2
@onready var lifeBar = $LifeBar
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D
@onready var mark = $Mark

var _halfPI : float = PI / 2
var _accelerate = false
var _player = null
var _playerDetected = false
var _showDamage = false

var _direction = Vector2(0, 0);
var _prepareingStrikeTimer = Timer.new()
var _strikeDurationTimer = Timer.new()
var _deathTimer = Timer.new()
var _isDead = false

signal killed

func _ready() -> void:
	_player = get_node("/root/World/Player")
	
	var visualSettings = ConfigHandler.load_visuals()
	_showDamage = visualSettings["show_damage_given"]
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	lifeBar.setColor(Color.GREEN)
	
	explosion.init()
	
	radar.connect("player_detected", _on_radar_player_detected)
	radar.connect("player_lost", _on_radar_player_lost)
	
	_prepareingStrikeTimer.one_shot = true;
	_prepareingStrikeTimer.wait_time = StrikeDelay
	_prepareingStrikeTimer.connect("timeout", _on_preparing_strike_timer_timeout)
	add_child(_prepareingStrikeTimer)
	
	_strikeDurationTimer.one_shot = true
	_strikeDurationTimer.wait_time = StrikeDuration
	_strikeDurationTimer.connect("timeout", _on_strike_duration_timer_timeout)
	add_child(_strikeDurationTimer)
	
	_deathTimer.one_shot = true
	_deathTimer.wait_time = 2
	_deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(_deathTimer)
	
	var dissolveTween = get_tree().create_tween()
	dissolveTween.tween_method(set_shader_dissolve_value, 0.0, 1.0, 1.0)
	
	
func set_shader_dissolve_value(value : float):
	sprite.material.set_shader_parameter("DissolveValue", value)
	beamSprite.material.set_shader_parameter("DissolveValue", value)


func _physics_process(delta: float) -> void:
	if _playerDetected:
		_direction = global_position.direction_to(_player.position)
		var theta = wrapf(atan2(_direction.y, _direction.x) - ship.rotation - _halfPI, -PI, PI)
		var diff = clamp(RotationSpeed * delta, 0, abs(theta) * sign(theta))
		
		ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)
		
		if _prepareingStrikeTimer.is_stopped():
			_prepareingStrikeTimer.start()
	else:
		if !_prepareingStrikeTimer.is_stopped():
			_prepareingStrikeTimer.stop()
	
	if _accelerate:
		velocity = velocity.move_toward(_direction * MaxSpeed, Acceleration)
	else:
		velocity = velocity.move_toward(Vector2(0, 0), Friction)
#
	if !_isDead:
		move_and_collide(velocity * delta)

# public
func get_enemy_name():
	return "Enemy 2"

# public
func setup_rotation(angle):
	ship.rotate(angle)

# public
func set_mark():
	mark.activate(1.0)

func _on_preparing_strike_timer_timeout():
	_accelerate = true
	_strikeDurationTimer.start()
	
func _on_strike_duration_timer_timeout():
	_accelerate = false

func _on_radar_player_detected():
	_playerDetected = true
	burst1.emitting = true
	burst2.emitting = true
	
func _on_radar_player_lost():
	_playerDetected = false
	burst1.emitting = false
	burst2.emitting = false


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return
			
		var hit_effect = hitEffectScene.instantiate()
		add_child(hit_effect)
		hit_effect.emitting = true
		
		if !_isDead and handleDamage(PlayerStatus.get_damage_from_weapon(bullet.Type)) == false:
			_isDead = true
			explode()

func _on_death_timer_timeout():
	dispose()

func dispose():
	if !is_queued_for_deletion():
		queue_free()


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
