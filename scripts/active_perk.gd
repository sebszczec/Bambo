extends Node2D

@export var TimeLeft = 10

@onready var timeLeftLabel = $VBoxContainer/TimeLeftLabel
@onready var sprite = $VBoxContainer/Sprite2D

const defaultState = Enums.WEAPONS.SMALL
var currentState : Enums.WEAPONS = defaultState
var textures : Dictionary = {}

signal timeout

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textures[Enums.WEAPONS.SMALL] = null
	textures[Enums.WEAPONS.BIG] = load("res://resources/perks/big_gun.png")
	textures[Enums.WEAPONS.SMALL_WAVE] = load("res://resources/perks/fire_circle.png")
	textures[Enums.WEAPONS.SMALL_HOMING] = load("res://resources/perks/rocket.png")
	textures[Enums.WEAPONS.SMALL_HOMING_WIHT_DELAY] = load("res://resources/perks/rocket.png")
	textures[Enums.WEAPONS.BOMB] = load("res://resources/perks/bomb.png")
	changeState(defaultState)


func _physics_process(delta: float) -> void:
	_updateTimeLeft(delta)
	

func _updateTimeLeft(delta):
	if TimeLeft == 0:
		_timeout()
		return

	TimeLeft -= delta
	if TimeLeft < 0:
		TimeLeft = 0
		
	timeLeftLabel.text = "%0.2f" % TimeLeft

func _timeout():
	if currentState == defaultState:
		return
	
	changeState(defaultState)
	timeLeftLabel.text = ""
	timeout.emit(currentState)

func changeState(weapon : Enums.WEAPONS):
	currentState = weapon
	sprite.texture = textures[currentState]
	
	if weapon == Enums.WEAPONS.SMALL or weapon == Enums.WEAPONS.BOMB:
		TimeLeft = 0
	else:
		TimeLeft = 10
