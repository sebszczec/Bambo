extends CharacterBody2D

# Shard Wasp - level 2 chaser (takes the Hunter's place). Circles the player at a short
# distance, then locks on - a targeting line shows the path - and lunges straight through
# the player. Its flint wings shed splinters along the path: a crackling wall that hangs in
# space for a few seconds and cuts the player who flies through it (scripts/shard_wake.gd).
# Chase -> Aim (the line, wings buzz) -> Lunge (path locked) -> Recover -> Chase.

var floatingTextScene = preload("res://scenes/floating_text.tscn")
var wakeScene = preload("res://scenes/shard_wake.tscn")

enum STATE { CHASE, AIM, LUNGE, RECOVER }

const BASE_DAMAGE = 6.0
# the wings buzz faster while it aims and lunges
const STATE_WING_SPEED = {
	STATE.CHASE : 1.0,
	STATE.AIM : 2.5,
	STATE.LUNGE : 3.0,
	STATE.RECOVER : 1.5,
}
# hdr colors of the targeting line, it heats up when the path is locked
const AIM_COLOR = Color(0.5, 1.8, 2.2, 0.5)
const LOCKED_COLOR = Color(2.4, 2.6, 2.8, 0.9)
const MIN_TRAIL_SPEED = 25.0

@onready var sprite = $Ship/AnimatedSprite2D
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/HitBoxCollisionShape
@onready var lifeBar = $LifeBar
@onready var ship = $Ship
@onready var aimLine = $AimLine
@onready var frostTrail = $Ship/FrostTrail
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D
@onready var aimAudio = $AimAudio
@onready var lungeAudio = $LungeAudio
@onready var mark = $Mark

@export_category("Movemement")
@export var RotationSpeed : float = TAU
@export var Speed = 150
@export var Acceleration = 420
@export var Knockback = 140
# circles the player at about this distance
@export var OrbitDistance = 230.0
@export_category("Lunge")
# locks on when the player is this close and the lunge is ready
@export var LungeRange = 380.0
@export var AimTime = 0.8
# the path is locked this long before the lunge, the player can still dodge
@export var LockTime = 0.25
@export var LungeSpeed = 1250.0
# flies this far past the player
@export var Overshoot = 170.0
@export var MinLunge = 280.0
@export var MaxLunge = 640.0
@export var LungeDamage = 10
@export var LungeHitRadius = 28.0
@export var LungeCooldown = 3.5
@export var RecoverTime = 0.5
@export_category("Wake")
@export var WakeDamage = 5
@export var WakeDuration = 2.6
# public - touching the wasp is one hit, the lunge and the wake are its real attack
@export var Damage = 6
# public
@export var IsDamageOverTime = false
# public
@export var DamageTickTime = 0.5
@export var Life = 90

signal killed

var _theta : float = 0
var _halfPI : float = PI / 2
var showDamage = true
var isDead = false

var player = null
var deathTimer = Timer.new()
var _state = STATE.CHASE
var _state_time = 0.0
var _cooldown = 0.0
var _orbit_side = 1.0
var _lunge_direction = Vector2.DOWN
var _lunge_left = 0.0
var _lunge_hit = false
var _wake = null

func _ready():
	set_physics_process(false)
	call_deferred("skip_frame")

	var visualSettings = ConfigHandler.load_visuals()
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	showDamage = visualSettings["show_damage_given"]
	lifeBar.setColor(Color.GREEN)
	lifeBar.setMaxValue(Life)
	lifeBar.setValue(Life)

	player = get_tree().get_first_node_in_group("player")
	Speed *= randf_range(0.9, 1.15)
	_orbit_side = 1.0 if randf() < 0.5 else -1.0
	# game_logic scales Damage in endless mode, the lunge and the wake follow it
	LungeDamage = int(LungeDamage * Damage / BASE_DAMAGE)
	WakeDamage = int(WakeDamage * Damage / BASE_DAMAGE)
	# a fresh wasp does not lunge the moment it arrives
	_cooldown = randf_range(1.0, LungeCooldown)

	aimLine.visible = false

	deathTimer.one_shot = true
	# the fragments fade out in a second, sound and particles are pooled in Juice
	deathTimer.wait_time = 1.2
	deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(deathTimer)

	# random start frame, wasps spawned together should not beat their wings in sync
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
	return "Shard Wasp"

# public
func setup_rotation(angle):
	ship.rotate(angle)
	collisionShape.rotation = ship.rotation
	hitBoxCollisionShape.rotation = ship.rotation

# public
func set_mark():
	mark.activate(1.0)

func skip_frame():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta):
	if isDead:
		return

	_state_time += delta
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player / max(distance, 0.001)

	match _state:
		STATE.CHASE:
			_chase(delta, direction, distance)
		STATE.AIM:
			_aim(delta, direction)
		STATE.LUNGE:
			_lunge(delta)
		STATE.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, Acceleration * 2.0 * delta)
			_face(direction, delta * 0.5)
			if _state_time >= RecoverTime:
				_set_state(STATE.CHASE)

	# the long body turns with the ship
	collisionShape.rotation = ship.rotation
	hitBoxCollisionShape.rotation = ship.rotation

	# frozen smoke from the vents while flying, the puffs left behind fade out on their own
	var moving = velocity.length() > MIN_TRAIL_SPEED
	if frostTrail.emitting != moving:
		frostTrail.emitting = moving

