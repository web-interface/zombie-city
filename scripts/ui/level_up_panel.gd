## [파일] scripts/ui/level_up_panel.gd
## [하는 일] 레벨 업 창: 카드 3장(아이콘·이름·단계·설명)을 보여 주고, 탭 한 번으로 고르게 한다. 다시 뽑기(남은 횟수 표시)·건너뛰기(체력 조금 회복) 버튼. 카드는 아래에서 살짝 올라오며 나타난다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고, LevelUp.cards_ready 신호를 받아 열린다. 고르면 LevelUp.choose() 를 부르고 닫힌다.
## [근거 문서] 02 §5 성장과 조합, 05 화면 목록(레벨 업), 13 (탭 한 번으로 고르기)
class_name LevelUpPanel
extends Control

signal closed

const CARD_SIZE := Vector2(164, 64)
const APPEAR_MILLISECONDS := 250.0      # 나타나는 시간 (실제 시간 — 보스 처치 느린 화면 중에도 똑같이)
const INPUT_GUARD_MILLISECONDS := 280.0 # 뜬 직후엔 눌러도 안 고름 (전투 중 두드리던 손에 잘못 골리지 않게 — 검수 지적)

var _level_up: LevelUp
var _card_box: VBoxContainer
var _reroll_button: Button
var _cards: Array = []
var _opened_at_msec: int = 0


func setup(level_up: LevelUp) -> void:
	_level_up = level_up
	_level_up.cards_ready.connect(_show_cards)
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.72)
	add_child(PixelUi.full_rect(dim))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	add_child(PixelUi.centered(column))
	var title := PixelUi.label("레벨 업!", PixelUi.GOOD, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_card_box = VBoxContainer.new()
	_card_box.add_theme_constant_override("separation", 5)
	column.add_child(_card_box)
	column.add_child(_build_bottom_row())


## 자동 플레이가 고를 때도 쓴다.
func choose(index: int) -> void:
	if visible and index >= 0 and index < _cards.size():
		_pick(_cards[index])


func is_open() -> bool:
	return visible


func current_cards() -> Array:
	return _cards


func _build_bottom_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_reroll_button = PixelUi.button("다시 뽑기", PixelUi.GOLD)
	_reroll_button.custom_minimum_size = Vector2(80, 22)
	_reroll_button.pressed.connect(func() -> void:
		if not _is_input_guarded():   # 창이 뜬 직후 손가락이 닿아 다시 뽑기가 눌리지 않게 (카드·건너뛰기와 같게)
			_level_up.reroll())
	row.add_child(_reroll_button)
	var skip_button := PixelUi.button("건너뛰기", PixelUi.MUTED)
	skip_button.custom_minimum_size = Vector2(80, 22)
	skip_button.pressed.connect(func() -> void:
		if not _is_input_guarded():
			_close_after(func() -> void: _level_up.skip()))
	row.add_child(skip_button)
	return row


func _show_cards(cards: Array) -> void:
	_cards = cards
	for child: Node in _card_box.get_children():
		child.queue_free()
	for card: Dictionary in cards:
		_card_box.add_child(_build_card(card))
	_reroll_button.text = "다시 뽑기 (%d)" % _level_up.rerolls_left
	_reroll_button.disabled = _level_up.rerolls_left <= 0
	_opened_at_msec = Time.get_ticks_msec()
	modulate.a = 0.0
	visible = true


func _build_card(card: Dictionary) -> Button:
	var card_button := PixelUi.button("", PixelUi.GOOD if String(card["kind"]).begins_with("new") else PixelUi.INK)
	card_button.custom_minimum_size = CARD_SIZE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.position = Vector2(5, 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(PixelUi.icon(String(card["icon"]), 2))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_line := PixelUi.label("%s  %s" % [card["name"], card["level_text"]], PixelUi.INK)
	texts.add_child(name_line)
	texts.add_child(PixelUi.small_lines(String(card["description"]), PixelUi.MUTED, CARD_SIZE.x - 40.0, 2))
	var flavor := String(card.get("flavor", ""))
	if not flavor.is_empty():   # 사람 냄새 나는 한 줄 (06 AI 티 안 나게)
		texts.add_child(PixelUi.small_lines(flavor, Color(PixelUi.MUTED, 0.6), CARD_SIZE.x - 40.0, 1))
	row.add_child(texts)
	card_button.add_child(row)
	card_button.pressed.connect(_pick.bind(card))
	return card_button


func _pick(card: Dictionary) -> void:
	if _is_input_guarded():
		return
	_close_after(func() -> void: _level_up.choose(card))


func _is_input_guarded() -> bool:
	return Time.get_ticks_msec() - _opened_at_msec < INPUT_GUARD_MILLISECONDS


func _close_after(action: Callable) -> void:
	visible = false
	action.call()
	closed.emit()


## 서서히 나타난다. 위치는 상자가 정하게 두고 투명도만 바꾼다 (제목을 가리지 않게 — 검수 지적)
func _process(_delta: float) -> void:
	if visible and modulate.a < 1.0:
		modulate.a = clampf((Time.get_ticks_msec() - _opened_at_msec) / APPEAR_MILLISECONDS, 0.0, 1.0)
