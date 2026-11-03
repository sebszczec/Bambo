extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func get_weapon(weapon: Enums.WEAPONS, damaging_player: bool, damaging_enemy: bool) -> Weapon:
	var result : Weapon = null
	if weapon == Enums.WEAPONS.SMALL:
		result = SmallBullet.new()
	elif weapon == Enums.WEAPONS.BIG:
		result = BigBullet.new()
	elif weapon == Enums.WEAPONS.SMALL_WAVE:
		result = SmallBulletWave.new()
	elif weapon == Enums.WEAPONS.SMALL_HOMING:
		result = SmallHomingBullet.new()
	elif weapon == Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY:
		result = SmallHomingBulletWithDelay.new()
	elif weapon == Enums.WEAPONS.FIREWORKS:
		result = Fireworks.new()
	elif weapon == Enums.WEAPONS.BOMB:
		result = Bomb.new()
	elif weapon == Enums.WEAPONS.ORBIT:
		result = Orbit.new()
	elif weapon == Enums.WEAPONS.WORM_SPIT:
		result = WormSpit.new()
	else:
		result = SmallBullet.new()

	result.setDamagingPlayer(damaging_player)
	result.setDamagingEnemy(damaging_enemy)
	# player weapons are affected by level ups and player stats
	result.player_owned = damaging_enemy

	return result


class Weapon:
	var object_owner = null
	var canShoot = true
	var timer = Timer.new()
	var shooting_delay = 0
	var bullet_scene = null
	var bullet_number = 0
	var speed = 20
	var life_time = 0.5
	var collision_mask = Enums.MASKS.PLAYER | Enums.MASKS.ENEMY
	var type : Enums.WEAPONS = Enums.WEAPONS.SMALL
	var level = 1
	var player_owned = false
	# set by game logic for the ship's own weapons only (mines and enemies fire the same classes)
	var is_player_weapon = false
	# auto weapons without a target in range do not fire
	var needs_target = true
	var extra_projectiles = 0
	var spread = 0.12

	var audio = AudioStreamPlayer2D.new()
	var explosion_audio = AudioStreamPlayer2D.new()

	signal bulletNumerChange

	func _init() -> void:
		setup()
		timer.wait_time = shooting_delay
		timer.one_shot = true
		timer.connect("timeout", _on_timer_timeout)

	func setup():
		shooting_delay = 0.1
		bullet_scene = preload("res://scenes/shared/bullet.tscn")
		audio.stream = load("res://resources/vendor/kenney/space_shooter_redux/Bonus/sfx_laser2.ogg")

	func set_owner(owner):
		object_owner = owner

	func setDamagingPlayer(value : bool):
		if value:
			collision_mask = collision_mask | Enums.MASKS.PLAYER
		else:
			collision_mask = collision_mask & ~Enums.MASKS.PLAYER

	func setDamagingEnemy(value: bool):
		if value:
			collision_mask = collision_mask | Enums.MASKS.ENEMY
		else:
			collision_mask = collision_mask & ~Enums.MASKS.ENEMY

	# public - called by game logic when the weapon is upgraded
	func level_up():
		level += 1
		apply_level()

	# public - sets stats for the current level, used only for player weapons
	func apply_level():
		pass

	# public - called every physics frame for weapons that need it
	func process(_delta: float, _player: Node2D):
		pass

	func get_projectile_count() -> int:
		if player_owned:
			return 1 + extra_projectiles + PlayerStatus.ProjectileCount
		return 1

	func start_cooldown():
		var delay = shooting_delay
		if player_owned:
			delay *= PlayerStatus.get_delay_factor()
		timer.wait_time = max(delay, 0.02)
		timer.start()

	func _on_timer_timeout():
		canShoot = true

	func register_internal_nodes(owner: Node):
		owner.add_child(timer)
		owner.add_child(audio)
		owner.add_child(explosion_audio)

	func shoot_on_start(_owner: Node, _start_position: Vector2, _direction: Vector2):
		pass

	# straight shots that can bounce off enemies (see Ricochet Plates)
	func can_bounce() -> bool:
		return false

	func create_bullet(start_position: Vector2, direction: Vector2):
		var bullet = Bullet.acquire(bullet_scene)
		bullet.Type = type
		bullet.set_collision_mask(collision_mask)
		# Ricochet Plates: only player shots that hit enemies bounce
		if can_bounce() and bullet.is_damaging_enemy():
			bullet.BounceCount = PlayerStatus.Ricochet
		bullet.position = start_position
		bullet.velocity = direction
		# face the shot from the first frame, bullet.gd only turns it on its first physics tick
		if direction != Vector2.ZERO:
			bullet.rotation = PI / 2 + direction.angle()
		bullet.Speed = speed
		bullet.LifeTime = life_time
		bullet.connect("freeing", _on_bullet_freeing, CONNECT_ONE_SHOT)
		if is_player_weapon:
			_apply_skin(bullet)
		return bullet

	# the level can give a player weapon its own bullet art (see levels.gd "weapon_skin")
	func _apply_skin(bullet):
		bullet.apply_skin(Levels.get_current().get("weapon_skin", {}).get(type, {}))

	# bigger, warm glow so homing rockets stand out from regular bullets
	func apply_rocket_look(bullet):
		var effect = bullet.get_node("BulletEffect")
		effect.scale = Vector2(1.8, 1.8)
		effect.self_modulate = Color(2.2, 1.1, 0.3)

	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var count = get_projectile_count()
			for i in range(count):
				var angle = (i - (count - 1) / 2.0) * spread
				owner.add_child(create_bullet(start_position, direction.rotated(angle)))
			start_cooldown()

			updateBulletNumber(count)

	func _on_bullet_freeing(_owner):
		updateBulletNumber(-1)


	func updateBulletNumber(diff):
		bullet_number += diff
		bulletNumerChange.emit(bullet_number)

