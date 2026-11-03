extends CharacterBody2D

# Mid boss of level 2 - the Quarry Mantis, a giant stone mantis of the rock brood.
# It stalks the player and cycles through four attacks:
#  - scythe lunge: a wedge marks its path, then it dashes and crosses both scythes
#  - shard spit: spreads of rock shards from the mouth
#  - chest beam: the chest crack charges, a cyan beam fires from the mouth
#  - rockfall: the scythes strike, plates of rock drop on marked spots around the player
# Below half life it is enraged: faster, more shards and rocks, a double lunge,
# a sweeping beam, and it calls a pack of hunters (shard wasps in level 2).
# Faces the player with its +Y side, the sheet draws the mantis head-right so the
# sprite is turned by 90 degrees. Animations come from one Gemini take (see
# resources/levels/level2/enemies/quarry_mantis/quarry_mantis_animations.json), the chase uses the
# planned move -> attack switches of the worm boss.

var floatingTextScene = preload("res://scenes/floating_text.tscn")
const MantisRock = preload("res://scripts/mantis_rock.gd")

@export var Life = 16000
@export var Damage = 100
@export var IsDamageOverTime = true
@export var DamageTickTime = 0.5
@export var MoveSpeed = 95
@export var Acceleration = 7
@export var RotationSpeed : float = PI * 0.8
# the mantis keeps this distance to the player while stalking
@export var KeepDistance = 340.0
@export var SlashDamage = 60
@export var RockDamage = 45

# Damage is what game_logic scales, attacks that are not contact damage follow it
const BASE_DAMAGE = 100
const SPRITE_SCALE = 1.2
const HURT_STEP = 0.1
const CROSSFADE_TIME = 0.15
const MOVE_ANIM_SCALE_MIN = 0.75
const MOVE_ANIM_SCALE_MAX = 1.35
const ENRAGED_COLOR = Color(1.2, 1.0, 0.88)
# frames of the animations (not of the sheet) where gameplay happens
const SLASH_DASH_FRAME = 9
const SLASH_HIT_FRAME = 15
const SPIT_FRAMES = [19, 22, 25]
# angle between two shards of a volley
const SPIT_STEP = 0.2
# the lunge: dash length = speed * time, then the scythes reach this far in front
const DASH_SPEED = 1250.0
const DASH_TIME = 0.2
const SLASH_REACH = 280.0
const SLASH_HALF_ANGLE = 0.95
const SLASH_KEEP_DISTANCE = 260.0
const DASH_STOP_DISTANCE = 190.0
const LASER_CHARGE_TIME = 0.9
const LASER_FIRE_TIME = 1.8
const ROCK_RADIUS = 72.0
const HUNTER_PACK = 3
# the debris atlas is 0.1 of the parts image, the parts image ~0.18 of the game size
const DEBRIS_SCALE = 1.7

@onready var ship = $Ship
@onready var sprite = $Ship/AnimatedSprite2D
@onready var ghost = $Ship/Ghost
@onready var slashWarning = $Ship/SlashWarning
@onready var mouthGlow = $Ship/MouthGlow
@onready var muzzle = $Ship/Muzzle
@onready var laser = $Ship/Laser
@onready var lifeBar = $LifeBar
@onready var audio = $AudioStreamPlayer2D
@onready var slashAudio = $SlashAudio
@onready var rockAudio = $RockAudio
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/CollisionShape2D
@onready var blast = $Blast
@onready var explosion = $Explosion
@onready var mark = $Mark

enum ATTACK {SLASH, SPIT, BEAM, ROCKFALL}
const ATTACK_ANIMATIONS = {ATTACK.SLASH: &"Slash", ATTACK.SPIT: &"Spit", ATTACK.BEAM: &"BeamCharge", ATTACK.ROCKFALL: &"Slash"}

var _player = null
var _world = null
var _spit = null
var _is_dead = false
var _show_damage = true
var _max_life = 0
var _enraged = false
var _moving = false
var _dashing = false
var _keep_distance = 0.0
var _turn_speed : float = 0.0
var _last_attack = -1
var _next_hurt_life = 0
var _ai_timer = Timer.new()
var _death_timer = Timer.new()
var _shown_animation = &"Idle"
var _shown_frame = 0
var _ghost_tween : Tween = null
var _seamless = false
var _move_speed_scale = 1.0
var _move_exit_frame = 0

