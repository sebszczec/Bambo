extends CharacterBody2D

# Boulder Beetle - level 2 kamikaze tank (takes the Guard's place). Crawls at the player
# with a 360 degree scanner around it; when the player enters the scan it brakes, overloads
# and blows up, destroying everything in the blast - the player, other enemies and rocks.
# Walk -> Charge (ChargeA / ChargeB, chosen by the walk frame it leaves) -> blast.
# Shooting it down first only shatters the shell, no blast. Once the charge has started
# it cannot be stopped: bullets do nothing and the player has to run.

var floatingTextScene = preload("res://scenes/floating_text.tscn")

enum STATE { WALK, CHARGE, BLOWN }

# walk frames that lead into a Charge animation through a bridge, the switch has no jump
const EXIT_ANIMATIONS = { 8 : &"ChargeA", 35 : &"ChargeB" }
# the bridge frames still walk, the beetle brakes in the overload
const CHARGE_BRAKE_FRAME = 3
const BASE_DAMAGE = 5.0
const MIN_TRAIL_SPEED = 20.0
const DEAD_FLAGS = ["isDead", "_isDead", "_is_dead"]
# enemy hitboxes (layer 8) and rocks (layer 1)
const BLAST_MASK = 9

@onready var sprite = $Ship/AnimatedSprite2D
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionshape = $HitBox/HitBoxCollisionShape
@onready var lifeBar = $LifeBar
@onready var ship = $Ship
@onready var scan = $Scan
@onready var shock = $Shock
@onready var blast = $Blast
@onready var frostTrail = $Ship/FrostTrail
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D
@onready var chargeAudio = $ChargeAudio
@onready var blastAudio = $BlastAudio
@onready var mark = $Mark

@export_category("Movemement")
@export var RotationSpeed : float = PI
@export var Speed = 70
@export var Acceleration = 300
@export var Knockback = 90
@export var StopDistance = 70.0
@export_category("Blast")
# radius of the scan: the player inside starts the charge, everything inside is hit by the blast
@export var ScanRange = 140.0
@export var BlastDamage = 30
# public - touching the beetle is one hit, the blast is its real attack
@export var Damage = 5
# public
@export var IsDamageOverTime = false
# public
@export var DamageTickTime = 0.5
@export var Life = 120

signal killed

var _theta : float = 0
var _halfPI : float = PI / 2
var showDamage = true
var isDead = false

var player = null
var deathTimer = Timer.new()
var _state = STATE.WALK
var _wants_charge = false
var _blast_pending = false
var _scan_material : ShaderMaterial = null
var _scan_tween : Tween = null

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
	Speed *= randf_range(0.9, 1.1)
	# game_logic scales Damage in endless mode, the blast follows it
	BlastDamage = int(BlastDamage * Damage / BASE_DAMAGE)

	_scan_material = scan.material
	_scan_material.set_shader_parameter("radius", ScanRange)
	_scan_material.set_shader_parameter("phase", randf() * TAU)
	_scan_material.set_shader_parameter("alert", 0.0)

	deathTimer.one_shot = true
	# the fragments fade out in a second, sound and particles are pooled in Juice
	deathTimer.wait_time = 1.2
	deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(deathTimer)

	sprite.connect("frame_changed", _on_frame_changed)
	sprite.connect("animation_finished", _on_animation_finished)

	sprite.play(&"Walk")
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count(&"Walk")

	var dissolveTween = get_tree().create_tween()
	dissolveTween.tween_method(set_shader_dissolve_value, 0.0, 1.0, 0.5)

func set_shader_dissolve_value(value : float):
	_scan_material.set_shader_parameter("DissolveValue", value)
	if Juice.is_flashing(sprite):
		return
	sprite.material.set_shader_parameter("DissolveValue", value)

