extends CharacterBody2D

var floatingTextScene = preload("res://scenes/floating_text.tscn")

@onready var satelite = $Satelite
@onready var mainBody = $MainBody
@onready var camera = $Camera2D
@onready var lifeBar = $LifeBar
@onready var shieldBar = $ShieldBar
@onready var explosion = $PlayerExplosion
@onready var audio = $AudioStreamPlayer2D

@export_category("Player")
@export var PlayerMaxVelocity = 200
@export var PlayerAcceleration = 10
@export var TurboFactor = 2
@export var PlayerFriction = 5
@export var SateliteRotationSpeed = 5
@export var SateliteRadius = 25
@export var PlayerRotationSpeed = 5
@export var MaxLife = 100
@export var MaxAfterburner = 100
@export var MaxShield = 100
var currentAfterburner = MaxAfterburner
var afterBurnerStep = 10
var burn = false
var life = MaxLife
var shield = MaxShield
var isDead = false

@export_category("Camera")
@export var ZoomFactor = 2

var sateliteAngle = 0
var playerAngle = 0
var playerRotationDirection = 1
var direction = Vector2(0, 0)
var calculatedMaxVelocity = PlayerMaxVelocity
var calculatedAcceleration = PlayerAcceleration
var aim_vector = Vector2(0, 0)
var aim_angle = 0
var showLifeBar = true
var showDamage = true
var useGamePad = true
var deathTimer = Timer.new()

var enemyDamageTimers = {}

signal update_life(value: int)
signal update_afterburner(value: int)
signal update_shield(value: int)
signal killed

func _ready() -> void:
	lifeBar.setColor(Color.RED)
	shieldBar.setColor(Color.DODGER_BLUE)
	
	var visualSettings = ConfigHandler.load_visuals()
	showLifeBar = visualSettings["show_player_lifebar"]
	showDamage = visualSettings["show_damage_taken"]
	lifeBar.setMaxValue(MaxLife)
	lifeBar.visible = showLifeBar
	shieldBar.setMaxValue(MaxShield)
	shieldBar.visible = showLifeBar
	
	var controlSettings = ConfigHandler.load_controls()
	useGamePad = controlSettings["use_gamepad"]
	
	deathTimer.one_shot = true
	deathTimer.wait_time = 2
	deathTimer.connect("timeout", _on_death_timer_timeout)
	add_child(deathTimer)


func _physics_process(delta):
	handleZoom()	
	calculatePlayerRotation(delta)
	calculateSatelitePosition(delta)
	calculateAcceleration()
	calculateVelocity()
	calculateAfterburner(delta)
	
	move_and_slide()

func explode():
	audio.play()
	explosion.position = mainBody.position
	explosion.rotation = mainBody.rotation
	explosion.modulate = Color.BLUE
	mainBody.visible = false
	satelite.visible = false
	lifeBar.visible = false
	shieldBar.visible = false
	explosion.visible = true
	explosion.Explode()

func handleZoom():
	if Input.is_action_just_pressed("ui_zoom"):
		camera.zoom = Vector2(ZoomFactor, ZoomFactor)
		return
		
	if Input.is_action_just_released("ui_zoom"):
		camera.zoom = Vector2(1.25, 1.25)


func calculateAfterburner(delta):
	if burn && currentAfterburner > 0:
		updateAfterBurner(-afterBurnerStep * delta)
		
	if !burn && currentAfterburner < MaxAfterburner:
		updateAfterBurner(afterBurnerStep * delta)


func calculateAcceleration():
	if currentAfterburner > 0:
		if Input.is_action_just_pressed("ui_accelerate"):
			calculatedMaxVelocity = PlayerMaxVelocity * TurboFactor
			calculatedAcceleration = PlayerAcceleration * TurboFactor
			playerRotationDirection = -2
			burn = true
	else:
		calculatedMaxVelocity = PlayerMaxVelocity
		calculatedAcceleration = PlayerAcceleration
		playerRotationDirection = 1
		
	if Input.is_action_just_released("ui_accelerate"):
		calculatedMaxVelocity = PlayerMaxVelocity
		calculatedAcceleration = PlayerAcceleration
		playerRotationDirection = 1
		burn = false
		
		
func calculateVelocity():
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	if direction.length() == 0 or isDead:
		velocity = velocity.move_toward(Vector2(0, 0), PlayerFriction)
	else:
		velocity = velocity.move_toward(direction.normalized() * calculatedMaxVelocity, calculatedAcceleration)

