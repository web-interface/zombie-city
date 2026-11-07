## [파일] scripts/ui/hud_top_bar.gd
## [하는 일] 화면 맨 위 정보 줄: 경험치 막대, 레벨, 구조까지 남은 시간(가운데 크게), 처치 수, 무기 4칸·장비 4칸 작은 아이콘과 단계 점, 생존자 체력 막대. 숫자가 바뀌면 살짝 튀어 오른다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 매 프레임 refresh() 를 부른다.
## [근거 문서] 05 게임 화면 배치, 02 §12 (숫자는 튀어 오르는 애니메이션)
class_name HudTopBar
extends Control

const SAFE_TOP := 4.0            # 폰 카메라 구멍을 피해 살짝 내림
const SLOT_SIZE := 12.0
const MAX_LEVEL_PIPS := 5        # 단계 점은 5개까지, 넘으면 숫자로

var _level_up: LevelUp
var _rack: WeaponRack
var _context: RunContext
var _remaining_seconds: float = 300.0
var _kills: int = 0
var _kill_bump: float = 0.0
var _level_bump: float = 0.0
var _last_level: int = 1
var _icon_cache: Dictionary = {}
var _night_name: String = "첫째 밤"
var _combo: int = 0
var _combo_ratio: float = 0.0
var _combo_bump: float = 0.0


func setup(context: RunContext, level_up: LevelUp, rack: WeaponRack) -> void:
	_context = context
	_level_up = level_up
	_rack = rack
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = 44.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 연속 처치는 5부터 보이고, 50 넘으면 금색 (문서 14 §4)
func set_run_status(night_name: String, combo: int, combo_ratio: float) -> void:
	_night_name = night_name
	if combo > _combo:
		_combo_bump = 1.0
	_combo = combo
	_combo_ratio = combo_ratio


func refresh(remaining_seconds: float, kills: int, delta: float) -> void:
	_remaining_seconds = remaining_seconds
	if kills != _kills:
		_kill_bump = 1.0
	_kills = kills
	if _level_up.level != _last_level:
		_level_bump = 1.0
		_last_level = _level_up.level
	_kill_bump = maxf(_kill_bump - delta * 6.0, 0.0)
	_level_bump = maxf(_level_bump - delta * 4.0, 0.0)
	_combo_bump = maxf(_combo_bump - delta * 8.0, 0.0)
	queue_redraw()


func _draw() -> void:
	var width := size.x
	var experience_ratio := clampf(_level_up.experience / _level_up.experience_needed(), 0.0, 1.0)
	draw_rect(Rect2(0, SAFE_TOP, width, 3), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(0, SAFE_TOP, width * experience_ratio, 3), PixelUi.GOOD)
	var font := PixelUi.FONT_REGULAR
	var level_y := SAFE_TOP + 16.0 - _level_bump * 2.0
	_draw_text(font, "레벨 %d" % _level_up.level, Vector2(4, level_y), HORIZONTAL_ALIGNMENT_LEFT, PixelUi.GOOD)
	_draw_text(PixelUi.FONT_BOLD, PixelUi.format_time(_remaining_seconds), Vector2(width * 0.5, SAFE_TOP + 16.0), HORIZONTAL_ALIGNMENT_CENTER, _timer_color())
	_draw_text(PixelUi.FONT_SMALL, _night_name, Vector2(width * 0.5, SAFE_TOP + 26.0), HORIZONTAL_ALIGNMENT_CENTER, PixelUi.MUTED, PixelUi.SIZE_SMALL)
	_draw_text(font, "처치 %d" % _kills, Vector2(width - 4, SAFE_TOP + 16.0 - _kill_bump * 1.5), HORIZONTAL_ALIGNMENT_RIGHT, PixelUi.INK)
	_draw_combo(width)
	_draw_slots(SAFE_TOP + 30.0)
	_draw_health_bar(width)


