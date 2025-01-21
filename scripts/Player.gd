extends CharacterBody2D

var floatingTextScene = preload("res://scenes/floating_text.tscn")

@onready var satelite = $Satelite
@onready var mainBody = $MainBody
@onready var camera = $Camera2D
@onready var lifeBar = $LifeBar

@export_category("Player")
@export var PlayerMaxVelocity = 200
@export var PlayerAcceleration = 10
@export var TurboFactor = 2
@export var PlayerFriction = 5
@export var SateliteRotationSpeed = 5
@export var SateliteRadius = 25
@export var PlayerRotationSpeed = 5
@export var Life = 100
@export var Afterburner = 100
var currentAfterburner = Afterburner
var afterBurnerStep = 10
var burn = false

@export_category("Camera")
@export var ZoomFactor = 0.2

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

var enemyDamagetimers = {}

signal update_life(value: int)
signal update_afterburner(value: int)

func _ready() -> void:
	lifeBar.setColor(Color(255, 0, 0))
	
	var visualSettings = ConfigHandler.load_visuals()
	showLifeBar = visualSettings["show_player_lifebar"]
	showDamage = visualSettings["show_damage_taken"]
	lifeBar.setMaxValue(Life)
	lifeBar.visible = showLifeBar


func _physics_process(delta):
	handleZoom()	
	calculatePlayerRotation(delta)
	calculateSatelitePosition(delta)
	calculateAcceleration()
	calculateVelocity()
	calculateAfterburner(delta)
	
	move_and_slide()


func handleZoom():
	if Input.is_action_just_pressed("ui_zoom"):
		camera.zoom = Vector2(ZoomFactor, ZoomFactor)
		return
		
	if Input.is_action_just_released("ui_zoom"):
		camera.zoom = Vector2(1, 1)


func calculateAfterburner(delta):
	if burn && currentAfterburner > 0:
		updateAfterBurner(-afterBurnerStep * delta)
		
	if !burn && currentAfterburner < Afterburner:
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
	
	if direction.length() == 0:
		velocity = velocity.move_toward(Vector2(0, 0), PlayerFriction)
	else:
		velocity = velocity.move_toward(direction.normalized() * calculatedMaxVelocity, calculatedAcceleration)


func calculateSatelitePosition(delta):
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
	

func calculatePlayerRotation(delta):
	playerAngle = playerAngle + PlayerRotationSpeed * playerRotationDirection * delta 
	mainBody.rotation = -playerAngle


func getShootingVector():
	return satelite.position


func _on_life_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		var enemy = area.get_parent()
		var id = enemy.get_instance_id()
		
		if handleDamage(enemy.Damage) == false:
			pass # handle dead of player
		
		if enemy.IsDamageOverTime == true:
			var timer = Timer.new()
			timer.one_shot = false
			timer.wait_time = enemy.DamageTickTime
			timer.connect("timeout", _on_take_damage_timeout.bind(enemy))
			add_child(timer)
			timer.start()
			
			enemyDamagetimers[id] = timer


func _on_take_damage_timeout(enemy):
	if handleDamage(enemy.Damage) == false:
		pass # handle dead of player


func handleDamage(damage):
	if showDamage:
		var damageText = floatingTextScene.instantiate()
		damageText.Amount = damage
		add_child(damageText)
	
	Life = Life - damage
	lifeBar.setValue(Life)
	
	update_life.emit(Life)
	
	if Life == 0:
		return false
	
	return true

func _on_life_box_area_exited(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		var enemy = area.get_parent()
		var id = enemy.get_instance_id()
		
		if enemyDamagetimers.has(id):
			enemyDamagetimers[id].stop()
			enemyDamagetimers.erase(id)

func updateAfterBurner(value):
	currentAfterburner += value
	update_afterburner.emit(currentAfterburner)
