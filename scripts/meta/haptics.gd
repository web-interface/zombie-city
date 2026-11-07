## [파일] scripts/meta/haptics.gd
## [하는 일] 폰 진동 도우미: 맞을 때(짧게, 너무 자주는 안 떨게)·보스 등장(길게)·레벨 업(짧게). 설정에서 진동을 끄면 아무것도 안 하고, 시험 봇일 때도 안 한다. 웹판은 안드로이드 브라우저에서만 떨린다(아이폰 브라우저는 진동을 막음).
## [쓰는 곳] 판 쪽(run.gd 의 맞음·보스 등장·레벨 업 신호 — 총책임관이 붙임)이 Haptics.on_hit() 처럼 부른다. data/meta_rules.json 'vibration' 길이, SaveData 설정을 읽는다.
## [근거 문서] 06 손맛 목록 '(폰) 맞을 때 짧은 진동', 14 §3 설정
class_name Haptics
extends RefCounted

static var _last_hit_msec: int = -100000


static func on_hit() -> void:
	var rules := _rules()
	var now := Time.get_ticks_msec()
	# 좀비에 둘러싸이면 매 프레임 맞으므로 간격을 두고 떤다 (계속 떨면 손이 저리고 배터리도 닳음)
	if now - _last_hit_msec < int(float(rules["hit_gap_seconds"]) * 1000.0):
		return
	_last_hit_msec = now
	_vibrate(int(rules["hit_milliseconds"]))


static func on_boss() -> void:
	_vibrate(int(_rules()["boss_milliseconds"]))


static func on_level_up() -> void:
	_vibrate(int(_rules()["level_up_milliseconds"]))


static func _vibrate(milliseconds: int) -> void:
	if not SaveData.is_vibration_on() or SceneRouter.is_autoplay():
		return
	Input.vibrate_handheld(milliseconds)


static func _rules() -> Dictionary:
	return GameData.table("meta_rules")["vibration"]
