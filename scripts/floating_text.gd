extends Node2D

var Amount = 0
var velocity = Vector2()

@onready var textValue = $TextValue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textValue.text = str(Amount)
	
	velocity.x = randf_range(-50, 50)
	velocity.y = randf_range(-50, -25)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

	
func _physics_process(delta: float) -> void:
	position = position + velocity * delta
	
