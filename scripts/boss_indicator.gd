extends Control

# Boss indicator: an arrow on the screen edge that points at the boss while it is off screen.
# Lives in the run HUD layer, so it is drawn in screen space and ignores the camera.

const EDGE_MARGIN = 56.0
const ARROW_SIZE = 22.0
const LABEL_SIZE = 20
const COLOR = Color(0.4, 0.85, 0.95)

var _boss : Node2D = null
var _font = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font

# public - the boss to point at, null hides the arrow
func set_boss(boss : Node2D) -> void:
	_boss = boss
	queue_redraw()

func _process(_delta : float) -> void:
	# the boss moves every frame, so the arrow is redrawn while it is alive
	if is_instance_valid(_boss):
		queue_redraw()
	else:
		_boss = null

func _draw() -> void:
	if !is_instance_valid(_boss):
		return

	var rect = get_viewport_rect()
	var screen_pos = get_viewport().get_canvas_transform() * _boss.global_position
	var inner = Rect2(Vector2.ONE * EDGE_MARGIN, rect.size - Vector2.ONE * EDGE_MARGIN * 2)
	if inner.has_point(screen_pos):
		return

	# the ray from the screen centre to the boss leaves the inner rect on one edge
	var center = rect.get_center()
	var dir = (screen_pos - center).normalized()
	var half = inner.size * 0.5
	var t = INF
	if abs(dir.x) > 0.0001:
		t = min(t, half.x / abs(dir.x))
	if abs(dir.y) > 0.0001:
		t = min(t, half.y / abs(dir.y))
	var edge = center + dir * t

	var tip = edge + dir * ARROW_SIZE
	var back = edge - dir * ARROW_SIZE * 0.5
	var side = dir.orthogonal() * ARROW_SIZE * 0.6
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), COLOR)
	draw_string(_font, edge - dir * 48.0 + Vector2(-36, 8), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, COLOR)