class Bomb extends Weapon:
	func setup():
		shooting_delay = 0.01
		bullet_scene = preload("res://scenes/shared/bomb.tscn")
		audio.stream = load("res://resources/shared/audio/sfx/seismic_charge.mp3")
		type = Enums.WEAPONS.BOMB

	func shoot(_owner: Node, _start_position: Vector2, _direction: Vector2):
		pass

	func shoot_on_start(owner: Node, start_position: Vector2, _direction: Vector2):
		audio.play(1.3)
		var bullet = bullet_scene.instantiate()
		bullet.Type = type
		bullet.set_collision_mask(collision_mask)
		bullet.position = start_position
		bullet.connect("freeing", _on_bullet_freeing)
		owner.call_deferred("add_child", bullet)
		timer.start()

		updateBulletNumber(1)

class SmallBullet extends Weapon:
	func can_bounce() -> bool:
		return true

	func apply_level():
		shooting_delay = 0.14 * pow(0.88, level - 1)
		extra_projectiles = int(level >= 3) + int(level >= 5)

class SmallHomingBullet extends SmallBullet:
	func setup():
		super.setup()
		shooting_delay = 0.2
		speed = 5
		life_time = 1
		type = Enums.WEAPONS.SMALL_HOMING

	func apply_level():
		shooting_delay = 1.2 * pow(0.85, level - 1)
		speed = 9
		life_time = 1.5
		spread = 0.35
		extra_projectiles = level - 1

	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		var enemy = object_owner.find_nearest_enemy()
		if enemy != null:
			super.shoot(owner, start_position, enemy.position - start_position)
		else:
			super.shoot(owner, start_position, direction)

	func create_bullet(start_position: Vector2, direction: Vector2):
		var bullet = super.create_bullet(start_position, direction)
		apply_rocket_look(bullet)
		return bullet

class SmallHomingBulletWithDelay extends SmallBullet:
	func setup():
		super.setup()
		shooting_delay = 0.2
		speed = 10
		life_time = 1
		type = Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY

	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet = create_bullet(start_position, direction)
			apply_rocket_look(bullet)

			var homing_timer = Timer.new()
			homing_timer.one_shot = true
			homing_timer.wait_time = 0.1
			homing_timer.connect("timeout", _homing_timer_on_timeout.bind(bullet))
			bullet.add_child(homing_timer)

			owner.add_child(bullet)
			start_cooldown()
			homing_timer.start()

			updateBulletNumber(1)

	func _homing_timer_on_timeout(bullet):
		var enemy = object_owner.find_nearest_enemy()
		if enemy != null:
			enemy.set_mark()
			bullet.velocity = enemy.position - bullet.position

class BigBullet extends Weapon:
	func setup():
		shooting_delay = 0.2
		bullet_scene = preload("res://scenes/shared/big_bullet.tscn")
		audio.stream = load("res://resources/vendor/kenney/space_shooter_redux/Bonus/sfx_laser2.ogg")
		type = Enums.WEAPONS.BIG

	func apply_level():
		shooting_delay = 1.0 * pow(0.85, level - 1)
		life_time = 0.8
		spread = 0.2
		extra_projectiles = int(level >= 2) + int(level >= 4) + int(level >= 6)

	func create_bullet(start_position: Vector2, direction: Vector2):
		var bullet = super.create_bullet(start_position, direction)
		# the level can make the heavy shells pierce enemies (levels.gd "weapon_skin": pierce, pierce_level)
		var skin = Levels.get_current().get("weapon_skin", {}).get(type, {})
		if is_player_weapon and skin.has("pierce") and level >= skin.get("pierce_level", 1):
			bullet.PierceCount = skin["pierce"]
		return bullet

