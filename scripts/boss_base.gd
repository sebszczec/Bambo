class_name BossBase
extends EnemyBase

# Engine of the big bosses (worm, quarry mantis, bedrock queen) on top of EnemyBase:
# the attack loop, the move loop that ends on the frame the next attack starts from,
# the ghost crossfade between animations, the hurt steps, the enrage and the death debris.
# A boss sets its stats and tables in _init() and implements _pick_attack(), _perform()
# and its own attacks. Animations come from the SpriteFrames metadata (entry_/exit_ tables).

signal spawn_requested(enemy : Enums.ENEMIES, spawn_position : Vector2)
signal health_changed(value : int, max_value : int)
signal enraged

const CROSSFADE_TIME = 0.15
const MOVE_ANIM_SCALE_MIN = 0.75
const MOVE_ANIM_SCALE_MAX = 1.35
const HURT_STEP = 0.1
# the death blast waits this long before the boss is removed
const DEATH_WAIT = 2.5
const HUNTER_PACK = 3
const ROCK_RADIUS = 72.0
const MantisRock = preload("res://scripts/mantis_rock.gd")

@export var MoveSpeed = 100
@export var Acceleration = 8
# the boss keeps this distance to the player while chasing
@export var KeepDistance = 320.0

# set by each boss in _init()
var bossBarColor = Color(0.4, 0.85, 0.95)
var enrageColor = Color(1.2, 1.0, 0.88)
var enrageFlashColor = Color(1.8, 0.9, 0.5)
var enrageFlashSize = 0.9
var chaseRange = Vector2(1.4, 2.4)
var firstWait = 1.0
var restTime = 0.5
# the move loop backs off this much of MoveSpeed when the player is closer than KeepDistance
var retreatFactor = 0.5
var deathShakeRange = 8.0
var attackAnimations = {}

var _max_life = 0
var _enraged = false
var _moving = false
var _vulnerable = true
var _turn_speed : float = 0.0
var _time = 0.0
var _last_attack = -1
var _next_hurt_life = 0
var _keep_distance = 0.0
var _world = null
var _spit = null
var _ai_timer = Timer.new()
var _shown_animation = &"Idle"
var _shown_frame = 0
var _ghost_tween : Tween = null
# the next animation change continues the clip, no crossfade needed
var _seamless = false
var _move_speed_scale = 1.0
var _move_exit_frame = 0

@onready var ghost = $Ship/Ghost
@onready var muzzle = $Ship/Muzzle
@onready var laser = $Ship/Laser
# not every boss has these nodes, the attacks that use them only exist on the bosses that do
@onready var blast = get_node_or_null("Blast")
@onready var rockAudio = get_node_or_null("RockAudio")


func _on_ready() -> void:
	_max_life = Life
	_next_hurt_life = Life * (1.0 - HURT_STEP)
	_keep_distance = KeepDistance
	_turn_speed = RotationSpeed
	lifeBar.setColor(bossBarColor)
	deathTimer.wait_time = DEATH_WAIT
	_world = get_tree().current_scene

	_ai_timer.one_shot = true
	add_child(_ai_timer)

	sprite.connect("animation_changed", _on_animation_changed)
	sprite.connect("frame_changed", _on_frame_changed)
	sprite.connect("animation_finished", _on_animation_finished)

	_on_boss_ready()
	_run_ai()


# the boss-specific part of the setup, runs before the attack loop starts
func _on_boss_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if isDead:
		return

	_time += delta
	var to_player = player.global_position - global_position
	var direction = to_player.normalized()

	var target = Vector2.ZERO
	if _moving:
		target = _approach_velocity(to_player, direction)

	velocity = velocity.move_toward(target, Acceleration * 60 * delta)

	var theta = wrapf(direction.angle() - HALF_PI - ship.rotation, -PI, PI)
	var step = _turn_speed * delta
	_set_rotation(ship.rotation + clamp(theta, -step, step))

	move_and_collide(velocity * delta)


func _approach_velocity(to_player : Vector2, direction : Vector2) -> Vector2:
	if to_player.length() > _keep_distance:
		return direction * MoveSpeed
	return -direction * MoveSpeed * retreatFactor


# the long body turns as a whole, its shapes follow the ship
func _set_rotation(angle : float) -> void:
	ship.rotation = angle
	_follow_ship_shapes()


func _facing() -> Vector2:
	return Vector2.DOWN.rotated(ship.rotation)


func _cooldown_factor() -> float:
	return 0.7 if _enraged else 1.0


func _keep_distance_for(_attack : int) -> float:
	return KeepDistance