func _chase(delta, direction, distance):
	# flies in, then circles the player like a wasp hunting around a target
	var radial = clamp((distance - OrbitDistance) / 80.0, -1.0, 1.0)
	var tangent = direction.orthogonal() * _orbit_side
	var wanted = (direction * radial + tangent * (1.0 - abs(radial) * 0.6)).normalized() * Speed
	velocity = velocity.move_toward(wanted, Acceleration * delta)
	_face(direction, delta)
	move_and_slide()

	_cooldown -= delta
	if _cooldown <= 0.0 and distance < LungeRange:
		_set_state(STATE.AIM)
		aimLine.visible = true
		aimLine.default_color = AIM_COLOR
		Juice.play_sound(aimAudio)

func _aim(delta, direction):
	# brakes and pulls back a bit, the anticipation before the strike
	velocity = velocity.move_toward(-direction * 35.0, Acceleration * 2.0 * delta)
	var locked = _state_time >= AimTime - LockTime
	if !locked:
		_face(direction, delta * 2.0)
		_lunge_direction = Vector2.DOWN.rotated(ship.rotation)
		var length = player.global_position.distance_to(global_position) + Overshoot
		_lunge_left = clamp(length, MinLunge, MaxLunge)
	elif aimLine.default_color != LOCKED_COLOR:
		aimLine.default_color = LOCKED_COLOR
	move_and_slide()

	# the line shows the path the lunge will take
	aimLine.set_point_position(0, _lunge_direction * 30.0)
	aimLine.set_point_position(1, _lunge_direction * _lunge_left)
	aimLine.width = (6.0 if locked else 2.0) + sin(_state_time * 40.0) * 1.0

	if _state_time >= AimTime:
		_start_lunge()

func _start_lunge():
	_set_state(STATE.LUNGE)
	aimLine.visible = false
	_lunge_hit = false
	velocity = _lunge_direction * LungeSpeed
	Juice.play_sound(lungeAudio)

	_wake = wakeScene.instantiate()
	_wake.Damage = WakeDamage
	_wake.Duration = WakeDuration
	get_tree().current_scene.add_child(_wake)
	_wake.begin(global_position)

func _lunge(delta):
	var from = global_position
	velocity = _lunge_direction * LungeSpeed
	move_and_slide()
	var moved = global_position.distance_to(from)
	_lunge_left -= moved

	if is_instance_valid(_wake):
		_wake.extend_to(global_position)

	# fast enough to skip over the player in one frame, so the swept path is tested
	if !_lunge_hit and player.has_method("take_damage"):
		var closest = Geometry2D.get_closest_point_to_segment(player.global_position, from, global_position)
		if closest.distance_to(player.global_position) <= LungeHitRadius:
			_lunge_hit = true
			player.take_damage(LungeDamage)
			Juice.shake(4.0)

	# a rock in the way ends the lunge early
	if _lunge_left <= 0.0 or moved < LungeSpeed * delta * 0.25:
		_end_lunge()

func _end_lunge():
	if is_instance_valid(_wake):
		_wake.seal()
	_wake = null
	velocity = _lunge_direction * Speed
	_cooldown = LungeCooldown * randf_range(0.85, 1.3)
	_orbit_side = 1.0 if randf() < 0.5 else -1.0
	_set_state(STATE.RECOVER)

func _set_state(state):
	_state = state
	_state_time = 0.0
	sprite.speed_scale = STATE_WING_SPEED[state]

func _face(direction, delta):
	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return

		Juice.hit_effect(self, bullet.get_global_position())

		if isDead:
			return

		# a lunging wasp is too heavy to knock off its path
		if _state != STATE.LUNGE:
			velocity += bullet.global_position.direction_to(global_position) * Knockback
		Juice.flash(sprite)

		if handleDamage(PlayerStatus.get_damage_from_weapon(bullet.Type)) == false:
			isDead = true
			explode()

# public
func explode():
	Juice.play_sound(audio)
	set_physics_process(false)
	frostTrail.emitting = false
	aimLine.visible = false
	# a wall half built still hangs in space
	if is_instance_valid(_wake):
		_wake.seal()
	_wake = null
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false
	killed.emit(get_instance_id())
	_shatter()

func _shatter():
	ship.visible = false
	explosion.visible = true
	# the explosion breaks the frame that was shown into fragments
	explosion.SpriteTexture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.scale = sprite.scale
	# stone dust with a bit of the cyan glow, not the red of the level 1 machines
	explosion.set_particle_color(Color(0.9, 1.3, 1.4))
	explosion.explode()
	deathTimer.start()

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
