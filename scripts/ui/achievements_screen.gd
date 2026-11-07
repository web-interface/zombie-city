## [파일] scripts/ui/achievements_screen.gd
## [하는 일] 업적 화면: 업적 40개를 줄마다 묶음 표시·이름·조건 글·보상 고철로 보여 준다. 이룬 업적은 금빛 테두리와 이룬 날, 못 이룬 업적은 흐리게, 숨은 업적은 이루기 전까지 '???'. 위 줄에 이룬 수/전체.
## [쓰는 곳] scenes/achievements.tscn. 타이틀에서 SceneRouter.go_to_achievements() 로 온다. scripts/meta/achievements.gd 를 읽는다.
## [근거 문서] 14 §3 업적 40·§4 모으기(빈칸이 보이게), 05 화면 목록(도감·업적)
extends MenuScreen

const TEXT_WIDTH := 118.0


func _ready() -> void:
	build_frame("업적", Color("10121a"))
	set_header_value("%d/%d" % [Achievements.done_count(), Achievements.ids().size()])
	for achievement_id: String in Achievements.ids():
		body.add_child(_build_row(achievement_id))


func _build_row(achievement_id: String) -> PanelContainer:
	var achievement := Achievements.info(achievement_id)
	var is_done := Achievements.is_done(achievement_id)
	var is_hidden := bool(achievement.get("is_secret", false)) and not is_done
	var row := row_panel(PixelUi.GOLD.darkened(0.35) if is_done else PixelUi.PANEL_EDGE)
	if not is_done:
		row.modulate = Color(0.78, 0.78, 0.82)   # 못 이룬 것은 한 단계 흐리게 — 이룬 것이 눈에 띄게
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	line.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(line)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(texts)
	texts.add_child(PixelUi.small_lines(String(achievement["group"]), PixelUi.MUTED, TEXT_WIDTH))
	var title := "???" if is_hidden else String(achievement["name"])
	texts.add_child(PixelUi.label(title, PixelUi.GOLD if is_done else PixelUi.INK))
	var description := "숨은 업적" if is_hidden else String(achievement["text"])
	texts.add_child(PixelUi.small_lines(description, PixelUi.INK if is_done else PixelUi.MUTED, TEXT_WIDTH))
	line.add_child(_build_reward(achievement_id, int(achievement.get("scrap", 0)), is_done))
	return row


## 오른쪽: 고철 보상, 이뤘으면 이룬 날짜 (11-07)
func _build_reward(achievement_id: String, scrap: int, is_done: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reward := PixelUi.label("고철 %d" % scrap, PixelUi.GOOD if is_done else PixelUi.MUTED, true)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(reward)
	if is_done:
		var date_text := String(SaveData.section("achievements").get(achievement_id, ""))
		var done_label := PixelUi.label("이룸 " + date_text.substr(5), PixelUi.GOLD, true)
		done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		column.add_child(done_label)
	return column
