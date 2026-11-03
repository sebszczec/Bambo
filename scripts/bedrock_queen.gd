extends BossBase

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

# Damage is what game_logic scales, attacks that are not contact damage follow it
const BASE_DAMAGE = 100
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
const BROOD_COUNT = 3
const BROOD_COUNT_ENRAGED = 4
const ROCK_DAMAGE = 45
# the debris atlas is 0.1 of the parts image, the parts image ~0.2 of the game size
const DEBRIS_SCALE = 2.0

@onready var mouthGlow = $Ship/MouthGlow
@onready var broodAudio = $SlashAudio

enum ATTACK {BROOD, BEAM, SPINES, QUAKE}


func _init() -> void:
	enemy_name = "Bedrock Queen"
	idleAnimation = &"Idle"
	randomStartFrame = false
	dissolveIn = 0.0
	shapesFollowShip = true
	bossBarColor = Color(0.4, 0.85, 0.95)
	enrageColor = Color(1.25, 0.95, 0.8)
	enrageFlashColor = Color(1.8, 0.9, 0.5)
	enrageFlashSize = 1.2
	deathShakeRange = 10.0
	chaseRange = Vector2(1.6, 2.6)
	firstWait = 1.5
	restTime = 0.8
	retreatFactor = 0.5
	RotationSpeed = PI * 0.6
	MoveSpeed = 70
	Acceleration = 4
	KeepDistance = 420.0
	Life = 16000
	Damage = 100
	IsDamageOverTime = true
	DamageTickTime = 0.5
	Knockback = 0


func _on_boss_ready() -> void:
	laser.Damage = int(laser.Damage * Damage / BASE_DAMAGE)
	laser.set_colors(Color(0.2, 0.75, 1.0), Color(1.0, 2.0, 2.4), Color(1.6, 0.6, 0.4))

	_setup_spit(preload("res://scenes/levels/level2/mantis_shard.tscn"), SPINE_SPEED)

	blast.get_node("Debris").texture = preload("res://resources/levels/level2/enemies/bedrock_queen/bedrock_queen_shards.png")


# the queen drifts with its idle loop instead of planning a move loop
func _approach(_attack : int) -> void:
	_keep_distance = KeepDistance
	await _drift(randf_range(chaseRange.x, chaseRange.y) * _cooldown_factor())


func _drift(duration : float):
	_moving = true
	_play_idle()
	await _wait(duration)
	_moving = false


func _settle() -> void:
	_play_idle()


func _play_idle():
	if sprite.animation != &"Idle":
		sprite.play(&"Idle")


func _pick_attack() -> int:
	var options = [ATTACK.BROOD, ATTACK.BEAM, ATTACK.SPINES, ATTACK.QUAKE]
	options.erase(_last_attack)
	var distance = global_position.distance_to(player.global_position)
	# the beam needs the player in front of it, the crown is for a close player
	if distance > 800:
		options.erase(ATTACK.SPINES)
	if distance > 900:
		options.erase(ATTACK.BEAM)
	return options.pick_random()


func _perform(attack : int) -> void:
	if attack == ATTACK.BROOD:
		await _attack_brood()
	elif attack == ATTACK.BEAM:
		await _attack_beam()
	elif attack == ATTACK.SPINES:
		await _attack_spines()
	else:
		await _attack_quake()


func _on_enrage() -> void:
	Juice.shake(10.0)
	# the brood answers its call
	_call_hunters(Vector2(300, 450))


# the rear plates lift, the egg sacs swell and hatch pebble mites on both sides
func _attack_brood():
	_turn_speed = RotationSpeed * 0.3
	sprite.play(&"Brood")
	var hatches = BROOD_HATCH_FRAMES_ENRAGED if _enraged else BROOD_HATCH_FRAMES
	var count = BROOD_COUNT_ENRAGED if _enraged else BROOD_COUNT
	for frame in hatches:
		await _await_frame(&"Brood", frame)
		if isDead or sprite.animation != &"Brood":
			return
		_hatch(count)
	if sprite.animation == &"Brood" and sprite.is_playing():
		await sprite.animation_finished
	_turn_speed = RotationSpeed


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
	_beam_attack(&"BeamCharge", &"BeamFire", &"BeamEnd", 0.26, LASER_CHARGE_TIME, LASER_FIRE_TIME, BEAM_TURN_ENRAGED)


# the shell throws a full ring of rock spines around itself
func _attack_spines():
	_turn_speed = RotationSpeed * 0.4
	sprite.play(&"Idle")
	Juice.shake(3.0)
	await _wait(0.5)
	if isDead:
		return
	var rings = 2 if _enraged else 1
	var count = SPINE_COUNT_ENRAGED if _enraged else SPINE_COUNT
	for ring in range(rings):
		_fire_ring(count, ring * 0.5 * TAU / count)
		Juice.play_sound(rockAudio)
		await _wait(0.45)
		if isDead:
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
	if isDead:
		return
	Juice.play_sound(rockAudio)
	Juice.shake(5.0)

	var count = 9 if _enraged else 6
	var warn_time = 0.9 if _enraged else 1.1
	await _rain_rocks(count, warn_time, ROCK_DAMAGE)
	_turn_speed = RotationSpeed


func explode() -> void:
	isDead = true
	_halt_boss()
	mouthGlow.visible = false

	# the shell cracks, shakes and goes dark, then it bursts
	create_tween().tween_method(_death_shake, 1.0, 0.0, 1.2)
	var fade = create_tween()
	fade.tween_property(sprite, "modulate", Color(0.3, 0.3, 0.35), 1.2)
	Juice.shake(6.0)
	await fade.finished

	blast.rotation = ship.rotation
	blast.fire(170.0)
	_fling_debris()
	_burst(&"Idle", 0, Color(0.8, 1.6, 1.9), 1.4)


# the big plates of the shell tumble away
func _fling_debris() -> void:
	_fling_shell_debris(200.0, Vector2(220, 460), DEBRIS_SCALE)
