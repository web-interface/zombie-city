## [파일] scripts/world/speech_bubble.gd
## [하는 일] 생존자 머리 위 말풍선: 짧은 한마디를 어두운 칸에 작은 픽셀 글씨로 띄우고, 생존자를 따라다니다 잠깐 뒤 흐려지며 사라진다.
## [쓰는 곳] scenes/run.tscn 의 World/SpeechBubble. scripts/run/survivor_chatter.gd 가 say() 를 부른다.
## [근거 문서] 14 §4 중독 설계(사용자 "개성 넘치게"), 06 AI 티 안 나게(동네 말투)
class_name SpeechBubble
extends Node2D

const SHOW_SECONDS := 2.2
const FADE_SECONDS := 0.4
const HEAD_OFFSET := Vector2(0, -20)
const PADDING := Vector2(3, 2)

var _target: Node2D
var _text: String = ""
var _time_left: float = 0.0


func setup(target: Node2D) -> void:
	_target = target
	z_index = 30   # 좀비·효과 위에


func say(text: String) -> void:
	_text = text
	_time_left = SHOW_SECONDS
	queue_redraw()


func _process(delta: float) -> void:
	if _time_left <= 0.0 or _target == null:
		return
	_time_left -= delta
	position = (_target.position + HEAD_OFFSET).round()
	queue_redraw()


func _draw() -> void:
	if _time_left <= 0.0 or _text.is_empty():
		return
	var alpha := clampf(_time_left / FADE_SECONDS, 0.0, 1.0)
	var font := PixelUi.FONT_SMALL
	var text_size := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelUi.SIZE_SMALL)
	var box := Rect2(Vector2(-text_size.x * 0.5, -text_size.y) - PADDING, text_size + PADDING * 2.0)
	draw_rect(box, Color(0.06, 0.06, 0.09, 0.85 * alpha))
	draw_rect(box, Color(1, 1, 1, 0.35 * alpha), false, 1.0)
	draw_rect(Rect2(Vector2(-1, box.end.y), Vector2(2, 2)), Color(0.06, 0.06, 0.09, 0.85 * alpha))   # 말풍선 꼬리
	draw_string(font, Vector2(-text_size.x * 0.5, -3.0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelUi.SIZE_SMALL, Color(PixelUi.INK, alpha))
