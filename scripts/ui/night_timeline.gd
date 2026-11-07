## [파일] scripts/ui/night_timeline.gd
## [하는 일] 화면 위쪽 '앞으로 올 일' 시간 줄: 무기 칸과 장비 칸 사이 빈 곳에 한 밤(3분) 진행 줄을 얇게 긋고, 금색 점 = 정예, 빨간 막대 = 보스, 끝의 작은 헬기 = 탈출을 미리 찍어 둔다. 지나간 일은 흐리게, 밀린 일은 지금 자리에 붙어 따라온다(딥락식 '예고된 긴장').
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 watch() 로 NightDirector 를 넘긴다. 매 프레임 스스로 다시 그린다. 칸 자리는 hud_top_bar.gd 의 상수를 따른다.
## [근거 문서] 15 §3-1 앞으로 올 일 보여 주기, 05 게임 화면 배치
class_name NightTimeline
extends Control

const INSET := 3.0              # 무기·장비 칸에서 떨어지는 만큼 (칸 테두리·단계 점과 1점도 안 겹치게)
const LINE_OFFSET := 6.0        # 칸 줄 위 끝에서 진행 줄까지 (칸 높이 12 의 가운데)
const ELITE_COLOR := Color("ffd25a")
const BOSS_COLOR := Color("ff3b3b")
const HELICOPTER_COLOR := Color("cfd8e3")
const DONE_ALPHA := 0.35

var _director: NightDirector
var _night_seconds: float = 180.0
var _helicopter_second: float = 180.0
var _weapon_slots: float = 4.0
var _gear_slots: float = 4.0


func watch(director: NightDirector) -> void:
	_director = director
	_night_seconds = float(GameData.rules("nights")["night_seconds"])
	_helicopter_second = float(GameData.rules("extraction")["helicopter_arrive_second"])
	_weapon_slots = float(GameData.rules("build")["weapon_slots"])
	_gear_slots = float(GameData.rules("build")["gear_slots"])
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = HudTopBar.SAFE_TOP + HudTopBar.SLOT_ROW_TOP + HudTopBar.SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _director == null:
		return
	var left := HudTopBar.SIDE_PADDING + _weapon_slots * (HudTopBar.SLOT_SIZE + HudTopBar.SLOT_GAP) + INSET
	var right := size.x - HudTopBar.SIDE_PADDING - _gear_slots * (HudTopBar.SLOT_SIZE + HudTopBar.SLOT_GAP) - INSET
	var line_y := HudTopBar.SAFE_TOP + HudTopBar.SLOT_ROW_TOP + LINE_OFFSET
	var width := right - left
	var progress := clampf(_director.elapsed_seconds() / _night_seconds, 0.0, 1.0)
	draw_rect(Rect2(left, line_y, width, 1.0), Color(1, 1, 1, 0.18))
	draw_rect(Rect2(left, line_y, width * progress, 1.0), Color(PixelUi.INK, 0.7))
	for mark: Dictionary in _director.timeline_marks():
		var x := roundf(left + width * clampf(float(mark["second"]) / _night_seconds, 0.0, 1.0))
		var alpha := DONE_ALPHA if bool(mark["is_done"]) else 1.0
		if mark["kind"] == "boss":
			_draw_boss_mark(x, line_y, alpha)
		else:
			_draw_elite_mark(x, line_y, alpha)
	_draw_helicopter(roundf(left + width * clampf(_helicopter_second / _night_seconds, 0.0, 1.0)), line_y)
	draw_rect(Rect2(roundf(left + width * progress), line_y - 2.0, 1.0, 5.0), PixelUi.INK)   # 지금


## 정예: 금색 십자 점 (3×3)
func _draw_elite_mark(x: float, line_y: float, alpha: float) -> void:
	draw_rect(Rect2(x, line_y - 4.0, 1.0, 3.0), Color(ELITE_COLOR, alpha))
	draw_rect(Rect2(x - 1.0, line_y - 3.0, 3.0, 1.0), Color(ELITE_COLOR, alpha))


## 보스: 빨간 세로 막대 (3×5) + 어두운 눈 두 점
func _draw_boss_mark(x: float, line_y: float, alpha: float) -> void:
	draw_rect(Rect2(x - 1.0, line_y - 5.0, 3.0, 5.0), Color(BOSS_COLOR, alpha))
	draw_rect(Rect2(x - 1.0, line_y - 4.0, 1.0, 1.0), Color(PixelUi.SHADOW, alpha))
	draw_rect(Rect2(x + 1.0, line_y - 4.0, 1.0, 1.0), Color(PixelUi.SHADOW, alpha))


## 헬기: 몸통 3×2 + 날개 5×1 (줄 끝 위)
func _draw_helicopter(x: float, line_y: float) -> void:
	draw_rect(Rect2(x - 2.0, line_y - 5.0, 5.0, 1.0), HELICOPTER_COLOR)
	draw_rect(Rect2(x - 1.0, line_y - 3.0, 3.0, 2.0), HELICOPTER_COLOR)
	draw_rect(Rect2(x, line_y - 4.0, 1.0, 1.0), HELICOPTER_COLOR)
