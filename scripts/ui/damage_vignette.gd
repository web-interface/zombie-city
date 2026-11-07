## [파일] scripts/ui/damage_vignette.gd
## [하는 일] 맞았을 때 화면에서 바로 알게: 맞은 쪽 화면 가장자리가 빨갛게(계단식 3단 띠) 번쩍였다 사라지고, 적 웅덩이 안에 서 있는 동안은 가장자리 빨강이 계속, 체력 30% 아래면 가장자리가 심장 박자로 붉게 두근. 생존자 머리 위에 받은 피해 숫자(빨강, 작게 — 계속 닿는 피해는 묶어서 띄움). 설정 '번쩍임 줄이기'면 두근 대신 가만히, '피해 숫자'를 끄면 숫자 없음.
## [쓰는 곳] scripts/ui/hud.gd 가 HUD 맨 아래 칸에 만들고 setup(context). Survivor.hit_taken 을 듣고, Hazards.is_survivor_in_zone 을 매 프레임 본다. 심장 박자에 맞춘 소리는 scripts/run/hit_feedback.gd.
## [근거 문서] 15 §7-3 맞았을 때 알기·§7-2 그리는 순서(적 테두리 위, HUD 아래), research_notes 뱀서라이크 readability.md §5 (가장자리 빨강·피해 숫자)
class_name DamageVignette
extends Control

const EDGE_COLOR := Color("ff1e2e")
const BAND_WIDTH := 3.0            # 계단 한 칸 두께(점) — 빛도 픽셀 단계로 (06 AI 티)
const BAND_STEPS := 3
const HIT_FADE_SECONDS := 0.45
const ZONE_EDGE_STRENGTH := 0.55
const LOW_HEALTH_BASE := 0.3
const LOW_HEALTH_PULSE := 0.45
const HEARTBEAT_SECONDS := 0.8
const NUMBER_COLOR := Color("ff4a4a")
const NUMBER_OUTLINE := Color(0.06, 0.03, 0.04)
const NUMBER_SECONDS := 0.6
const NUMBER_RISE := 14.0
const NUMBER_GATHER_SECONDS := 0.3   # 이 시간 안에 받은 작은 피해는 숫자 하나로
const MAX_NUMBERS := 6

var _context: RunContext
## 가장자리 세기 0~1: 왼쪽·오른쪽·위·아래
var _edges: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _numbers: Array[Dictionary] = []
var _gathered_damage: float = 0.0
var _gather_time: float = 0.0
var _time: float = 0.0
var _font: Font


func setup(context: RunContext) -> void:
	_context = context
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE   # 창이 떠 있는 동안엔 멈춘 그대로
	_font = PixelUi.FONT_SMALL
	context.survivor.hit_taken.connect(_on_hit_taken)


## 심장 박자 0~1 (HitFeedback 이 소리를 같은 박자에 맞춘다)
static func heartbeat(time: float) -> float:
	var beat := fposmod(time, HEARTBEAT_SECONDS) / HEARTBEAT_SECONDS
	return maxf(1.0 - beat * 6.0, 0.0) + 0.6 * maxf(1.0 - absf(beat - 0.25) * 8.0, 0.0)   # 쿵-쿵


func _on_hit_taken(amount: float, _source: String, from_position: Vector2) -> void:
	var strength := clampf(0.45 + amount / 20.0, 0.45, 1.0)
	if from_position == Survivor.NO_DIRECTION:
		for index: int in range(4):
			_edges[index] = maxf(_edges[index], strength)
	else:
		var direction := (from_position - _context.survivor.position).normalized()
		_edges[0] = maxf(_edges[0], strength * maxf(-direction.x, 0.0))
		_edges[1] = maxf(_edges[1], strength * maxf(direction.x, 0.0))
		_edges[2] = maxf(_edges[2], strength * maxf(-direction.y, 0.0))
		_edges[3] = maxf(_edges[3], strength * maxf(direction.y, 0.0))
	_gathered_damage += amount


func _process(delta: float) -> void:
	_time += delta
	for index: int in range(4):
		_edges[index] = maxf(_edges[index] - delta / HIT_FADE_SECONDS, 0.0)
	_gather_time += delta
	if _gathered_damage >= 1.0 and (_gather_time >= NUMBER_GATHER_SECONDS or _gathered_damage >= 8.0):
		_add_number(_gathered_damage)
	for number: Dictionary in _numbers:
		number["time"] = float(number["time"]) + delta
	_numbers.assign(_numbers.filter(func(number: Dictionary) -> bool: return float(number["time"]) < NUMBER_SECONDS))
	queue_redraw()


func _add_number(amount: float) -> void:
	_gathered_damage = 0.0
	_gather_time = 0.0
	if not SaveData.is_damage_numbers_on():
		return
	if _numbers.size() >= MAX_NUMBERS:
		_numbers.pop_front()
	_numbers.append({"text": "-%d" % maxi(1, roundi(amount)), "time": 0.0, "jitter": randf_range(-3.0, 3.0)})


## 지속 빨강(장판 안 · 체력 낮음)과 맞은 쪽 번쩍 중 큰 쪽
func _steady_strength() -> float:
	var steady := 0.0
	if _context.hazards.is_survivor_in_zone:
		steady = ZONE_EDGE_STRENGTH
	if _context.survivor.health_ratio() < Survivor.CRITICAL_HEALTH_RATIO and not _context.survivor.is_dead:
		var pulse := LOW_HEALTH_PULSE * (0.5 if SaveData.is_flash_reduced() else heartbeat(_time))
		steady = maxf(steady, LOW_HEALTH_BASE + pulse)
	return steady


func _draw() -> void:
	var steady := _steady_strength()
	var screen := size
	for step: int in range(BAND_STEPS):
		var inset := step * BAND_WIDTH
		var alpha_scale := 0.55 * (1.0 - float(step) / BAND_STEPS)
		var left := maxf(_edges[0], steady) * alpha_scale
		var right := maxf(_edges[1], steady) * alpha_scale
		var top := maxf(_edges[2], steady) * alpha_scale
		var bottom := maxf(_edges[3], steady) * alpha_scale
		draw_rect(Rect2(inset, 0, BAND_WIDTH, screen.y), Color(EDGE_COLOR, left))
		draw_rect(Rect2(screen.x - inset - BAND_WIDTH, 0, BAND_WIDTH, screen.y), Color(EDGE_COLOR, right))
		draw_rect(Rect2(0, inset, screen.x, BAND_WIDTH), Color(EDGE_COLOR, top))
		draw_rect(Rect2(0, screen.y - inset - BAND_WIDTH, screen.x, BAND_WIDTH), Color(EDGE_COLOR, bottom))
	_draw_numbers()


## 생존자 머리 위 받은 피해 숫자 (세상 → 화면 좌표)
func _draw_numbers() -> void:
	var head := _context.survivor.get_global_transform_with_canvas().origin + Vector2(0, -16)
	for number: Dictionary in _numbers:
		var age := float(number["time"])
		var spot := (head + Vector2(float(number["jitter"]), -NUMBER_RISE * age)).round()
		var fade := clampf(1.0 - maxf(0.0, age - NUMBER_SECONDS * 0.5) / (NUMBER_SECONDS * 0.5), 0.0, 1.0)
		draw_string_outline(_font, spot, number["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, PixelUi.SIZE_SMALL, 2, Color(NUMBER_OUTLINE, fade))
		draw_string(_font, spot, number["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, PixelUi.SIZE_SMALL, Color(NUMBER_COLOR, fade))
