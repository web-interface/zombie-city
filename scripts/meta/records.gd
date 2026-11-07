## [파일] scripts/meta/records.gd
## [하는 일] 생존자별 기록: 최고 밤(버틴 밤 수)·최다 처치·최장 연속 처치. 판 끝에 넘은 기록을 고치고 '새 기록' 글을 돌려준다.
## [쓰는 곳] scripts/meta/run_settlement.gd (판 끝), scripts/ui/survivor_select.gd (생존자 기록 줄), near_miss.gd ("최고 기록까지 1밤!"). 저장은 SaveData 'records' 묶음 {생존자 id: {best_night, best_kills, best_combo}}.
## [근거 문서] 14 §3 기록·§4 모으기
class_name Records
extends RefCounted

## 기록 칸 → 판 숫자 이름과 새 기록 글
const RECORD_FIELDS := {
	"best_night": {"metric": "nights_survived", "text": "최고 밤 %s"},
	"best_kills": {"metric": "kills", "text": "최다 처치 %s"},
	"best_combo": {"metric": "max_combo", "text": "최장 연속 %s"},
}


## {best_night, best_kills, best_combo} — 한 번도 안 했으면 모두 0 (읽기만 해서는 저장에 칸을 만들지 않음)
static func of(survivor_id: String) -> Dictionary:
	var stored: Variant = SaveData.section("records").get(survivor_id)
	if typeof(stored) == TYPE_DICTIONARY:
		return stored
	return {"best_night": 0, "best_kills": 0, "best_combo": 0}


static func has_played(survivor_id: String) -> bool:
	return SaveData.section("records").has(survivor_id)


## 판 끝: 넘은 기록을 고치고 새 기록 글 목록("최고 밤 3")을 돌려준다. 0 → 0 은 새 기록이 아님.
static func note_run(survivor_id: String, metrics: Dictionary) -> Array[String]:
	var record := of(survivor_id)
	SaveData.section("records")[survivor_id] = record
	var new_texts: Array[String] = []
	for field: String in RECORD_FIELDS.keys():
		var rule: Dictionary = RECORD_FIELDS[field]
		var value := int(metrics[String(rule["metric"])])
		if value > int(record.get(field, 0)):
			record[field] = value
			new_texts.append(String(rule["text"]) % RunMetrics.format_count(value))
	return new_texts
