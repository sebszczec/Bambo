extends Node2D

# Homing mine dropped by the worm boss. It slowly follows the player,
# blinks and bursts into a ring of acid spit. Touching it hurts and pops it,
# it can also be shot down before it bursts.

# public - read by the player on contact
@export var Damage = 30
# public
@export var IsDamageOverTime = false
# public
@export var DamageTickTime = 0.0
@export var Life = 3
@export var Speed = 120.0
@export var Steering = 260.0
@export var HomingTime = 3.0
@export var BlinksNumber = 3
@export var BurstCount = 10

@onready var sprite = $Sprite2D
@onready var glow = $Glow
@onready var hit_box_collision = $HitBox/CollisionShape2D
@onready var blinking_sound = $BlinkingSoundPlayer
@onready var explosion_sound = $ExplosionSoundPlayer

# public - launch speed, set by the boss before adding the mine
var velocity = Vector2.ZERO

var _player = null
var _world = null
var _weapon = null
var _time = 0.0
var _done = false

func _ready() -> void:
	_world = get_tree().current_scene
	_player = get_tree().get_first_node_in_group("player")

	_weapon = WeaponFactory.get_weapon(Enums.WEAPONS.WORM_SPIT, true, false)
	_weapon.set_owner(_world)
	_weapon.register_internal_nodes(self)
	_weapon.count = BurstCount
	_weapon.spread = TAU / BurstCount
	_weapon.speed = 4

	# pop in
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_run()

func _physics_process(delta: float) -> void:
	if _done:
		return

	_time += delta
	if _player != null and is_instance_valid(_player) and !_player.isDead:
		var desired = global_position.direction_to(_player.global_position) * Speed
		velocity = velocity.move_toward(desired, Steering * delta)
	position += velocity * delta

	sprite.rotation += delta * 4.0
	glow.scale = Vector2.ONE * (0.16 + 0.03 * sin(_time * 8.0))

func _run():
	await get_tree().create_timer(HomingTime, false).timeout
	for i in range(BlinksNumber):
		if _done:
			return
		blinking_sound.play()
		create_tween().tween_method(_set_blink_intensity, 1.0, 0.0, 0.3)
		await get_tree().create_timer(0.3, false).timeout

	if !_done:
		_burst(true)

func _set_blink_intensity(value : float):
	# hit flash removes the material for a moment
	if Juice.is_flashing(sprite):
		return
	sprite.material.set_shader_parameter("blink_intensity", value)

func _burst(spit : bool):
	if _done:
		return
	_done = true

	hit_box_collision.set_deferred("disabled", true)
	explosion_sound.play()
	Juice.hit_effect(_world, global_position)
	if spit:
		_weapon.shoot(_world, global_position, Vector2.DOWN)

	# flash ring, then wait for the sounds before freeing
	sprite.visible = false
	glow.modulate = Color(1.5, 3, 1.5, 1)
	var tween = create_tween().set_parallel()
	tween.tween_property(glow, "scale", Vector2.ONE * 0.6, 0.25)
	tween.tween_property(glow, "modulate:a", 0.0, 0.25)
	await get_tree().create_timer(1.0, false).timeout
	queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	if _done:
		return

	if area.is_in_group("Player"):
		_burst(false)
		return

	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		if !bullet.is_damaging_enemy():
			return

		Juice.flash(sprite, 0.05)
		Life -= 1
		if Life <= 0:
			_burst(false)
