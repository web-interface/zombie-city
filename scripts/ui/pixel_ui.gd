## [파일] scripts/ui/pixel_ui.gd
## [하는 일] 픽셀 스타일 화면 부품을 만드는 공통 도구: 글꼴 3종(Galmuri11·Bold·Galmuri9), 색, 각진 패널·버튼 모양, 글자·아이콘 만들기. 모든 화면이 같은 모양을 쓰게 한곳에 모았다.
## [쓰는 곳] scripts/ui/*.gd 가 PixelUi.label() · PixelUi.button() 처럼 부른다.
## [근거 문서] 05 화면 원칙(픽셀 글꼴·각진 테두리), 06 색, 13 (영어 라벨·이모지·둥근 버튼 = AI 티)
class_name PixelUi
extends RefCounted

const FONT_REGULAR: Font = preload("res://fonts/Galmuri11.ttf")
const FONT_BOLD: Font = preload("res://fonts/Galmuri11-Bold.ttf")
const FONT_SMALL: Font = preload("res://fonts/Galmuri9.ttf")
const SIZE_REGULAR := 12
const SIZE_SMALL := 10

const INK := Color("e8ecf3")
const MUTED := Color("9aa3b5")
const GOOD := Color("8ff59a")
const GOLD := Color("ffd166")
const ALERT := Color("ff6b6b")
const PANEL := Color("171a22")
const PANEL_EDGE := Color("3a4152")
const SHADOW := Color(0.04, 0.04, 0.07, 0.85)


static func label(text: String, color: Color = INK, is_small: bool = false, is_bold: bool = false) -> Label:
	var new_label := Label.new()
	new_label.text = text
	new_label.add_theme_font_override("font", FONT_SMALL if is_small else (FONT_BOLD if is_bold else FONT_REGULAR))
	new_label.add_theme_font_size_override("font_size", SIZE_SMALL if is_small else SIZE_REGULAR)
	new_label.add_theme_color_override("font_color", color)
	new_label.add_theme_color_override("font_shadow_color", SHADOW)
	new_label.add_theme_constant_override("shadow_offset_x", 1)
	new_label.add_theme_constant_override("shadow_offset_y", 1)
	new_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return new_label


## 각진 패널 모양 (둥근 모서리 없음 — 픽셀 스타일)
static func panel_style(background: Color = PANEL, edge: Color = PANEL_EDGE, edge_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = edge
	style.set_border_width_all(edge_width)
	style.set_content_margin_all(4)
	return style


static func panel(background: Color = PANEL, edge: Color = PANEL_EDGE) -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", panel_style(background, edge))
	return container


static func button(text: String, accent: Color = INK) -> Button:
	var new_button := Button.new()
	new_button.text = text
	new_button.add_theme_font_override("font", FONT_REGULAR)
	new_button.add_theme_font_size_override("font_size", SIZE_REGULAR)
	new_button.add_theme_color_override("font_color", accent)
	new_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	new_button.add_theme_color_override("font_hover_color", Color.WHITE)
	new_button.add_theme_stylebox_override("normal", panel_style(Color("232838"), accent.darkened(0.3)))
	new_button.add_theme_stylebox_override("hover", panel_style(Color("2c3349"), accent))
	new_button.add_theme_stylebox_override("pressed", panel_style(Color("1b1f2b"), accent))
	new_button.add_theme_stylebox_override("disabled", panel_style(Color("1b1e26"), PANEL_EDGE))
	new_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return new_button


## 10×10 아이콘을 2배로 (art/sprites/icons/<이름>.png)
static func icon(icon_name: String, scale: int = 2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load("res://art/sprites/icons/%s.png" % icon_name)
	rect.custom_minimum_size = Vector2(10, 10) * scale
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## 부모 크기에 꽉 차게 (기준점과 여백을 함께 맞춰야 크기가 0 이 되지 않는다)
static func full_rect(control: Control) -> Control:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


## 가운데 정렬 상자: 부모에 꽉 차고 안의 것을 화면 가운데에 둔다
static func centered(child: Control) -> CenterContainer:
	var center := CenterContainer.new()
	full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(child)
	return center


static func format_time(seconds: float) -> String:
	var whole := maxi(0, ceili(seconds))
	return "%02d:%02d" % [floori(whole / 60.0), whole % 60]
