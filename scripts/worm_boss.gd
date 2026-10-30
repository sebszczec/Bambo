extends CharacterBody2D

# Second boss - a giant space worm. It slithers after the player and cycles
# through four attacks: spread shot, laser, homing mines and teleport.
# Below half life it gets enraged: faster, more bullets and a sweeping laser.
# Like the first boss it faces the player with its +Y side, the sheet draws
# the worm with its head to the right so the sprite is turned by 90 degrees.

var floatingTextScene = preload("res://scenes/floating_text.tscn")
var mineScene = preload("res://scenes/worm_mine.tscn")

@export var Life = 20000
@export var Damage = 120
@export var IsDamageOverTime = true
@export var DamageTickTime = 0.5
@export var MoveSpeed = 110
@export var Acceleration = 8
@export var RotationSpeed : float = PI
# the worm keeps this distance to the player while chasing
@export var KeepDistance = 320.0

const SPRITE_SCALE = 1.1
const LASER_CHARGE_TIME = 0.9
const LASER_FIRE_TIME = 1.6
const HURT_STEP = 0.1
# animations start from other parts of the clip, the last frame fades out over the new one
const CROSSFADE_TIME = 0.15
# the move loop plays a bit faster or slower so the chase ends on the right frame
const MOVE_ANIM_SCALE_MIN = 0.75
const MOVE_ANIM_SCALE_MAX = 1.35
const ENRAGED_COLOR = Color(1.35, 0.8, 0.9)
# body segments of the first idle frame, flung around on death
const DEBRIS_REGIONS = [
	Rect2(24, 40, 70, 100), Rect2(94, 30, 70, 115),
	Rect2(164, 20, 70, 125), Rect2(234, 15, 70, 130),
	Rect2(304, 15, 71, 136),
]

@onready var ship = $Ship
@onready var sprite = $Ship/AnimatedSprite2D
@onready var ghost = $Ship/Ghost
@onready var eyeGlow = $Ship/EyeGlow
@onready var muzzle = $Ship/Muzzle
@onready var laser = $Ship/Laser
@onready var lifeBar = $LifeBar
@onready var audio = $AudioStreamPlayer2D
@onready var teleportSound = $TeleportSound
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/CollisionShape2D
@onready var explosion = $Explosion
@onready var mark = $Mark

enum ATTACK {SPREAD, LASER, MINES, TELEPORT}
const ATTACK_ANIMATIONS = {ATTACK.SPREAD: &"Spread", ATTACK.LASER: &"LaserCharge", ATTACK.MINES: &"Mines", ATTACK.TELEPORT: &"TeleportOut"}

var _player = null
var _world = null
var _spit = null
var _is_dead = false
var _show_damage = true
var _max_life = 0
var _enraged = false
var _moving = false
var _vulnerable = true
var _turn_speed : float = 0.0
var _time = 0.0
var _last_attack = -1
var _next_hurt_life = 0
var _ai_timer = Timer.new()
var _death_timer = Timer.new()
var _shown_animation = &"Idle"
var _shown_frame = 0
var _ghost_tween : Tween = null
# the next animation change continues the clip, no crossfade needed
var _seamless = false
var _move_speed_scale = 1.0
var _move_exit_frame = 0

signal killed
# not used by the worm, game logic connects it for every boss
@warning_ignore("unused_signal")
signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)
signal health_changed(value : int, max_value : int)
signal enraged

# public
func get_enemy_name():
	return "Worm"

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
	lifeBar.setColor(Color.MEDIUM_PURPLE)
	lifeBar.setMaxValue(Life)
	lifeBar.setValue(Life)
	_max_life = Life
	_next_hurt_life = Life * (1.0 - HURT_STEP)
	_turn_speed = RotationSpeed

	_world = get_tree().current_scene
	_player = get_tree().get_first_node_in_group("player")

	_spit = WeaponFactory.get_weapon(Enums.WEAPONS.WORM_SPIT, true, false)
	_spit.set_owner(_world)
	_spit.register_internal_nodes(self)

	_ai_timer.one_shot = true
	add_child(_ai_timer)

	_death_timer.one_shot = true
	_death_timer.wait_time = 2.5
	_death_timer.connect("timeout", dispose)
	add_child(_death_timer)

	sprite.connect("animation_finished", _on_animation_finished)
	sprite.connect("animation_changed", _on_animation_changed)
	sprite.connect("frame_changed", _on_frame_changed)
	sprite.play("Idle")

	_run_ai()

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_time += delta
	var to_player = _player.global_position - global_position
	var direction = to_player.normalized()

	var target = Vector2.ZERO
	if _moving:
		if to_player.length() > KeepDistance:
			target = direction * MoveSpeed
		else:
			target = -direction * MoveSpeed * 0.4
		# serpentine wobble
		target += direction.orthogonal() * sin(_time * 2.2) * MoveSpeed * 0.7

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
	await _wait(1.0)
	while !_is_dead:
		# picked before the chase, so the move loop can end on the frame leading into it
		var attack = _pick_attack()
		_last_attack = attack
		await _chase(randf_range(1.6, 2.6) * _cooldown_factor(), ATTACK_ANIMATIONS[attack])
		if _is_dead:
			return

		if attack == ATTACK.SPREAD:
			await _attack_spread()
		elif attack == ATTACK.LASER:
			await _attack_laser()
		elif attack == ATTACK.MINES:
			await _attack_mines()
		else:
			await _attack_teleport()
		if _is_dead:
			return

		_play_matched(&"Idle")
		await _wait(0.5 * _cooldown_factor())

