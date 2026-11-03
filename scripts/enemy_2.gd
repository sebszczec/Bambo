extends EnemyBase

# Guard - drifts towards the player, then when the radar spots him it lunges in a straight
# strike. The radar beam shows the detection cone.

@export var MaxSpeed = 300
@export var DriftSpeed = 70
@export var Acceleration = 10
@export var Friction = 5
@export var StrikeDelay : float = 0.25
@export var StrikeDuration : float = 1.0

@onready var beamSprite = $Ship/RadarBeam/Sprite2D
@onready var radar = $Ship/RadarBeam
@onready var burst1 = $Ship/EngineBurst1
@onready var burst2 = $Ship/EngineBurst2

var _accelerate = false
var _playerDetected = false
var _direction = Vector2(0, 0)
var _prepareingStrikeTimer = Timer.new()
var _strikeDurationTimer = Timer.new()


func _init() -> void:
	enemy_name = "Enemy 2"
	idleAnimation = &"Fly"
	shapesFollowShip = true
	Life = 120
	Knockback = 120
	Damage = 20


func _on_ready() -> void:
	radar.connect("player_detected", _on_radar_player_detected)
	radar.connect("player_lost", _on_radar_player_lost)

	_prepareingStrikeTimer.one_shot = true
	_prepareingStrikeTimer.wait_time = StrikeDelay
	_prepareingStrikeTimer.connect("timeout", _on_preparing_strike_timer_timeout)
	add_child(_prepareingStrikeTimer)

	_strikeDurationTimer.one_shot = true
	_strikeDurationTimer.wait_time = StrikeDuration
	_strikeDurationTimer.connect("timeout", _on_strike_duration_timer_timeout)
	add_child(_strikeDurationTimer)


func set_shader_dissolve_value(value: float) -> void:
	super.set_shader_dissolve_value(value)
	beamSprite.material.set_shader_parameter("DissolveValue", value)


func _physics_process(delta: float) -> void:
	var to_player = global_position.direction_to(player.position)
	if _playerDetected:
		_direction = to_player
		if _prepareingStrikeTimer.is_stopped():
			_prepareingStrikeTimer.start()
	else:
		if !_prepareingStrikeTimer.is_stopped():
			_prepareingStrikeTimer.stop()

	# always face the player, so the radar finds him
	_turn_towards(to_player, delta)

	if _accelerate:
		velocity = velocity.move_toward(_direction * MaxSpeed, Acceleration)
	elif _playerDetected:
		velocity = velocity.move_toward(Vector2(0, 0), Friction)
	else:
		# drift towards the player until he is in radar range
		velocity = velocity.move_toward(to_player * DriftSpeed, Friction)

	if !isDead:
		move_and_collide(velocity * delta)


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


func _on_died() -> void:
	_prepareingStrikeTimer.stop()
	_strikeDurationTimer.stop()
