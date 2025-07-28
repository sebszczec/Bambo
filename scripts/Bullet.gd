extends StaticBody2D

class_name Bullet

@export var Speed = 20
@export var LifeTime = 0.5
@export var HitBox : Area2D
@export var Type : Enums.WEAPONS = Enums.WEAPONS.SMALL

@onready var lifeTimer = $LifeTimer
@onready var bolid = $BulletEffect

var velocity = Vector2(0, 0)

signal freeing

func _ready():
	lifeTimer.connect("timeout", _on_life_timer_timeout)
	lifeTimer.wait_time = LifeTime
	lifeTimer.start()
	HitBox.connect("area_entered", _on_hit_box_area_entered)


func _physics_process(_delta):
	rotation = PI / 2 + atan2(velocity.y, velocity.x)
	velocity = velocity.normalized() * Speed
	var _collision = move_and_collide(velocity)

func set_modulate_color(color : Color):
	bolid.self_modulate = color

func dispose():
	if is_queued_for_deletion():
		return
	
	freeing.emit(self)
	queue_free()

func _on_life_timer_timeout():
	dispose()

func is_damaging_player() -> bool:
	return collision_mask & Enums.MASKS.PLAYER == Enums.MASKS.PLAYER
	
func is_damaging_enemy() -> bool:
	return collision_mask & Enums.MASKS.ENEMY == Enums.MASKS.ENEMY

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		if is_damaging_enemy():
			dispose()
		return
		
	if area.is_in_group("Player"):
		if is_damaging_player():
			dispose()
		return
		
	if area.is_in_group("Rock"):
		dispose()
		return
		
