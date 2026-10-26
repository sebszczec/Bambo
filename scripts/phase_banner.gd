extends Label

@export var ShowTime : float = 2.5
@export var FadeTime : float = 0.5

var _tween : Tween = null

func _ready() -> void:
	modulate.a = 0.0

# public
func show_text(value : String, color : Color = Color.WHITE):
	text = value
	add_theme_color_override("font_color", color)

	if _tween != null:
		_tween.kill()

	pivot_offset = size / 2
	scale = Vector2(1.3, 1.3)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, FadeTime)
	_tween.tween_property(self, "scale", Vector2(1, 1), FadeTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(ShowTime)
	_tween.chain().tween_property(self, "modulate:a", 0.0, FadeTime)
