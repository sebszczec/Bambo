extends VBoxContainer
class_name HighScoreTable

# Arcade style high score table: rank, three letter name and score.
# Rows get the classic rainbow colors and a highlighted row blinks.

const RANK_NAMES = ["1ST", "2ND", "3RD", "4TH", "5TH", "6TH", "7TH", "8TH", "9TH", "10TH"]
const ROW_COLORS = [
	Color(1.0, 0.85, 0.2), Color(1.0, 0.6, 0.2), Color(1.0, 0.35, 0.35), Color(1.0, 0.4, 0.8), Color(0.75, 0.45, 1.0),
	Color(0.45, 0.55, 1.0), Color(0.3, 0.8, 1.0), Color(0.3, 1.0, 0.8), Color(0.45, 1.0, 0.45), Color(0.8, 1.0, 0.4),
]
const HIGHLIGHT_COLOR = Color(2.0, 2.0, 2.0)
const BLINK_TIME = 0.15

@export var FontSize : int = 30
@export var Title : String = "HIGH SCORES"

var _font = null
var _title_label : Label
var _grid : GridContainer
var _highlight_labels : Array = []
var _blink_time = 0.0
var _title_hue = 0.0

func _ready() -> void:
	_font = load("res://resources/kenney_space-shooter-redux/Bonus/kenvector_future.ttf")
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 16)

	_title_label = _create_label(int(FontSize * 1.3), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_title_label.text = Title
	add_child(_title_label)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", FontSize * 2)
	_grid.add_theme_constant_override("v_separation", int(FontSize * 0.3))
	add_child(_grid)

	refresh()

func _process(delta: float) -> void:
	_title_hue = fmod(_title_hue + delta * 0.25, 1.0)
	_title_label.add_theme_color_override("font_color", Color.from_hsv(_title_hue, 0.6, 1.0))

	if _highlight_labels.is_empty():
		return

	_blink_time += delta
	var on = int(_blink_time / BLINK_TIME) % 2 == 0
	for label in _highlight_labels:
		label.modulate.a = 1.0 if on else 0.15

# public - rebuilds the rows, highlight_rank marks a freshly added entry
func refresh(highlight_rank : int = -1):
	for child in _grid.get_children():
		child.queue_free()
	_highlight_labels.clear()

	var table = ConfigHandler.get_high_scores()
	for i in table.size():
		var color = HIGHLIGHT_COLOR if i == highlight_rank else ROW_COLORS[i % ROW_COLORS.size()]
		var rank = _create_label(FontSize, color, HORIZONTAL_ALIGNMENT_RIGHT)
		rank.text = RANK_NAMES[i] if i < RANK_NAMES.size() else str(i + 1)
		var player_name = _create_label(FontSize, color, HORIZONTAL_ALIGNMENT_CENTER)
		player_name.text = table[i]["name"]
		var score = _create_label(FontSize, color, HORIZONTAL_ALIGNMENT_RIGHT)
		score.text = str(table[i]["score"])
		for label in [rank, player_name, score]:
			_grid.add_child(label)
			if i == highlight_rank:
				_highlight_labels.append(label)

func _create_label(font_size : int, color : Color, align : HorizontalAlignment) -> Label:
	var label = Label.new()
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = align
	return label
