## [파일] scripts/ui/shelter_screen.gd
## [하는 일] 은신처 화면(옛 소방서): 강화 10종을 줄마다 이름·단계 칸(■□)·지금 값 → 다음 값·한 줄 이야기·[고철 가격] 버튼으로 보여 준다. 누르면 고철을 내고 한 단계 올리고(소리·번쩍), 고철이 모자라면 줄이 흔들리고 위 고철 숫자가 빨개진다.
## [쓰는 곳] scenes/shelter.tscn. 타이틀·결과 화면에서 SceneRouter.go_to_shelter() 로 온다. scripts/meta/shelter.gd 로 계산·저장한다.
## [근거 문서] 14 §3 은신처 강화 10종, 05 화면 목록(은신처), 03 §11
extends MenuScreen

const BUY_BUTTON_SIZE := Vector2(46, 30)
const TEXT_WIDTH := 112.0
const SHAKE_DISTANCE := 3.0

var _rows: Dictionary = {}   # 강화 id → 줄 패널 (산 뒤 번쩍·모자랄 때 흔들기)


func _ready() -> void:
	build_frame("은신처", Color("13110e"))
	MenuScreen.play_music_if_present("music_shelter")
	_refresh("")


## 목록을 다시 그린다. just_bought 줄은 금빛으로 번쩍 (방금 산 것이 눈에 보이게)
func _refresh(just_bought: String) -> void:
	clear_body()
	_rows.clear()
	set_header_value("고철 %s" % RunMetrics.format_count(SaveData.scrap()))
	body.add_child(PixelUi.small_lines("옛 소방서. 고철로 고쳐 두면 다음 출동이 든든해요", PixelUi.MUTED, BODY_WIDTH))
	for upgrade_id: String in Shelter.upgrade_ids():
		var row := _build_row(upgrade_id)
		_rows[upgrade_id] = row
		body.add_child(row)
	if _rows.has(just_bought):
		var row: PanelContainer = _rows[just_bought]
		row.modulate = PixelUi.GOLD * 1.6
		row.create_tween().tween_property(row, "modulate", Color.WHITE, 0.45)


func _build_row(upgrade_id: String) -> PanelContainer:
	var upgrade := Shelter.info(upgrade_id)
	var row := row_panel(PixelUi.GOLD.darkened(0.55) if Shelter.level(upgrade_id) > 0 else PixelUi.PANEL_EDGE)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	line.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(line)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(texts)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 4)
	name_row.add_child(PixelUi.label(String(upgrade["name"]), PixelUi.INK))
	name_row.add_child(PixelUi.label(_level_marks(upgrade_id), PixelUi.GOLD, true))
	texts.add_child(name_row)
	texts.add_child(PixelUi.small_lines(_effect_text(upgrade_id), PixelUi.GOOD, TEXT_WIDTH))
	texts.add_child(PixelUi.small_lines(String(upgrade["flavor"]), PixelUi.MUTED, TEXT_WIDTH))
	line.add_child(_build_buy_button(upgrade_id))
	return row


## ■■□□□ — 몇 단계 중 몇 단계인지 한눈에
func _level_marks(upgrade_id: String) -> String:
	var level := Shelter.level(upgrade_id)
	return "■".repeat(level) + "□".repeat(Shelter.max_level(upgrade_id) - level)


## "최대 체력 +14 → +22" (최고 단계면 "… (최고)")
func _effect_text(upgrade_id: String) -> String:
	var effect_name := String(Shelter.info(upgrade_id)["effect_name"])
	var level := Shelter.level(upgrade_id)
	if Shelter.is_maxed(upgrade_id):
		return "%s %s (최고)" % [effect_name, Shelter.value_text(upgrade_id, level)]
	return "%s %s → %s" % [effect_name, Shelter.value_text(upgrade_id, level), Shelter.value_text(upgrade_id, level + 1)]


func _build_buy_button(upgrade_id: String) -> Button:
	if Shelter.is_maxed(upgrade_id):
		var done := PixelUi.button("최고", PixelUi.GOLD)
		done.disabled = true
		done.custom_minimum_size = BUY_BUTTON_SIZE
		done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return done
	var cost := Shelter.next_cost(upgrade_id)
	var can_afford := SaveData.scrap() >= cost
	var buy := PixelUi.button(RunMetrics.format_count(cost), PixelUi.GOOD if can_afford else PixelUi.MUTED)
	buy.custom_minimum_size = BUY_BUTTON_SIZE
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	PixelUi.on_press(buy, _try_buy.bind(upgrade_id), "card_select" if can_afford else "ui_back")
	return buy


func _try_buy(upgrade_id: String) -> void:
	if Shelter.buy(upgrade_id):
		SoundPlayer.play("level_up")
		_refresh(upgrade_id)
		return
	_shake_row(upgrade_id)


## 고철이 모자라면 줄을 좌우로 흔들고 위 고철 숫자를 잠깐 빨갛게 (왜 안 되는지 바로 보이게)
func _shake_row(upgrade_id: String) -> void:
	if not _rows.has(upgrade_id):
		return
	var row: PanelContainer = _rows[upgrade_id]
	var shake := row.create_tween()
	for step: int in range(4):
		var direction := 1.0 if step % 2 == 0 else -1.0
		shake.tween_property(row, "position:x", direction * SHAKE_DISTANCE, 0.03).as_relative()
		shake.tween_property(row, "position:x", -direction * SHAKE_DISTANCE, 0.03).as_relative()
	flash_header_value(PixelUi.ALERT)
