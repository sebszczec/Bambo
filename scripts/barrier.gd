extends Node2D

@onready var sprite = $Sprite2D
@onready var energyShield = $CollisionShape2D

func changeState(enabled):
	sprite.visible = enabled
	energyShield.disabled = !enabled