func _pick_attack() -> int:
	var options = [ATTACK.SPREAD, ATTACK.LASER, ATTACK.MINES, ATTACK.TELEPORT]
	options.erase(_last_attack)
	# far away player - come closer
	if options.has(ATTACK.TELEPORT) and global_position.distance_to(_player.global_position) > 750 and randf() < 0.6:
		return ATTACK.TELEPORT
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
	# a flinch at the end of the chase plays out, the loop then runs on to the exit frame
	if sprite.animation == &"Hurt":
		await sprite.animation_finished
		if _is_dead:
			return
		await _wait(_plan_move(sprite.frame, 0.4, 0.0))
	await _reach_frame(&"Move", _move_exit_frame, 3)
	_moving = false
	_seamless = sprite.animation == &"Move" and sprite.frame == _move_exit_frame

# starts the move loop on the frame that best continues the current pose
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

# back to the move loop after a flinch, the rest of the chase is planned again
# and the chase timer restarted so it still ends on the exit frame
func _resume_move():
	var start = _play_move()
	if !_ai_timer.is_stopped():
		_ai_timer.start(_plan_move(start, _ai_timer.time_left, 0.0))

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

func _attack_spread():
	_turn_speed = RotationSpeed * 0.5
	sprite.play("Spread")
	await _wait(0.25)

	var volleys = [5, 7, 9]
	if _enraged:
		volleys = [7, 10, 13, 10]
	for i in range(volleys.size()):
		if _is_dead:
			return
		# every second volley is shifted to fill the gaps
		_fire_spread(volleys[i], 0.0 if i % 2 == 0 else 0.08)
		await _wait(0.22)

	_turn_speed = RotationSpeed

func _fire_spread(count : int, offset : float):
	_spit.count = count
	_spit.spread = 1.5 / (count - 1)
	_spit.canShoot = true
	_spit.shoot(_world, muzzle.global_position, _facing().rotated(offset))
	_spawn_flash(muzzle.global_position, Color(0.5, 1.6, 0.6), 0.15, 0.2)
	Juice.shake(1.5)

