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
	else:
		result = SmallBullet.new()
		
	result.setDamagingPlayer(damaging_player)
	result.setDamagingEnemy(damaging_enemy)
		
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
	
	var audio = AudioStreamPlayer2D.new()
	var explosion_audio = AudioStreamPlayer2D.new()
	
	signal bulletNumerChange
	
	func _init() -> void:
		setup()
		timer.wait_time = shooting_delay
		timer.connect("timeout", _on_timer_timeout)
	
	func setup():
		shooting_delay = 0.1
		bullet_scene = preload("res://scenes/bullet.tscn")
		audio.stream = load("res://resources/kenney_space-shooter-redux/Bonus/sfx_laser2.ogg")
		
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
	
	func _on_timer_timeout():
		canShoot = true
	
	func register_internal_nodes(owner: Node):
		owner.add_child(timer)
		owner.add_child(audio)
		owner.add_child(explosion_audio)
	
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet = bullet_scene.instantiate()
			bullet.Type = type
			bullet.set_collision_mask(collision_mask)
			bullet.position = start_position
			bullet.velocity = direction
			bullet.Speed = speed
			bullet.LifeTime = life_time
			bullet.connect("freeing", _on_bullet_freeing)
			owner.add_child(bullet)
			timer.start()
				
			updateBulletNumber(1)
	
	func _on_bullet_freeing(_owner):
		updateBulletNumber(-1)

		
	func updateBulletNumber(diff):
		bullet_number += diff
		bulletNumerChange.emit(bullet_number)


class SmallBullet extends Weapon:
	pass
	
class SmallHomingBullet extends SmallBullet:
	func setup():
		super.setup()
		shooting_delay = 0.2
		speed = 5
		life_time = 1
		type = Enums.WEAPONS.SMALL_HOMING
		
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		var enemy = object_owner.find_nearest_enemy()
		if enemy != null:
			super.shoot(owner, start_position, enemy.position - start_position)
		else:
			super.shoot(owner, start_position, direction)

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
			var bullet = bullet_scene.instantiate()
			bullet.Type = type
			bullet.set_collision_mask(collision_mask)
			bullet.position = start_position
			bullet.velocity = direction
			bullet.Speed = speed
			bullet.LifeTime = life_time
			bullet.connect("freeing", _on_bullet_freeing)
			
			var homing_timer = Timer.new()
			homing_timer.one_shot = true
			homing_timer.wait_time = 0.1
			homing_timer.connect("timeout", _homing_timer_on_timeout.bind(bullet))
			bullet.add_child(homing_timer)
			
			owner.add_child(bullet)
			timer.start()
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
		bullet_scene = preload("res://scenes/big_bullet.tscn")
		audio.stream = load("res://resources/kenney_space-shooter-redux/Bonus/sfx_laser2.ogg")
		type = Enums.WEAPONS.BIG

class SmallBulletWave extends SmallBullet:
	var size = 30
	
	func setup():
		super.setup()
		shooting_delay = 1
		speed = 5
		type = Enums.WEAPONS.SMALL_WAVE
		
	func shoot(owner: Node, start_position: Vector2, _direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var radial_increment = (2.0 * PI) / float(size)
			for i in range (0, size):
				var bullet = bullet_scene.instantiate()
				bullet.Type = type
				bullet.set_collision_mask(collision_mask)
				bullet.Speed = speed
				bullet.LifeTime = 1
				
				var radial_v = Vector2(0.1, 0).rotated(i * radial_increment)
				bullet.position = start_position + radial_v
				bullet.velocity = radial_v
				bullet.connect("freeing", _on_bullet_freeing)
				owner.add_child(bullet)
			
			timer.start()	
			updateBulletNumber(size)

class Fireworks extends BigBullet:
	var size = 30
	var explosion_speed = 2
	var explosion_bullet_scene = preload("res://scenes/bullet.tscn")
	
		
	func setup():
		super.setup()
		shooting_delay = 0.5
		speed = 2
		life_time = 2
		explosion_audio.stream = load("res://resources/explode_sounds/350977__cabled_mess__boom_c_06.wav")
		type = Enums.WEAPONS.FIREWORKS
		
	
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet = bullet_scene.instantiate()
			bullet.Type = type
			bullet.set_collision_mask(collision_mask)
			bullet.position = start_position
			bullet.velocity = direction
			bullet.Speed = speed
			bullet.LifeTime = life_time
			bullet.connect("freeing", _on_bullet_freeing)
			bullet.connect("freeing", _explode)
			owner.add_child(bullet)
			timer.start()
				
			updateBulletNumber(1)
	
	func _explode(bullet_owner):
		explosion_audio.play()
		var radial_increment = (2.0 * PI) / float(size)
		for i in range (0, size):
			var bullet = explosion_bullet_scene.instantiate()
			bullet.Type = type
			bullet.set_collision_mask(collision_mask)
			bullet.Speed = explosion_speed

			bullet.LifeTime = 1
			
			var radial_v = Vector2(0.1, 0).rotated(i * radial_increment)
			bullet.position = bullet_owner.position + radial_v
			bullet.velocity = radial_v
			bullet.connect("freeing", _on_bullet_freeing)
			object_owner.call_deferred("add_child", bullet)

		updateBulletNumber(size)
