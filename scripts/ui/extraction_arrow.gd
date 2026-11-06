## [파일] scripts/ui/extraction_arrow.gd
## [하는 일] 착륙 지점 안내: 착륙 지점이 화면 밖이면 화면 가장자리에 그쪽을 가리키는 깜빡이는 화살표와 남은 거리(m)를 그린다. 원 안에서 버티는 중이면 가운데 아래에 탈출 진행 막대를 그린다.
## [쓰는 곳] scripts/ui/hud.gd 가 만든다. Extraction 의 phase·zone_position·hold_ratio() 를 읽는다.
## [근거 문서] 05 게임 화면 배치(착륙 화살표), 02 §3 탈출
class_name ExtractionArrow
extends Control

const EDGE_MARGIN := 14.0
const ARROW_COLOR := Color("8ff59a")

var _extraction: Extraction
var _context: RunContext
var _time: float = 0.0


func setup(context: RunContext, extraction: Extraction) -> void:
	_context = context
	_extraction = extraction
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _extraction.phase in ["waiting", "done"]:
		return
	var screen_size := get_viewport_rect().size
	var camera_center := _context.camera.global_position
	var to_zone := _extraction.zone_position - camera_center
	var half := screen_size * 0.5 - Vector2.ONE * EDGE_MARGIN
	var is_offscreen := absf(to_zone.x) > half.x or absf(to_zone.y) > half.y
	if is_offscreen:
		_draw_edge_arrow(to_zone, screen_size, half)
	if _extraction.phase == "landed" and _extraction.is_survivor_in_zone():
		var bar := Rect2(screen_size.x * 0.5 - 40, screen_size.y - 40, 80, 4)
		draw_rect(bar.grow(1.0), Color(0.05, 0.05, 0.08, 0.85))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * _extraction.hold_ratio(), bar.size.y)), ARROW_COLOR)
		draw_string(PixelUi.FONT_SMALL, bar.position + Vector2(0, -3), "탑승 중…", HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, PixelUi.SIZE_SMALL, ARROW_COLOR)


func _draw_edge_arrow(to_zone: Vector2, screen_size: Vector2, half: Vector2) -> void:
	var direction := to_zone.normalized()
	var scale_to_edge := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	var tip := screen_size * 0.5 + direction * scale_to_edge
	if int(_time * 3.0) % 3 == 2:
		return
	var side := direction.orthogonal() * 4.0
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * 8.0 + side, tip - direction * 8.0 - side]), ARROW_COLOR)
	var meters := int(to_zone.length() / 4.0)   # 화면 점 4개 ≈ 1m 로 친다
	draw_string(PixelUi.FONT_SMALL, tip - direction * 18.0 - Vector2(20, -3), "%dm" % meters, HORIZONTAL_ALIGNMENT_CENTER, 40, PixelUi.SIZE_SMALL, ARROW_COLOR)
