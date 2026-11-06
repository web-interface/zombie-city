## [파일] scripts/ui/boss_health_bar.gd
## [하는 일] 보스가 살아 있으면 화면 위(무기 칸 아래)에 보스 이름과 체력 줄을 그린다. 체력이 깎이면 흰 줄이 뒤늦게 따라 내려오고(얼마나 깎았는지 보이게), 분노하면 줄이 붉게 깜빡이며 '분노'가 붙는다. 보스가 둘이면 "외 1".
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 watch() 로 BossDirector 를 넘긴다. 매 프레임 스스로 다시 그린다.
## [근거 문서] 14 §1-3 보스(체력 줄·분노), 05 화면 UI
class_name BossHealthBar
extends Control

const TOP := 60.0                 # 무기 칸(아래 끝 46) 밑
const RIGHT_MARGIN := 40.0        # 오른쪽 '멈춤' 버튼을 피함
const BAR_HEIGHT := 4.0
const SIDE_MARGIN := 8.0
const TRAIL_FOLLOW_SPEED := 0.6   # 흰 줄이 따라 내려오는 빠르기 (초당 체력 비율)

var _director: BossDirector
var _shown_ratio: float = 1.0
var _trail_ratio: float = 1.0
var _last_boss: Zombie = null
var _time: float = 0.0


func watch(director: BossDirector) -> void:
	_director = director
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = TOP + 10.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _director == null:
		return
	var bosses := _director.alive_bosses()
	if bosses.is_empty():
		_last_boss = null
		return
	var boss := bosses[0]
	if boss != _last_boss:
		_last_boss = boss
		_trail_ratio = 1.0
	_shown_ratio = clampf(boss.health / boss.max_health, 0.0, 1.0)
	_trail_ratio = maxf(_shown_ratio, _trail_ratio - TRAIL_FOLLOW_SPEED * delta)


func _draw() -> void:
	if _last_boss == null or _last_boss.is_dead:
		return
	var is_raging := bool(_last_boss.boss_state.get("is_raging", false))
	var width := size.x - SIDE_MARGIN - RIGHT_MARGIN
	var name_text := String(_last_boss.info["name"])
	var others := _director.alive_boss_count() - 1
	if others > 0:
		name_text += " 외 %d" % others
	if is_raging:
		name_text += " · 분노"
	var name_color := PixelUi.ALERT if is_raging and int(_time * 6.0) % 2 == 0 else PixelUi.INK
	draw_string(PixelUi.FONT_SMALL, Vector2(SIDE_MARGIN, TOP), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelUi.SIZE_SMALL, name_color)
	var bar_top := TOP + 3.0
	draw_rect(Rect2(SIDE_MARGIN - 1.0, bar_top - 1.0, width + 2.0, BAR_HEIGHT + 2.0), PixelUi.SHADOW)
	draw_rect(Rect2(SIDE_MARGIN, bar_top, width * _trail_ratio, BAR_HEIGHT), Color(1, 1, 1, 0.7))
	var fill := Color("ff3b3b") if is_raging else Color("d9534f")
	draw_rect(Rect2(SIDE_MARGIN, bar_top, width * _shown_ratio, BAR_HEIGHT), fill)
	var rage_mark := SIDE_MARGIN + width * float(_last_boss.info.get("rage", {}).get("health_ratio", 0.0))
	draw_rect(Rect2(rage_mark, bar_top, 1.0, BAR_HEIGHT), Color(1, 1, 1, 0.5))   # 여기서 분노한다는 표시
