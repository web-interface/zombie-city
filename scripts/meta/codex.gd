## [파일] scripts/meta/codex.gd
## [하는 일] 도감: 좀비·무기·진화·히든 스킬 칸을 data/meta_rules.json 'codex' 설정대로 표에서 골라 만들고, 판에서 만난 것을 채우고(저장 'codex' 묶음), 칸별·전체 % 를 센다.
## [쓰는 곳] scripts/meta/run_settlement.gd (판 끝에 채우기), scripts/ui/codex_screen.gd (화면), run_metrics.gd (업적 조건 codex_percent·evolutions_found·hidden_skills_found).
## [근거 문서] 04 §8 도감, 14 §3 도감·§4 모으기(빈칸이 보이게)
class_name Codex
extends RefCounted


## 항목이 하나라도 있는 칸만 (아직 없는 진화 칸 등은 숨김)
static func categories() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for category: Dictionary in GameData.table("meta_rules")["codex"]:
		if not entry_ids(category).is_empty():
			result.append(category)
	return result


## 칸 하나에 들어가는 항목 이름 (표 순서 그대로)
static func entry_ids(category: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var table_name := String(category["table"])
	if not GameData.has_table(table_name):
		return ids
	if category.has("nested_key"):   # 진화처럼 다른 항목 안에 든 것 (weapons.json 무기마다 evolution 칸)
		for owner_id: String in GameData.entry_ids(table_name):
			var nested: Variant = GameData.table(table_name)[owner_id].get(String(category["nested_key"]), {})
			if typeof(nested) == TYPE_DICTIONARY and nested.has("id"):
				ids.append(String(nested["id"]))
		return ids
	for entry_id: String in GameData.entry_ids(table_name):
		if _belongs(category, entry_id, GameData.table(table_name)[entry_id]):
			ids.append(entry_id)
	return ids


## 칸의 항목 이름·아이콘 {name, icon} — 표의 항목이든 무기 안의 진화든 같은 모양으로
static func entry_info(category: Dictionary, entry_id: String) -> Dictionary:
	var table: Dictionary = GameData.table(String(category["table"]))
	if category.has("nested_key"):
		for owner_id: String in GameData.entry_ids(String(category["table"])):
			var nested: Variant = table[owner_id].get(String(category["nested_key"]), {})
			if typeof(nested) == TYPE_DICTIONARY and String(nested.get("id", "")) == entry_id:
				return {"name": String(nested.get("name", entry_id)), "icon": String(nested.get("icon", "icon_%s_evolved" % owner_id))}
		return {"name": entry_id, "icon": "icon_" + entry_id}
	var entry: Dictionary = table.get(entry_id, {})
	return {"name": String(entry.get("name", entry_id)), "icon": String(entry.get("icon", "icon_" + entry_id))}


static func is_found(category_id: String, entry_id: String) -> bool:
	return _found_set(category_id).has(entry_id)


## 표에 있는 것 중 찾은 수 (표에서 빠진 옛 항목은 세지 않음)
static func found_count(category_id: String) -> int:
	var category := _category(category_id)
	if category.is_empty():
		return 0
	var count := 0
	for entry_id: String in entry_ids(category):
		if is_found(category_id, entry_id):
			count += 1
	return count


static func total_count(category_id: String) -> int:
	var category := _category(category_id)
	return 0 if category.is_empty() else entry_ids(category).size()


## 전체 % (모든 칸의 찾은 수 ÷ 전체 수)
static func total_percent() -> int:
	var found := 0
	var total := 0
	for category: Dictionary in categories():
		found += found_count(String(category["id"]))
		total += total_count(String(category["id"]))
	return 0 if total == 0 else floori(100.0 * found / total)


## 판 끝: 만난 좀비·쓴 무기·진화·히든 스킬을 채운다. 새로 채운 항목 이름(화면용)을 돌려준다.
static func note_run(result: Dictionary) -> Array[String]:
	var seen_by_table := {
		"zombies": _as_strings(result.get("zombie_kinds_met", [])),
		"weapons": _weapon_ids_from(result),
		"skills": [String(result.get("hidden_skill", ""))],
	}
	var new_names: Array[String] = []
	for category: Dictionary in categories():
		var seen: Array = seen_by_table.get(String(category["table"]), [])
		for entry_id: String in entry_ids(category):
			if seen.has(entry_id) and _add_found(String(category["id"]), entry_id):
				new_names.append(String(entry_info(category, entry_id)["name"]))
	return new_names


static func _belongs(category: Dictionary, entry_id: String, entry: Variant) -> bool:
	if typeof(entry) != TYPE_DICTIONARY:
		return false
	var info: Dictionary = entry
	if category.has("filter_key") and not bool(info.get(String(category["filter_key"]), false)):
		return false
	if category.has("exclude_key") and bool(info.get(String(category["exclude_key"]), false)):
		return false
	if category.has("id_prefix") and not entry_id.begins_with(String(category["id_prefix"])):
		return false
	return true


static func _category(category_id: String) -> Dictionary:
	for category: Dictionary in GameData.table("meta_rules")["codex"]:
		if String(category["id"]) == category_id:
			return category
	return {}


static func _found_set(category_id: String) -> Dictionary:
	var codex := SaveData.section("codex")
	if typeof(codex.get(category_id)) != TYPE_DICTIONARY:
		codex[category_id] = {}
	return codex[category_id]


static func _add_found(category_id: String, entry_id: String) -> bool:
	var found := _found_set(category_id)
	if found.has(entry_id):
		return false
	found[entry_id] = true
	return true


## 무기는 끝에 들고 있던 것 + 진화 + 판 중 고른 무기 카드 + 시작 무기 (중간에 바꾼 것도 '만남')
static func _weapon_ids_from(result: Dictionary) -> Array[String]:
	var ids := _as_strings(result.get("weapons_final", []))
	ids.append_array(_as_strings(result.get("evolutions", [])))
	for card: String in _as_strings(result.get("chosen_cards", [])):
		ids.append(card.get_slice(":", 1))
	var survivor_id := String(result.get("survivor", ""))
	if GameData.table("survivors").has(survivor_id):
		ids.append(String(GameData.table("survivors")[survivor_id].get("start_weapon", "")))
	return ids


static func _as_strings(value: Variant) -> Array[String]:
	var strings: Array[String] = []
	if typeof(value) == TYPE_ARRAY:
		for item: Variant in value:
			strings.append(String(item))
	return strings
