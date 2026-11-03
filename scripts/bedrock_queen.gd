extends CharacterBody2D

# Final boss of level 2 - the Bedrock Queen, a colossal trilobite of the rock brood.
# It drifts after the player and cycles through four attacks:
#  - brood: the rear plates lift, the egg sacs swell and hatch pebble mites
#  - beam: the X-crack charges and a cyan beam fires from the head
#  - crown spines: a ring of rock shards from the whole shell (a full circle)
#  - quake: the queen shudders, rock plates drop around the player
# Below half life it is enraged: faster, a second brood, a double crown and more rocks.
# Faces the player with its +Y side. The sheet draws the queen head-left, so the sprite
# is turned by -90 degrees. Animations come from one Gemini take (see
# resources/levels/level2/enemies/bedrock_queen/bedrock_queen_animations.json), the idle is a ping-pong loop.

var floatingTextScene = preload("res://scenes/floating_text.tscn")
const MantisRock = preload("res://scripts/mantis_rock.gd")

@export var Life = 16000
@export var Damage = 100
@export var IsDamageOverTime = true
@export var DamageTickTime = 0.5
@export var MoveSpeed = 70
@export var Acceleration = 4
@export var RotationSpeed : float = PI * 0.6
# the queen keeps this distance to the player while drifting
@export var KeepDistance = 420.0

# Damage is what game_logic scales, attacks that are not contact damage follow it
const BASE_DAMAGE = 100
const CROSSFADE_TIME = 0.15
const ENRAGED_COLOR = Color(1.25, 0.95, 0.8)
# frame indices of the animations (not of the sheet) where gameplay happens
# the Brood animation starts at sheet frame 40, the plates open at sheet frame 84
const BROOD_HATCH_FRAMES = [44, 56]
const BROOD_HATCH_FRAMES_ENRAGED = [44, 52, 60]
# the Beam animation charges for 43 frames at 30 fps
const LASER_CHARGE_TIME = 1.43
const LASER_FIRE_TIME = 2.0
const BEAM_TURN_ENRAGED = 0.18
# crown spines: one shard per direction of the ring
const SPINE_COUNT = 12
const SPINE_COUNT_ENRAGED = 16
const SPINE_SPEED = 6
const QUAKE_WINDUP = 0.9
const ROCK_RADIUS = 72.0
const HUNTER_PACK = 3
const BROOD_COUNT = 3
const BROOD_COUNT_ENRAGED = 4
# the debris atlas is 0.1 of the parts image, the parts image ~0.2 of the game size
const DEBRIS_SCALE = 2.0

@onready var ship = $Ship
@onready var sprite = $Ship/AnimatedSprite2D
@onready var ghost = $Ship/Ghost
@onready var mouthGlow = $Ship/MouthGlow
@onready var muzzle = $Ship/Muzzle
@onready var laser = $Ship/Laser
@onready var lifeBar = $LifeBar
@onready var audio = $AudioStreamPlayer2D
@onready var broodAudio = $SlashAudio
@onready var rockAudio = $RockAudio
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/CollisionShape2D
@onready var blast = $Blast
@onready var explosion = $Explosion
@onready var mark = $Mark

enum ATTACK {BROOD, BEAM, SPINES, QUAKE}

var _player = null
var _world = null
var _spit = null
var _is_dead = false
var _show_damage = true
var _max_life = 0
var _enraged = false
var _moving = false
var _keep_distance = 0.0
var _turn_speed : float = 0.0
var _last_attack = -1
var _next_hurt_life = 0
var _ai_timer = Timer.new()
var _death_timer = Timer.new()
var _shown_animation = &"Idle"
var _shown_frame = 0
var _ghost_tween : Tween = null
var _mouth_tween : Tween = null

signal killed
signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)
signal health_changed(value : int, max_value : int)
signal enraged

# public
func get_enemy_name():
	return "Bedrock Queen"

# public
func setup_rotation(angle):
	_set_rotation(ship.rotation + angle)

# public
func set_mark():
	mark.activate(1.0)

