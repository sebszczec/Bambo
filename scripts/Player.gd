extends CharacterBody2D

@onready var satelite = $Satelite
@onready var mainBody = $MainBody

@export var PlayerMaxVelocity = 200
@export var PlayerAcceleration = 10
@export var PlayerFriction = 5
@export var SateliteRotationSpeed = 5
@export var SateliteRadius = 25
@export var PlayerRotationSpeed = 5

var sateliteAngle = 0
var playerAngle = 0
var direction = Vector2(0, 0)

func _physics_process(delta):
	calculatePlayerRotation(delta)
	calculateSatelitePosition(delta)
	
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	if direction.length() == 0:
		velocity = velocity.move_toward(Vector2(0, 0), PlayerFriction)
	else:
		velocity = velocity.move_toward(direction.normalized() * PlayerMaxVelocity, PlayerAcceleration)
	
	
	move_and_slide()
	

func calculateSatelitePosition(delta):
	sateliteAngle = sateliteAngle + SateliteRotationSpeed * delta
	satelite.position.x = SateliteRadius * cos(sateliteAngle)
	satelite.position.y = SateliteRadius * sin(sateliteAngle)
	

func calculatePlayerRotation(delta):
	playerAngle = playerAngle + PlayerRotationSpeed * delta
	mainBody.rotation = -playerAngle
