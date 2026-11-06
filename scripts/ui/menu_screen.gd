## [파일] scripts/ui/menu_screen.gd
## [하는 일] 목록 화면 공통 틀 MenuScreen: 어두운 바탕, 위 줄(뒤로 버튼·제목·오른쪽 숫자), 아래로 끌어 올리는 목록 칸(body). 은신처·도감·업적 화면이 이어받아 body 에 줄을 채운다. 폰의 뒤로 가기 버튼도 타이틀로.
## [쓰는 곳] scripts/ui/shelter_screen.gd · codex_screen.gd · achievements_screen.gd 가 extends MenuScreen.
## [근거 문서] 05 화면 원칙(픽셀 글꼴·각진 테두리·엄지가 닿는 버튼)
class_name MenuScreen
extends Control

const HEADER_HEIGHT := 26.0
const SIDE_MARGIN := 5.0
const BODY_WIDTH := 166.0   # 목록 줄 너비 (화면 180 − 양옆 여백 − 막대)

## 목록 칸 — 이어받은 화면이 줄을 넣는다
var body: VBoxContainer
var _header_value: Label
var _scroll: ScrollContainer


## 화면 틀 만들기. 이어받은 화면이 _ready 맨 앞에서 부른다.
func build_frame(title_text: String, background_color: Color) -> void:
	PixelUi.full_rect(self)
	var background := ColorRect.new()
	background.color = background_color
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(PixelUi.full_rect(background))
	var back := PixelUi.button("◀ 뒤로", PixelUi.MUTED)
	back.position = Vector2(SIDE_MARGIN, 4)
	back.custom_minimum_size = Vector2(44, 18)
	PixelUi.on_press(back, go_back, "ui_back")
	add_child(back)
	var title := PixelUi.label(title_text, PixelUi.INK, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 6.0
	title.offset_bottom = 20.0
	add_child(title)
	_header_value = PixelUi.label("", PixelUi.GOLD, true)
	_header_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_value.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_header_value.offset_top = 8.0
	_header_value.offset_bottom = 20.0
	_header_value.offset_right = -SIDE_MARGIN
	add_child(_header_value)
	_build_body()


## 위 줄 오른쪽 작은 숫자 (고철 1,240 · 12/40 · 34%)
func set_header_value(text: String) -> void:
	_header_value.text = text


## 위 줄 숫자를 잠깐 다른 색으로 (고철이 모자랄 때 빨강)
func flash_header_value(color: Color) -> void:
	_header_value.modulate = color * 1.5
	create_tween().tween_property(_header_value, "modulate", Color.WHITE, 0.6)


## 목록을 비운다 (다시 채우기 전에)
func clear_body() -> void:
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()


## 그 곡 파일이 있을 때만 바꿔 튼다. 아직 없으면(소리 담당이 만드는 중) 지금 음악을 그대로 둔다 — 갑자기 조용해지지 않게
static func play_music_if_present(track_name: String) -> void:
	if ResourceLoader.exists("res://audio/%s.wav" % track_name):
		SoundPlayer.play_single_music(track_name)


func go_back() -> void:
	SceneRouter.go_to_title()


## 안드로이드 뒤로 가기 버튼 = 화면 왼쪽 위 [뒤로]
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## 목록 줄 하나의 바탕: 각진 패널. 끌어 올릴 때 줄 위에서 시작해도 목록이 움직이게 입력을 넘긴다.
func row_panel(edge: Color = PixelUi.PANEL_EDGE) -> PanelContainer:
	var row := PixelUi.panel(PixelUi.PANEL, edge)
	row.custom_minimum_size = Vector2(BODY_WIDTH, 0)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	return row


func _build_body() -> void:
	_scroll = PixelUi.scroll_area()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = HEADER_HEIGHT
	_scroll.offset_left = SIDE_MARGIN
	_scroll.offset_right = -2.0
	_scroll.offset_bottom = -4.0
	add_child(_scroll)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	body.custom_minimum_size = Vector2(BODY_WIDTH, 0)
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(body)
