extends CharacterBody2D

@export var Life = 200
# public
@export var Damage = 0
# public
@export var IsDamageOverTime = false
# public
@export var DamageTickTime = 0.0

var floatingTextScene = preload("res://scenes/floating_text.tscn")
var hitEffectScene = preload("res://scenes/hit_effect.tscn")

@onready var ship = $Ship
@onready var lifeBar = $LifeBar
@onready var collisionShape = $CollisionShape2D
@onready var hitBoxCollisionShape = $HitBox/CollisionShape2D
@onready var explosion = $Explosion
@onready var audio = $AudioStreamPlayer2D

var _showDamage = false
var _deathTimer = Timer.new()
var _isDead = false

signal killed

func _ready() -> void:
	var visualSettings = ConfigHandler.load_visuals()
	_showDamage = visualSettings["show_damage_given"]
	lifeBar.visible = visualSettings["show_enemies_lifebar"]
	lifeBar.setColor(Color.GREEN)
	
	_deathTimer.one_shot = true
	_deathTimer.wait_time = 2
	_deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(_deathTimer)

func _physics_process(_delta: float) -> void:
	pass

func get_enemy_name():
	return "Enemy 3"

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		var hit_effect = hitEffectScene.instantiate()
		add_child(hit_effect)
		hit_effect.emitting = true
		
		if handleDamage(bullet.Damage) == false and !_isDead:
			_isDead = true
			explode()

func handleDamage(damage):
	if _showDamage:
		var damageText = floatingTextScene.instantiate()
		damageText.set_color(Color.WHITE)
		damageText.Amount = str(damage)
		add_child(damageText)
		
	Life = Life - damage
	lifeBar.setValue(Life)
	
	if Life <= 0:
		return false

func _on_death_timer_timeout():
	dispose()

func dispose():
	if !is_queued_for_deletion():
		queue_free()

func explode():
	audio.play()
	ship.visible = false
	collisionShape.set_deferred("disabled", true)
	hitBoxCollisionShape.set_deferred("disabled", true)
	lifeBar.visible = false
	explosion.visible = true
	explosion.rotation = ship.rotation
	explosion.Explode()
	_deathTimer.start()
	killed.emit(get_instance_id())
