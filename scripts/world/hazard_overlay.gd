## [파일] scripts/world/hazard_overlay.gd
## [하는 일] 적의 것을 맨 위 '적 층'에 그린다: 웅덩이 테두리(안쪽 1점 밝게 + 바깥 1점 어둡게, 깜빡임)·거품, 빨간 예고 원·선, 날아오는 침·식칼·철근(밝은 몸 + 검은 테두리 1점). 밤 어둠·안개·내 효과보다 위라서 무엇에도 안 묻힌다. 생존자가 웅덩이 안이면 그 테두리가 크게 깜빡이고 발밑에 고리.
## [쓰는 곳] scripts/world/hazards.gd 가 자식으로 만들어 목록을 넘기고 매 프레임 advance()·queue_redraw(). 적 경고 선 층 번호(ENEMY_LAYER)는 effects.gd 도 쓴다.
## [근거 문서] 15 §7-1 색 언어·§7-2 그리는 순서·§7-3 장판 안 알림, research_notes 뱀서라이크 readability.md §4 (밝은 테두리 + 어두운 바깥 테두리)
class_name HazardOverlay
extends CanvasLayer

## 날씨(2) 위, HUD(10)·피격 표시 아래 — 적 테두리·예고는 언제나 맨 위 (문서 15 §7-2)
const ENEMY_LAYER := 3
const EDGE_BRIGHT := Color("ffb08a")
const EDGE_DARK := Color("1a0408")
const BUBBLE_COLORS: Array[Color] = [Color("ff2fa0"), Color("ff6a2a"), Color("ffc2e4")]
const WARNING_COLOR := Color("ff3b3b")
const HATCH_COLOR := Color("ff4fb8")
const HATCH_ALPHA := 0.45
const HATCH_GAP := 4
const KEEP_CLEAR_RADIUS := 7.0
const OUTLINE_COLOR := Color("0b0b10")
const SPIT_COLOR := Color("ff3fb4")
const THROWN_LOOKS := {
	"cleaver": {"color": Color("ff6a7a"), "shine": Color("ffffff"), "size": Vector2(3, 3)},
	"rebar": {"color": Color("ff7a3c"), "shine": Color("ffd9c4"), "size": Vector2(5, 2)},
}
const BLINK_SPEED := 9.0
const STANDING_BLINK_SPEED := 22.0
const FEET_RING_RADIUS := 6.0

var _context: RunContext
var _lists: Dictionary = {}
var _canvas: Node2D
var _time: float = 0.0


## lists = {"puddles", "warnings", "line_warnings", "thrown", "spits"} — hazards.gd 의 목록을 그대로 (같은 배열을 봄)
func setup(context: RunContext, lists: Dictionary) -> void:
	_context = context
	_lists = lists
	layer = ENEMY_LAYER
	follow_viewport_enabled = true
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_enemy_things)


func advance(delta: float) -> void:
	_time += delta


func queue_redraw() -> void:
	_canvas.queue_redraw()


## 원 안을 대각선 빗금으로 (색이 안 보여도 '적 장판' 모양으로 알게 — 색약 배려, 문서 15 §7-1)
## keep_clear 둘레(생존자)는 비워 둔다 — 웅덩이가 겹쳐 쌓여도 내 캐릭터가 빗금에 묻히지 않게
static func draw_hatch(canvas: CanvasItem, center: Vector2, radius: float, gap: int, color: Color, keep_clear: Vector2) -> void:
	var inner := radius - 1.0
	var along := Vector2(1, 1).normalized()
	var reach := int(inner * 1.41)
	for shift: int in range(-reach, reach + 1, gap):
		var distance := absf(shift) / 1.41421   # 선 y = x + offset 과 가운데 사이 거리
		if distance >= inner:
			continue
		var middle := center + Vector2(-shift * 0.5, shift * 0.5)
		var half := sqrt(inner * inner - distance * distance)
		for step: int in range(-int(half), int(half) + 1):   # 1점씩 찍어 픽셀 빗금 (얇은 선은 폰·웹에서 안 보일 때가 있음)
			var dot := (middle + along * step).round()
			if dot.distance_to(keep_clear) > KEEP_CLEAR_RADIUS:
				canvas.draw_rect(Rect2(dot, Vector2.ONE), color)


func _draw_enemy_things() -> void:
	for puddle: Dictionary in _lists["puddles"]:
		_draw_puddle_edge(puddle)
	for warning: Dictionary in _lists["warnings"]:
		_draw_warning(warning)
	for line: Dictionary in _lists["line_warnings"]:
		_draw_line_warning(line)
	for item: Dictionary in _lists["thrown"]:
		_draw_thrown(item)
	for spit_item: Dictionary in _lists["spits"]:
		var point := Vector2(spit_item["position"]).round()
		var trail := point - Vector2(spit_item["velocity"]).normalized() * 3.0
		_canvas.draw_rect(Rect2(trail.round(), Vector2.ONE), Color(SPIT_COLOR, 0.6))
		_draw_outlined_rect(point - Vector2(1, 1), Vector2(3, 3), SPIT_COLOR)


