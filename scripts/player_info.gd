extends Node2D

@onready var baseDamageLabel = $BaseDamageLabel

func _ready() -> void:
	baseDamageLabel.text = "Base damage: " + str(int(PlayerStatus.BaseDamage * 100)) + "%"
	
	PlayerStatus.connect("base_damage_changed", on_base_damage_changed)
	

func on_base_damage_changed(value):
	baseDamageLabel.text = "Base damage: " + str(int(value * 100)) + "%"
	