func _ready() -> void:
	var visualSettings = ConfigHandler.load_visuals()
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	_show_damage = visualSettings["show_damage_given"]
	lifeBar.setColor(Color(0.4, 0.85, 0.95))
	lifeBar.setMaxValue(Life)
	lifeBar.setValue(Life)
	_max_life = Life
	_next_hurt_life = Life * 0.9
	_keep_distance = KeepDistance

	laser.Damage = int(laser.Damage * Damage / BASE_DAMAGE)
	laser.set_colors(Color(0.2, 0.75, 1.0), Color(1.0, 2.0, 2.4), Color(1.6, 0.6, 0.4))

	_world = get_tree().current_scene
	_player = get_tree().get_first_node_in_group("player")

	_spit = WeaponFactory.get_weapon(Enums.WEAPONS.WORM_SPIT, true, false)
	_spit.bullet_scene = preload("res://scenes/mantis_shard.tscn")
	_spit.speed = SPINE_SPEED
	_spit.set_owner(_world)
	_spit.register_internal_nodes(self)

	blast.get_node("Debris").texture = preload("res://resources/levels/level2/enemies/bedrock_queen/bedrock_queen_shards.png")

	_ai_timer.one_shot = true
	add_child(_ai_timer)

	_death_timer.one_shot = true
	_death_timer.wait_time = 2.5
	_death_timer.connect("timeout", dispose)
	add_child(_death_timer)

	sprite.connect("animation_changed", _on_animation_changed)
	sprite.connect("frame_changed", _on_frame_changed)
	sprite.play("Idle")

	_run_ai()

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	var to_player = _player.global_position - global_position
	var direction = to_player.normalized()

	var target = Vector2.ZERO
	if _moving:
		if to_player.length() > _keep_distance:
			target = direction * MoveSpeed
		else:
			target = -direction * MoveSpeed * 0.5

	velocity = velocity.move_toward(target, Acceleration * 60 * delta)

	var theta = wrapf(direction.angle() - PI / 2 - ship.rotation, -PI, PI)
	var step = _turn_speed * delta
	_set_rotation(ship.rotation + clamp(theta, -step, step))

	move_and_collide(velocity * delta)

func _set_rotation(angle : float):
	ship.rotation = angle
	collisionShape.rotation = angle
	hitBoxCollisionShape.rotation = angle

func _facing() -> Vector2:
	return Vector2.DOWN.rotated(ship.rotation)

func _cooldown_factor() -> float:
	return 0.7 if _enraged else 1.0

# the timer is a child of the boss, a coroutine waiting on it
# simply never resumes when the boss is freed
func _wait(seconds : float):
	_ai_timer.start(seconds)
	await _ai_timer.timeout

func _run_ai():
	await _wait(1.5)
	while !_is_dead:
		var attack = _pick_attack()
		_last_attack = attack
		_keep_distance = KeepDistance
		await _drift(randf_range(1.6, 2.6) * _cooldown_factor())
		if _is_dead:
			return

		if attack == ATTACK.BROOD:
			await _attack_brood()
		elif attack == ATTACK.BEAM:
			await _attack_beam()
		elif attack == ATTACK.SPINES:
			await _attack_spines()
		else:
			await _attack_quake()
		if _is_dead:
			return

		_play_idle()
		await _wait(0.8 * _cooldown_factor())

func _pick_attack() -> int:
	var options = [ATTACK.BROOD, ATTACK.BEAM, ATTACK.SPINES, ATTACK.QUAKE]
	options.erase(_last_attack)
	var distance = global_position.distance_to(_player.global_position)
	# the beam needs the player in front of it, the crown is for a close player
	if distance > 800:
		options.erase(ATTACK.SPINES)
	if distance > 900:
		options.erase(ATTACK.BEAM)
	return options.pick_random()

# drifts toward the keep distance with the idle loop for `duration` seconds
func _drift(duration : float):
	_moving = true
	_play_idle()
	await _wait(duration)
	_moving = false

func _play_idle():
	if sprite.animation != &"Idle":
		sprite.play(&"Idle")

# the rear plates lift, the egg sacs swell and hatch pebble mites on both sides
func _attack_brood():
	_turn_speed = RotationSpeed * 0.3
	sprite.play(&"Brood")
	var hatches = BROOD_HATCH_FRAMES_ENRAGED if _enraged else BROOD_HATCH_FRAMES
	var count = BROOD_COUNT_ENRAGED if _enraged else BROOD_COUNT
	for frame in hatches:
		await _await_frame(&"Brood", frame)
		if _is_dead or sprite.animation != &"Brood":
			return
		_hatch(count)
	if sprite.animation == &"Brood" and sprite.is_playing():
		await sprite.animation_finished
	_turn_speed = RotationSpeed

