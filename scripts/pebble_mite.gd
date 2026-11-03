extends CharacterBody2D

# Pebble Mite - level 2 swarm enemy (takes the Scout's place). Crawls at the player,
# and when it gets close its cracks light up and it discharges a ring of lightning.
# Walk -> Charge -> Discharge (shock on SHOCK_FRAME) -> Recover -> Walk.
# The body collides with rocks only (mask 2): colliding with the player body made the
# player push a stopped mite along, it looked glued to the ship.

var floatingTextScene = preload("res://scenes/floating_text.tscn")

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

@onready var sprite = $Ship/AnimatedSprite2D
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionshape = $HitBox/HitBoxCollisionShape
@onready var lifeBar = $LifeBar
@onready var ship = $Ship
@onready var shock = $Shock
@onready var frostTrail = $Ship/FrostTrail
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D
@onready var shockAudio = $ShockAudio
@onready var mark = $Mark

@export_category("Movemement")
@export var RotationSpeed : float = TAU
@export var Speed = 95
@export var Acceleration = 500
@export var Knockback = 260
@export var StopDistance = 62.0
@export_category("Shock")
# starts charging when the player is this close
@export var TriggerRange = 170.0
# the lightning ring hits everything inside this radius
@export var ShockRadius = 120.0
@export var ShockDamage = 8
@export var ShockCooldown = 3.0
# public - touching the mite is one small hit, the shock is its real attack
@export var Damage = 3
# public
@export var IsDamageOverTime = false
# public
@export var DamageTickTime = 0.5
@export var Life = 30

signal killed

var _theta : float = 0
var _halfPI : float = PI / 2
var showDamage = true
var isDead = false

var player = null
var deathTimer = Timer.new()
var _state = STATE.WALK
var _wants_charge = false
var _cooldown = 0.0

func _ready():
	set_physics_process(false)
	call_deferred("skip_frame")

	var visualSettings = ConfigHandler.load_visuals()
	lifeBar.visible = false
	showDamage = visualSettings["show_damage_given"]
	lifeBar.setColor(Color.GREEN)
	lifeBar.setMaxValue(Life)
	lifeBar.setValue(Life)

	player = get_tree().get_first_node_in_group("player")
	Speed *= randf_range(0.85, 1.2)
	# game_logic scales Damage in endless mode, the shock follows it
	ShockDamage = int(ShockDamage * Damage / BASE_DAMAGE)
	# a fresh mite does not shock the moment it arrives
	_cooldown = randf_range(0.0, ShockCooldown)

	deathTimer.one_shot = true
	# the fragments fade out in a second, sound and particles are pooled in Juice
	deathTimer.wait_time = 1.2
	deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(deathTimer)

	sprite.connect("frame_changed", _on_frame_changed)
	sprite.connect("animation_finished", _on_animation_finished)

	# random start frame, a swarm should not move its legs in sync
	sprite.play(&"Walk")
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count(&"Walk")

	var dissolveTween = get_tree().create_tween()
	dissolveTween.tween_method(set_shader_dissolve_value, 0.0, 1.0, 0.5)

func set_shader_dissolve_value(value : float):
	if Juice.is_flashing(sprite):
		return
	sprite.material.set_shader_parameter("DissolveValue", value)

# public
func get_enemy_name():
	return "Pebble Mite"

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
	if isDead:
		return

	var to_player = player.global_position - global_position
	var direction = to_player.normalized()
	# stops at the hull instead of crawling under the player, the swarm rings around the ship
	var speed = Speed * STATE_SPEED[_state] if to_player.length() > StopDistance else 0.0
	velocity = velocity.move_toward(direction * speed, Acceleration * delta)

	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)

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

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return

		Juice.hit_effect(self, bullet.get_global_position())

		if isDead:
			return

		velocity += bullet.global_position.direction_to(global_position) * Knockback
		Juice.flash(sprite)

		if handleDamage(PlayerStatus.get_damage_from_weapon(bullet.Type, self)) == false:
			isDead = true
			explode()

# the shell crumbles first, the fragments fly when the Death animation ends
func explode():
	Juice.play_sound(audio)
	set_physics_process(false)
	frostTrail.emitting = false
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionshape.set_deferred("disabled", true)
	lifeBar.visible = false
	sprite.play(&"Death")
	killed.emit(get_instance_id())

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