# the timer is a child of the boss, a coroutine waiting on it
# simply never resumes when the boss is freed
func _wait(seconds : float):
	_ai_timer.start(seconds)
	await _ai_timer.timeout


# waits until the animation shows `frame` (or plays something else)
func _await_frame(animation : StringName, frame : int):
	while !isDead and sprite.animation == animation and sprite.frame < frame and sprite.is_playing():
		await sprite.frame_changed


# ---- the attack loop ----

func _run_ai():
	await _wait(firstWait)
	while !isDead:
		# picked before the chase, so the move loop can end on the frame leading into it
		var attack = _pick_attack()
		_last_attack = attack
		await _approach(attack)
		if isDead:
			return

		await _perform(attack)
		if isDead:
			return

		_settle()
		await _wait(restTime * _cooldown_factor())


# the boss-specific attack choice, returns the attack id
func _pick_attack() -> int:
	return 0


# the boss-specific attack, a coroutine
func _perform(_attack : int) -> void:
	pass


# the approach before an attack: the move loop with the attack's animation
func _approach(attack : int) -> void:
	_keep_distance = _keep_distance_for(attack)
	await _chase(randf_range(chaseRange.x, chaseRange.y) * _cooldown_factor(), attackAnimations[attack])


# back to the idle pose after an attack
func _settle() -> void:
	_play_matched(&"Idle")


# ---- the move loop ----

# moves towards the player and ends on the exit frame of the attack's animation
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
		if isDead:
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


# ---- animation bookkeeping ----

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

	# the old pose fades out over the new animation
	if _ghost_tween:
		_ghost_tween.kill()
	ghost.visible = true
	ghost.modulate.a = 1.0
	_ghost_tween = create_tween()
	_ghost_tween.tween_property(ghost, "modulate:a", 0.0, CROSSFADE_TIME)
	_ghost_tween.tween_callback(ghost.hide)


func _on_animation_finished():
	if sprite.animation == &"Hurt" and !isDead:
		if _moving:
			_resume_move()
		else:
			_play_matched(&"Idle")


# ---- damage, enrage, death ----

func _accepts_hits() -> bool:
	return !isDead and _vulnerable


func _knockback_enabled() -> bool:
	return false


func _flash_hit() -> void:
	Juice.flash(sprite, 0.05)


func _damage_from_bullet(bullet):
	return PlayerStatus.get_boss_damage_from_weapon(bullet.Type, _max_life, self)


func _label_position(bullet):
	return bullet.get_global_position()


func _on_damage_taken() -> void:
	health_changed.emit(max(Life, 0), _max_life)


func handleDamage(damage, label_position = null) -> bool:
	if !super.handleDamage(damage, label_position):
		return false

	if !_enraged and Life < _max_life * 0.5:
		_enrage()

	if Life < _next_hurt_life:
		_next_hurt_life -= _max_life * HURT_STEP
		_on_hurt()
	return true


# the flinch or shudder at each hurt step, the default is a shake
func _on_hurt() -> void:
	Juice.shake(2.0)


func _enrage() -> void:
	_enraged = true
	MoveSpeed *= 1.3
	create_tween().tween_property(ship, "modulate", enrageColor, 0.6)
	_spawn_flash(global_position, enrageFlashColor, enrageFlashSize, 0.6)
	_on_enrage()
	enraged.emit()


# the boss-specific part of the enrage, e.g. a pack of hunters
func _on_enrage() -> void:
	pass


# a pack of hunters spawns around the boss, game logic creates and tracks them
func _call_hunters(radius : Vector2) -> void:
	for i in range(HUNTER_PACK):
		var offset = Vector2(randf_range(radius.x, radius.y), 0).rotated(TAU * i / HUNTER_PACK + randf() * 0.5)
		spawn_requested.emit(Enums.ENEMIES.HUNTER, global_position + offset)


