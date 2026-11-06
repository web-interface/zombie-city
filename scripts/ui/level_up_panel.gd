## [파일] scripts/ui/level_up_panel.gd
## [하는 일] 레벨 업 창: 카드 3장(UpgradeCard — 새로 얻기·강화·진화·금색 히든)을 보여 주고, 탭 한 번으로 고르게 한다. 다시 뽑기(남은 횟수)·빼 버리기(남은 횟수, 누르고 카드를 고르면 그 판에서 다시 안 나옴)·건너뛰기(체력 조금 회복) 버튼. 카드는 서서히 나타나고, 히든 카드가 뜨면 전용 소리.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고, LevelUp.cards_ready 신호를 받아 열린다. 고르면 LevelUp.choose() 를, 빼 버리기는 LevelUp.banish() 를 부르고 닫힌다.
## [근거 문서] 02 §5 성장과 조합, 05 화면 목록(레벨 업), 13 (탭 한 번으로 고르기), 14 §2-1 빼 버리기·§2-5 히든 카드
class_name LevelUpPanel
extends Control

signal closed

const APPEAR_MILLISECONDS := 250.0      # 나타나는 시간 (실제 시간 — 보스 처치 느린 화면 중에도 똑같이)
const INPUT_GUARD_MILLISECONDS := 280.0 # 뜬 직후엔 눌러도 안 고름 (전투 중 두드리던 손에 잘못 골리지 않게 — 검수 지적)
const BUTTON_SIZE := Vector2(80, 22)

var _level_up: LevelUp
var _title: Label
var _card_box: VBoxContainer
var _reroll_button: Button
var _banish_button: Button
var _cards: Array = []
var _opened_at_msec: int = 0
var _is_banishing: bool = false
var _was_hidden_shown: bool = false


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
	_title = PixelUi.label("레벨 업!", PixelUi.GOOD, false, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_card_box = VBoxContainer.new()
	_card_box.add_theme_constant_override("separation", 5)
	column.add_child(_card_box)
	column.add_child(_build_bottom_rows())


## 자동 플레이가 고를 때도 쓴다.
func choose(index: int) -> void:
	if visible and index >= 0 and index < _cards.size():
		_pick(_cards[index])


func is_open() -> bool:
	return visible


func current_cards() -> Array:
	return _cards


## 아래 버튼 두 줄: [다시 뽑기][빼 버리기] / [건너뛰기]
func _build_bottom_rows() -> VBoxContainer:
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_reroll_button = _bottom_button("다시 뽑기", PixelUi.GOLD, func() -> void: _level_up.reroll())
	row.add_child(_reroll_button)
	_banish_button = _bottom_button("빼 버리기", PixelUi.ALERT, _toggle_banish)
	row.add_child(_banish_button)
	rows.add_child(row)
	var skip_button := _bottom_button("건너뛰기", PixelUi.MUTED, func() -> void: _close_after(func() -> void: _level_up.skip()))
	skip_button.custom_minimum_size = Vector2(BUTTON_SIZE.x * 2.0 + 4.0, BUTTON_SIZE.y)
	rows.add_child(skip_button)
	return rows


## 창이 뜬 직후 손가락이 닿아 눌리지 않게 (카드와 같은 막기)
func _bottom_button(text: String, accent: Color, action: Callable) -> Button:
	var new_button := PixelUi.button(text, accent)
	new_button.custom_minimum_size = BUTTON_SIZE
	new_button.pressed.connect(func() -> void:
		if not _is_input_guarded():
			action.call())
	return new_button


func _show_cards(cards: Array) -> void:
	_cards = cards
	_is_banishing = false
	for child: Node in _card_box.get_children():
		child.queue_free()
	var has_hidden := false
	for card: Dictionary in cards:
		var card_button := UpgradeCard.new()
		card_button.setup(card)
		card_button.pressed.connect(_pick.bind(card))
		_card_box.add_child(card_button)
		has_hidden = has_hidden or card["kind"] == "hidden_skill"
	if has_hidden and not _was_hidden_shown:
		SoundPlayer.play("hidden_card_appear")   # 다시 뽑기로 남은 히든 카드엔 또 울리지 않게
	_was_hidden_shown = has_hidden
	_reroll_button.text = "다시 뽑기 (%d)" % _level_up.rerolls_left
	_reroll_button.disabled = _level_up.rerolls_left <= 0
	_refresh_banish_mode()
	_opened_at_msec = Time.get_ticks_msec()
	modulate.a = 0.0
	visible = true


func _toggle_banish() -> void:
	if _level_up.deck.banishes_left <= 0:
		return
	_is_banishing = not _is_banishing
	SoundPlayer.play("ui_click")
	_refresh_banish_mode()


func _refresh_banish_mode() -> void:
	_title.text = "뺄 카드를 고르세요" if _is_banishing else "레벨 업!"
	_title.add_theme_color_override("font_color", PixelUi.ALERT if _is_banishing else PixelUi.GOOD)
	_banish_button.text = "취소" if _is_banishing else "빼 버리기 (%d)" % _level_up.deck.banishes_left
	_banish_button.disabled = _level_up.deck.banishes_left <= 0
	for child: Node in _card_box.get_children():
		var card_button := child as UpgradeCard
		if card_button != null and not card_button.is_queued_for_deletion():
			card_button.set_banish_mode(_is_banishing, _level_up.deck.can_banish(card_button.card))


func _pick(card: Dictionary) -> void:
	if _is_input_guarded():
		return
	if _is_banishing:
		if not _level_up.banish(card):   # 진화·히든·구급상자는 뺄 수 없음 (새 카드는 cards_ready 로 다시 뜬다)
			SoundPlayer.play("ui_back")
		return
	_close_after(func() -> void: _level_up.choose(card))


func _is_input_guarded() -> bool:
	return Time.get_ticks_msec() - _opened_at_msec < INPUT_GUARD_MILLISECONDS


func _close_after(action: Callable) -> void:
	visible = false
	_was_hidden_shown = false
	action.call()
	closed.emit()


## 서서히 나타난다. 위치는 상자가 정하게 두고 투명도만 바꾼다 (제목을 가리지 않게 — 검수 지적)
func _process(_delta: float) -> void:
	if visible and modulate.a < 1.0:
		modulate.a = clampf((Time.get_ticks_msec() - _opened_at_msec) / APPEAR_MILLISECONDS, 0.0, 1.0)
