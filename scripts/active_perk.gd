extends Node2D

@export var TimeLeft = 10

@onready var timeLeftLabel = $VBoxContainer/TimeLeftLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_updateTimeLeft(0)


func _physics_process(delta: float) -> void:
	_updateTimeLeft(delta)
	

func _updateTimeLeft(delta):
	if TimeLeft == 0:
		return

	TimeLeft -= delta
	if TimeLeft < 0:
		TimeLeft = 0
		
	timeLeftLabel.text = "%0.2f" % TimeLeft
		