## 웅덩이 테두리 두 겹 + 깜빡임 + 거품. 생존자가 안에 있으면 빠르고 굵게 깜빡이고 발밑에 고리.
func _draw_puddle_edge(puddle: Dictionary) -> void:
	var center := Vector2(puddle["center"]).round()
	var radius := float(puddle["radius"])
	var fade := clampf(float(puddle["time_left"]) * 1.5, 0.0, 1.0)
	var is_standing := bool(puddle.get("has_survivor", false))
	var speed := STANDING_BLINK_SPEED if is_standing else BLINK_SPEED
	var blink := 0.65 + 0.35 * absf(sin(_time * speed + center.x))
	# 빗금은 여기(맨 위)에도 옅게 — 밤 어둠·내 효과에 묻혀도 '적 장판' 모양이 보이게
	draw_hatch(_canvas, center, radius, HATCH_GAP, Color(HATCH_COLOR, HATCH_ALPHA * fade), _context.survivor.position + Vector2(0, -5))
	_canvas.draw_arc(center, radius + 1.0, 0.0, TAU, 40, Color(EDGE_DARK, 0.9 * fade), 1.0)
	_canvas.draw_arc(center, radius, 0.0, TAU, 40, Color(EDGE_BRIGHT, blink * fade), 2.0 if is_standing else 1.0)
	var bubbles := maxi(3, int(radius * 0.35))
	for index: int in range(bubbles):
		var cycle := fposmod(_time * 0.8 + index * 0.37, 1.0)   # 부풀었다 터지는 한 바퀴
		var angle := float(index) * 2.39996
		var point := center + Vector2.from_angle(angle) * sqrt(fposmod(index * 0.618, 1.0)) * (radius - 2.0)
		var size := Vector2.ONE * (2.0 if cycle > 0.6 else 1.0)
		_canvas.draw_rect(Rect2((point - Vector2(0, cycle * 2.0)).round(), size), Color(BUBBLE_COLORS[index % 3], (1.0 - cycle) * fade))
	if is_standing:
		var feet := _context.survivor.position.round()
		_canvas.draw_arc(feet, FEET_RING_RADIUS, 0.0, TAU, 16, Color(EDGE_DARK, 0.9), 3.0)
		_canvas.draw_arc(feet, FEET_RING_RADIUS, 0.0, TAU, 16, Color(EDGE_BRIGHT, blink), 1.0)


## 예고 원: 테두리가 깜빡이고 안쪽이 차오른다 — 다 차면 터진다
func _draw_warning(warning: Dictionary) -> void:
	var progress := 1.0 - float(warning["time_left"]) / maxf(float(warning["total"]), 0.01)
	var radius := float(warning["radius"])
	var blink := 0.55 + 0.45 * absf(sin(_time * 14.0))
	_canvas.draw_arc(warning["center"], radius + 1.0, 0.0, TAU, 32, Color(EDGE_DARK, 0.8), 1.0)
	_canvas.draw_arc(warning["center"], radius, 0.0, TAU, 32, Color(WARNING_COLOR, blink), 1.0)
	_canvas.draw_circle(warning["center"], radius * progress, Color(WARNING_COLOR, 0.28))


## 예고 선: 빨간 띠가 깜빡이며 앞에서부터 차오른다
func _draw_line_warning(line: Dictionary) -> void:
	var from_position: Vector2 = line["from"]
	var to_position: Vector2 = line["to"]
	var progress := 1.0 - float(line["time_left"]) / maxf(float(line["total"]), 0.01)
	var side := (to_position - from_position).normalized().orthogonal() * float(line["width"]) * 0.5
	var blink := 0.55 + 0.45 * absf(sin(_time * 14.0))
	var outline := PackedVector2Array([from_position + side, to_position + side, to_position - side, from_position - side, from_position + side])
	_canvas.draw_polyline(outline, Color(WARNING_COLOR, blink), 1.0)
	var filled_end := from_position.lerp(to_position, progress)
	_canvas.draw_colored_polygon(PackedVector2Array([from_position + side, filled_end + side, filled_end - side, from_position - side]), Color(WARNING_COLOR, 0.25))


## 식칼은 빙글빙글(반짝이는 점이 돌아감), 철근은 날아가는 쪽으로 누운 막대 — 둘 다 검은 테두리
func _draw_thrown(item: Dictionary) -> void:
	var look: Dictionary = THROWN_LOOKS.get(item["look"], THROWN_LOOKS["cleaver"])
	var point := Vector2(item["position"]).round()
	var size: Vector2 = look["size"]
	if item["look"] == "rebar" and absf(Vector2(item["velocity"]).y) > absf(Vector2(item["velocity"]).x):
		size = Vector2(size.y, size.x)
	_draw_outlined_rect((point - size * 0.5).round(), size, look["color"])
	var spin := Vector2.from_angle(_time * 20.0).round()
	_canvas.draw_rect(Rect2(point + spin, Vector2.ONE), look["shine"])


func _draw_outlined_rect(top_left: Vector2, size: Vector2, color: Color) -> void:
	_canvas.draw_rect(Rect2(top_left - Vector2.ONE, size + Vector2(2, 2)), OUTLINE_COLOR)
	_canvas.draw_rect(Rect2(top_left, size), color)
