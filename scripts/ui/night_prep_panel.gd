## [파일] scripts/ui/night_prep_panel.gd
## [하는 일] 밤 생존 창 [다음 밤] 뒤에 뜨는 '다음 밤 준비' 창, 두 단계: ① 들고 갈 무기 1개(레벨 표시 — 진화한 무기는 '진화 풀림') ② 훈장 3장 중 1장(위험 훈장·생존자 전용 표시, 몇 장째인지). 다 고르면 chosen 을 보내고 닫힌다. 뜬 직후 잘못 눌림은 TapGuard 로 막는다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 open() 으로 연다 (목록은 scripts/run/night_carry.gd). 자동 플레이 봇은 step()·options()·is_ready()·choose() 를 쓴다.
## [근거 문서] 15 §2 한 판 구조(밤 생존: ① 들고 갈 무기 1개 ② 훈장 1장)·§5-2·부록 A
class_name NightPrepPanel
extends Control

## 다 골랐다 {"weapon_id", "weapon_level", "medal_id"}
signal chosen(choice: Dictionary)

const CARD_SIZE := Vector2(164, 30)
const RISKY_COLOR := Color("ff9a5a")   # 위험 훈장 (나쁜 점이 있음 — 경고 빨강과 구분되는 주황)

var _guard := TapGuard.new()
var _title: Label
var _hint: Label
var _card_box: VBoxContainer
var _cards: Array[Button] = []
var _weapon_options: Array[Dictionary] = []
var _medal_options: Array[Dictionary] = []
var _choice: Dictionary = {}
var _step: String = ""


func _ready() -> void:
	PixelUi.full_rect(self)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.88)
	add_child(PixelUi.full_rect(dim))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	TapGuard.place_above_thumb_zone(self, column)   # 조이스틱 엄지 자리(아래)는 비워 둔다
	_title = PixelUi.label("", PixelUi.GOLD, false, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_hint = PixelUi.label("", PixelUi.MUTED, true)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_hint)
	_card_box = VBoxContainer.new()
	_card_box.add_theme_constant_override("separation", 4)
	column.add_child(_card_box)


func open(weapon_options: Array[Dictionary], medal_options: Array[Dictionary]) -> void:
	_weapon_options = weapon_options
	_medal_options = medal_options
	_choice = {}
	visible = true
	if _weapon_options.is_empty():
		_show_medals()
	else:
		_show_weapons()


func is_open() -> bool:
	return visible


## 자동 플레이 봇용: 지금 고르는 것 "weapon" / "medal"
func step() -> String:
	return _step


func options() -> Array[Dictionary]:
	return _weapon_options if _step == "weapon" else _medal_options


func is_ready() -> bool:
	return visible and _guard.is_ready()


## 자동 플레이 봇: 무기는 가장 높은 레벨, 훈장은 무작위
func bot_pick_index() -> int:
	if _step != "weapon":
		return randi() % maxi(_medal_options.size(), 1)
	var levels: Array = _weapon_options.map(func(option: Dictionary) -> int: return int(option["level"]))
	return levels.find(levels.max())


func choose(index: int) -> void:
	if visible and index >= 0 and index < options().size():
		_pick(options()[index])


func _show_weapons() -> void:
	_step = "weapon"
	_title.text = "다음 밤 준비 ① 무기"
	_hint.text = "들고 갈 무기 1개 · 레벨 그대로"
	_clear_cards()
	for option: Dictionary in _weapon_options:
		var level_text := "%d단계" % int(option["level"]) + (" · 진화 풀림" if bool(option["is_evolved"]) else "")
		_add_card(option, String(option["name"]), level_text, PixelUi.GOOD)


func _show_medals() -> void:
	_step = "medal"
	_title.text = "다음 밤 준비 ② 훈장"
	_hint.text = "1장 고르기 · 판 끝까지 남아요"
	_clear_cards()
	for option: Dictionary in _medal_options:
		var is_risky := String(option["kind"]) == "risky"
		var tag := "위험 · " if is_risky else ("전용 · " if bool(option["is_survivor_only"]) else "")
		var stacks := int(option["stacks"])
		var name_text := String(option["name"]) + (" (%d장째)" % (stacks + 1) if stacks > 0 else "")
		_add_card(option, name_text, tag + String(option["description"]), RISKY_COLOR if is_risky else PixelUi.GOLD)


func _add_card(option: Dictionary, name_text: String, detail_text: String, accent: Color) -> void:
	var card := PixelUi.button("", accent)
	card.custom_minimum_size = CARD_SIZE
	var row := HBoxContainer.new()
	row.position = Vector2(4, 4)
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(PixelUi.icon(String(option["icon"])))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(PixelUi.label(name_text, accent, false, true))
	texts.add_child(PixelUi.small_lines(detail_text, PixelUi.INK, CARD_SIZE.x - 32.0, 1))
	row.add_child(texts)
	card.add_child(row)
	_guard.watch(card)
	card.pressed.connect(func() -> void:
		if _guard.accepts_pick(card):
			_pick(option))
	_card_box.add_child(card)
	_cards.append(card)


func _pick(option: Dictionary) -> void:
	SoundPlayer.play("card_select")
	if _step == "weapon":
		_choice["weapon_id"] = String(option["id"])
		_choice["weapon_level"] = int(option["level"])
		if not _medal_options.is_empty():
			_show_medals()
			_hint.text = "들고 감: %s %d단계" % [option["name"], int(option["level"])]
			return
	else:
		_choice["medal_id"] = String(option["id"])
	visible = false
	_step = ""
	chosen.emit(_choice)


func _clear_cards() -> void:
	for card: Button in _cards:
		card.queue_free()
	_cards.clear()
	_guard.open()


## 막는 동안 카드를 흐리게 → 또렷하게 (지금은 못 누른다는 걸 보이게)
func _process(_delta: float) -> void:
	if visible:
		_card_box.modulate = _guard.current_modulate()
