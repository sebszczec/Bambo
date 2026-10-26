extends Node2D

class_name FloatingText

# with a big horde on screen normal hits are not shown, only crits
const MAX_ALIVE = 25

static var alive_count = 0

@export var Amount : String = "0"
@export var RoundNumber : bool = false
@export var Big : bool = false
var velocity = Vector2()
var color: Color

@onready var textValue = $TextValue

# public
static func can_spawn(important : bool) -> bool:
	return important or alive_count < MAX_ALIVE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	alive_count += 1
	if RoundNumber == true and int(Amount) > 1000:
		textValue.text = str(int(int(Amount) / 1000.0)) + "k"
		pass
	else:
		textValue.text = str(Amount)
	textValue.add_theme_color_override("font_color", color)

	velocity.x = randf_range(-50, 50)
	velocity.y = randf_range(-50, -25)

	var tween = create_tween()
	if Big:
		# crits pop out and then shrink a bit
		scale = Vector2(0.5, 0.5)
		tween.tween_property(self, "scale", Vector2(2.2, 2.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.6)
	else:
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

func _exit_tree() -> void:
	alive_count -= 1

func _physics_process(delta: float) -> void:
	position = position + velocity * delta


func set_color(font_color: Color):
	color = font_color
