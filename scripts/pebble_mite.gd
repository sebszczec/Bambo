extends EnemyBase

# Pebble Mite - level 2 swarm enemy (takes the Scout's place). Crawls at the player,
# and when it gets close its cracks light up and it discharges a ring of lightning.
# Walk -> Charge -> Discharge (shock on SHOCK_FRAME) -> Recover -> Walk.
# The body collides with rocks only (mask 2): colliding with the player body made the
# player push a stopped mite along, it looked glued to the ship.

enum STATE { WALK, CHARGE, DISCHARGE, RECOVER }

# walk frames whose next frame matches the first Charge frame, the switch has no jump
const EXIT_FRAMES = [21, 49]
# Recover ends on the frame that follows this Walk frame in the video
const WALK_ENTRY_FRAME = 49
# the flash of the eye in the Discharge animation
const SHOCK_FRAME = 6
# speed multiplier per state, a charging mite almost stops
const STATE_SPEED = {
	STATE.WALK : 1.0,
	STATE.CHARGE : 0.35,
	STATE.DISCHARGE : 0.0,
	STATE.RECOVER : 0.5,
}
const BASE_DAMAGE = 3.0
const MIN_TRAIL_SPEED = 25.0

@onready var frostTrail = $Ship/FrostTrail
@onready var shock = $Shock
@onready var shockAudio = $ShockAudio

@export_category("Movemement")
@export var Speed = 95
@export var Acceleration = 500
@export var StopDistance = 62.0
@export_category("Shock")
# starts charging when the player is this close
@export var TriggerRange = 170.0
# the lightning ring hits everything inside this radius
@export var ShockRadius = 120.0
@export var ShockDamage = 8
@export var ShockCooldown = 3.0

var _wants_charge = false
var _cooldown = 0.0
var _state = STATE.WALK


func _init() -> void:
	enemy_name = "Pebble Mite"
	idleAnimation = &"Walk"
	shapesFollowShip = false
	fragmentTint = Color(0.9, 1.3, 1.4)
	Life = 30
	Knockback = 260
	# public - touching the mite is one small hit, the shock is its real attack
	Damage = 3
	IsDamageOverTime = false


func _on_ready() -> void:
	Speed *= randf_range(0.85, 1.2)
	# game_logic scales Damage in endless mode, the shock follows it
	ShockDamage = int(ShockDamage * Damage / BASE_DAMAGE)
	# a fresh mite does not shock the moment it arrives
	_cooldown = randf_range(0.0, ShockCooldown)

	sprite.connect("frame_changed", _on_frame_changed)
	sprite.connect("animation_finished", _on_animation_finished)


func _show_life_bar(_visualSettings: Dictionary) -> bool:
	return false


func _physics_process(delta):
	if isDead:
		return

	var to_player = player.global_position - global_position
	var direction = to_player.normalized()
	# stops at the hull instead of crawling under the player, the swarm rings around the ship
	var speed = Speed * STATE_SPEED[_state] if to_player.length() > StopDistance else 0.0
	velocity = velocity.move_toward(direction * speed, Acceleration * delta)
	_turn_towards(direction, delta)

	if _state == STATE.WALK:
		_cooldown -= delta
		# the switch waits for an exit frame of the walk cycle
		var distance = to_player.length()
		if _wants_charge:
			_wants_charge = distance < TriggerRange * 1.5
		elif _cooldown <= 0.0 and distance < TriggerRange:
			_wants_charge = true

	move_and_slide()

	# frozen smoke only while crawling, the puffs left behind fade out on their own
	var moving = velocity.length() > MIN_TRAIL_SPEED
	if frostTrail.emitting != moving:
		frostTrail.emitting = moving


func _on_frame_changed():
	if isDead:
		return
	if _state == STATE.WALK and _wants_charge and sprite.frame in EXIT_FRAMES:
		_wants_charge = false
		_state = STATE.CHARGE
		sprite.play(&"Charge")
	elif _state == STATE.DISCHARGE and sprite.frame == SHOCK_FRAME:
		_shock()


func _on_animation_finished():
	if isDead:
		if sprite.animation == &"Death":
			_shatter()
		return

	match _state:
		STATE.CHARGE:
			_state = STATE.DISCHARGE
			sprite.play(&"Discharge")
		STATE.DISCHARGE:
			_state = STATE.RECOVER
			sprite.play(&"Recover")
		STATE.RECOVER:
			_state = STATE.WALK
			_cooldown = ShockCooldown
			sprite.play(&"Walk")
			sprite.frame = WALK_ENTRY_FRAME


func _shock():
	shock.fire(ShockRadius, 0.35)
	Juice.play_sound(shockAudio)
	if global_position.distance_to(player.global_position) <= ShockRadius and player.has_method("take_damage"):
		player.take_damage(ShockDamage)


# the shell crumbles first, the fragments fly when the Death animation ends
func explode():
	isDead = true
	Juice.play_sound(audio)
	set_physics_process(false)
	frostTrail.emitting = false
	_disable_body()
	sprite.play(&"Death")
	killed.emit(get_instance_id())