signal killed
signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)
signal health_changed(value : int, max_value : int)
signal enraged

# public
func get_enemy_name():
	return "Quarry Mantis"

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
	_next_hurt_life = Life * (1.0 - HURT_STEP)
	_turn_speed = RotationSpeed
	_keep_distance = KeepDistance

	SlashDamage = int(SlashDamage * Damage / BASE_DAMAGE)
	RockDamage = int(RockDamage * Damage / BASE_DAMAGE)
	laser.Damage = int(laser.Damage * Damage / BASE_DAMAGE)
	laser.set_colors(Color(0.2, 0.75, 1.0), Color(1.0, 2.0, 2.4), Color(1.6, 0.6, 0.4))

	_world = get_tree().current_scene
	_player = get_tree().get_first_node_in_group("player")

	_spit = WeaponFactory.get_weapon(Enums.WEAPONS.WORM_SPIT, true, false)
	_spit.bullet_scene = preload("res://scenes/mantis_shard.tscn")
	_spit.speed = 6
	_spit.set_owner(_world)
	_spit.register_internal_nodes(self)

	blast.get_node("Debris").texture = preload("res://resources/levels/level2/enemies/quarry_mantis/mantis_shards.png")
	_build_slash_warning()

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
	if _dashing:
		# the scythes hit in front, running over the player would only add contact damage
		if to_player.length() < DASH_STOP_DISTANCE:
			velocity = velocity.normalized() * MoveSpeed
		move_and_collide(velocity * delta)
		return

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

# the wedge is the real danger zone: the dash path, then the scythe sector around the dash end
func _build_slash_warning():
	var dash = DASH_SPEED * DASH_TIME
	var points = PackedVector2Array([Vector2(-60, 80), Vector2(60, 80), Vector2(60, dash)])
	for i in range(13):
		var a = lerp(-SLASH_HALF_ANGLE, SLASH_HALF_ANGLE, i / 12.0)
		points.append(Vector2(0, dash) + Vector2(0, SLASH_REACH).rotated(a))
	points.append(Vector2(-60, dash))
	slashWarning.polygon = points
	slashWarning.visible = false

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

# waits until the animation shows `frame` (or plays something else)
func _await_frame(animation : StringName, frame : int):
	while !_is_dead and sprite.animation == animation and sprite.frame < frame and sprite.is_playing():
		await sprite.frame_changed

func _run_ai():
	await _wait(1.2)
	while !_is_dead:
		# picked before the chase, so the move loop can end on the frame leading into it
		var attack = _pick_attack()
		_last_attack = attack
		_keep_distance = SLASH_KEEP_DISTANCE if attack == ATTACK.SLASH else KeepDistance
		await _chase(randf_range(1.4, 2.4) * _cooldown_factor(), ATTACK_ANIMATIONS[attack])
		if _is_dead:
			return

		if attack == ATTACK.SLASH:
			await _attack_slash()
			if _enraged and !_is_dead:
				await _attack_slash()
		elif attack == ATTACK.SPIT:
			await _attack_spit()
		elif attack == ATTACK.BEAM:
			await _attack_beam()
		else:
			await _attack_rockfall()
		if _is_dead:
			return

		_play_matched(&"Idle")
		await _wait(0.6 * _cooldown_factor())

func _pick_attack() -> int:
	var options = [ATTACK.SLASH, ATTACK.SPIT, ATTACK.BEAM, ATTACK.ROCKFALL]
	options.erase(_last_attack)
	var distance = global_position.distance_to(_player.global_position)
	# close - the scythes, far away - the beam or the rocks
	if distance < 420 and options.has(ATTACK.SLASH) and randf() < 0.5:
		return ATTACK.SLASH
	if distance > 750:
		options.erase(ATTACK.SLASH)
	return options.pick_random()

