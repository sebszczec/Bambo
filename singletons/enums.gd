extends Node

enum WEAPONS {SMALL, BIG, SMALL_WAVE, SMALL_HOMING, SMALL_HOMING_WIHT_DELAY, FIREWORKS}
enum PERKS {LIFE, SHIELD, DAMAGE_UP, CRITIC_CHANCE_UP, CRITIC_HIT_MULTIPLIER, BIG_GUN, WAVE, HOMING}
enum ENEMIES { SCOUT, GUARD, HUNTER }
enum MASKS {PLAYER = 1, ENEMY = 8}
enum PHASE { Phase1, Phase2, Phase3 }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
