## [파일] scripts/world/weather.gd
## [하는 일] 밤의 분위기(data/night_themes.json): 화면 위에 날씨를 그린다 — 비(비스듬히 떨어지는 빗줄기), 재(붉은 달 아래 흩날리는 재), 안개(천천히 흐르는 뿌연 덩어리). 어둠 색도 그 밤의 색으로 바꾼다. 게임 화면 위·UI 아래 층.
## [쓰는 곳] scenes/run.tscn 의 Weather (CanvasLayer, RunContext.weather). setup() 때 첫째 밤 분위기를 걸고, scripts/run/night_flow.gd 가 다음 밤마다 apply_theme() 을 부른다.
## [근거 문서] 14 §4 중독 설계(사용자 "개성 넘치고, 계속 하고 싶게"), 06 밤 분위기
class_name Weather
extends CanvasLayer

const RAIN_COUNT := 70
const ASH_COUNT := 45
const FOG_COUNT := 7
const RAIN_VELOCITY := Vector2(-40, 260)
const ASH_VELOCITY := Vector2(-6, 14)
const FOG_SPEED := 6.0

var _context: RunContext
var _kind: String = "none"
var _drops: Array[Vector2] = []
var _canvas: Node2D
var _time: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	layer = 2   # 게임 화면(0) 위, HUD(10) 아래
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_weather)
	apply_theme(context.night_cycle.theme())


## theme = {name, darkness, weather, …}
func apply_theme(theme: Dictionary) -> void:
	_context.lighting.set_darkness_color(Color(String(theme["darkness"])))
	_kind = String(theme["weather"])
	_drops.clear()
	var count := {"rain": RAIN_COUNT, "ash": ASH_COUNT, "fog": FOG_COUNT}.get(_kind, 0) as int
	var screen := _screen_size()
	for index: int in range(count):
		_drops.append(Vector2(randf() * screen.x, randf() * screen.y))


func _process(delta: float) -> void:
	if _kind == "none" or get_tree().paused:
		return
	_time += delta
	var screen := _screen_size()
	for index: int in range(_drops.size()):
		_drops[index] = _wrap(_drops[index] + _velocity(index) * delta, screen)
	_canvas.queue_redraw()


func _velocity(index: int) -> Vector2:
	match _kind:
		"rain":
			return RAIN_VELOCITY * (0.8 + 0.4 * float(index % 5) / 4.0)
		"ash":
			return ASH_VELOCITY + Vector2(sin(_time * 1.3 + index) * 8.0, 0)
		"fog":
			return Vector2(FOG_SPEED * (1.0 if index % 2 == 0 else -0.7), 0)
	return Vector2.ZERO


func _wrap(point: Vector2, screen: Vector2) -> Vector2:
	return Vector2(fposmod(point.x, screen.x + 20.0) - 10.0, fposmod(point.y, screen.y + 20.0) - 10.0)


func _draw_weather() -> void:
	match _kind:
		"rain":
			for drop: Vector2 in _drops:
				_canvas.draw_line(drop.round(), (drop + RAIN_VELOCITY.normalized() * 4.0).round(), Color(0.7, 0.8, 1.0, 0.28), 1.0)
		"ash":
			for flake: Vector2 in _drops:
				_canvas.draw_rect(Rect2(flake.round(), Vector2.ONE), Color(0.85, 0.6, 0.55, 0.55))
		"fog":
			for index: int in range(_drops.size()):
				_canvas.draw_circle(_drops[index], 40.0 + 12.0 * (index % 3), Color(0.75, 0.78, 0.85, 0.06))


func _screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size