# additive light that grows and fades, left in the world
func _spawn_flash(pos : Vector2, color : Color, size : float, duration : float):
	var glow = _glow_sprite()
	var flash = Sprite2D.new()
	flash.texture = glow.texture
	flash.material = glow.material
	flash.modulate = color
	flash.position = pos
	flash.scale = Vector2.ONE * size * 0.3
	_world.add_child(flash)

	var tween = flash.create_tween().set_parallel()
	tween.tween_property(flash, "scale", Vector2.ONE * size, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(flash.queue_free)


# the glow the flashes are drawn from, the worm uses its eye
func _glow_sprite() -> Sprite2D:
	return $Ship/MouthGlow


# the cracking shake while the body dies
func _death_shake(strength : float):
	ship.position = Vector2(randf_range(-deathShakeRange, deathShakeRange), randf_range(-deathShakeRange, deathShakeRange)) * strength


# stops the attacks and the body, the death sequence runs after it
func _halt_boss() -> void:
	_ai_timer.stop()
	laser.stop()
	_moving = false
	velocity = Vector2.ZERO
	_disable_body()


# the shell bursts into an explosion and a flash, then killed is announced
func _burst(animation : StringName, frame : int, flash_color : Color, flash_size : float) -> void:
	audio.play()
	ship.visible = false
	explosion.position = sprite.position
	explosion.SpriteTexture = sprite.get_sprite_frames().get_frame_texture(animation, frame)
	explosion.scale = sprite.scale
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.init(Vector2(3.0, 3.0), 250)
	explosion.visible = true
	explosion.explode()
	_spawn_flash(global_position, flash_color, flash_size, 0.7)
	deathTimer.start()
	killed.emit(get_instance_id())


# the big plates of the shell (cells of the debris atlas on the blast node) tumble away
func _fling_shell_debris(spread : float, distance : Vector2, piece_scale : float) -> void:
	var atlas = blast.get_node("Debris").texture
	for cell in range(10):
		var texture = AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2((cell % 4) * 128, (cell / 4) * 128, 128, 128)
		var spawn = global_position + _facing().rotated(randf_range(-0.4, 0.4)) * randf_range(-spread, spread)
		_fling_piece(texture, piece_scale, spawn, distance, 5.0)


# one piece of debris: flies off in a random direction and fades
func _fling_piece(texture : Texture2D, piece_scale : float, spawn : Vector2, distance : Vector2, spin : float) -> void:
	var piece = Sprite2D.new()
	piece.texture = texture
	piece.scale = Vector2.ONE * piece_scale
	piece.position = spawn
	piece.rotation = randf() * TAU
	piece.modulate = ship.modulate
	_world.add_child(piece)

	var target = piece.position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(distance.x, distance.y)
	var tween = piece.create_tween().set_parallel()
	tween.tween_property(piece, "position", target, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "rotation", piece.rotation + randf_range(-spin, spin), 1.8)
	tween.tween_property(piece, "modulate:a", 0.0, 1.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(piece.queue_free)


# the beam: the glow charges, the laser fires, then the mouth closes
func _beam_attack(charge_anim : StringName, fire_anim : StringName, end_anim : StringName, glow_size : float, charge_time : float, fire_time : float, enraged_turn : float) -> void:
	_turn_speed = RotationSpeed
	sprite.play(charge_anim)
	var glow = _glow_sprite()
	glow.visible = true
	glow.scale = Vector2.ONE * 0.05
	create_tween().tween_property(glow, "scale", Vector2.ONE * glow_size, charge_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	laser.fire(charge_time, fire_time)

	await laser.beam_started
	if isDead:
		return
	_turn_speed = RotationSpeed * enraged_turn if _enraged else 0.0
	sprite.play(fire_anim)
	Juice.shake(6.0)

	await laser.finished
	glow.visible = false
	_turn_speed = RotationSpeed
	if isDead:
		return
	sprite.play(end_anim)
	await sprite.animation_finished


# the scythes or the shell strike, rock plates drop on the player and around it
func _rain_rocks(count : int, warn_time : float, damage : int) -> void:
	# the first rock falls where the player will be, the others around
	var center = player.global_position
	var lead = player.velocity * warn_time * 0.8
	for i in range(count):
		if isDead:
			return
		var pos = center + lead if i == 0 else center + Vector2(randf_range(90, 340), 0).rotated(randf() * TAU)
		_drop_rock(pos, warn_time, damage)
		await _wait(0.07)


func _drop_rock(pos : Vector2, warn_time : float, damage : int) -> void:
	var rock = MantisRock.new()
	rock.setup(ROCK_RADIUS * randf_range(0.85, 1.15), damage, warn_time)
	rock.position = pos
	rock.connect("landed", _on_rock_landed)
	_world.add_child(rock)


func _on_rock_landed():
	if !isDead:
		Juice.play_sound(rockAudio)


# sets up the spit weapon of the boss, the bullet scene and speed are optional
func _setup_spit(bullet_scene : PackedScene = null, speed : int = -1) -> void:
	_spit = WeaponFactory.get_weapon(Enums.WEAPONS.WORM_SPIT, true, false)
	if bullet_scene != null:
		_spit.bullet_scene = bullet_scene
	if speed >= 0:
		_spit.speed = speed
	_spit.set_owner(_world)
	_spit.register_internal_nodes(self)
