## [파일] scripts/ui/settings_panel.gd
## [하는 일] 설정 창(화면 위에 겹쳐 뜸): 효과음·음악 크기(− 칸 막대 +), 진동 켜기/끄기, 화면 흔들림 켜기/끄기, 닫기. 바꾸면 바로 저장·반영된다. 게임이 멈춘 동안(멈춤 메뉴)에도 움직인다.
## [쓰는 곳] scripts/ui/title_screen.gd (타이틀 [설정]), scripts/ui/pause_menu.gd (멈춤 창 [설정]) 가 add_child 로 띄운다. SaveData.set_setting() 으로 저장, 소리 크기는 SoundPlayer 에 바로 반영된다.
## [근거 문서] 14 §3 설정, 05 화면 목록(설정)
class_name SettingsPanel
extends Control

## 닫기를 눌렀다 (멈춤 메뉴는 이때 자기 창을 다시 보여 줌)
signal closed

const WINDOW_WIDTH := 152.0
const BAR_SEGMENTS := 10
const SEGMENT_SIZE := Vector2(4, 7)

var _volume_bars: Dictionary = {}     # 설정 이름 → 칸 ColorRect 목록
var _toggle_buttons: Dictionary = {}  # 설정 이름 → 버튼


func _ready() -> void:
	PixelUi.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP   # 창 뒤의 버튼이 눌리지 않게
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(PixelUi.full_rect(dim))
	add_child(PixelUi.centered(_build_window()))
	_refresh()


func _build_window() -> PanelContainer:
	var window := PixelUi.panel()
	window.custom_minimum_size = Vector2(WINDOW_WIDTH, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	window.add_child(column)
	var title := PixelUi.label("설정", PixelUi.INK, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(_build_volume_row("효과음", "effects_volume"))
	column.add_child(_build_volume_row("음악", "music_volume"))
	column.add_child(_build_toggle_row("진동", "is_vibration_on"))
	column.add_child(_build_toggle_row("화면 흔들림", "is_screen_shake_on"))
	column.add_child(PixelUi.small_lines("진동은 안드로이드 폰에서만 떨려요", PixelUi.MUTED, WINDOW_WIDTH - 8.0))
	var close := PixelUi.button("닫기", PixelUi.GOOD)
	close.custom_minimum_size = Vector2(0, 22)
	PixelUi.on_press(close, _close, "ui_back")
	column.add_child(close)
	return window


func _build_volume_row(title: String, setting_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var name_label := PixelUi.label(title, PixelUi.MUTED)
	name_label.custom_minimum_size = Vector2(40, 0)
	row.add_child(name_label)
	row.add_child(_small_button("-", _change_volume.bind(setting_name, -1)))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 1)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var segments: Array[ColorRect] = []
	for index: int in range(BAR_SEGMENTS):
		var segment := ColorRect.new()
		segment.custom_minimum_size = SEGMENT_SIZE
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(segment)
		segments.append(segment)
	_volume_bars[setting_name] = segments
	row.add_child(bar)
	row.add_child(_small_button("+", _change_volume.bind(setting_name, 1)))
	return row


func _build_toggle_row(title: String, setting_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := PixelUi.label(title, PixelUi.MUTED)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var toggle := PixelUi.button("", PixelUi.GOOD)
	toggle.custom_minimum_size = Vector2(48, 20)
	PixelUi.on_press(toggle, _flip.bind(setting_name))
	_toggle_buttons[setting_name] = toggle
	row.add_child(toggle)
	return row


func _small_button(text: String, action: Callable) -> Button:
	var small := PixelUi.button(text, PixelUi.INK)
	small.custom_minimum_size = Vector2(18, 18)
	PixelUi.on_press(small, action)
	return small


func _change_volume(setting_name: String, step_direction: int) -> void:
	var step := float(GameData.table("meta_rules")["volume_step"])
	var value := clampf(snappedf(float(SaveData.setting(setting_name)) + step * step_direction, step), 0.0, 1.0)
	SaveData.set_setting(setting_name, value)
	_refresh()


func _flip(setting_name: String) -> void:
	SaveData.set_setting(setting_name, not bool(SaveData.setting(setting_name)))
	if setting_name == "is_vibration_on":
		Haptics.on_level_up()   # 켰을 때 한 번 떨어서 되는지 바로 알게
	_refresh()


## 막대 칸 색과 켜짐/꺼짐 글을 지금 설정대로
func _refresh() -> void:
	for setting_name: String in _volume_bars.keys():
		var filled := roundi(float(SaveData.setting(setting_name)) * BAR_SEGMENTS)
		var segments: Array[ColorRect] = _volume_bars[setting_name]
		for index: int in range(segments.size()):
			segments[index].color = PixelUi.GOOD if index < filled else PixelUi.PANEL_EDGE
	for setting_name: String in _toggle_buttons.keys():
		var is_on := bool(SaveData.setting(setting_name))
		var toggle: Button = _toggle_buttons[setting_name]
		toggle.text = "켜짐" if is_on else "꺼짐"
		toggle.add_theme_color_override("font_color", PixelUi.GOOD if is_on else PixelUi.MUTED)


func _close() -> void:
	closed.emit()
	queue_free()


## 안드로이드 뒤로 가기 = 닫기
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()
