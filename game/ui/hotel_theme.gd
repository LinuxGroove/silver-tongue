class_name HotelTheme
extends RefCounted
## Silver Tongue's look for the shared theme: the Meridian's back of house.
## Dark panels like the hotel's lacquered wood, thin brass edges, ivory text,
## brass for what wants you and burgundy for trouble. The type is Montserrat,
## which comes with Cogito: medium for running text, semibold for headings
## and buttons, black for the biggest words.

const TEXT := Color(0.94, 0.9, 0.82)
const DIM := Color(0.66, 0.6, 0.52)
const BRASS := Color(0.9, 0.72, 0.36)
const BURGUNDY := Color(0.72, 0.2, 0.24)
const GREEN := Color(0.55, 0.85, 0.5)
const PANEL := Color(0.08, 0.06, 0.06, 0.9)
const EDGE := Color(0.9, 0.72, 0.36, 0.45)
const MONTSERRAT := "res://addons/cogito/Assets/Fonts/Montserrat/"

static var text_font: Font
static var bold_font: Font
## Headings, buttons and the HUD.
static var heading_font: Font
## The biggest words: the game's name, a result, a banner.
static var title_font: Font


static func apply(root: Window, base_size := 22) -> Theme:
	var t := build(base_size)
	root.theme = t
	ThemeDB.get_default_theme().merge_with(t)
	ThemeDB.get_default_theme().default_font = t.default_font
	ThemeDB.get_default_theme().default_font_size = t.default_font_size
	return t


static func build(base_size := 22) -> Theme:
	var t := LGTheme.build(base_size)
	if text_font == null:
		text_font = load(MONTSERRAT + "Montserrat-Medium.ttf")
		bold_font = load(MONTSERRAT + "Montserrat-Bold.ttf")
		heading_font = load(MONTSERRAT + "Montserrat-SemiBold.ttf")
		title_font = load(MONTSERRAT + "Montserrat-Black.ttf")
	# The add-on's own screens and HotelTheme's HUD labels read this.
	LGTheme.heading_font = heading_font
	t.default_font = text_font
	t.set_font("normal_font", "RichTextLabel", text_font)
	t.set_font("bold_font", "RichTextLabel", bold_font)
	for v in ["HeaderMedium", "InkHeader", "NameLabel", "Button", "OptionButton", "MenuButton"]:
		t.set_font("font", v, heading_font)
	for v in ["HeaderLarge", "InkTitle"]:
		t.set_font("font", v, title_font)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.9))
	t.set_constant("outline_size", "Label", 3)
	for v in ["InkLabel", "InkHeader", "InkTitle"]:
		t.set_color("font_color", v, TEXT)
	t.set_type_variation("DimLabel", "Label")
	t.set_color("font_color", "DimLabel", DIM)
	t.set_font_size("font_size", "DimLabel", int(base_size * 0.8))

	# Buttons: dark lacquer with a brass edge; focus lights the edge.
	var normal := box(Color(0.1, 0.08, 0.08, 0.94), EDGE, 2, 4)
	normal.set_content_margin_all(12)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.12, 0.11, 0.96)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.06, 0.05, 0.05, 0.96)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.07, 0.06, 0.06, 0.7)
	disabled.border_color = Color(EDGE, 0.15)
	var focus := box(Color(BRASS, 0.14), BRASS, 3, 4)
	for type in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("hover_pressed", type, pressed)
		t.set_stylebox("disabled", type, disabled)
		t.set_stylebox("focus", type, focus)
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_focus_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, TEXT)
		t.set_color("font_hover_pressed_color", type, Color.WHITE)
		t.set_color("font_disabled_color", type, Color(DIM, 0.6))
	var danger := box(Color(0.3, 0.08, 0.09, 0.94), Color(BURGUNDY, 0.8), 2, 4)
	danger.set_content_margin_all(12)
	danger.content_margin_left = 22
	danger.content_margin_right = 22
	t.set_stylebox("normal", "DangerButton", danger)
	t.set_stylebox("hover", "DangerButton", danger)
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		t.set_color(c, "DangerButton", Color.WHITE)

	# Panels.
	var panel := box(PANEL, EDGE, 1, 6)
	panel.set_content_margin_all(22)
	for v in ["PanelContainer", "Panel", "DarkPanel", "ParchmentPanel"]:
		t.set_stylebox("panel", v, panel)
	var glass := box(Color(0.04, 0.03, 0.03, 0.72), Color(EDGE, 0.25), 1, 4)
	glass.set_content_margin_all(14)
	t.set_stylebox("panel", "GlassPanel", glass)

	# Text entry.
	var edit := box(Color(0.04, 0.03, 0.03, 0.95), EDGE, 2, 4)
	edit.set_content_margin_all(10)
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", BRASS)
	t.set_color("font_placeholder_color", "LineEdit", Color(DIM, 0.6))

	# Bars.
	t.set_stylebox("background", "ProgressBar", box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 0, 2))
	t.set_stylebox("fill", "ProgressBar", box(BRASS, Color(0, 0, 0, 0), 0, 2))
	t.set_color("default_color", "RichTextLabel", TEXT)
	return t


static func box(bg: Color, edge: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = edge
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.anti_aliasing = true
	return b


## A small panel for the HUD: dark lacquer with a thin brass edge.
static func hud_panel(edge := EDGE) -> PanelContainer:
	var p := PanelContainer.new()
	var b := box(Color(0.04, 0.03, 0.03, 0.66), edge, 1, 4)
	b.content_margin_left = 16
	b.content_margin_right = 16
	b.content_margin_top = 10
	b.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", b)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## A HUD label in the heading font.
static func hud_label(text: String, size := 18, color := TEXT, heading := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 2)
	if heading and heading_font:
		l.add_theme_font_override("font", heading_font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A HUD label in the title font, for the biggest words.
static func title_label(text: String, size := 40, color := TEXT) -> Label:
	var l := hud_label(text, size, color, false)
	if title_font:
		l.add_theme_font_override("font", title_font)
	return l


## A thin bar for the HUD.
static func bar(color: Color, width := 160.0, height := 8.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(width, height)
	b.max_value = 1.0
	b.add_theme_stylebox_override("background", box(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 0, 2))
	b.add_theme_stylebox_override("fill", box(color, Color(0, 0, 0, 0), 0, 2))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b