class SmallBulletWave extends SmallBullet:
	var size = 30
	var modulate_color : Color = Color.WHITE

	func setup():
		super.setup()
		shooting_delay = 1
		speed = 5
		type = Enums.WEAPONS.SMALL_WAVE
		needs_target = false

	func apply_level():
		shooting_delay = 2.2 * pow(0.88, level - 1)
		size = 12 + 4 * level
		modulate_color = Color(1.5, 0.8, 0.2)

	func set_modulate_color(color : Color):
		modulate_color = color

	func shoot(owner: Node, start_position: Vector2, _direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet_count = size
			if player_owned:
				bullet_count += 4 * PlayerStatus.ProjectileCount
			var radial_increment = (2.0 * PI) / float(bullet_count)
			for i in range (0, bullet_count):
				var bullet = Bullet.acquire(bullet_scene)
				bullet.Type = type
				bullet.set_collision_mask(collision_mask)
				bullet.Speed = speed
				bullet.LifeTime = 1

				var radial_v = Vector2(0.1, 0).rotated(i * radial_increment)
				bullet.position = start_position + radial_v
				bullet.velocity = radial_v
				bullet.connect("freeing", _on_bullet_freeing, CONNECT_ONE_SHOT)
				owner.add_child(bullet)
				bullet.set_modulate_color(modulate_color)
				if is_player_weapon:
					_apply_skin(bullet)

			start_cooldown()
			updateBulletNumber(bullet_count)

class Fireworks extends BigBullet:
	var size = 30
	var explosion_speed = 2
	var explosion_bullet_scene = preload("res://scenes/shared/bullet.tscn")


	func setup():
		super.setup()
		shooting_delay = 0.5
		speed = 8
		life_time = 2
		explosion_audio.stream = load("res://resources/shared/audio/explosions/350977__cabled_mess__boom_c_06.wav")
		type = Enums.WEAPONS.FIREWORKS

	func apply_level():
		shooting_delay = 2.0 * pow(0.88, level - 1)
		life_time = 0.7
		size = 12 + 4 * level
		explosion_speed = 4


	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet = create_bullet(start_position, direction)
			bullet.connect("freeing", _explode, CONNECT_ONE_SHOT)
			owner.add_child(bullet)
			start_cooldown()

			updateBulletNumber(1)

	func _explode(bullet_owner):
		explosion_audio.play()
		var radial_increment = (2.0 * PI) / float(size)
		for i in range (0, size):
			var bullet = Bullet.acquire(explosion_bullet_scene)
			bullet.Type = type
			bullet.set_collision_mask(collision_mask)
			bullet.Speed = explosion_speed

			bullet.LifeTime = 1

			var radial_v = Vector2(0.1, 0).rotated(i * radial_increment)
			bullet.position = bullet_owner.position + radial_v
			bullet.velocity = radial_v
			bullet.connect("freeing", _on_bullet_freeing, CONNECT_ONE_SHOT)
			object_owner.call_deferred("add_child", bullet)

		updateBulletNumber(size)

# blades circling the player, they pass through enemies
class Orbit extends Weapon:
	const SMOKE_TEXTURE = "res://resources/vendor/kenney/particles/smoke_01.png"
	# per weapon level: rocks on the inner ring (Multishot adds to it), rocks on the outer ring,
	# rock scale (hit box too), inner radius and spin
	const LEVEL_STATS = [
		{ "rocks" : 2, "outer" : 0, "scale" : 2.0, "radius" : 85.0, "spin" : 3.0 },
		{ "rocks" : 2, "outer" : 0, "scale" : 2.4, "radius" : 100.0, "spin" : 3.4 },
		{ "rocks" : 3, "outer" : 0, "scale" : 2.4, "radius" : 100.0, "spin" : 3.8 },
		{ "rocks" : 3, "outer" : 0, "scale" : 2.8, "radius" : 115.0, "spin" : 4.2 },
		{ "rocks" : 4, "outer" : 0, "scale" : 2.8, "radius" : 115.0, "spin" : 4.6 },
		{ "rocks" : 4, "outer" : 2, "scale" : 3.0, "radius" : 115.0, "spin" : 4.6 },
	]
	# level 6 outer ring, turns the other way
	const OUTER_RADIUS = 190.0
	const OUTER_SPIN = -3.0

	var blades : Array = []
	var outer_blades : Array = []
	var radius = 85.0
	var outer_radius = OUTER_RADIUS
	var rotation_speed = 3.0
	var outer_spin = OUTER_SPIN
	var rock_scale = 2.0
	var angle = 0.0
	var outer_angle = 0.0

	func setup():
		super.setup()
		type = Enums.WEAPONS.ORBIT
		needs_target = false

	func _stats() -> Dictionary:
		return LEVEL_STATS[clampi(level, 1, LEVEL_STATS.size()) - 1]

	func apply_level():
		var stats = _stats()
		rock_scale = stats["scale"]
		radius = stats["radius"]
		rotation_speed = stats["spin"]

	func get_blade_count() -> int:
		return _stats()["rocks"] + PlayerStatus.ProjectileCount

	func get_outer_count() -> int:
		return _stats()["outer"]

	func shoot(_owner: Node, _start_position: Vector2, _direction: Vector2):
		pass

	func process(delta: float, player: Node2D):
		blades = blades.filter(func(b): return is_instance_valid(b) and !b.is_queued_for_deletion())
		outer_blades = outer_blades.filter(func(b): return is_instance_valid(b) and !b.is_queued_for_deletion())
		_grow_ring(blades, get_blade_count(), player)
		_grow_ring(outer_blades, get_outer_count(), player)

		angle = wrapf(angle + rotation_speed * delta, 0, TAU)
		outer_angle = wrapf(outer_angle + outer_spin * delta, 0, TAU)
		_place_ring(blades, radius, angle, player)
		_place_ring(outer_blades, outer_radius, outer_angle, player)

	# adds rocks until the ring holds count of them
	func _grow_ring(ring : Array, count : int, player : Node2D):
		while ring.size() < count:
			var blade = create_bullet(player.global_position, Vector2.ZERO)
			blade.Speed = 0
			blade.LifeTime = 100000
			blade.Piercing = true
			object_owner.add_child(blade)
			# the level skin paints the rocks (Tether Rocks); without one the blades keep the cyan tint.
			# set after add_child: the tint node is only ready once the bullet is in the tree
			if !Levels.get_current().get("weapon_skin", {}).has(type):
				blade.set_modulate_color(Color(0.4, 1.6, 2.0))
			else:
				_add_smoke(blade)
			ring.append(blade)
			updateBulletNumber(1)

	# spreads the rocks of a ring evenly on its circle, every rock gets the level scale
	func _place_ring(ring : Array, ring_radius : float, ring_angle : float, player : Node2D):
		if ring.is_empty():
			return
		var step = TAU / ring.size()
		for i in range(ring.size()):
			var offset = Vector2(ring_radius, 0).rotated(ring_angle + i * step)
			ring[i].global_position = player.global_position + offset
			ring[i].scale = Vector2.ONE * rock_scale
			# point along the direction of flight (tangent of the circle)
			ring[i].rotation = offset.angle() + PI

	# smoke puffs left behind each rock (Tether Rocks). Emitted in global space, so the puffs stay
	# where the rock was and form a trail while it orbits; they go with the rock when it is freed
	func _add_smoke(blade):
		var smoke = CPUParticles2D.new()
		smoke.texture = load(SMOKE_TEXTURE)
		smoke.local_coords = false
		smoke.amount = 36
		smoke.lifetime = 1.1
		smoke.explosiveness = 0.0
		smoke.spread = 180.0
		smoke.gravity = Vector2.ZERO
		smoke.initial_velocity_min = 3.0
		smoke.initial_velocity_max = 12.0
		# the texture is 512 px: these scales give puffs of about 40-80 px
		smoke.scale_amount_min = 0.08
		smoke.scale_amount_max = 0.16
		var fade = Gradient.new()
		fade.colors = PackedColorArray([Color(1, 1, 1, 0.7), Color(0.8, 0.8, 0.82, 0.0)])
		smoke.color_ramp = fade
		blade.add_child(smoke)

	# public - removes blades when the player dies
	func clear():
		for blade in blades + outer_blades:
			if is_instance_valid(blade):
				blade.dispose()
		blades.clear()
		outer_blades.clear()

# acid spit of the worm boss, fires count bullets in a fan,
# spread = TAU / count gives a full ring
class WormSpit extends Weapon:
	var count = 5

	func setup():
		shooting_delay = 0.05
		speed = 5
		life_time = 3
		spread = 0.2
		bullet_scene = preload("res://scenes/levels/level1/worm_bullet.tscn")
		audio.stream = load("res://resources/vendor/kenney/space_shooter_redux/Bonus/sfx_laser1.ogg")
		type = Enums.WEAPONS.WORM_SPIT
		needs_target = false

	func get_projectile_count() -> int:
		return count
