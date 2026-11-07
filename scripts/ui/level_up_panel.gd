## [파일] scripts/ui/level_up_panel.gd
## [하는 일] 레벨 업 창: 카드 3장(UpgradeCard — 새로 얻기·강화·진화·금색 히든)을 보여 주고 탭으로 고르게 한다. 위쪽 줄에 다시 뽑기(남은 횟수)·빼 버리기(남은 횟수, 누르고 카드를 고르면 그 판에서 다시 안 나옴)·건너뛰기(체력 조금 회복). 카드·버튼은 조이스틱 엄지 자리(화면 아래 35%) 밖 위쪽에만 놓고, 뜬 뒤 0.6초는 흐리게 막아 두었다가 '딸깍'과 함께 켠다(TapGuard). 히든 카드가 뜨면 전용 소리.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고, LevelUp.cards_ready 신호를 받아 열린다. 고르면 LevelUp.choose() 를, 빼 버리기는 LevelUp.banish() 를 부르고 닫힌다. 자동 플레이 봇은 choose(번호).
## [근거 문서] 15 §8 잘못 눌림, 02 §5 성장과 조합, 05 화면 목록(레벨 업), 14 §2-1 빼 버리기·§2-5 히든 카드
class_name LevelUpPanel
extends Control

signal closed

const BUTTON_HEIGHT := 18.0
const ROW_WIDTH := 164.0

var _level_up: LevelUp
var _guard := TapGuard.new()
var _title: Label
var _card_box: VBoxContainer
var _reroll_button: Button
var _banish_button: Button
var _skip_button: Button
var _cards: Array = []
var _is_banishing: bool = false
var _was_hidden_shown: bool = false


func setup(level_up: LevelUp) -> void:
	_level_up = level_up
	_level_up.cards_ready.connect(_show_cards)
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP   # 아래 엄지 자리를 두드려도 창 뒤로 안 새게
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.72)
	add_child(PixelUi.full_rect(dim))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	TapGuard.place_above_thumb_zone(self, column)
	_title = PixelUi.label("레벨 업!", PixelUi.GOOD, false, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	column.add_child(_build_button_row())
	_card_box = VBoxContainer.new()
	_card_box.add_theme_constant_override("separation", 3)
	column.add_child(_card_box)


## 자동 플레이가 고를 때 (손가락이 없으니 막는 시간이 끝났는지만 본다)
func choose(index: int) -> void:
	if visible and _guard.is_ready() and index >= 0 and index < _cards.size():
		_apply_pick(_cards[index])


func is_open() -> bool:
	return visible


func current_cards() -> Array:
	return _cards


## 위쪽 버튼 한 줄: [다시 뽑기][빼 버리기][건너뛰기] — 아래 엄지 자리에 두지 않으려고 카드 위에
func _build_button_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.custom_minimum_size = Vector2(ROW_WIDTH, BUTTON_HEIGHT)
	_reroll_button = _small_button(PixelUi.GOLD, func() -> void: _level_up.reroll())
	row.add_child(_reroll_button)
	_banish_button = _small_button(PixelUi.ALERT, _toggle_banish)
	row.add_child(_banish_button)
	_skip_button = _small_button(PixelUi.MUTED, func() -> void: _close_after(func() -> void: _level_up.skip()))
	_skip_button.text = "건너뛰기"
	row.add_child(_skip_button)
	return row


func _small_button(accent: Color, action: Callable) -> Button:
	var new_button := PixelUi.button("", accent)
	new_button.add_theme_font_override("font", PixelUi.FONT_SMALL)
	new_button.add_theme_font_size_override("font_size", PixelUi.SIZE_SMALL)
	new_button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guard.watch(new_button)
	new_button.pressed.connect(func() -> void:
		if _guard.accepts(new_button):
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
		_guard.watch(card_button)
		card_button.pressed.connect(_on_card_pressed.bind(card_button))
		_card_box.add_child(card_button)
		has_hidden = has_hidden or card["kind"] == "hidden_skill"
	if has_hidden and not _was_hidden_shown:
		SoundPlayer.play("hidden_card_appear")   # 다시 뽑기로 남은 히든 카드엔 또 울리지 않게
	_was_hidden_shown = has_hidden
	_reroll_button.text = "다시 뽑기 %d" % _level_up.rerolls_left
	_reroll_button.disabled = _level_up.rerolls_left <= 0
	_refresh_banish_mode()
	_guard.open()   # 다시 뽑기·빼 버리기로 카드가 바뀌어도 다시 0.6초 막음 (바뀐 카드를 보고 고르게)
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
	_banish_button.text = "취소" if _is_banishing else "빼 버리기 %d" % _level_up.deck.banishes_left
	_banish_button.disabled = _level_up.deck.banishes_left <= 0
	for child: Node in _card_box.get_children():
		var card_button := child as UpgradeCard
		if card_button != null and not card_button.is_queued_for_deletion():
			card_button.set_banish_mode(_is_banishing, _level_up.deck.can_banish(card_button.card))


## 사람 손가락으로 누름: 막는 시간 뒤 새로 누른 것만, 두 번 눌러 고르기면 두 번째에
func _on_card_pressed(card_button: UpgradeCard) -> void:
	if _guard.accepts_pick(card_button):
		_apply_pick(card_button.card)


func _apply_pick(card: Dictionary) -> void:
	if _is_banishing:
		if not _level_up.banish(card):   # 진화·히든·구급상자는 뺄 수 없음 (새 카드는 cards_ready 로 다시 뜬다)
			SoundPlayer.play("ui_back")
		return
	_close_after(func() -> void: _level_up.choose(card))


func _close_after(action: Callable) -> void:
	visible = false
	_was_hidden_shown = false
	action.call()
	closed.emit()


## 막는 동안 카드·버튼을 흐리게, 켜지는 순간 또렷하게 (실제 시간 — 멈춘 화면에서도)
func _process(_delta: float) -> void:
	if not visible:
		return
	var look := _guard.current_modulate()
	_card_box.modulate = look
	_reroll_button.get_parent().modulate = look
