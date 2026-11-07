## [파일] scripts/ui/pause_menu.gd
## [하는 일] 일시정지: 오른쪽 위 작은 '멈춤' 버튼과, 누르면(또는 앱을 나갔다 오면) 뜨는 창 — 지금 생존자·전직·무기/장비 목록, 계속하기(3초 세고 다시 시작), 설정(소리·진동·흔들림 창), 포기하기.
## [쓰는 곳] scripts/ui/hud.gd 가 만든다. run.gd 가 앱을 나갈 때 Hud.show_pause_menu() 로 연다.
## [근거 문서] 05 화면 목록(일시정지), 13 (앱 전환·전화에도 판이 안 날아가게, 돌아오면 3초 카운트)
class_name PauseMenu
extends Control

signal give_up_requested

const RESUME_COUNTDOWN_SECONDS := 3.0
const INFO_WIDTH := 140.0   # 창 안 목록 글 너비

var _info_box: VBoxContainer
var _pause_button: Button
var _countdown_left: float = 0.0
var _countdown_label: Label
var _window: PanelContainer
var _promotion: Promotion
var _rack: WeaponRack
## 다른 창(카드·전직)이 열려 있나 — 열려 있으면 카운트다운이 끝나도 멈춤을 풀지 않는다 (Hud 가 넣어 줌)
var is_other_window_open: Callable = func() -> bool: return false


func setup(promotion: Promotion, rack: WeaponRack) -> void:
	_promotion = promotion
	_rack = rack
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_button = PixelUi.button("멈춤", PixelUi.MUTED)
	_pause_button.pressed.connect(open)
	add_child(_pause_button)
	_pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.offset_left = -34.0
	_pause_button.offset_top = 50.0   # 맨 위 무기·장비 칸 줄(34~46) 아래로 — 겹치지 않게
	_pause_button.offset_right = -4.0
	_pause_button.offset_bottom = 66.0
	_window = _build_window()
	add_child(PixelUi.centered(_window))
	_countdown_label = PixelUi.label("", PixelUi.GOLD, false, true)
	_countdown_label.visible = false
	add_child(PixelUi.centered(_countdown_label))


func open() -> void:
	if _window.visible:
		return
	get_tree().paused = true
	for child: Node in _info_box.get_children():
		child.queue_free()
	_info_box.add_child(PixelUi.small_lines(_build_info_text(), PixelUi.MUTED, INFO_WIDTH))
	_window.visible = true
	_countdown_left = 0.0
	_countdown_label.visible = false


## 판이 끝나 결과 화면으로 넘어가는 동안엔 멈춤 버튼을 숨긴다 (마지막 검수: 쓰러진 뒤 1.6초 동안 창이 떴음)
func hide_button() -> void:
	_pause_button.visible = false


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
	_info_box = VBoxContainer.new()
	_info_box.custom_minimum_size = Vector2(INFO_WIDTH, 0)
	column.add_child(_info_box)
	var resume_button := PixelUi.button("계속하기", PixelUi.GOOD)
	resume_button.pressed.connect(_start_countdown)
	column.add_child(resume_button)
	var settings_button := PixelUi.button("설정", PixelUi.INK)
	PixelUi.on_press(settings_button, _open_settings)
	column.add_child(settings_button)
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
		lines.append("· %s %s" % [weapon.display_name(), "진화" if weapon.is_evolved else "%d단계" % weapon.level])
	for gear_id: String in _rack.gear_levels.keys():
		lines.append("· %s %d단계" % [GameData.entry("gear", gear_id)["name"], _rack.gear_levels[gear_id]])
	return "\n".join(lines)


## 설정 창을 멈춤 창 자리에 띄우고, 닫으면 멈춤 창으로 돌아온다 (판은 계속 멈춰 있음)
func _open_settings() -> void:
	_window.visible = false
	var settings := SettingsPanel.new()
	settings.closed.connect(func() -> void: _window.visible = true)
	add_child(settings)


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
		if not is_other_window_open.call():
			get_tree().paused = false
