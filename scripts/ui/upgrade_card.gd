## [파일] scripts/ui/upgrade_card.gd
## [하는 일] 레벨 업 카드 한 장(버튼): 아이콘·이름·단계·설명·한 줄 이야기(또는 금색 진화 힌트). 종류마다 모양이 다르다 — 새로 얻기 초록 테두리, 진화 주황빛 금색 테두리 + 천천히 지나가는 빛, 히든 스킬 금색 바탕 + 반짝이는 별 + 빠르게 지나가는 빛줄기. 빼 버리기 고르는 중엔 뺄 수 있는 카드만 빨간 테두리.
## [쓰는 곳] scripts/ui/level_up_panel.gd 가 카드마다 만든다. 고르기는 패널이 pressed 신호로 받는다.
## [근거 문서] 14 §2-1 (빼 버리기)·§2-5 (금색 반짝이 카드)·§2-7, 05 화면 목록(레벨 업), 06 AI 티(카드 한 줄 이야기)
class_name UpgradeCard
extends Button

const CARD_SIZE := Vector2(164, 64)
const TEXT_WIDTH := 124.0
const EVOLUTION_EDGE := Color("ffb347")
const HIDDEN_FILL := Color("3d2c06")
const EVOLUTION_FILL := Color("2e2414")
const BANISH_FILL := Color("2b1a20")
const BANISH_DIM := Color(0.45, 0.45, 0.5)
const HIDDEN_SHINE_SECONDS := 1.3        # 빛줄기가 카드를 한 번 지나가는 시간
const EVOLUTION_SHINE_SECONDS := 2.2
const SHINE_WIDTH := 7.0
## 히든 카드 별 자리 (카드 안 점 위치) — 차례로 반짝인다
const SPARKLE_POINTS: Array[Vector2] = [Vector2(150, 8), Vector2(12, 54), Vector2(122, 52), Vector2(144, 32), Vector2(34, 5), Vector2(96, 9), Vector2(70, 56)]

var card: Dictionary = {}
var _kind: String = ""
var _effect_layer: Control
var _normal_style: StyleBox


func setup(new_card: Dictionary) -> void:
	card = new_card
	_kind = String(card["kind"])
	PixelUi.style_button(self, "", _accent_color())
	custom_minimum_size = CARD_SIZE
	if _kind == "hidden_skill":
		add_theme_stylebox_override("normal", PixelUi.panel_style(HIDDEN_FILL, PixelUi.GOLD, 2))
		add_theme_stylebox_override("hover", PixelUi.panel_style(HIDDEN_FILL.lightened(0.1), Color.WHITE, 2))
	elif _kind == "evolution":
		add_theme_stylebox_override("normal", PixelUi.panel_style(EVOLUTION_FILL, EVOLUTION_EDGE, 2))
	_normal_style = get_theme_stylebox("normal")
	add_child(_build_row())
	if _is_special():
		_effect_layer = PixelUi.full_rect(Control.new())
		_effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_effect_layer.clip_contents = true   # 빛줄기가 카드 밖으로 나가지 않게
		_effect_layer.draw.connect(_draw_effects)
		add_child(_effect_layer)


## 빼 버리기 고르는 중: 뺄 수 있는 카드는 빨간 테두리, 못 빼는 카드(진화·히든·구급상자)는 흐리게
func set_banish_mode(is_banishing: bool, can_banish: bool) -> void:
	modulate = BANISH_DIM if is_banishing and not can_banish else Color.WHITE   # 투명하게 하면 뒤 화면이 비쳐 어지러워서 어둡게만
	var style := PixelUi.panel_style(BANISH_FILL, PixelUi.ALERT, 2) if is_banishing and can_banish else _normal_style
	add_theme_stylebox_override("normal", style)


func _accent_color() -> Color:
	match _kind:
		"hidden_skill", "evolution":
			return PixelUi.GOLD
		"new_weapon", "new_gear":
			return PixelUi.GOOD
	return PixelUi.INK


