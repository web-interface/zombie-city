## [파일] scripts/autoload/game_data.gd
## [하는 일] data/*.json 숫자 표를 게임을 켤 때 한 번 읽어 두고, 다른 스크립트가 표 이름·항목 이름으로 꺼내 쓰게 한다. '_' 로 시작하는 설명 칸은 건너뛴다.
## [쓰는 곳] 자동 로드 'GameData'. 생존자·무기·좀비·시스템·화면 스크립트가 모두 쓴다.
## [근거 문서] 11 §7 데이터 표, 10 §4 숫자는 데이터 표에
extends Node

const DATA_FOLDER := "res://data/"
const TABLE_NAMES: Array[String] = [
	"survivors", "skills", "promotions", "weapons", "gear", "zombies", "spawn_curve", "run_rules",
	"flavor_texts", "city_decor", "survivor_lines", "night_themes", "medals",
]

## 판 밖 성장 표 (저장·은신처·감염도·업적·판 목표 — 문서 14 §3). 판 안 표와 따로 적어 두면 함께 고칠 때 덜 부딪힌다.
const META_TABLE_NAMES: Array[String] = ["meta_rules", "shelter", "infection", "achievements", "run_goals"]

var _tables: Dictionary = {}


func _ready() -> void:
	for table_name: String in TABLE_NAMES + META_TABLE_NAMES:
		_tables[table_name] = _load_table(table_name)


## 이 이름의 표를 읽어 두었나 (도감처럼 아직 없을 수도 있는 표를 오류 없이 확인할 때)
func has_table(table_name: String) -> bool:
	return _tables.has(table_name)


## 표 전체 (설명 칸 포함). 규칙 표처럼 항목이 아닌 묶음을 꺼낼 때 쓴다.
func table(table_name: String) -> Dictionary:
	if not _tables.has(table_name):
		push_error("GameData: '%s' 라는 표가 없음 (TABLE_NAMES 에 추가했나?)" % table_name)
		return {}
	return _tables[table_name]


## 표 안의 항목 하나. 없으면 어느 표의 어느 이름인지 오류로 알린다.
func entry(table_name: String, entry_id: String) -> Dictionary:
	var found: Dictionary = table(table_name).get(entry_id, {})
	if found.is_empty():
		push_error("data/%s.json: '%s' 항목이 없음" % [table_name, entry_id])
	return found


## 표의 항목 이름 목록 ('_' 로 시작하는 설명 칸 제외, 파일에 적힌 순서).
func entry_ids(table_name: String) -> Array[String]:
	var result: Array[String] = []
	for key: String in table(table_name).keys():
		if not key.begins_with("_"):
			result.append(key)
	return result


## 한 판 규칙 표(run_rules.json)의 묶음 하나. 예: rules("extraction")
func rules(section_name: String) -> Dictionary:
	var section: Dictionary = table("run_rules").get(section_name, {})
	if section.is_empty():
		push_error("data/run_rules.json: '%s' 묶음이 없음" % section_name)
	return section


func _load_table(table_name: String) -> Dictionary:
	var path := DATA_FOLDER + table_name + ".json"
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("GameData: %s 를 읽지 못함" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameData: %s 가 올바른 JSON 객체가 아님" % path)
		return {}
	return parsed