func _chase(duration : float, next_animation : StringName):
	_moving = true
	# the move loop starts on the frame that continues the current pose and has to
	# sit on the exit frame of the next animation when the chase ends
	# (entry and exit frames are stored in the SpriteFrames metadata)
	_move_exit_frame = sprite.sprite_frames.get_meta("exit_Move")[next_animation]
	var start = _play_move()
	duration = _plan_move(start, duration, duration * 0.6)
	await _wait(duration)
	await _reach_frame(&"Move", _move_exit_frame, 3)
	_moving = false
	_seamless = sprite.animation == &"Move" and sprite.frame == _move_exit_frame

func _play_move() -> int:
	var entry = sprite.sprite_frames.get_meta("entry_Move")
	var start = entry[_shown_animation][_shown_frame] if entry.has(_shown_animation) else 0
	sprite.play(&"Move")
	sprite.frame = start
	return start

# sets the loop speed so it reaches the exit frame in about `duration`,
# returns the real duration (one or two loops, never shorter than min_duration if possible)
func _plan_move(start : int, duration : float, min_duration : float) -> float:
	var frames = sprite.sprite_frames
	var count = frames.get_frame_count(&"Move")
	var fps = frames.get_animation_speed(&"Move")
	var steps = posmod(_move_exit_frame - start, count)
	var best = -1.0
	for n in [steps, steps + count]:
		if n == 0:
			continue
		var anim_scale = clamp(n / (fps * duration), MOVE_ANIM_SCALE_MIN, MOVE_ANIM_SCALE_MAX)
		var d = n / (fps * anim_scale)
		var long_enough = d >= min_duration
		var better = best < 0.0
		if !better and long_enough != (best >= min_duration):
			better = long_enough
		elif !better:
			better = abs(d - duration) < abs(best - duration)
		if better:
			best = d
			_move_speed_scale = anim_scale
	sprite.speed_scale = _move_speed_scale
	return best

# timer and animation can drift by a frame, waits a few frames at most
func _reach_frame(animation : StringName, frame : int, max_frames : int):
	for i in range(max_frames):
		if sprite.animation != animation or sprite.frame == frame:
			return
		await sprite.frame_changed

# starts an animation on the frame that best continues the last shown one (entry_ tables)
func _play_matched(animation : StringName):
	if sprite.animation == animation and sprite.is_playing():
		return
	var entry = sprite.sprite_frames.get_meta("entry_" + animation)
	var from = _shown_animation
	var frame = _shown_frame
	sprite.play(animation)
	if entry.has(from):
		sprite.frame = entry[from][frame]

# scythes rise while a wedge marks the path, a short dash, then both scythes cross in front
func _attack_slash():
	_turn_speed = RotationSpeed * 1.2
	sprite.play(&"Slash")
	slashWarning.visible = true
	slashWarning.modulate.a = 0.0
	create_tween().tween_property(slashWarning, "modulate:a", 1.0, 0.25)

	await _await_frame(&"Slash", SLASH_DASH_FRAME)
	if _is_dead:
		return
	slashWarning.visible = false
	_turn_speed = 0.0
	Juice.play_sound(slashAudio)
	_dashing = true
	velocity = _facing() * DASH_SPEED
	await _wait(DASH_TIME)
	_dashing = false
	velocity = _facing() * MoveSpeed
	if _is_dead:
		return

	await _await_frame(&"Slash", SLASH_HIT_FRAME)
	if _is_dead:
		return
	_slash_hit()
	if sprite.animation == &"Slash" and sprite.is_playing():
		await sprite.animation_finished
	_turn_speed = RotationSpeed

func _slash_hit():
	Juice.shake(4.0)
	var to_player = _player.global_position - global_position
	if to_player.length() < SLASH_REACH and abs(_facing().angle_to(to_player)) < SLASH_HALF_ANGLE:
		_player.take_damage(SlashDamage)
		Juice.hitstop(0.06)

func _attack_spit():
	_turn_speed = RotationSpeed * 0.6
	sprite.play(&"Spit")
	# same step in every volley, odd and even counts interleave, so the second volley fills the gaps
	var volleys = [7, 6] if !_enraged else [9, 8, 9]
	var step = SPIT_STEP if !_enraged else SPIT_STEP * 0.85
	for i in range(volleys.size()):
		await _await_frame(&"Spit", SPIT_FRAMES[i])
		if _is_dead or sprite.animation != &"Spit":
			return
		_fire_spread(volleys[i], step)
	if sprite.is_playing():
		await sprite.animation_finished
	_turn_speed = RotationSpeed

