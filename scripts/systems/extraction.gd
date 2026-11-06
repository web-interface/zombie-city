## [파일] scripts/systems/extraction.gd
## [하는 일] 탈출 담당: 4:30 에 착륙 지점을 정해 알리고(화면 밖이면 HUD 가 화살표), 5:00 에 헬기가 내려와 서치라이트를 비춘다. 생존자가 착륙 원 안에 8초(밖으로 나가면 멈춤) 있으면 탈출 성공, 5:30 까지 못 타면 헬기가 떠나 실패. 헬기와 착륙 원도 직접 그린다.
## [쓰는 곳] scenes/run.tscn 의 World/Extraction. run.gd 가 update() 를 부르고 신호를 HUD·결과에 잇는다.
## [근거 문서] 02 §3 시간표·§9 승패, 03 §8 탈출, data/run_rules.json extraction
class_name Extraction
extends Node2D

signal landing_zone_revealed(zone_position: Vector2)
signal helicopter_arrived
signal extracted
signal helicopter_left

const HELICOPTER_TEXTURE: Texture2D = preload("res://art/sprites/helicopter.png")
const ZONE_COLOR := Color("8ff59a")
const DESCENT_SECONDS := 2.0

var zone_position: Vector2 = Vector2.ZERO
var hold_progress: float = 0.0
var phase: String = "waiting"      # waiting → revealed → landed → done
var _context: RunContext
var _rules: Dictionary = {}
var _time: float = 0.0
var _landed_at: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	_rules = GameData.rules("extraction")
	z_index = 15


func update(delta: float) -> void:
	_time += delta
	var elapsed := _context.elapsed_seconds
	match phase:
		"waiting":
			if elapsed >= float(_rules["landing_zone_reveal_second"]):
				_reveal_zone()
		"revealed":
			if elapsed >= float(_rules["helicopter_arrive_second"]):
				phase = "landed"
				_landed_at = elapsed
				_context.lighting.add_temporary_light(zone_position, 46.0, 999.0)
				SoundPlayer.start_loop("helicopter_loop")
				helicopter_arrived.emit()
		"landed":
			_update_hold(delta)
	queue_redraw()


func is_survivor_in_zone() -> bool:
	return _context.survivor.position.distance_to(zone_position) <= float(_rules["landing_zone_radius"])


func hold_ratio() -> float:
	return clampf(hold_progress / float(_rules["hold_seconds"]), 0.0, 1.0)


func _reveal_zone() -> void:
	phase = "revealed"
	var direction := Vector2.from_angle(randf() * TAU)
	zone_position = _context.survivor.position + direction * float(_rules["landing_zone_distance"])
	zone_position = _context.props.push_out(zone_position, float(_rules["landing_zone_radius"]))
	landing_zone_revealed.emit(zone_position)


func _update_hold(delta: float) -> void:
	if is_survivor_in_zone():
		hold_progress += delta
	if hold_progress >= float(_rules["hold_seconds"]):
		phase = "done"
		SoundPlayer.stop_loop("helicopter_loop")
		_context.play_sound("extraction_success")
		extracted.emit()
	elif _context.elapsed_seconds >= float(_rules["helicopter_leave_second"]):
		phase = "done"
		SoundPlayer.stop_loop("helicopter_loop")
		helicopter_left.emit()


func _draw() -> void:
	if phase == "waiting":
		return
	var radius := float(_rules["landing_zone_radius"])
	var dots := 28
	for index: int in range(dots):
		var is_lit := float(index) / dots < hold_ratio() or int(_time * 4.0) % 2 == 0
		var point := zone_position + Vector2.from_angle(TAU * index / dots + _time * 0.5) * radius
		draw_rect(Rect2(point.round(), Vector2.ONE * 2.0), Color(ZONE_COLOR, 1.0 if is_lit else 0.35))
	_draw_landing_mark(radius)
	if phase in ["landed", "done"]:
		_draw_helicopter()


func _draw_landing_mark(radius: float) -> void:
	var mark_color := Color(ZONE_COLOR, 0.6)
	draw_rect(Rect2(zone_position + Vector2(-5, -6), Vector2(2, 12)), mark_color)
	draw_rect(Rect2(zone_position + Vector2(3, -6), Vector2(2, 12)), mark_color)
	draw_rect(Rect2(zone_position + Vector2(-3, -1), Vector2(6, 2)), mark_color)
	if hold_progress > 0.0:
		draw_arc(zone_position, radius + 3.0, -PI * 0.5, -PI * 0.5 + TAU * hold_ratio(), 24, ZONE_COLOR, 2.0)


func _draw_helicopter() -> void:
	var descent := clampf((_context.elapsed_seconds - _landed_at) / DESCENT_SECONDS, 0.0, 1.0)
	var height := lerpf(60.0, 18.0, descent)
	var body_position := zone_position + Vector2(-12, -height - 5)
	# 서치라이트: 헬기에서 바닥으로 비추는 빛이 착륙 원 위를 천천히 훑는다
	var spot := zone_position + Vector2(cos(_time * 1.3) * 12.0, sin(_time * 0.9) * 7.0)
	var lamp := body_position + Vector2(9, 7)
	draw_colored_polygon(PackedVector2Array([lamp, spot + Vector2(-11, 2), spot + Vector2(11, 2)]), Color(1.0, 0.97, 0.8, 0.13))
	draw_circle(spot, 9.0, Color(1.0, 0.97, 0.8, 0.12))
	draw_texture(HELICOPTER_TEXTURE, body_position.round())
	var rotor_center := body_position + Vector2(8, 3)
	var rotor_angle := _time * 30.0
	draw_line(rotor_center - Vector2.from_angle(rotor_angle) * 14.0, rotor_center + Vector2.from_angle(rotor_angle) * 14.0, Color(0.85, 0.87, 0.9, 0.8), 1.0)
	draw_rect(Rect2((zone_position + Vector2(-8, 4)).round(), Vector2(16, 3)), Color(0, 0, 0, 0.35))   # 그림자
