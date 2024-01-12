extends CharacterBody2D

@onready var satelite = $Satelite

@export var PlayerVelocity = 200
@export var SateliteRotationSpeed = 5
@export var SateliteRadius = 25

var angle = 0
var direction = Vector2(0, 0)

func _physics_process(delta):
	calculateSatelitePosition(delta)
	
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	velocity = direction.normalized() * PlayerVelocity
	
	move_and_slide()
	

func calculateSatelitePosition(delta):
	angle = angle + SateliteRotationSpeed * delta
	satelite.position.x = SateliteRadius * cos(angle)
	satelite.position.y = SateliteRadius * sin(angle)
	
