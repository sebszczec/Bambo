extends RefCounted
class_name MenuTheme

# Shared Space Thunder look for the menus: dark blue panels, neon blue borders, gold focus.

const FONT_PATH = "res://resources/kenney_space-shooter-redux/Bonus/kenvector_future.ttf"
const TITLE_COLOR = Color(0.6, 1.4, 2.2)
const TEXT_COLOR = Color(0.75, 0.85, 1.0)
const ACCENT_COLOR = Color(1.0, 0.85, 0.2)
const BORDER_COLOR = Color(0.2, 0.4, 1.0)
const PANEL_COLOR = Color(0.02, 0.03, 0.1, 0.85)
const CHECK_SIZE = 28

static func create(font_size : int = 26) -> Theme:
	var t = Theme.new()
	t.default_font = load(FONT_PATH)
	t.default_font_size = font_size

	var normal = box(Color(0.05, 0.08, 0.2, 0.85), BORDER_COLOR)
	var hover = box(Color(0.08, 0.12, 0.3, 0.9), Color(0.3, 0.8, 1.0))
	var pressed = box(Color(0.15, 0.12, 0.05, 0.9), ACCENT_COLOR)
	var disabled = box(Color(0.03, 0.04, 0.1, 0.6), Color(0.1, 0.15, 0.3))
	var focus = box(Color(0, 0, 0, 0), ACCENT_COLOR)
	focus.draw_center = false
	var flat = StyleBoxEmpty.new()
	flat.set_content_margin_all(6)

	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("disabled", type, disabled)
		t.set_stylebox("focus", type, focus)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		t.set_stylebox(state, "CheckBox", flat)
	t.set_stylebox("focus", "CheckBox", focus)
	t.set_icon("checked", "CheckBox", _check_icon(true))
	t.set_icon("unchecked", "CheckBox", _check_icon(false))
	t.set_constant("h_separation", "CheckBox", 16)

	for type in ["Button", "OptionButton", "CheckBox"]:
		t.set_color("font_color", type, TEXT_COLOR)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_focus_color", type, ACCENT_COLOR)
		t.set_color("font_pressed_color", type, ACCENT_COLOR)
		t.set_color("font_hover_pressed_color", type, ACCENT_COLOR)
		t.set_color("font_disabled_color", type, Color(0.4, 0.45, 0.6))
	t.set_color("font_color", "Label", TEXT_COLOR)

	var panel = box(PANEL_COLOR, BORDER_COLOR)
	panel.set_content_margin_all(32)
	t.set_stylebox("panel", "TabContainer", panel)
	t.set_stylebox("tab_selected", "TabContainer", box(Color(0.1, 0.18, 0.45, 0.95), BORDER_COLOR))
	t.set_stylebox("tab_unselected", "TabContainer", box(Color(0.02, 0.03, 0.1, 0.7), Color(0.1, 0.2, 0.5)))
	t.set_stylebox("tab_hovered", "TabContainer", hover)
	t.set_stylebox("tab_focus", "TabContainer", focus)
	t.set_color("font_selected_color", "TabContainer", ACCENT_COLOR)
	t.set_color("font_unselected_color", "TabContainer", TEXT_COLOR)
	t.set_color("font_hovered_color", "TabContainer", Color.WHITE)

	t.set_stylebox("panel", "PopupMenu", box(PANEL_COLOR, BORDER_COLOR))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.1, 0.18, 0.45, 0.95), ACCENT_COLOR))
	t.set_color("font_color", "PopupMenu", TEXT_COLOR)
	t.set_color("font_hover_color", "PopupMenu", ACCENT_COLOR)

	return t

static func box(bg : Color, border : Color) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = border
	result.set_border_width_all(2)
	result.set_corner_radius_all(6)
	result.content_margin_left = 18
	result.content_margin_right = 18
	result.content_margin_top = 8
	result.content_margin_bottom = 8
	return result

# big glowing title label like the one on the start screen
static func style_title(label : Label, font_size : int = 80, spacing : int = 24):
	var font = FontVariation.new()
	font.base_font = load(FONT_PATH)
	font.spacing_glyph = spacing
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TITLE_COLOR)
	label.add_theme_color_override("font_outline_color", BORDER_COLOR)
	label.add_theme_constant_override("outline_size", 12)

# square box with a border, filled with gold when checked
static func _check_icon(checked : bool) -> ImageTexture:
	var image = Image.create(CHECK_SIZE, CHECK_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.05, 0.08, 0.2, 0.9))
	var border = 3
	for i in border:
		image.fill_rect(Rect2i(i, 0, 1, CHECK_SIZE), BORDER_COLOR)
		image.fill_rect(Rect2i(CHECK_SIZE - 1 - i, 0, 1, CHECK_SIZE), BORDER_COLOR)
		image.fill_rect(Rect2i(0, i, CHECK_SIZE, 1), BORDER_COLOR)
		image.fill_rect(Rect2i(0, CHECK_SIZE - 1 - i, CHECK_SIZE, 1), BORDER_COLOR)
	if checked:
		image.fill_rect(Rect2i(7, 7, CHECK_SIZE - 14, CHECK_SIZE - 14), ACCENT_COLOR)
	return ImageTexture.create_from_image(image)
