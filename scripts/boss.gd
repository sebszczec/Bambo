extends CharacterBody2D

var floatingTextScene = preload("res://scenes/floating_text.tscn")

@export var Life = 15000
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
@onready var mark = $Mark
@onready var aim1 = $Ship/Aim1
@onready var aim1_1 = $Ship/Aim1_1
@onready var aim2 = $Ship/Aim2
@onready var aim2_2 = $Ship/Aim2_2

var _player = null
var _halfPI : float = PI / 2
var _speed = Vector2(0, 0)
var _is_dead = false
var _show_damage = true
var _death_timer = Timer.new()
var _world = null
var _weapon = null

# idle time between attacks
var _state_timer = Timer.new()
var _state_timeout = 4

var _shot_count = 0
var _max_shots = 6

var _spawn_count = 0
var _max_spawn = 5
var _spawn_distance = 240
var _max_life = 0

# frames of resources/skullboss/skull_animations.json
# Idle frame that ShellOpen and Summon continue from (both start with it)
const IDLE_EXIT = 39
# Idle frame that follows the last ShellClose frame
const IDLE_AFTER_CLOSE = 19
# ShellHold frame with the shell fully open, ShellClose starts with it
const HOLD_SHOT_FRAME = 7
# Summon frames with raised antennae, one scout each
const SUMMON_SPAWN_FRAMES = [10, 15, 20, 25, 30]

signal killed
signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)
signal health_changed(value : int, max_value : int)

enum STATE {NONE, SHOOT, SPAWN}
var _next_attack = STATE.SHOOT
# attack waiting for the idle loop to reach IDLE_EXIT
var _pending_attack = STATE.NONE

# public
func get_enemy_name():
	return "Boss"

# public
func setup_rotation(angle):
	ship.rotate(angle)
	collisionShape.rotation = ship.rotation
	hitBoxCollisionShape.rotation = ship.rotation
	
# public
func set_mark():
	mark.activate(1.0)

func _ready() -> void:
	var visualSettings = ConfigHandler.load_visuals()
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	_show_damage = visualSettings["show_damage_given"]
	lifeBar.setColor(Color.GREEN)
	lifeBar.setMaxValue(Life)
	_max_life = Life
	lifeBar.setValue(Life)
	
	_world = get_tree().current_scene
	_player = get_tree().get_first_node_in_group("player")
	
	_weapon = WeaponFactory.get_weapon(Enums.WEAPONS.FIREWORKS, true, false)
	_weapon.set_owner(_world)
	_weapon.register_internal_nodes(self)
	
	_death_timer.one_shot = true
	_death_timer.wait_time = 2
	_death_timer.connect("timeout", _on_death_timer_timeout)
	add_child(_death_timer)
	
	_state_timer.one_shot = true
	_state_timer.wait_time = _state_timeout
	_state_timer.connect("timeout", _on_state_timer_timout)
	add_child(_state_timer)
	_state_timer.start()

	# shots and spawns are timed by the animation frames
	mainBody.connect("frame_changed", _on_frame_changed)
	mainBody.connect("animation_finished", _on_animation_finished)
	mainBody.play(&"Idle")

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_speed = MoveSpeed

	var direction = global_position.direction_to(_player.get_global_position())
	velocity = velocity.move_toward(direction * _speed, Acceleration * 60 * delta)
	
	var theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(theta) * sign(theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)
	# the beetle is long, its shapes turn with it
	collisionShape.rotation = ship.rotation
	hitBoxCollisionShape.rotation = ship.rotation

	move_and_collide(velocity * delta)

func _on_state_timer_timout():
	# the attack starts when the idle loop reaches the frame it continues from
	_pending_attack = _next_attack

func _on_frame_changed():
	if _is_dead:
		return

	var frame = mainBody.frame
	match mainBody.animation:
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
	if _is_dead:
		return

	match mainBody.animation:
		&"ShellOpen":
			mainBody.play(&"ShellHold")
		&"ShellClose":
			_back_to_idle(IDLE_AFTER_CLOSE)
		&"Summon":
			_back_to_idle(0)

func _start_attack():
	if _pending_attack == STATE.SHOOT:
		_shot_count = 0
		mainBody.play(&"ShellOpen")
		_next_attack = STATE.SPAWN
	else:
		_spawn_count = 0
		mainBody.play(&"Summon")
		_next_attack = STATE.SHOOT
	_pending_attack = STATE.NONE

func _back_to_idle(frame : int):
	mainBody.play(&"Idle")
	mainBody.set_frame_and_progress(frame, 0.0)
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
		mainBody.play(&"ShellClose")

func _spawn_scout():
	_spawn_count += 1
	# spawn scouts around the boss, game logic creates and tracks them
	var angle = ship.rotation + _spawn_count * TAU / _max_spawn
	var offset = Vector2(_spawn_distance, 0).rotated(angle)
	spawn_requested.emit(Enums.ENEMIES.SCOUT, global_position + offset)

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


		Juice.hit_effect(self, bullet.get_global_position())

		if _is_dead:
			return

		var damage = PlayerStatus.get_boss_damage_from_weapon(bullet.Type, _max_life)
		Juice.flash(mainBody, 0.05)

		if handleDamage(damage, bullet.get_global_position()) == false:
			_is_dead = true
			explode()

func explode():
	_state_timer.stop()
	mainBody.stop()
	audio.play()
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false
	ship.visible = false
	explosion.position = mainBody.position
	explosion.SpriteTexture = mainBody.get_sprite_frames().get_frame_texture(mainBody.animation, mainBody.get_frame())
	explosion.scale = mainBody.scale
	# the sheet is drawn head right
	explosion.rotation = ship.rotation + mainBody.rotation
	explosion.init(Vector2(3.0, 3.0), 250)
	explosion.visible = true
	explosion.explode()
	_death_timer.start()
	killed.emit(get_instance_id())

func handleDamage(damage, label_position : Vector2):
	if _show_damage and FloatingText.can_spawn(damage.Critical):
		var damageText = floatingTextScene.instantiate()
		damageText.RoundNumber = true
		damageText.Big = damage.Critical
		if damage.Critical:
			damageText.set_color(Color.YELLOW)
		else:
			damageText.set_color(Color.WHITE)
			
		damageText.Amount = str(damage.Value)
		add_child(damageText)
		damageText.set_global_position(label_position)
		
	Life = Life - damage.Value
	lifeBar.setValue(Life)
	health_changed.emit(max(Life, 0), _max_life)
	
	if Life <= 0:
		return false
	
	return true
