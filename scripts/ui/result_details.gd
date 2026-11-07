## [파일] scripts/ui/result_details.gd
## [하는 일] 결과 화면 아래 목록에 들어가는 부품 만들기: 새 기록·업적·해금·감염도·도감 '띠', 아까운 표시, 판 목표 3개(○·×), 얻은 고철 항목별 줄. 판 정산(RunSettlement) 묶음을 읽어 글을 정한다.
## [쓰는 곳] scripts/ui/result_screen.gd 가 부른다 (화면 배치·차례로 나타나는 연출은 그쪽).
## [근거 문서] 14 §4 아까운 표시·판 목표·쌓이는 성장, 05 화면 목록(결과)
class_name ResultDetails
extends RefCounted

const SINGLE_ACHIEVEMENT_BANNERS := 2

## 띠 종류별 색: 바탕, 테두리, 글자
const BANNER_STYLES := {
	"record": [Color("12301c"), Color("8ff59a"), Color("8ff59a")],
	"achievement": [Color("3a2a0c"), Color("ffd166"), Color("ffd166")],
	"unlock": [Color("4a3208"), Color("ffe08a"), Color("fff3c4")],
	"infection": [Color("3a1014"), Color("ff6b6b"), Color("ff9c9c")],
	"codex": [Color("10263a"), Color("7cc4ff"), Color("b8e0ff")],
}


## 띠로 보여 줄 것 [{"text", "style", "sound"}] — 해금이 가장 크니 맨 앞
static func banner_items(settlement: Dictionary) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for survivor_id: String in settlement.get("new_unlocks", []):
		items.append({"text": "새 생존자 %s 해금!" % Unlocks.display_name(survivor_id), "style": "unlock", "sound": "promotion"})
	if int(settlement.get("new_infection_level", 0)) > 0:
		items.append({"text": "감염도 %d 열림! 고철 더 받기" % int(settlement["new_infection_level"]), "style": "infection", "sound": "boss_warning"})
	if bool(settlement.get("is_daily_best", false)):
		items.append({"text": "오늘의 도전 최고 기록!", "style": "record", "sound": "level_up"})
	var new_records: Array = settlement.get("new_records", [])
	if not new_records.is_empty():
		items.append({"text": "새 기록! " + " · ".join(PackedStringArray(new_records)), "style": "record", "sound": "level_up"})
	items.append_array(_achievement_items(settlement.get("new_achievements", [])))
	var new_codex: Array = settlement.get("new_codex", [])
	if not new_codex.is_empty():
		items.append({"text": "도감 +%d: %s" % [new_codex.size(), ", ".join(PackedStringArray(new_codex))], "style": "codex", "sound": "card_select"})
	return items


## 업적은 처음 몇 개만 하나씩 띠로, 나머지는 한 띠에 묶는다 (첫 판에 업적이 열 개씩 열리면 띠가 화면을 다 덮음)
static func _achievement_items(achievement_ids: Array) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var rest_names: PackedStringArray = []
	var rest_scrap := 0
	for index: int in range(achievement_ids.size()):
		var achievement := Achievements.info(String(achievement_ids[index]))
		if index < SINGLE_ACHIEVEMENT_BANNERS:
			items.append({"text": "업적 '%s' 고철 +%d" % [achievement["name"], int(achievement.get("scrap", 0))], "style": "achievement", "sound": "card_select"})
		else:
			rest_names.append(String(achievement["name"]))
			rest_scrap += int(achievement.get("scrap", 0))
	if not rest_names.is_empty():
		items.append({"text": "업적 %d개 더 고철 +%d: %s" % [rest_names.size(), rest_scrap, ", ".join(rest_names)], "style": "achievement", "sound": "card_select"})
	return items


static func build_banner(item: Dictionary, width: float) -> PanelContainer:
	var colors: Array = BANNER_STYLES.get(String(item["style"]), BANNER_STYLES["record"])
	var banner := PixelUi.panel(colors[0], colors[1])
	banner.custom_minimum_size = Vector2(width, 0)
	banner.mouse_filter = Control.MOUSE_FILTER_PASS
	banner.add_child(PixelUi.small_lines(String(item["text"]), colors[2], width - 8.0, 2))
	return banner


## 아까운 표시: "최고 기록까지 1밤!" — 주황 테두리, 한 줄씩
static func build_near_miss(lines: Array, width: float) -> PanelContainer:
	var panel := PixelUi.panel(Color("2a1a10"), Color("ff9f43"))
	panel.custom_minimum_size = Vector2(width, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	panel.add_child(column)
	for text: String in lines:
		column.add_child(PixelUi.small_lines("▶ " + text, Color("ffc58a"), width - 8.0))
	return panel


## 판 목표 3개: ○ 이룬 것(초록, +고철) · × 못 이룬 것(회색)
static func build_goals(goals: Array, width: float) -> VBoxContainer:
	var column := _section("판 목표")
	for goal: Dictionary in goals:
		var is_done := bool(goal["is_done"])
		var row := HBoxContainer.new()
		var mark := "○ " if is_done else "× "
		var text := PixelUi.label(mark + String(goal["text"]), PixelUi.GOOD if is_done else PixelUi.MUTED, true)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.clip_text = true
		row.add_child(text)
		var scrap_text := "+%d" % int(goal.get("scrap", 0)) if is_done else "%d" % int(goal.get("scrap", 0))
		row.add_child(PixelUi.label(scrap_text, PixelUi.GOLD if is_done else PixelUi.MUTED, true))
		row.custom_minimum_size = Vector2(width, 0)
		column.add_child(row)
	return column


## 얻은 고철 항목별 줄 + 지금 가진 고철
static func build_scrap(reward_lines: Array, total: int, width: float) -> VBoxContainer:
	var column := _section("얻은 고철 %s" % RunMetrics.format_count(total))
	for line: Dictionary in reward_lines:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(width, 0)
		var name_label := PixelUi.label(String(line["label"]), PixelUi.MUTED, true)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(PixelUi.label("+%s" % RunMetrics.format_count(int(line["amount"])), PixelUi.GOLD, true))
		column.add_child(row)
	var owned := PixelUi.label("가진 고철 %s" % RunMetrics.format_count(SaveData.scrap()), PixelUi.INK, true)
	owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owned.custom_minimum_size = Vector2(width, 0)
	column.add_child(owned)
	return column


static func _section(title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(PixelUi.label(title, PixelUi.INK))
	return column