# waits until the animation shows `frame` (or plays something else)
func _await_frame(animation : StringName, frame : int):
	while !_is_dead and sprite.animation == animation and sprite.frame < frame and sprite.is_playing():
		await sprite.frame_changed

func _hatch(count : int):
	Juice.play_sound(broodAudio)
	Juice.shake(3.0)
	for i in range(count):
		# eggs sit under the rear plates: tail is -Y in the ship's frame
		var local = Vector2(randf_range(-170, 170), randf_range(-200, -120))
		spawn_requested.emit(Enums.ENEMIES.SCOUT, ship.to_global(local))
	_spawn_flash(ship.to_global(Vector2(0, -160)), Color(0.5, 1.4, 1.8), 0.7, 0.4)

# the X-crack charges, the beam is locked on the player's direction, then it fires
func _attack_beam():
	_turn_speed = RotationSpeed
	sprite.play(&"BeamCharge")
	mouthGlow.visible = true
	mouthGlow.scale = Vector2.ONE * 0.05
	_mouth_tween = create_tween()
	_mouth_tween.tween_property(mouthGlow, "scale", Vector2.ONE * 0.26, LASER_CHARGE_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	laser.fire(LASER_CHARGE_TIME, LASER_FIRE_TIME)

	await laser.beam_started
	if _is_dead:
		return
	_turn_speed = RotationSpeed * BEAM_TURN_ENRAGED if _enraged else 0.0
	sprite.play(&"BeamFire")
	Juice.shake(6.0)

	await laser.finished
	mouthGlow.visible = false
	_turn_speed = RotationSpeed
	if _is_dead:
		return
	sprite.play(&"BeamEnd")
	await sprite.animation_finished

# the shell throws a full ring of rock spines around itself
func _attack_spines():
	_turn_speed = RotationSpeed * 0.4
	sprite.play(&"Idle")
	Juice.shake(3.0)
	await _wait(0.5)
	if _is_dead:
		return
	var rings = 2 if _enraged else 1
	var count = SPINE_COUNT_ENRAGED if _enraged else SPINE_COUNT
	for ring in range(rings):
		_fire_ring(count, ring * 0.5 * TAU / count)
		Juice.play_sound(rockAudio)
		await _wait(0.45)
		if _is_dead:
			return
	_turn_speed = RotationSpeed

func _fire_ring(count : int, offset : float):
	_spit.count = 1
	_spit.spread = 0.0
	for i in range(count):
		var dir = Vector2.RIGHT.rotated(TAU * i / count + offset)
		_spit.canShoot = true
		_spit.shoot(_world, global_position, dir)
	_spawn_flash(global_position, Color(0.5, 1.4, 1.8), 0.9, 0.3)
	Juice.shake(4.0)

# the body shudders and rock plates drop around the player
func _attack_quake():
	_turn_speed = RotationSpeed * 0.5
	sprite.play(&"Idle")
	Juice.shake(5.0)
	await _wait(QUAKE_WINDUP)
	if _is_dead:
		return
	Juice.play_sound(rockAudio)
	Juice.shake(5.0)

	var count = 9 if _enraged else 6
	var warn_time = 0.9 if _enraged else 1.1
	# the first rock falls where the player will be, the others around
	var center = _player.global_position
	var lead = _player.velocity * warn_time * 0.8
	for i in range(count):
		if _is_dead:
			return
		var pos = center + lead if i == 0 else center + Vector2(randf_range(90, 340), 0).rotated(randf() * TAU)
		_drop_rock(pos, warn_time)
		await _wait(0.07)
	_turn_speed = RotationSpeed

func _drop_rock(pos : Vector2, warn_time : float):
	var rock = MantisRock.new()
	rock.setup(ROCK_RADIUS * randf_range(0.85, 1.15), 45, warn_time)
	rock.position = pos
	rock.connect("landed", _on_rock_landed)
	_world.add_child(rock)

func _on_rock_landed():
	if !_is_dead:
		Juice.play_sound(rockAudio)

# additive light that grows and fades, left in the world
func _spawn_flash(pos : Vector2, color : Color, size : float, duration : float):
	var flash = Sprite2D.new()
	flash.texture = mouthGlow.texture
	flash.material = mouthGlow.material
	flash.modulate = color
	flash.position = pos
	flash.scale = Vector2.ONE * size * 0.3
	_world.add_child(flash)

	var tween = flash.create_tween().set_parallel()
	tween.tween_property(flash, "scale", Vector2.ONE * size, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(flash.queue_free)

# frame_changed of the new animation can come first, it is ignored then
func _on_frame_changed():
	if sprite.animation == _shown_animation:
		_shown_frame = sprite.frame

func _on_animation_changed():
	ghost.texture = sprite.sprite_frames.get_frame_texture(_shown_animation, _shown_frame)
	_shown_animation = sprite.animation
	_shown_frame = sprite.frame

	if _ghost_tween:
		_ghost_tween.kill()
	ghost.visible = true
	ghost.modulate.a = 1.0
	_ghost_tween = create_tween()
	_ghost_tween.tween_property(ghost, "modulate:a", 0.0, CROSSFADE_TIME)
	_ghost_tween.tween_callback(ghost.hide)

func _enrage():
	_enraged = true
	MoveSpeed *= 1.3
	create_tween().tween_property(ship, "modulate", ENRAGED_COLOR, 0.6)
	_spawn_flash(global_position, Color(1.8, 0.9, 0.5), 1.2, 0.6)
	Juice.shake(10.0)
	# the brood answers its call
	for i in range(HUNTER_PACK):
		var offset = Vector2(randf_range(300, 450), 0).rotated(TAU * i / HUNTER_PACK + randf() * 0.5)
		spawn_requested.emit(Enums.ENEMIES.HUNTER, global_position + offset)
	enraged.emit()

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

		var damage = PlayerStatus.get_boss_damage_from_weapon(bullet.Type, _max_life, self)
		Juice.flash(sprite, 0.05)

		if handleDamage(damage, bullet.get_global_position()) == false:
			_is_dead = true
			explode()

func explode():
	_ai_timer.stop()
	laser.stop()
	_moving = false
	velocity = Vector2.ZERO
	mouthGlow.visible = false
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false

	# the shell cracks, shakes and goes dark, then it bursts
	create_tween().tween_method(_death_shake, 1.0, 0.0, 1.2)
	var fade = create_tween()
	fade.tween_property(sprite, "modulate", Color(0.3, 0.3, 0.35), 1.2)
	Juice.shake(6.0)
	await fade.finished

	audio.play()
	ship.visible = false
	blast.rotation = ship.rotation
	blast.fire(170.0)
	_fling_debris()
	explosion.position = sprite.position
	explosion.SpriteTexture = sprite.get_sprite_frames().get_frame_texture(&"Idle", 0)
	explosion.scale = sprite.scale
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.init(Vector2(3.0, 3.0), 250)
	explosion.visible = true
	explosion.explode()
	_spawn_flash(global_position, Color(0.8, 1.6, 1.9), 1.4, 0.7)
	_death_timer.start()
	killed.emit(get_instance_id())

func _death_shake(strength : float):
	ship.position = Vector2(randf_range(-10, 10), randf_range(-10, 10)) * strength

# the big plates of the shell (first cells of the debris atlas) tumble away
func _fling_debris():
	var atlas = blast.get_node("Debris").texture
	for cell in range(10):
		var texture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2((cell % 4) * 128, (cell / 4) * 128, 128, 128)

		var piece = Sprite2D.new()
		piece.texture = texture
		piece.scale = Vector2.ONE * DEBRIS_SCALE
		piece.position = global_position + _facing().rotated(randf_range(-0.4, 0.4)) * randf_range(-200, 200)
		piece.rotation = randf() * TAU
		piece.modulate = ship.modulate
		_world.add_child(piece)

		var target = piece.position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(220, 460)
		var tween = piece.create_tween().set_parallel()
		tween.tween_property(piece, "position", target, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "rotation", piece.rotation + randf_range(-5, 5), 1.8)
		tween.tween_property(piece, "modulate:a", 0.0, 1.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(piece.queue_free)

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

	if !_enraged and Life < _max_life * 0.5:
		_enrage()

	# no flinch clip, the stone just shudders
	if Life < _next_hurt_life:
		_next_hurt_life -= _max_life * 0.1
		Juice.shake(2.0)

	return true
