extends CharacterBody2D

@onready var satelite = $Satelite
@onready var mainBody = $MainBody
@onready var camera = $Camera2D

@export_category("Player")
@export var PlayerMaxVelocity = 200
@export var PlayerAcceleration = 10
@export var TurboFactor = 2
@export var PlayerFriction = 5
@export var SateliteRotationSpeed = 5
@export var SateliteRadius = 25
@export var PlayerRotationSpeed = 5

@export_category("Camera")
@export var ZoomFactor = 0.2

var sateliteAngle = 0
var playerAngle = 0
var direction = Vector2(0, 0)
var calculatedMaxVelocity = PlayerMaxVelocity
var calculatedAcceleration = PlayerAcceleration

func _physics_process(delta):
	handleZoom()	
	calculatePlayerRotation(delta)
	calculateSatelitePosition(delta)
	calculateAcceleration()
	calculateVelocity()
	
	move_and_slide()


func handleZoom():
	if Input.is_action_just_pressed("ui_zoom"):
		camera.zoom = Vector2(ZoomFactor, ZoomFactor)
		return
		
	if Input.is_action_just_released("ui_zoom"):
		camera.zoom = Vector2(1, 1)


func calculateAcceleration():
	if Input.is_action_just_pressed("ui_accelerate"):
		calculatedMaxVelocity = PlayerMaxVelocity * TurboFactor
		calculatedAcceleration = PlayerAcceleration * TurboFactor
		return
	
	if Input.is_action_just_released("ui_accelerate"):
		calculatedMaxVelocity = PlayerMaxVelocity
		calculatedAcceleration = PlayerAcceleration


func calculateVelocity():
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	if direction.length() == 0:
		velocity = velocity.move_toward(Vector2(0, 0), PlayerFriction)
	else:
		velocity = velocity.move_toward(direction.normalized() * calculatedMaxVelocity, calculatedAcceleration)


func calculateSatelitePosition(delta):
	sateliteAngle = sateliteAngle + SateliteRotationSpeed * delta
	satelite.position.x = SateliteRadius * cos(sateliteAngle)
	satelite.position.y = SateliteRadius * sin(sateliteAngle)
	

func calculatePlayerRotation(delta):
	playerAngle = playerAngle + PlayerRotationSpeed * delta
	mainBody.rotation = -playerAngle
