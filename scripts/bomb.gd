extends StaticBody2D

@onready var own_collision_shape = $CollisionShape2D
@onready var hit_box_collision_shape = $HitBox/CollisionShape2D

@export var MaxScale = 100.0
@export var Type : Enums.WEAPONS = Enums.WEAPONS.BOMB

var _current_scale = Vector2(1.0, 1.0)
var _scale_step = 100.0

signal freeing

func _ready() -> void:
	pass

func is_damaging_player() -> bool:
	return collision_mask & Enums.MASKS.PLAYER == Enums.MASKS.PLAYER
	
func is_damaging_enemy() -> bool:
	return collision_mask & Enums.MASKS.ENEMY == Enums.MASKS.ENEMY
	
func _physics_process(delta: float) -> void:
	_current_scale = _current_scale.move_toward(Vector2(MaxScale, MaxScale), _scale_step * delta)
	scale = _current_scale
	
	if _current_scale.x >= MaxScale:
		dispose()
	
func dispose():
	if is_queued_for_deletion():
		return
	
	freeing.emit(self)
	queue_free()