func _fire_spread(count : int, step : float):
	_spit.count = count
	_spit.spread = step
	_spit.canShoot = true
	_spit.shoot(_world, muzzle.global_position, _facing())
	_spawn_flash(muzzle.global_position, Color(0.5, 1.4, 1.8), 0.12, 0.15)
	Juice.shake(1.5)

func _attack_beam():
	# aims while charging, then the beam is locked (or sweeps after the player when enraged)
	_turn_speed = RotationSpeed
	sprite.play(&"BeamCharge")
	mouthGlow.visible = true
	mouthGlow.scale = Vector2.ONE * 0.05
	create_tween().tween_property(mouthGlow, "scale", Vector2.ONE * 0.22, LASER_CHARGE_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	laser.fire(LASER_CHARGE_TIME, LASER_FIRE_TIME * (1.25 if _enraged else 1.0))

	await laser.beam_started
	if _is_dead:
		return
	_turn_speed = RotationSpeed * 0.18 if _enraged else 0.0
	sprite.play(&"BeamFire")
	Juice.shake(6.0)

	await laser.finished
	mouthGlow.visible = false
	_turn_speed = RotationSpeed
	if _is_dead:
		return
	sprite.play(&"BeamEnd")
	await sprite.animation_finished

# the scythes strike the ground, rock plates drop around the player
func _attack_rockfall():
	_turn_speed = RotationSpeed * 0.5
	sprite.play(&"Slash")
	await _await_frame(&"Slash", SLASH_HIT_FRAME)
	if _is_dead:
		return
	Juice.play_sound(slashAudio)
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

	if sprite.animation == &"Slash" and sprite.is_playing():
		await sprite.animation_finished
	_turn_speed = RotationSpeed

func _drop_rock(pos : Vector2, warn_time : float):
	var rock = MantisRock.new()
	rock.setup(ROCK_RADIUS * randf_range(0.85, 1.15), RockDamage, warn_time)
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
	sprite.speed_scale = _move_speed_scale if sprite.animation == &"Move" else 1.0

	if _seamless:
		_seamless = false
		return

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
	_spawn_flash(global_position, Color(1.8, 0.9, 0.5), 0.9, 0.6)
	# the brood answers its call
	for i in range(HUNTER_PACK):
		var offset = Vector2(randf_range(250, 400), 0).rotated(TAU * i / HUNTER_PACK + randf() * 0.5)
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
	_dashing = false
	velocity = Vector2.ZERO
	mouthGlow.visible = false
	slashWarning.visible = false
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false

	# the stone body cracks and falls apart, then the shell bursts
	sprite.play(&"Death")
	create_tween().tween_method(_death_shake, 1.0, 0.0, 1.0)
	Juice.shake(6.0)

	await sprite.animation_finished
	audio.play()
	ship.visible = false
	blast.rotation = ship.rotation
	blast.fire(170.0)
	_fling_debris()
	explosion.position = sprite.position
	explosion.SpriteTexture = sprite.get_sprite_frames().get_frame_texture(&"Death", 0)
	explosion.scale = sprite.scale
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.init(Vector2(3.0, 3.0), 250)
	explosion.visible = true
	explosion.explode()
	_spawn_flash(global_position, Color(0.8, 1.6, 1.9), 1.1, 0.7)
	_death_timer.start()
	killed.emit(get_instance_id())

func _death_shake(strength : float):
	ship.position = Vector2(randf_range(-8, 8), randf_range(-8, 8)) * strength

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
		piece.position = global_position + _facing().rotated(randf_range(-0.4, 0.4)) * randf_range(-180, 180)
		piece.rotation = randf() * TAU
		piece.modulate = ship.modulate
		_world.add_child(piece)

		var target = piece.position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(200, 420)
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
		_next_hurt_life -= _max_life * HURT_STEP
		Juice.shake(2.0)

	return true
