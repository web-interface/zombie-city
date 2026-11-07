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
	var font := FONT_REGULAR
	if is_small:
		font = FONT_SMALL
	elif is_bold:
		font = FONT_BOLD
	new_label.add_theme_font_override("font", font)
	new_label.add_theme_font_size_override("font_size", SIZE_SMALL if is_small else SIZE_REGULAR)
	new_label.add_theme_color_override("font_color", color)
	new_label.add_theme_color_override("font_shadow_color", SHADOW)
	new_label.add_theme_constant_override("shadow_offset_x", 1)
	new_label.add_theme_constant_override("shadow_offset_y", 1)
	# 줄 간격은 글꼴 그대로 둔다 (Galmuri9 10크기 = 줄 높이 11점). 예전에 -3 으로 줄였더니 두 줄짜리 글이 서로 포개졌음 (마지막 검수)
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


## 버튼을 누르면: 소리 + 살짝 눌렸다 돌아오는 움직임 + 할 일. 모든 메뉴 버튼이 같은 손맛을 갖게 (문서 05 원칙)
static func on_press(target: Button, action: Callable, sound_name: String = "ui_click") -> void:
	target.pressed.connect(func() -> void:
		SoundPlayer.play(sound_name)
		target.pivot_offset = target.size * 0.5
		var bounce := target.create_tween()
		bounce.tween_property(target, "scale", Vector2(0.93, 0.93), 0.04)
		bounce.tween_property(target, "scale", Vector2.ONE, 0.08)
		action.call())


## 세로로 끌어 올리는 목록 칸: 가로 막대 없음, 얇은 각진 막대 (기본 회색 둥근 막대 = AI 티)
static func scroll_area() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 4   # 손가락으로 버튼을 누르다 조금 흔들려도 목록이 움직이지 않게
	var bar := scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(3, 0)
	bar.add_theme_stylebox_override("scroll", panel_style(Color("10131a"), Color("10131a"), 0))
	bar.add_theme_stylebox_override("grabber", panel_style(PANEL_EDGE, PANEL_EDGE, 0))
	bar.add_theme_stylebox_override("grabber_highlight", panel_style(MUTED, MUTED, 0))
	bar.add_theme_stylebox_override("grabber_pressed", panel_style(INK, INK, 0))
	return scroll


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


## 여러 줄 작은 글: 줄마다 Label 하나씩 쌓는다. Label 하나에 여러 줄을 넣으면 엔진 기본 줄 간격 때문에
## 화면마다 줄이 겹치거나 벌어져 보였다 (마지막 검수). 줄바꿈(\n)은 그대로 살리고, 긴 줄은 낱말 단위로 감싼다.
static func small_lines(text: String, color: Color, max_width: float, max_lines: int = 0) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for paragraph: String in text.split("\n"):
		for line: String in wrap_words(paragraph, FONT_SMALL, SIZE_SMALL, max_width, max_lines).split("\n"):
			column.add_child(label(line, color, true))
	return column


## 띄어쓰기 단위로만 줄을 바꾼다. Godot 기본 줄바꿈은 한글 글자 사이에서도 끊어서
## "휘두른 / 다" 처럼 낱말이 쪼개지기 때문 (검수 지적). 너비는 글꼴로 실제로 잰다.
## max_lines 를 넘으면 마지막 줄 끝을 '…' 로 줄인다 (0 이면 줄 수 제한 없음).
static func wrap_words(text: String, font: Font, font_size: int, max_width: float, max_lines: int = 0) -> String:
	var lines: Array[String] = []
	var current := ""
	for word: String in text.split(" "):
		var candidate := word if current.is_empty() else current + " " + word
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width or current.is_empty():
			current = candidate
		else:
			lines.append(current)
			current = word
	if not current.is_empty():
		lines.append(current)
	if max_lines > 0 and lines.size() > max_lines:
		lines.resize(max_lines)
		lines[max_lines - 1] = lines[max_lines - 1].left(maxi(lines[max_lines - 1].length() - 1, 0)) + "…"
	return "\n".join(lines)   # 글자 그대로 줄을 바꿔 적으면 파일 줄바꿈(\r\n)이 따라와 빈 줄이 하나 더 생김


static func format_time(seconds: float) -> String:
	var whole := maxi(0, ceili(seconds))
	return "%02d:%02d" % [floori(whole / 60.0), whole % 60]
