class_name EnemyBase
extends CharacterBody2D

# Plumbing shared by every enemy and boss: hit points, damage numbers, the hit box,
# the dissolve-in, the physics gate and the death sequence.
# Subclasses set their stats and name in _init() (a scene override still wins) and
# extend the hooks below instead of copying the methods.

const HALF_PI = PI / 2
# the fragments fade out in a second, sound and particles are pooled in Juice
const DEATH_DELAY = 1.2
const FLOATING_TEXT_SCENE = preload("res://scenes/effects/floating_text.tscn")

@export var Life = 30
@export var Knockback = 200
# public
@export var Damage = 8
# public
@export var IsDamageOverTime = true
# public
@export var DamageTickTime = 0.5
@export var RotationSpeed : float = TAU

signal killed

# set by each subclass in _init(), enemy_kind by LevelSettings.get_enemy()
var enemy_name = ""
var enemy_kind : int = -1
var idleAnimation : StringName = &"Fly"
# a swarm should not move its legs in sync
var randomStartFrame = true
var dissolveIn = 0.5
# long bodies (capsules, polygons) turn their collision shapes with the ship
var shapesFollowShip = false
# tint of the fragments, null keeps the default colour
var fragmentTint = null

var isDead = false
var showDamage = true
var player = null
var deathTimer = Timer.new()

@onready var ship = $Ship
@onready var sprite = $Ship/AnimatedSprite2D
@onready var collisionShape = $CollisionShape2D
@onready var hitBox = $HitBox
@onready var hitBoxShape = $HitBox.get_child(0)
@onready var lifeBar = $LifeBar
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D
@onready var mark = $Mark


func _ready() -> void:
	# physics waits one frame, the spawn position settles first
	set_physics_process(false)
	call_deferred("skip_frame")

	var visualSettings = ConfigHandler.load_visuals()
	showDamage = visualSettings["show_damage_given"]
	lifeBar.visible = _show_life_bar(visualSettings)
	lifeBar.setColor(Color.GREEN)
	lifeBar.setMaxValue(Life)
	lifeBar.setValue(Life)

	player = get_tree().get_first_node_in_group("player")

	deathTimer.one_shot = true
	deathTimer.wait_time = DEATH_DELAY
	deathTimer.timeout.connect(dispose)
	add_child(deathTimer)

	sprite.play(idleAnimation)
	if randomStartFrame:
		sprite.frame = randi() % sprite.sprite_frames.get_frame_count(idleAnimation)

	_on_ready()

	if dissolveIn > 0.0:
		get_tree().create_tween().tween_method(set_shader_dissolve_value, 0.0, 1.0, dissolveIn)


func skip_frame() -> void:
	await get_tree().physics_frame
	# a body killed in its first frame stays dead
	if !isDead:
		set_physics_process(true)


# public
func get_enemy_name() -> String:
	return enemy_name


# public
func setup_rotation(angle: float) -> void:
	ship.rotate(angle)
	_follow_ship_shapes()


# public
func set_mark() -> void:
	mark.activate(1.0)


func set_shader_dissolve_value(value: float) -> void:
	if Juice.is_flashing(sprite):
		return
	sprite.material.set_shader_parameter("DissolveValue", value)


func dispose() -> void:
	if !is_queued_for_deletion():
		queue_free()


# public - the death sequence: the body stops, the fragments fly, killed is announced
func explode() -> void:
	isDead = true
	Juice.play_sound(audio)
	set_physics_process(false)
	_on_died()
	_disable_body()
	_shatter()
	killed.emit(get_instance_id())


func handleDamage(damage, label_position = null) -> bool:
	if showDamage and FloatingText.can_spawn(damage.Critical):
		var damageText = FLOATING_TEXT_SCENE.instantiate()
		damageText.RoundNumber = true
		damageText.Big = damage.Critical
		damageText.set_color(Color.YELLOW if damage.Critical else Color.WHITE)
		damageText.Amount = str(damage.Value)
		add_child(damageText)
		if label_position != null:
			damageText.set_global_position(label_position)

	Life = Life - damage.Value
	lifeBar.setValue(Life)
	_on_damage_taken()
	return Life > 0


# turns the ship towards a direction, at most RotationSpeed radians per second
func _turn_towards(direction: Vector2, delta: float) -> void:
	var theta = wrapf(atan2(direction.y, direction.x) - ship.rotation - HALF_PI, -PI, PI)
	var diff = clamp(RotationSpeed * delta, 0, abs(theta) * sign(theta))
	ship.rotation = move_toward(ship.rotation, ship.rotation + diff, 0.1)
	_follow_ship_shapes()


func _follow_ship_shapes() -> void:
	# changing a shape transform makes the physics server update it, so only on a real turn
	if !shapesFollowShip or collisionShape.rotation == ship.rotation:
		return
	collisionShape.rotation = ship.rotation
	hitBoxShape.rotation = ship.rotation


# the common death pieces, subclasses call them from their own explode()
func _disable_body() -> void:
	collisionShape.set_deferred("disabled", true)
	hitBoxShape.set_deferred("disabled", true)
	lifeBar.visible = false


# the explosion breaks the frame that was shown into fragments
func _shatter() -> void:
	ship.visible = false
	explosion.visible = true
	explosion.SpriteTexture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	explosion.rotation = ship.rotation + sprite.rotation
	explosion.scale = sprite.scale
	if fragmentTint != null:
		explosion.set_particle_color(fragmentTint)
	explosion.explode()
	deathTimer.start()


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		_on_player_contact()
	elif area.is_in_group("Bullet"):
		_on_bullet_hit(area.get_parent())


func _on_bullet_hit(bullet) -> void:
	if !bullet.is_damaging_enemy():
		return

	Juice.hit_effect(self, bullet.get_global_position())

	if !_accepts_hits():
		return

	if _knockback_enabled():
		velocity += bullet.global_position.direction_to(global_position) * Knockback
	_flash_hit()

	if handleDamage(_damage_from_bullet(bullet), _label_position(bullet)) == false:
		explode()


# ---- hooks for subclasses ----

func _on_ready() -> void:
	pass


func _show_life_bar(visualSettings: Dictionary) -> bool:
	return visualSettings["show_enemies_lifebar"]


# stop timers, emitters and anything else that belongs to a living body
func _on_died() -> void:
	pass


func _on_player_contact() -> void:
	pass


func _accepts_hits() -> bool:
	return !isDead


func _knockback_enabled() -> bool:
	return true


func _flash_hit() -> void:
	Juice.flash(sprite)


func _damage_from_bullet(bullet):
	return PlayerStatus.get_damage_from_weapon(bullet.Type, self)


# where the damage number appears, null lets it follow the ship
func _label_position(_bullet):
	return null


func _on_damage_taken() -> void:
	pass


func _physics_process(_delta: float) -> void:
	pass