# public
func get_enemy_name():
	return "Boulder Beetle"

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
	# the shape query of the blast has to run in the physics step
	# (checked first, a nuke sets isDead before it asks a charging beetle to blow)
	if _blast_pending:
		_blow_up()
		return
	if isDead:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()
	var speed = Speed if distance > StopDistance else 0.0
	if _state == STATE.CHARGE:
		# keeps crawling through the bridge frames, then braces
		speed = Speed * 0.5 if sprite.frame < CHARGE_BRAKE_FRAME else 0.0
	velocity = velocity.move_toward(direction * speed, Acceleration * delta)

	# a charging beetle keeps turning to the player, the blast is round anyway
	_theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - _halfPI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(_theta) * sign(_theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)

	if _state == STATE.WALK:
		# the switch waits for an exit frame of the walk cycle (at most ~1.3 s)
		if _wants_charge:
			_wants_charge = distance < ScanRange * 1.5
		elif distance < ScanRange:
			_wants_charge = true

	move_and_slide()

	# frozen smoke only while crawling, the puffs left behind fade out on their own
	var moving = velocity.length() > MIN_TRAIL_SPEED
	if frostTrail.emitting != moving:
		frostTrail.emitting = moving

func _on_frame_changed():
	if isDead:
		return
	if _state == STATE.WALK and _wants_charge and EXIT_ANIMATIONS.has(sprite.frame):
		_start_charge(EXIT_ANIMATIONS[sprite.frame])

func _start_charge(animation : StringName):
	_wants_charge = false
	_state = STATE.CHARGE
	sprite.play(animation)
	Juice.play_sound(chargeAudio)
	# the scan turns amber, it is the blast range, the player sees where to run
	_scan_tween = create_tween()
	_scan_tween.tween_method(_set_scan_alert, 0.0, 1.0, 0.2)

func _set_scan_alert(value : float):
	_scan_material.set_shader_parameter("alert", value)

func _on_animation_finished():
	if isDead or _state != STATE.CHARGE:
		return
	_blast_pending = true

func _blow_up():
	isDead = true
	_state = STATE.BLOWN
	_stop()
	scan.visible = false

	Juice.play_sound(blastAudio)
	Juice.shake(10.0)
	Juice.hitstop(0.06)
	# the shell bursts into its own plates inside the blast, no explosion fragments
	ship.visible = false
	deathTimer.wait_time = blast.fire(ScanRange)
	deathTimer.start()
	shock.fire(ScanRange * 0.6, 0.2)

	if global_position.distance_to(player.global_position) <= ScanRange and player.has_method("take_damage"):
		player.take_damage(BlastDamage)
	_blast_surroundings()

	killed.emit(get_instance_id())

# kills every enemy and breaks every rock in the blast, bosses only shrug it off
func _blast_surroundings():
	var circle = CircleShape2D.new()
	circle.radius = ScanRange
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = BLAST_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [$HitBox.get_rid()]

	var hit = {}
	for result in get_world_2d().direct_space_state.intersect_shape(query, 256):
		var area = result.collider
		if area == null:
			continue
		var target = area.get_parent()
		if hit.has(target):
			continue
		hit[target] = true
		if area.is_in_group("Enemy"):
			_blast_enemy(target)
		elif area.is_in_group("Rock") and target.has_method("handle_destruction") and !target.is_dead:
			target.handle_destruction()

func _blast_enemy(enemy):
	# bosses have a life bar of their own, mines are not counted enemies
	if enemy == self or enemy.has_signal("health_changed") or !enemy.has_signal("killed"):
		return
	# same as game_logic._kill_enemy, the kill still counts for score and xp
	for flag in DEAD_FLAGS:
		if enemy.get(flag):
			return
	for flag in DEAD_FLAGS:
		enemy.set(flag, true)
	enemy.explode()

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return

		Juice.hit_effect(self, bullet.get_global_position())

		# the overloaded shell shrugs bullets off
		if isDead or _state == STATE.CHARGE:
			return

		velocity += bullet.global_position.direction_to(global_position) * Knockback
		Juice.flash(sprite)

		if handleDamage(PlayerStatus.get_damage_from_weapon(bullet.Type)) == false:
			isDead = true
			explode()

# public - shot down (or nuked) before it blew, the shell just breaks
func explode():
	# a nuke or another blast cannot stop the charge either, it only blows now
	if _state == STATE.CHARGE:
		_blast_pending = true
		return
	Juice.play_sound(audio)
	_stop()
	scan.visible = false
	killed.emit(get_instance_id())
	_shatter()

func _stop():
	set_physics_process(false)
	frostTrail.emitting = false
	if _scan_tween != null:
		_scan_tween.kill()
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionshape.set_deferred("disabled", true)
	lifeBar.visible = false

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