func _draw_combo(width: float) -> void:
	if _combo < 5:
		return
	var color := PixelUi.GOLD if _combo >= 50 else PixelUi.INK
	var top := SAFE_TOP + 27.0 - _combo_bump * 2.0
	_draw_text(PixelUi.FONT_SMALL, "연속 %d" % _combo, Vector2(width - 4, top), HORIZONTAL_ALIGNMENT_RIGHT, color, PixelUi.SIZE_SMALL)
	draw_rect(Rect2(width - 34, SAFE_TOP + 29.0, 30.0 * _combo_ratio, 1), Color(color, 0.7))   # 끊기기까지 남은 시간


func _timer_color() -> Color:
	if _remaining_seconds <= 30.0:
		return PixelUi.GOLD
	return PixelUi.INK


func _draw_slots(top: float) -> void:
	var slot_left := 4.0
	for weapon: Weapon in _rack.weapons:
		_draw_slot(weapon.icon_name(), weapon.level, Vector2(slot_left, top))
		if weapon.is_evolved:   # 진화 무기 칸은 금색 테두리 (문서 14 §2-7)
			draw_rect(Rect2(Vector2(slot_left, top), Vector2.ONE * SLOT_SIZE), Weapon.EVOLVED_COLOR, false, 1.0)
		slot_left += SLOT_SIZE + 2.0
	slot_left = size.x - 4.0 - (SLOT_SIZE + 2.0) * _rack.gear_levels.size()
	for gear_id: String in _rack.gear_levels.keys():
		_draw_slot(String(GameData.entry("gear", gear_id)["icon"]), int(_rack.gear_levels[gear_id]), Vector2(slot_left, top))
		slot_left += SLOT_SIZE + 2.0


func _draw_slot(icon_name: String, level: int, top_left: Vector2) -> void:
	if not _icon_cache.has(icon_name):
		_icon_cache[icon_name] = PixelUi.icon_texture(icon_name)
	draw_rect(Rect2(top_left, Vector2.ONE * SLOT_SIZE), Color(0.09, 0.1, 0.14, 0.75))
	draw_texture(_icon_cache[icon_name], top_left + Vector2.ONE)
	for pip: int in range(mini(level, MAX_LEVEL_PIPS)):
		draw_rect(Rect2(top_left + Vector2(1 + pip * 2, SLOT_SIZE), Vector2(1, 1)), PixelUi.GOLD)
	if level > MAX_LEVEL_PIPS:   # 늦은 밤 무기는 63레벨까지 — 점 대신 숫자 (문서 15 §5-2)
		_draw_text(PixelUi.FONT_SMALL, str(level), top_left + Vector2(SLOT_SIZE + 1.0, SLOT_SIZE + 2.0), HORIZONTAL_ALIGNMENT_RIGHT, PixelUi.GOLD, PixelUi.SIZE_SMALL)


## 생존자 머리 위가 아니라 화면 아래쪽 가운데에 얇게 (손가락에 안 가리게)
func _draw_health_bar(width: float) -> void:
	var survivor := _context.survivor
	var ratio := survivor.health_ratio()
	var bar := Rect2(width * 0.5 - 30.0, get_viewport_rect().size.y - 10.0, 60.0, 3.0)
	draw_rect(bar.grow(1.0), Color(0.05, 0.05, 0.08, 0.8))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), PixelUi.ALERT if ratio < Survivor.LOW_HEALTH_RATIO else Color("e05252"))
	if survivor.is_guarding():
		draw_rect(bar.grow(2.0), Color("8fd3ff"), false, 1.0)


func _draw_text(font: Font, text: String, at: Vector2, alignment: HorizontalAlignment, color: Color, font_size: int = PixelUi.SIZE_REGULAR) -> void:
	var box_width := 120.0
	var left := at.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		left -= box_width * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		left -= box_width
	draw_string(font, Vector2(left, at.y) + Vector2.ONE, text, alignment, box_width, font_size, PixelUi.SHADOW)
	draw_string(font, Vector2(left, at.y), text, alignment, box_width, font_size, color)