func _attack_laser():
	# aims while charging, then the beam is locked (or sweeps slowly when enraged)
	_turn_speed = RotationSpeed
	sprite.play("LaserCharge")
	eyeGlow.visible = true
	eyeGlow.scale = Vector2.ONE * 0.05
	create_tween().tween_property(eyeGlow, "scale", Vector2.ONE * 0.2, LASER_CHARGE_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	laser.fire(LASER_CHARGE_TIME, LASER_FIRE_TIME * (1.3 if _enraged else 1.0))

	await laser.beam_started
	if _is_dead:
		return
	_turn_speed = RotationSpeed * 0.15 if _enraged else 0.0
	sprite.play("LaserFire")
	Juice.shake(6.0)

	await laser.finished
	eyeGlow.visible = false
	_turn_speed = RotationSpeed
	if _is_dead:
		return
	# the mouth closes from the current frame back into an idle pose
	_play_matched(&"LaserEnd")
	await sprite.animation_finished

func _attack_mines():
	_turn_speed = RotationSpeed * 0.5
	sprite.play("Mines")
	await _wait(0.2)

	var count = 6 if _enraged else 4
	for i in range(count):
		if _is_dead:
			return
		var mine = mineScene.instantiate()
		var angle = lerp(-0.9, 0.9, i / float(count - 1))
		mine.velocity = _facing().rotated(angle) * 320
		mine.position = muzzle.global_position
		_world.add_child(mine)
		await _wait(0.1)

	await _wait(0.3)
	_turn_speed = RotationSpeed

func _attack_teleport():
	_set_vulnerable(false)
	teleportSound.play()
	sprite.play("TeleportOut")
	await sprite.animation_finished
	if _is_dead:
		return

	_spawn_flash(global_position, Color(1.2, 0.5, 1.8), 0.7, 0.5)
	ship.visible = false
	await _wait(0.35)
	if _is_dead:
		return

	var pos = _player.global_position + Vector2(randf_range(380, 520), 0).rotated(randf() * TAU)
	pos.x = clamp(pos.x, LevelSettings.MinX, LevelSettings.MaxX)
	pos.y = clamp(pos.y, LevelSettings.MinY, LevelSettings.MaxY)
	global_position = pos
	velocity = Vector2.ZERO
	_set_rotation((_player.global_position - pos).angle() - PI / 2)

	ship.visible = true
	teleportSound.play()
	_spawn_flash(global_position, Color(1.3, 0.6, 2.0), 0.8, 0.5)
	sprite.play("TeleportIn")
	await sprite.animation_finished
	if _is_dead:
		return

	_set_vulnerable(true)
	_fire_spread(11 if _enraged else 8, 0.0)

func _set_vulnerable(value : bool):
	_vulnerable = value
	collisionShape.set_deferred("disabled", !value)
	hitBoxCollisionShape.set_deferred("disabled", !value)

# additive light that grows and fades, left in the world
func _spawn_flash(pos : Vector2, color : Color, size : float, duration : float):
	var flash = Sprite2D.new()
	flash.texture = eyeGlow.texture
	flash.material = eyeGlow.material
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

func _on_animation_finished():
	if sprite.animation == &"Hurt" and !_is_dead:
		if _moving:
			_resume_move()
		else:
			_play_matched(&"Idle")

# short flinch, only when no attack is playing
func _play_hurt():
	if sprite.animation == &"Idle" or sprite.animation == &"Move":
		sprite.play("Hurt")
	Juice.shake(2.0)

func _enrage():
	_enraged = true
	MoveSpeed *= 1.3
	create_tween().tween_property(ship, "modulate", ENRAGED_COLOR, 0.6)
	_spawn_flash(global_position, Color(1.8, 0.5, 0.6), 0.9, 0.6)
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

		if _is_dead or !_vulnerable:
			return

		var damage = PlayerStatus.get_damage_from_weapon(bullet.Type)
		Juice.flash(sprite, 0.05)

		if handleDamage(damage, bullet.get_global_position()) == false:
			_is_dead = true
			explode()

func explode():
	_ai_timer.stop()
	laser.stop()
	_moving = false
	velocity = Vector2.ZERO
	eyeGlow.visible = false
	ship.visible = true
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false

	# the body cracks for a second before it blows up
	sprite.play("Death")
	create_tween().tween_method(_death_shake, 1.0, 0.0, 1.0)
	_fling_debris()
	Juice.shake(6.0)

	await sprite.animation_finished
	audio.play()
	ship.visible = false
	explosion.position = sprite.position
	explosion.SpriteTexture = sprite.get_sprite_frames().get_frame_texture(&"Death", 1)
	explosion.scale = sprite.scale
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.init(Vector2(3.0, 3.0), 250)
	explosion.visible = true
	explosion.explode()
	_spawn_flash(global_position, Color(1.0, 1.6, 0.9), 1.1, 0.7)
	_death_timer.start()
	killed.emit(get_instance_id())

func _death_shake(strength : float):
	ship.position = Vector2(randf_range(-8, 8), randf_range(-8, 8)) * strength

func _fling_debris():
	var sheet = sprite.get_sprite_frames().get_frame_texture(&"Idle", 0).atlas
	for region in DEBRIS_REGIONS:
		var texture = AtlasTexture.new()
		texture.atlas = sheet
		texture.region = region

		var piece = Sprite2D.new()
		piece.texture = texture
		piece.scale = Vector2.ONE * SPRITE_SCALE
		piece.position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		piece.rotation = randf() * TAU
		piece.modulate = ship.modulate
		_world.add_child(piece)

		var target = piece.position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(250, 450)
		var tween = piece.create_tween().set_parallel()
		tween.tween_property(piece, "position", target, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "rotation", piece.rotation + randf_range(-6, 6), 1.8)
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

	if Life < _next_hurt_life:
		_next_hurt_life -= _max_life * HURT_STEP
		_play_hurt()

	return true