func _is_special() -> bool:
	return _kind == "hidden_skill" or _kind == "evolution"


func _build_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.position = Vector2(5, 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(PixelUi.icon(String(card["icon"]), 2))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_color := PixelUi.GOLD if _is_special() else PixelUi.INK
	texts.add_child(PixelUi.label("%s  %s" % [card["name"], card["level_text"]], name_color, false, _is_special()))
	texts.add_child(PixelUi.small_lines(String(card["description"]), PixelUi.MUTED, TEXT_WIDTH, 2))
	var hint := String(card.get("hint", ""))
	var flavor := String(card.get("flavor", ""))
	if not hint.is_empty():   # 진화 짝이 보이면 이야기 대신 금색 힌트 (한 판 더 하고 싶게)
		texts.add_child(PixelUi.small_lines(hint, PixelUi.GOLD, TEXT_WIDTH, 1))
	elif not flavor.is_empty():   # 사람 냄새 나는 한 줄 (06 AI 티 안 나게)
		texts.add_child(PixelUi.small_lines(flavor, Color(PixelUi.MUTED, 0.6), TEXT_WIDTH, 1))
	row.add_child(texts)
	return row


## 창이 멈춘 동안에도 움직이게 실제 시간으로 그린다 (Hud 가 늘 도는 층이라 _process 가 돈다)
func _process(_delta: float) -> void:
	if _effect_layer != null and is_visible_in_tree():
		_effect_layer.queue_redraw()


func _draw_effects() -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var layer_size := _effect_layer.size
	var shine_seconds := HIDDEN_SHINE_SECONDS if _kind == "hidden_skill" else EVOLUTION_SHINE_SECONDS
	var shine_x := lerpf(-SHINE_WIDTH * 2.0, layer_size.x + SHINE_WIDTH * 2.0, fmod(time, shine_seconds) / shine_seconds)
	var shine := PackedVector2Array([Vector2(shine_x, 0), Vector2(shine_x + SHINE_WIDTH, 0), Vector2(shine_x - SHINE_WIDTH, layer_size.y), Vector2(shine_x - SHINE_WIDTH * 2.0, layer_size.y)])
	_effect_layer.draw_colored_polygon(shine, Color(1.0, 1.0, 1.0, 0.16 if _kind == "hidden_skill" else 0.1))
	var edge_color := PixelUi.GOLD if _kind == "hidden_skill" else EVOLUTION_EDGE
	var pulse := 0.5 + 0.5 * sin(time * 5.0)
	_effect_layer.draw_rect(Rect2(Vector2.ONE, layer_size - Vector2.ONE * 2.0), Color(Color.WHITE, 0.35 * pulse), false, 1.0)
	_effect_layer.draw_rect(Rect2(Vector2.ZERO, layer_size), Color(edge_color, 0.6 + 0.4 * pulse), false, 1.0)
	if _kind == "hidden_skill":
		_draw_sparkles(time)


## 별 모양(+) 반짝임이 자리마다 박자를 달리해 켜졌다 꺼진다
func _draw_sparkles(time: float) -> void:
	for index: int in range(SPARKLE_POINTS.size()):
		var brightness := sin(time * 6.0 + index * 1.7)
		if brightness < 0.2:
			continue
		var point := SPARKLE_POINTS[index]
		var color := Color(Color.WHITE if index % 2 == 0 else PixelUi.GOLD, brightness)
		_effect_layer.draw_rect(Rect2(point, Vector2.ONE), color)
		if brightness > 0.7:
			_effect_layer.draw_rect(Rect2(point + Vector2(-1, 0), Vector2(3, 1)), Color(color, brightness * 0.6))
			_effect_layer.draw_rect(Rect2(point + Vector2(0, -1), Vector2(1, 3)), Color(color, brightness * 0.6))
