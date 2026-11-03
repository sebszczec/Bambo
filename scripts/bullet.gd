extends StaticBody2D

class_name Bullet

@export var Speed = 20
@export var LifeTime = 0.5
@export var HitBox : Area2D
@export var Type : Enums.WEAPONS = Enums.WEAPONS.SMALL
# piercing bullets are not destroyed when they hit something (orbit blades)
@export var Piercing = false
# enemies a bullet passes through before it is destroyed (drill cannon shells from their piercing level)
@export var PierceCount = 0
# bounces left: after an enemy hit the bullet turns to the nearest other enemy (Ricochet Plates, level 2)
@export var BounceCount = 0
const BOUNCE_RANGE = 400.0

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
	# bullets moved from outside (orbit blades) set their own rotation
	if Speed == 0:
		return

	rotation = PI / 2 + atan2(velocity.y, velocity.x)
	velocity = velocity.normalized() * Speed
	# no move_and_collide - hits are found by the HitBox areas, a physical stop on
	# a body bigger than its hit box (boss capsule) left bullets stuck on its hull
	global_position += velocity

func set_modulate_color(color : Color):
	bolid.self_modulate = color

func dispose():
	if is_queued_for_deletion():
		return
	
	freeing.emit(self)
	queue_free()

func _on_life_timer_timeout():
	dispose()

# turns the bullet to the nearest living enemy other than the one it just hit, false when there is none in range
func _bounce_to_next(hit: Area2D) -> bool:
	var best : Area2D = null
	var best_distance = BOUNCE_RANGE
	for node in get_tree().get_nodes_in_group("Enemy"):
		if !(node is Area2D) or node.is_queued_for_deletion() or node.get_parent() == hit.get_parent():
			continue
		var distance = global_position.distance_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = node
	if best == null:
		return false
	velocity = (best.global_position - global_position).normalized() * velocity.length()
	return true

func is_damaging_player() -> bool:
	return collision_mask & Enums.MASKS.PLAYER == Enums.MASKS.PLAYER
	
func is_damaging_enemy() -> bool:
	return collision_mask & Enums.MASKS.ENEMY == Enums.MASKS.ENEMY

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		if is_damaging_enemy() and !Piercing:
			# Slag Trails: the shot sets the enemy it hits on fire
			PlayerStatus.apply_burn(area.get_parent(), Type)
			if PierceCount > 0:
				PierceCount -= 1
			elif BounceCount > 0 and _bounce_to_next(area):
				BounceCount -= 1
			else:
				dispose()
		return

	if area.is_in_group("Player"):
		if is_damaging_player():
			dispose()
		return

	if area.is_in_group("Rock"):
		if !Piercing:
			dispose()
		return
		