var last_mouse_pos = Vector2(0, 0)
func calculateSatelitePosition(delta):
	if useGamePad:
		aim_vector.x = Input.get_axis("ui_aim_left", "ui_aim_right")
		aim_vector.y = Input.get_axis("ui_aim_up", "ui_aim_down")
		aim_angle = atan2(aim_vector.y, aim_vector.x)
		
		if (aim_vector.x == 0 and aim_vector.y == 0):
			sateliteAngle = sateliteAngle + SateliteRotationSpeed * delta
			satelite.position.x = SateliteRadius * cos(sateliteAngle)
			satelite.position.y = SateliteRadius * sin(sateliteAngle)
			return
		
		satelite.position.x = SateliteRadius * cos(aim_angle)
		satelite.position.y = SateliteRadius * sin(aim_angle)
		sateliteAngle = aim_angle
	else:
		var mouse_pos = get_global_mouse_position()
		mouse_pos = get_global_mouse_position() - position
		satelite.position = mouse_pos.normalized() * SateliteRadius
	

func getSatelitePosition() -> Vector2:
	return satelite.get_global_position()


func calculatePlayerRotation(delta):
	playerAngle = playerAngle + PlayerRotationSpeed * playerRotationDirection * delta 
	mainBody.rotation = -playerAngle


func getShootingVector():
	return satelite.position

func _on_death_timer_timeout():
	killed.emit()

func _on_life_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		var enemy = area.get_parent()
		var id = enemy.get_instance_id()
		
		if !isDead and handleDamage(enemy.Damage) == false:
			handleKilled()
			return
		
		if enemy.IsDamageOverTime == true:
			var timer = Timer.new()
			timer.one_shot = false
			timer.wait_time = enemy.DamageTickTime
			timer.connect("timeout", _on_take_damage_timeout.bind(enemy))
			add_child(timer)
			timer.start()
			
			enemyDamageTimers[id] = timer
		return
		
	if area.is_in_group("Bullet"):
		var bullet = area.get_parent()
		#var hit_effect = hitEffectScene.instantiate()
		#add_child(hit_effect)
		#hit_effect.emitting = true
		
		if !isDead and handleDamage(bullet.Damage) == false:
			handleKilled()
			return


func _on_take_damage_timeout(enemy):
	if handleDamage(enemy.Damage) == false:
		handleKilled()


func handleDamage(damage):
	Input.start_joy_vibration(0, 0.5, 0.5, 0.1)
	
	var real_damage = damage
	if shield > 0:
		real_damage -= shield
		if real_damage < 0:
			real_damage = 0
		var tmp = updateShield(-damage)
		if showDamage:
			createShieldFloatingText(str(-tmp))
		
	if showDamage && real_damage > 0:
		createLifeFloatingText(str(real_damage))
	
	updateLife(-real_damage)
	
	if life <= 0:
		return false
	
	return true


func handleKilled():
	isDead = true
	$LifeBox/CollisionShape2D.set_deferred("disabled", true)
	explode()
	deathTimer.start()

func createFloatingText(value: String, color: Color, scale_factor: float = 1):
	var damageText = floatingTextScene.instantiate()
	damageText.scale = Vector2(scale_factor, scale_factor)
	damageText.set_color(color)
	damageText.Amount = value
	add_child(damageText)


func createLifeFloatingText(value, scale_factor: float = 1):
	createFloatingText(value, Color.RED, scale_factor)
	
	
func createShieldFloatingText(value, scale_factor: float = 1):
	createFloatingText(value, Color.DODGER_BLUE, scale_factor)


func updateShield(value):
	shield += value
	
	var tmp = value
	if shield < 0:
		tmp = shield + value
		shield = 0
	
	if shield > MaxShield:
		shield = MaxShield
		
	shieldBar.setValue(shield)
	update_shield.emit(shield)
	
	return tmp
	

func updateLife(value):
	life += value
	
	if life < 0:
		life = 0
	
	if life > MaxLife:
		life = MaxLife
	
	lifeBar.setValue(life)
	update_life.emit(life)

func _on_life_box_area_exited(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		var enemy = area.get_parent()
		var id = enemy.get_instance_id()
		
		if enemyDamageTimers.has(id):
			enemyDamageTimers[id].stop()
			enemyDamageTimers.erase(id)
		return
	
	if area.is_in_group("LifePerk"):
		createLifeFloatingText("+" + str(area.Life), 2)
		updateLife(area.Life)
		return
		
	if area.is_in_group("ShieldPerk"):
		createShieldFloatingText("+" + str(area.Shield), 2)
		updateShield(area.Shield)
		return

func updateAfterBurner(value):
	currentAfterburner += value
	update_afterburner.emit(currentAfterburner)
