## [파일] scripts/ui/tap_guard.gd
## [하는 일] 고르는 창(레벨 업·보물 상자·밤 생존·전직·무기 들고 가기·훈장)이 뜬 직후 잘못 눌림 막기. 창이 열리고 GUARD_SECONDS 가 지난 '뒤에 새로 누른' 손가락만 받는다 — 움직이며 화면을 두드리던 손이 카드를 보지도 못하고 고르는 일을 없앤다. 막는 동안 0~1 진행값을 줘서 창이 카드를 흐리게 그렸다가 켤 수 있게 한다.
## [쓰는 곳] 고르는 창 스크립트가 하나씩 가진다: open() 은 창을 열 때, watch(버튼) 은 버튼을 만들 때, accepts(버튼) 은 눌렸을 때, is_ready() 는 자동 플레이 봇이 고를 때.
## [근거 문서] 사용자 피드백(2026-11-07 오후) '무빙 치다 템 선택 보지도 못하고 눌리는 게 너무 많음', 13 (탭 한 번으로 고르기)
class_name TapGuard
extends RefCounted

## 창이 뜬 뒤 이만큼은 눌러도 안 고름 (실제 시간 — 멈춘 화면·느린 화면에서도 똑같이)
const GUARD_SECONDS := 0.6

var _opened_msec: int = 0
var _pressed_down_msec: Dictionary = {}   # 버튼 instance id → 손가락이 닿은 때


## 창을 열 때마다 부른다
func open() -> void:
	_opened_msec = Time.get_ticks_msec()
	_pressed_down_msec.clear()


## 버튼을 만들 때 한 번: 손가락이 '닿은 때'를 적어 둔다 (떼는 때가 아니라)
func watch(button: BaseButton) -> void:
	var button_id := button.get_instance_id()
	button.button_down.connect(func() -> void: _pressed_down_msec[button_id] = Time.get_ticks_msec())


## 이 버튼이 눌린 걸 받아도 되나: 막는 시간이 끝난 뒤에 새로 닿은 손가락만
func accepts(button: BaseButton) -> bool:
	var pressed_at := int(_pressed_down_msec.get(button.get_instance_id(), -1))
	return pressed_at >= _opened_msec + roundi(GUARD_SECONDS * 1000.0)


## 막는 시간이 끝났나 (자동 플레이 봇처럼 손가락 없이 고를 때)
func is_ready() -> bool:
	return progress() >= 1.0


## 0 = 막 열림, 1 = 이제 고를 수 있음 (카드를 흐리게 → 또렷하게)
func progress() -> float:
	return clampf((Time.get_ticks_msec() - _opened_msec) / (GUARD_SECONDS * 1000.0), 0.0, 1.0)
