extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	

func get_weapon(weapon: Enums.WEAPONS) -> Weapon:
	if weapon == Enums.WEAPONS.SMALL:
		return SmallBullet.new()
	elif weapon == Enums.WEAPONS.BIG:
		return BigBullet.new()
	elif weapon == Enums.WEAPONS.SMALL_WAVE:
		return SmallBulletWave.new()
	elif weapon == Enums.WEAPONS.SMALL_HOMING:
		return SmallHomingBullet.new()
	elif weapon == Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY:
		return SmallHomingBulletWithDelay.new()
	elif weapon == Enums.WEAPONS.FIREWORKS:
		return Fireworks.new()
	else:
		return SmallBullet.new()
	
	
class Weapon:
	var object_owner = null
	var canShoot = true
	var timer = Timer.new()
	var shooting_delay = 0
	var bullet_scene = null
	var bullet_number = 0
	var speed = 20
	var life_time = 0.5
	var type : Enums.WEAPONS
	
	var audio = AudioStreamPlayer2D.new()
	
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
	
	func _on_timer_timeout():
		canShoot = true
	
	func register_internal_nodes(owner: Node):
		owner.add_child(timer)
		owner.add_child(audio)
	
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet = bullet_scene.instantiate()
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
		
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet = bullet_scene.instantiate()
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
			bullet.velocity = enemy.position - bullet.position

class BigBullet extends Weapon:
	func setup():
		shooting_delay = 0.2
		bullet_scene = preload("res://scenes/big_bullet.tscn")
		audio.stream = load("res://resources/kenney_space-shooter-redux/Bonus/sfx_laser2.ogg")

class SmallBulletWave extends SmallBullet:
	var size = 30
	var min_damage = 25
	var max_damage = 50
	
	func setup():
		super.setup()
		shooting_delay = 1
		speed = 5
		
	func shoot(owner: Node, start_position: Vector2, _direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var radial_increment = (2.0 * PI) / float(size)
			for i in range (0, size):
				var bullet = bullet_scene.instantiate()
				bullet.Speed = speed
				bullet.MinDamage = min_damage
				bullet.MaxDamage = max_damage
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
	var min_damage = 25
	var max_damage = 50
	var explosion_speed = 2
	var explosion_bullet_scene = preload("res://scenes/bullet.tscn")
	var explosion_audio = AudioStreamPlayer2D.new()
	
		
	func setup():
		super.setup()
		shooting_delay = 0.5
		speed = 2
		life_time = 2
		explosion_audio.stream = load("res://resources/kenney_space-shooter-redux/Bonus/sfx_laser2.ogg")
	
	func shoot(owner: Node, start_position: Vector2, direction: Vector2):
		if canShoot:
			audio.play()
			canShoot = false
			var bullet = bullet_scene.instantiate()
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
		audio.play()
		var radial_increment = (2.0 * PI) / float(size)
		for i in range (0, size):
			var bullet = explosion_bullet_scene.instantiate()
			bullet.Speed = explosion_speed
			bullet.MinDamage = min_damage
			bullet.MaxDamage = max_damage
			bullet.LifeTime = 1
			
			var radial_v = Vector2(0.1, 0).rotated(i * radial_increment)
			bullet.position = bullet_owner.position + radial_v
			bullet.velocity = radial_v
			bullet.connect("freeing", _on_bullet_freeing)
			object_owner.add_child(bullet)
		
		timer.start()	
		updateBulletNumber(size)
