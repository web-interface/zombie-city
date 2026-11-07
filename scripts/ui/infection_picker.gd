## [파일] scripts/ui/infection_picker.gd
## [하는 일] 감염도 고르기 줄: [◀] 감염도 N [▶] 고철 +N% 와, 그 단계에서 새로 더해지는 규칙 한 줄. 열린 단계까지만 고를 수 있고, 가장 높은 단계에서는 다음 단계를 여는 방법을 보여 준다. 고른 값은 SceneRouter.selected_infection_level 에 둔다.
## [쓰는 곳] scripts/ui/survivor_select.gd 가 만든다. scripts/meta/infection.gd 를 읽는다.
## [근거 문서] 03 §10 감염도, 14 §3, 05 화면 목록(출동 준비 — 감염도 고르기)
class_name InfectionPicker
extends VBoxContainer

const ARROW_SIZE := Vector2(18, 16)

var _level_label: Label
var _bonus_label: Label
var _rule_box: VBoxContainer
var _width: float = 168.0


func setup(width: float) -> void:
	_width = width
	add_theme_constant_override("separation", 1)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	add_child(row)
	row.add_child(_arrow_button("◀", -1))
	_level_label = PixelUi.label("", PixelUi.ALERT)
	_level_label.custom_minimum_size = Vector2(52, 0)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_level_label)
	row.add_child(_arrow_button("▶", 1))
	_bonus_label = PixelUi.label("", PixelUi.GOLD, true)
	_bonus_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_bonus_label)
	_rule_box = VBoxContainer.new()
	add_child(_rule_box)
	SceneRouter.selected_infection_level = clampi(SceneRouter.selected_infection_level, 0, Infection.unlocked_level())
	_refresh()


func _arrow_button(text: String, step: int) -> Button:
	var arrow := PixelUi.button(text, PixelUi.MUTED)
	arrow.custom_minimum_size = ARROW_SIZE
	PixelUi.on_press(arrow, _change.bind(step))
	return arrow


func _change(step: int) -> void:
	var wanted := SceneRouter.selected_infection_level + step
	if wanted < 0 or wanted > Infection.unlocked_level():
		_level_label.modulate = Color(1.6, 1.6, 1.6)   # 더 못 가면 숫자만 번쩍 (잠긴 단계라는 건 아래 글이 알려 줌)
		_level_label.create_tween().tween_property(_level_label, "modulate", Color.WHITE, 0.25)
		return
	SceneRouter.selected_infection_level = wanted
	_refresh()


func _refresh() -> void:
	var level := SceneRouter.selected_infection_level
	_level_label.text = "감염도 %d" % level
	_level_label.add_theme_color_override("font_color", PixelUi.MUTED if level == 0 else PixelUi.ALERT)
	_bonus_label.text = "" if level == 0 else "고철 +%d%%" % roundi(Infection.scrap_bonus_ratio(level) * 100.0)
	for child: Node in _rule_box.get_children():
		child.queue_free()
	_rule_box.add_child(PixelUi.small_lines(_rule_line(level), PixelUi.MUTED, _width, 1))


## 새로 더해지는 규칙, 또는 다음 단계를 여는 방법 (가장 높은 단계를 고르고 있을 때)
func _rule_line(level: int) -> String:
	var unlock_hint := "%s 넘기면 감염도 %d 열림" % [RunMetrics.night_name(Infection.unlock_nights()), level + 1]
	if level == 0:
		return unlock_hint if Infection.unlocked_level() == 0 else "기본 난이도"
	return "+ " + Infection.rule_text(level)
