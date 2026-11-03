extends BossBase

# Second boss - a giant space worm. It slithers after the player and cycles
# through four attacks: spread shot, laser, homing mines and teleport.
# Below half life it gets enraged: faster, more bullets and a sweeping laser.
# Like the first boss it faces the player with its +Y side, the sheet draws
# the worm with its head to the right so the sprite is turned by 90 degrees.

var mineScene = preload("res://scenes/levels/level1/worm_mine.tscn")

const SPRITE_SCALE = 1.1
const LASER_CHARGE_TIME = 0.9
const LASER_FIRE_TIME = 1.6
# body segments of the first idle frame, flung around on death
const DEBRIS_REGIONS = [
	Rect2(24, 40, 70, 100), Rect2(94, 30, 70, 115),
	Rect2(164, 20, 70, 125), Rect2(234, 15, 70, 130),
	Rect2(304, 15, 71, 136),
]

@onready var eyeGlow = $Ship/EyeGlow
@onready var teleportSound = $TeleportSound

enum ATTACK {SPREAD, LASER, MINES, TELEPORT}


func _init() -> void:
	enemy_name = "Worm"
	idleAnimation = &"Idle"
	randomStartFrame = false
	dissolveIn = 0.0
	shapesFollowShip = true
	bossBarColor = Color.MEDIUM_PURPLE
	enrageColor = Color(1.35, 0.8, 0.9)
	enrageFlashColor = Color(1.8, 0.5, 0.6)
	enrageFlashSize = 0.9
	deathShakeRange = 8.0
	chaseRange = Vector2(1.6, 2.6)
	firstWait = 1.0
	restTime = 0.5
	retreatFactor = 0.4
	attackAnimations = {ATTACK.SPREAD: &"Spread", ATTACK.LASER: &"LaserCharge", ATTACK.MINES: &"Mines", ATTACK.TELEPORT: &"TeleportOut"}
	RotationSpeed = PI
	MoveSpeed = 110
	Acceleration = 8
	KeepDistance = 320.0
	Life = 20000
	Damage = 120
	IsDamageOverTime = true
	DamageTickTime = 0.5
	Knockback = 0


func _on_boss_ready() -> void:
	_setup_spit()


# the worm wobbles like a serpent while it chases
func _approach_velocity(to_player : Vector2, direction : Vector2) -> Vector2:
	var target = super._approach_velocity(to_player, direction)
	return target + direction.orthogonal() * sin(_time * 2.2) * MoveSpeed * 0.7


func _pick_attack() -> int:
	var options = [ATTACK.SPREAD, ATTACK.LASER, ATTACK.MINES, ATTACK.TELEPORT]
	options.erase(_last_attack)
	# far away player - come closer
	if options.has(ATTACK.TELEPORT) and global_position.distance_to(player.global_position) > 750 and randf() < 0.6:
		return ATTACK.TELEPORT
	return options.pick_random()


func _perform(attack : int) -> void:
	if attack == ATTACK.SPREAD:
		await _attack_spread()
	elif attack == ATTACK.LASER:
		await _attack_laser()
	elif attack == ATTACK.MINES:
		await _attack_mines()
	else:
		await _attack_teleport()


func _glow_sprite() -> Sprite2D:
	return eyeGlow


# short flinch, only when no attack is playing
func _on_hurt() -> void:
	if sprite.animation == &"Idle" or sprite.animation == &"Move":
		sprite.play("Hurt")
	Juice.shake(2.0)


func _attack_spread():
	_turn_speed = RotationSpeed * 0.5
	sprite.play("Spread")
	await _wait(0.25)

	var volleys = [5, 7, 9]
	if _enraged:
		volleys = [7, 10, 13, 10]
	for i in range(volleys.size()):
		if isDead:
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
	if isDead:
		return
	_turn_speed = RotationSpeed * 0.15 if _enraged else 0.0
	sprite.play("LaserFire")
	Juice.shake(6.0)

	await laser.finished
	eyeGlow.visible = false
	_turn_speed = RotationSpeed
	if isDead:
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
		if isDead:
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
	if isDead:
		return

	_spawn_flash(global_position, Color(1.2, 0.5, 1.8), 0.7, 0.5)
	ship.visible = false
	await _wait(0.35)
	if isDead:
		return

	var pos = player.global_position + Vector2(randf_range(380, 520), 0).rotated(randf() * TAU)
	pos.x = clamp(pos.x, LevelSettings.MinX, LevelSettings.MaxX)
	pos.y = clamp(pos.y, LevelSettings.MinY, LevelSettings.MaxY)
	global_position = pos
	velocity = Vector2.ZERO
	_set_rotation((player.global_position - pos).angle() - PI / 2)

	ship.visible = true
	teleportSound.play()
	_spawn_flash(global_position, Color(1.3, 0.6, 2.0), 0.8, 0.5)
	sprite.play("TeleportIn")
	await sprite.animation_finished
	if isDead:
		return

	_set_vulnerable(true)
	_fire_spread(11 if _enraged else 8, 0.0)


func _set_vulnerable(value : bool):
	_vulnerable = value
	collisionShape.set_deferred("disabled", !value)
	hitBoxShape.set_deferred("disabled", !value)


func explode() -> void:
	isDead = true
	_halt_boss()
	eyeGlow.visible = false
	ship.visible = true

	# the body cracks for a second before it blows up
	sprite.play("Death")
	create_tween().tween_method(_death_shake, 1.0, 0.0, 1.0)
	_fling_debris()
	Juice.shake(6.0)

	await sprite.animation_finished
	_burst(&"Death", 1, Color(1.0, 1.6, 0.9), 1.1)


# the body segments of the first idle frame tumble away
func _fling_debris():
	var sheet = sprite.get_sprite_frames().get_frame_texture(&"Idle", 0).atlas
	for region in DEBRIS_REGIONS:
		var texture = AtlasTexture.new()
		texture.atlas = sheet
		texture.region = region
		var spawn = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		_fling_piece(texture, SPRITE_SCALE, spawn, Vector2(250, 450), 6.0)
