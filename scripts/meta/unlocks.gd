## [파일] scripts/meta/unlocks.gd
## [하는 일] 생존자 해금: data/meta_rules.json 'unlocks' 에 적힌 생존자(야구선수·사냥꾼)는 조건을 채워야 열린다. 판 끝에 조건을 확인해 새로 연 생존자를 저장하고, 고르기 화면에 보일 잠김 칸 목록·조건 글·남은 양을 준다. 'unlocks' 에 없는 생존자는 처음부터 열려 있다.
## [쓰는 곳] scripts/ui/survivor_select.gd (잠김 실루엣·조건 글), scripts/meta/run_settlement.gd (판 끝 해금), near_miss.gd ("야구선수 해금까지 처치 320"). 저장은 SaveData 'unlocked_survivors' 묶음.
## [근거 문서] 14 §3 새 생존자, 03 §11 생존자 해금
class_name Unlocks
extends RefCounted


static func is_unlocked(survivor_id: String) -> bool:
	if not _rules().has(survivor_id):
		return true
	return bool(SaveData.section("unlocked_survivors").get(survivor_id, false))


## 고르기 화면에 나올 생존자: 표에 있는 생존자 + 아직 표에 없지만 해금 조건이 정해진 생존자 (잠김 칸만 보임)
static func listed_survivor_ids() -> Array[String]:
	var ids: Array[String] = GameData.entry_ids("survivors")
	for survivor_id: String in _rules().keys():
		if not ids.has(survivor_id):
			ids.append(survivor_id)
	return ids


## 게임에 실제로 들어 있는 생존자인가 (아직 안 들어온 생존자는 잠김 칸만)
static func is_playable(survivor_id: String) -> bool:
	return GameData.table("survivors").has(survivor_id) and is_unlocked(survivor_id)


static func display_name(survivor_id: String) -> String:
	if _rules().has(survivor_id):
		return String((_rules()[survivor_id] as Dictionary)["name"])
	return String(GameData.entry("survivors", survivor_id).get("role", survivor_id))


static func condition_text(survivor_id: String) -> String:
	return String((_rules().get(survivor_id, {}) as Dictionary).get("condition_text", ""))


## 진행 글 앞말: "버틴 밤" · "처치" (고르기 화면 "지금 처치 4,680 / 5,000")
static func progress_word(survivor_id: String) -> String:
	return String((_rules().get(survivor_id, {}) as Dictionary).get("progress_word", ""))


static func condition(survivor_id: String) -> Dictionary:
	return (_rules().get(survivor_id, {}) as Dictionary).get("condition", {})


## 아직 잠긴 생존자들 (해금 조건이 있는 것만)
static func locked_ids() -> Array[String]:
	var ids: Array[String] = []
	for survivor_id: String in _rules().keys():
		if not is_unlocked(survivor_id):
			ids.append(survivor_id)
	return ids


## 판 끝: 한 판 숫자 + 누적 숫자(metrics)로 조건을 확인해 새로 연 생존자 id 목록을 돌려준다.
static func note_run(metrics: Dictionary) -> Array[String]:
	var newly_unlocked: Array[String] = []
	for survivor_id: String in locked_ids():
		if RunMetrics.is_condition_met(condition(survivor_id), metrics):
			SaveData.section("unlocked_survivors")[survivor_id] = true
			newly_unlocked.append(survivor_id)
	return newly_unlocked


static func _rules() -> Dictionary:
	return GameData.table("meta_rules")["unlocks"]
