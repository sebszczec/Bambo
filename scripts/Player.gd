extends CharacterBody2D

@onready var satelite = $Satelite

@export var SateliteRotationSpeed = 5
@export var SateliteRadius = 25
var angle = 0

func _physics_process(delta):
	calculateSatelitePosition(delta)
	

func calculateSatelitePosition(delta):
	angle = angle + SateliteRotationSpeed * delta
	satelite.position.x = SateliteRadius * cos(angle)
	satelite.position.y = SateliteRadius * sin(angle)
	
