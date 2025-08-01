extends Node2D

@onready var baseDamageLabel = $BaseDamageLabel
@onready var cirticalChanceLabel = $CriticalChanceLabel
@onready var criticalMultiplierLabel = $CriticalMultiplierLabel
@onready var speedLabel = $SpeedLabel

func _ready() -> void:
	baseDamageLabel.text = "Base damage: " + str(int(PlayerStatus.BaseDamage)) + "%"
	cirticalChanceLabel.text = "Cricital chance: " + str(int(PlayerStatus.CriticalHitChance)) + "%"
	criticalMultiplierLabel.text = "Critical multiplier: " + str(int(PlayerStatus.CriticalHitMultiplier)) + "%"
	speedLabel.text = "Speed: " + str(int(PlayerStatus.Speed)) + "%"
	
	PlayerStatus.connect("base_damage_changed", on_base_damage_changed)
	PlayerStatus.connect("critical_hit_chance_changed", on_cirtic_chance_up_changed)
	PlayerStatus.connect("critcal_hit_multipayer_changed", on_critic_hit_multiplier_changed)
	PlayerStatus.connect("speed_changed", on_speed_changed)
	

func on_base_damage_changed(value):
	baseDamageLabel.text = "Base damage: " + str(int(value)) + "%"
	
func on_cirtic_chance_up_changed(value):
	cirticalChanceLabel.text = "Cricital chance: " + str(int(value)) + "%"
	
func on_critic_hit_multiplier_changed(value):
	criticalMultiplierLabel.text = "Critical multiplier: " + str(int(value)) + "%"
	
func on_speed_changed(value):
	speedLabel.text = "Speed: " + str(int(value)) + "%"
