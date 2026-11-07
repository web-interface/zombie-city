## [파일] scripts/ui/banner.gd
## [하는 일] 화면 위쪽 알림 띠. 종류마다 모양이 다르다: "alert" = 긴급재난문자 모양(빨간 줄 + '[새벽시청]' 같은 말투), "good" = 초록, "promotion" = 금색, "evolution" = 주황빛 금색(진화), "hidden" = 금색(히든 스킬). 위에서 내려왔다가 2.4초 뒤 사라진다. 여러 개가 오면 차례로 보여 준다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고, run.gd 가 Hud.show_banner() 로 부른다.
## [근거 문서] 05 게임 화면 배치(알림), 13 국내 조사(긴급재난문자 모양 알림 — 한국적 재미)
class_name Banner
extends Control

const SHOW_SECONDS := 2.4
const SLIDE_SECONDS := 0.18
const MAX_LINES := 3
const STYLES := {
	"alert": {"edge": Color("ff5c5c"), "text": Color("ffe9e9"), "tag": "긴급재난문자"},
	"good": {"edge": Color("8ff59a"), "text": Color("e9ffe9"), "tag": ""},
	"promotion": {"edge": Color("ffd166"), "text": Color("fff4d6"), "tag": "전직"},
	"evolution": {"edge": Color("ffb347"), "text": Color("fff4d6"), "tag": "진화"},
	"hidden": {"edge": Color("ffd166"), "text": Color("ffffff"), "tag": "히든"},
}

var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_top = 70.0      # 무기 칸(34~46)·보스 체력 줄(50~64)·멈춤 버튼(50~66) 아래 — 겹치지 않게 (검수 지적)
	offset_bottom = 130.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_message(text: String, style_name: String) -> void:
	_queue.append({"text": text, "style": style_name})


func _process(delta: float) -> void:
	if _current.is_empty() and not _queue.is_empty():
		_current = _queue.pop_front()
		_time = 0.0
	if _current.is_empty():
		return
	_time += delta
	if _time > SHOW_SECONDS:
		_current = {}
	queue_redraw()


func _draw() -> void:
	if _current.is_empty():
		return
	var style: Dictionary = STYLES.get(_current["style"], STYLES["good"])
	var slide := clampf(_time / SLIDE_SECONDS, 0.0, 1.0)
	var fade := clampf((SHOW_SECONDS - _time) / 0.3, 0.0, 1.0)
	var top := -8.0 * (1.0 - slide)
	var lines := PixelUi.wrap_words(String(_current["text"]), PixelUi.FONT_REGULAR, PixelUi.SIZE_REGULAR, size.x - 20.0, MAX_LINES).split("
")
	var box := Rect2(6, top, size.x - 12, 14 + 13 * lines.size() + (0 if String(style["tag"]).is_empty() else 8))
	draw_rect(box, Color(0.06, 0.06, 0.09, 0.9 * fade))
	draw_rect(Rect2(box.position, Vector2(box.size.x, 2)), Color(style["edge"], fade))
	var text_top := box.position.y + 15.0
	if not String(style["tag"]).is_empty():
		draw_string(PixelUi.FONT_SMALL, Vector2(box.position.x + 4, box.position.y + 13), String(style["tag"]), HORIZONTAL_ALIGNMENT_LEFT, -1, PixelUi.SIZE_SMALL, Color(style["edge"], fade))
		text_top += 8.0
	# 좁은 세로 화면이라 길면 낱말 단위로 여러 줄 (글자가 화면 밖으로 잘리지 않게, 줄마다 따로 그려 줄 간격이 고르게)
	for index: int in range(lines.size()):
		draw_string(PixelUi.FONT_REGULAR, Vector2(box.position.x + 2, text_top + 13.0 * index), lines[index], HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 4, PixelUi.SIZE_REGULAR, Color(style["text"], fade))
