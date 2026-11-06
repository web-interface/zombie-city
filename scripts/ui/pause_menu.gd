## [파일] scripts/ui/pause_menu.gd
## [하는 일] 일시정지: 오른쪽 위 작은 버튼(II)과, 누르면(또는 앱을 나갔다 오면) 뜨는 창 — 지금 생존자·전직·무기/장비 목록, 계속하기(3초 세고 다시 시작), 포기하기.
## [쓰는 곳] scripts/ui/hud.gd 가 만든다. run.gd 가 앱을 나갈 때 Hud.show_pause_menu() 로 연다.
## [근거 문서] 05 화면 목록(일시정지), 13 (앱 전환·전화에도 판이 안 날아가게, 돌아오면 3초 카운트)
class_name PauseMenu
extends Control

signal give_up_requested

const RESUME_COUNTDOWN_SECONDS := 3.0

var _info_label: Label
var _countdown_left: float = 0.0
var _countdown_label: Label
var _window: PanelContainer
var _promotion: Promotion
var _rack: WeaponRack


func setup(promotion: Promotion, rack: WeaponRack) -> void:
	_promotion = promotion
	_rack = rack
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	var pause_button := PixelUi.button("II", PixelUi.MUTED)
	pause_button.pressed.connect(open)
	add_child(pause_button)
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -22.0
	pause_button.offset_top = 34.0
	pause_button.offset_right = -4.0
	pause_button.offset_bottom = 50.0
	_window = _build_window()
	add_child(PixelUi.centered(_window))
	_countdown_label = PixelUi.label("", PixelUi.GOLD, false, true)
	_countdown_label.visible = false
	add_child(PixelUi.centered(_countdown_label))


func open() -> void:
	if _window.visible:
		return
	get_tree().paused = true
	_info_label.text = _build_info_text()
	_window.visible = true
	_countdown_left = 0.0
	_countdown_label.visible = false


func _build_window() -> PanelContainer:
	var window := PixelUi.panel()
	window.custom_minimum_size = Vector2(148, 0)
	window.visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	window.add_child(column)
	var title := PixelUi.label("잠깐 멈춤", PixelUi.INK, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_info_label = PixelUi.label("", PixelUi.MUTED, true)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(140, 0)
	column.add_child(_info_label)
	var resume_button := PixelUi.button("계속하기", PixelUi.GOOD)
	resume_button.pressed.connect(_start_countdown)
	column.add_child(resume_button)
	var give_up_button := PixelUi.button("포기하기", PixelUi.ALERT)
	give_up_button.pressed.connect(func() -> void:
		_window.visible = false
		give_up_requested.emit())
	column.add_child(give_up_button)
	return window


func _build_info_text() -> String:
	var lines: Array[String] = []
	var branch := _promotion.branch_name()
	lines.append("전직: %s" % (branch if not branch.is_empty() else "아직 (레벨 10)"))
	for weapon: Weapon in _rack.weapons:
		lines.append("· %s %d단계" % [weapon.info["name"], weapon.level])
	for gear_id: String in _rack.gear_levels.keys():
		lines.append("· %s %d단계" % [GameData.entry("gear", gear_id)["name"], _rack.gear_levels[gear_id]])
	return "\n".join(lines)


func _start_countdown() -> void:
	_window.visible = false
	_countdown_left = RESUME_COUNTDOWN_SECONDS
	_countdown_label.visible = true


func _process(delta: float) -> void:
	if _countdown_left <= 0.0:
		return
	_countdown_left -= delta
	_countdown_label.text = str(ceili(_countdown_left))
	if _countdown_left <= 0.0:
		_countdown_label.visible = false
		get_tree().paused = false
