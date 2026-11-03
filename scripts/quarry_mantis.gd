extends BossBase

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

@export var SlashDamage = 60
@export var RockDamage = 45

# Damage is what game_logic scales, attacks that are not contact damage follow it
const BASE_DAMAGE = 100
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
# the debris atlas is 0.1 of the parts image, the parts image ~0.18 of the game size
const DEBRIS_SCALE = 1.7

@onready var slashWarning = $Ship/SlashWarning
@onready var mouthGlow = $Ship/MouthGlow
@onready var slashAudio = $SlashAudio

enum ATTACK {SLASH, SPIT, BEAM, ROCKFALL}

var _dashing = false


func _init() -> void:
	enemy_name = "Quarry Mantis"
	idleAnimation = &"Idle"
	randomStartFrame = false
	dissolveIn = 0.0
	shapesFollowShip = true
	bossBarColor = Color(0.4, 0.85, 0.95)
	enrageColor = Color(1.2, 1.0, 0.88)
	enrageFlashColor = Color(1.8, 0.9, 0.5)
	enrageFlashSize = 0.9
	deathShakeRange = 8.0
	chaseRange = Vector2(1.4, 2.4)
	firstWait = 1.2
	restTime = 0.6
	retreatFactor = 0.5
	attackAnimations = {ATTACK.SLASH: &"Slash", ATTACK.SPIT: &"Spit", ATTACK.BEAM: &"BeamCharge", ATTACK.ROCKFALL: &"Slash"}
	RotationSpeed = PI * 0.8
	MoveSpeed = 95
	Acceleration = 7
	KeepDistance = 340.0
	Life = 16000
	Damage = 100
	IsDamageOverTime = true
	DamageTickTime = 0.5
	Knockback = 0


func _on_boss_ready() -> void:
	SlashDamage = int(SlashDamage * Damage / BASE_DAMAGE)
	RockDamage = int(RockDamage * Damage / BASE_DAMAGE)
	laser.Damage = int(laser.Damage * Damage / BASE_DAMAGE)
	laser.set_colors(Color(0.2, 0.75, 1.0), Color(1.0, 2.0, 2.4), Color(1.6, 0.6, 0.4))

	_setup_spit(preload("res://scenes/levels/level2/mantis_shard.tscn"), 6)

	blast.get_node("Debris").texture = preload("res://resources/levels/level2/enemies/quarry_mantis/mantis_shards.png")
	_build_slash_warning()


# the dash runs straight through the player, the scythes hit in front
func _physics_process(delta):
	if isDead:
		return
	if _dashing:
		var to_player = player.global_position - global_position
		if to_player.length() < DASH_STOP_DISTANCE:
			velocity = velocity.normalized() * MoveSpeed
		move_and_collide(velocity * delta)
		return
	super._physics_process(delta)


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


func _keep_distance_for(attack : int) -> float:
	return SLASH_KEEP_DISTANCE if attack == ATTACK.SLASH else KeepDistance


func _pick_attack() -> int:
	var options = [ATTACK.SLASH, ATTACK.SPIT, ATTACK.BEAM, ATTACK.ROCKFALL]
	options.erase(_last_attack)
	var distance = global_position.distance_to(player.global_position)
	# close - the scythes, far away - the beam or the rocks
	if distance < 420 and options.has(ATTACK.SLASH) and randf() < 0.5:
		return ATTACK.SLASH
	if distance > 750:
		options.erase(ATTACK.SLASH)
	return options.pick_random()


func _perform(attack : int) -> void:
	if attack == ATTACK.SLASH:
		await _attack_slash()
		if _enraged and !isDead:
			await _attack_slash()
	elif attack == ATTACK.SPIT:
		await _attack_spit()
	elif attack == ATTACK.BEAM:
		await _attack_beam()
	else:
		await _attack_rockfall()


func _on_enrage() -> void:
	# the brood answers its call
	_call_hunters(Vector2(250, 400))


# scythes rise while a wedge marks the path, a short dash, then both scythes cross in front
func _attack_slash():
	_turn_speed = RotationSpeed * 1.2
	sprite.play(&"Slash")
	slashWarning.visible = true
	slashWarning.modulate.a = 0.0
	create_tween().tween_property(slashWarning, "modulate:a", 1.0, 0.25)

	await _await_frame(&"Slash", SLASH_DASH_FRAME)
	if isDead:
		return
	slashWarning.visible = false
	_turn_speed = 0.0
	Juice.play_sound(slashAudio)
	_dashing = true
	velocity = _facing() * DASH_SPEED
	await _wait(DASH_TIME)
	_dashing = false
	velocity = _facing() * MoveSpeed
	if isDead:
		return

	await _await_frame(&"Slash", SLASH_HIT_FRAME)
	if isDead:
		return
	_slash_hit()
	if sprite.animation == &"Slash" and sprite.is_playing():
		await sprite.animation_finished
	_turn_speed = RotationSpeed


func _slash_hit():
	Juice.shake(4.0)
	var to_player = player.global_position - global_position
	if to_player.length() < SLASH_REACH and abs(_facing().angle_to(to_player)) < SLASH_HALF_ANGLE:
		player.take_damage(SlashDamage)
		Juice.hitstop(0.06)


func _attack_spit():
	_turn_speed = RotationSpeed * 0.6
	sprite.play(&"Spit")
	# same step in every volley, odd and even counts interleave, so the second volley fills the gaps
	var volleys = [7, 6] if !_enraged else [9, 8, 9]
	var step = SPIT_STEP if !_enraged else SPIT_STEP * 0.85
	for i in range(volleys.size()):
		await _await_frame(&"Spit", SPIT_FRAMES[i])
		if isDead or sprite.animation != &"Spit":
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


# aims while charging, then the beam is locked (or sweeps after the player when enraged)
func _attack_beam():
	_beam_attack(&"BeamCharge", &"BeamFire", &"BeamEnd", 0.22, LASER_CHARGE_TIME, LASER_FIRE_TIME * (1.25 if _enraged else 1.0), 0.18)


# the scythes strike the ground, rock plates drop around the player
func _attack_rockfall():
	_turn_speed = RotationSpeed * 0.5
	sprite.play(&"Slash")
	await _await_frame(&"Slash", SLASH_HIT_FRAME)
	if isDead:
		return
	Juice.play_sound(slashAudio)
	Juice.shake(5.0)

	var count = 9 if _enraged else 6
	var warn_time = 0.9 if _enraged else 1.1
	await _rain_rocks(count, warn_time, RockDamage)

	if sprite.animation == &"Slash" and sprite.is_playing():
		await sprite.animation_finished
	_turn_speed = RotationSpeed


func explode() -> void:
	isDead = true
	_halt_boss()
	_dashing = false
	mouthGlow.visible = false
	slashWarning.visible = false

	# the stone body cracks and falls apart, then the shell bursts
	sprite.play(&"Death")
	create_tween().tween_method(_death_shake, 1.0, 0.0, 1.0)
	Juice.shake(6.0)

	await sprite.animation_finished
	blast.rotation = ship.rotation
	blast.fire(170.0)
	_fling_debris()
	_burst(&"Death", 0, Color(0.8, 1.6, 1.9), 1.1)


# the big plates of the shell tumble away
func _fling_debris() -> void:
	_fling_shell_debris(180.0, Vector2(200, 420), DEBRIS_SCALE)
