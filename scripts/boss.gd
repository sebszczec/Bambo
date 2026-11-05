extends EnemyBase

# Hive boss (skull) - shoots fireworks from its shell, then opens its shell to summon scouts.
# Attacks are timed by the animation frames, not by timers.

@export var MoveSpeed = 100
@export var Acceleration = 10
@export var Friction = 5

@onready var aim1 = $Ship/Aim1
@onready var aim1_1 = $Ship/Aim1_1
@onready var aim2 = $Ship/Aim2
@onready var aim2_2 = $Ship/Aim2_2

var _speed = Vector2(0, 0)
var _world = null
var _weapon = null

# frames of resources/levels/level1/enemies/hive_beetle/skull_animations.json
# Idle frame that ShellOpen and Summon continue from (both start with it)
const IDLE_EXIT = 39
# Idle frame that follows the last ShellClose frame
const IDLE_AFTER_CLOSE = 19
# ShellHold frame with the shell fully open, ShellClose starts with it
const HOLD_SHOT_FRAME = 7
# Summon frames with raised antennae, one scout each
const SUMMON_SPAWN_FRAMES = [10, 15, 20, 25, 30]

var _state_timer = Timer.new()
var _state_timeout = 4
var _shot_count = 0
var _max_shots = 6
var _spawn_count = 0
var _max_spawn = 5
var _spawn_distance = 240
var _max_life = 0

signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)
signal health_changed(value : int, max_value : int)

enum STATE {NONE, SHOOT, SPAWN}
var _next_attack = STATE.SHOOT
# attack waiting for the idle loop to reach IDLE_EXIT
var _pending_attack = STATE.NONE


func _init() -> void:
	enemy_name = "Boss"
	idleAnimation = &"Idle"
	randomStartFrame = false
	# the boss has no dissolve and is not pushed by bullets
	dissolveIn = 0.0
	shapesFollowShip = true
	RotationSpeed = TAU
	Life = 15000
	Knockback = 0
	Damage = 100
	IsDamageOverTime = true
	DamageTickTime = 0.5


func _on_ready() -> void:
	_max_life = Life
	_world = get_tree().current_scene

	_weapon = WeaponFactory.get_weapon(Enums.WEAPONS.FIREWORKS, true, false)
	_weapon.set_owner(_world)
	_weapon.register_internal_nodes(self)

	deathTimer.wait_time = 2

	_state_timer.one_shot = true
	_state_timer.wait_time = _state_timeout
	_state_timer.connect("timeout", _on_state_timer_timout)
	add_child(_state_timer)
	_state_timer.start()

	# shots and spawns are timed by the animation frames
	sprite.connect("frame_changed", _on_frame_changed)
	sprite.connect("animation_finished", _on_animation_finished)


func _physics_process(delta: float) -> void:
	if isDead:
		return

	_speed = MoveSpeed

	var direction = global_position.direction_to(player.get_global_position())
	velocity = velocity.move_toward(direction * _speed, Acceleration * 60 * delta)
	_turn_towards(direction, delta)

	move_and_collide(velocity * delta)


func _on_state_timer_timout():
	# the attack starts when the idle loop reaches the frame it continues from
	_pending_attack = _next_attack


func _on_frame_changed():
	if isDead:
		return

	var frame = sprite.frame
	match sprite.animation:
		&"Idle":
			if frame == IDLE_EXIT and _pending_attack != STATE.NONE:
				_start_attack()
		&"ShellHold":
			if frame == HOLD_SHOT_FRAME:
				_shoot()
		&"Summon":
			if frame in SUMMON_SPAWN_FRAMES:
				_spawn_scout()


func _on_animation_finished():
	if isDead:
		return

	match sprite.animation:
		&"ShellOpen":
			sprite.play(&"ShellHold")
		&"ShellClose":
			_back_to_idle(IDLE_AFTER_CLOSE)
		&"Summon":
			_back_to_idle(0)


func _start_attack():
	if _pending_attack == STATE.SHOOT:
		_shot_count = 0
		sprite.play(&"ShellOpen")
		_next_attack = STATE.SPAWN
	else:
		_spawn_count = 0
		sprite.play(&"Summon")
		_next_attack = STATE.SHOOT
	_pending_attack = STATE.NONE


func _back_to_idle(frame : int):
	sprite.play(&"Idle")
	sprite.set_frame_and_progress(frame, 0.0)
	_state_timer.start()


func _shoot():
	# fireworks leave the glowing core, one side per open shell cycle
	_shot_count += 1
	if _shot_count % 2 == 0:
		_weapon.shoot(_world, aim2.get_global_position(), aim2.get_global_position() - aim2_2.get_global_position())
	else:
		_weapon.shoot(_world, aim1.get_global_position(), aim1.get_global_position() - aim1_1.get_global_position())

	# ShellClose starts with this frame, the shell closes without a jump
	if _shot_count >= _max_shots:
		sprite.play(&"ShellClose")


func _spawn_scout():
	_spawn_count += 1
	# spawn scouts around the boss, game logic creates and tracks them
	var angle = ship.rotation + _spawn_count * TAU / _max_spawn
	var offset = Vector2(_spawn_distance, 0).rotated(angle)
	spawn_requested.emit(Enums.ENEMIES.SCOUT, global_position + offset)


func _flash_hit() -> void:
	Juice.flash(sprite, 0.05)


func _damage_from_bullet(bullet):
	return PlayerStatus.get_boss_damage_from_weapon(bullet.Type, _max_life, self, Bullet.damage_scale_of(bullet))


func _label_position(bullet):
	return bullet.get_global_position()


func _on_damage_taken() -> void:
	health_changed.emit(max(Life, 0), _max_life)


func explode() -> void:
	isDead = true
	_state_timer.stop()
	sprite.stop()
	audio.play()
	_disable_body()
	ship.visible = false
	explosion.position = sprite.position
	explosion.SpriteTexture = sprite.get_sprite_frames().get_frame_texture(sprite.animation, sprite.get_frame())
	explosion.scale = sprite.scale
	# the sheet is drawn head right
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.init(Vector2(3.0, 3.0), 250)
	explosion.visible = true
	explosion.explode()
	deathTimer.start()
	killed.emit(get_instance_id())
