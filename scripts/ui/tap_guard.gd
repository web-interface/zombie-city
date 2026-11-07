## [파일] scripts/ui/tap_guard.gd
## [하는 일] 고르는 창(레벨 업·보물 상자·밤 생존·전직·무기 들고 가기·훈장)의 잘못 눌림 막기. ① 창이 열리고 GUARD_SECONDS 가 지난 '뒤에 새로 누른' 손가락만 받는다 — 창이 뜨기 전부터 누르던 손가락(조이스틱)이 카드 위로 미끄러져 와 떼도, 0.6초 안에 두드려도 안 고름. ② 카드·버튼을 조이스틱 엄지가 놓이는 화면 아래 35% 밖(위쪽)에 놓는다. ③ 막는 동안 0~1 진행값(카드 흐림 → 또렷)과 켜지는 순간(딸깍). ④ 설정 '두 번 눌러 고르기'면 처음 누른 카드는 커지기만 하고 같은 카드를 한 번 더 눌러야 고른다.
## [쓰는 곳] 고르는 창 스크립트가 하나씩 가진다: open() 은 창을 열 때, watch(버튼) 은 버튼을 만들 때, accepts(버튼) 은 눌렸을 때, is_ready() 는 자동 플레이 봇이 고를 때, place_above_thumb_zone() 은 창을 만들 때. tools/tap_guard_test.gd 가 입력을 흉내 내 시험한다.
## [근거 문서] 15 §8 잘못 눌림, 사용자 피드백(2026-11-07) '무빙 치다 템 선택 보지도 못하고 눌리는 게 너무 많음'
class_name TapGuard
extends RefCounted

## 창이 뜬 뒤 이만큼은 눌러도 안 고름 (실제 시간 — 멈춘 화면·느린 화면에서도 똑같이)
const GUARD_SECONDS := 0.6
## 화면 아래 이 비율은 조이스틱 엄지 자리 — 고르는 버튼을 두지 않는다 (떠 있는 조이스틱을 주로 아래쪽에서 잡음)
const THUMB_ZONE_RATIO := 0.35
const TOP_MARGIN := 4.0
## 막는 동안 카드 모습: 흐리게(어둡고 반투명)
const GUARDED_MODULATE := Color(0.55, 0.55, 0.6, 0.55)
## 두 번 눌러 고르기: 처음 누른 카드는 이만큼 커짐
const ARMED_SCALE := 1.06

var _opened_msec: int = 0
var _pressed_down_msec: Dictionary = {}   # 버튼 instance id → 손가락이 닿은 때
var _armed_button_id: int = 0
var _was_ready: bool = false


## 창을 열 때마다 부른다
func open() -> void:
	_opened_msec = Time.get_ticks_msec()
	_pressed_down_msec.clear()
	_armed_button_id = 0
	_was_ready = false


## 버튼을 만들 때 한 번: 손가락이 '닿은 때'를 적어 둔다 (떼는 때가 아니라)
func watch(button: BaseButton) -> void:
	var button_id := button.get_instance_id()
	button.button_down.connect(func() -> void: _pressed_down_msec[button_id] = Time.get_ticks_msec())


## 이 버튼이 눌린 걸 받아도 되나: 막는 시간이 끝난 뒤에 새로 닿은 손가락만
func accepts(button: BaseButton) -> bool:
	var pressed_at := int(_pressed_down_msec.get(button.get_instance_id(), -1))
	return pressed_at >= _opened_msec + roundi(GUARD_SECONDS * 1000.0)


## 카드 고르기: accepts 에 더해 '두 번 눌러 고르기'가 켜져 있으면 같은 카드를 두 번째 눌렀을 때만 true (처음엔 카드를 키움)
func accepts_pick(button: Control) -> bool:
	if not accepts(button as BaseButton):
		return false
	if not SaveData.is_double_tap_pick_on() or _armed_button_id == button.get_instance_id():
		return true
	var previous := instance_from_id(_armed_button_id) as Control
	if previous != null:
		previous.scale = Vector2.ONE
	_armed_button_id = button.get_instance_id()
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2.ONE * ARMED_SCALE
	SoundPlayer.play("ui_click")
	return false


## 막는 시간이 끝났나 (자동 플레이 봇처럼 손가락 없이 고를 때)
func is_ready() -> bool:
	return progress() >= 1.0


## 0 = 막 열림, 1 = 이제 고를 수 있음 (카드를 흐리게 → 또렷하게)
func progress() -> float:
	return clampf((Time.get_ticks_msec() - _opened_msec) / (GUARD_SECONDS * 1000.0), 0.0, 1.0)


## 카드·버튼에 입힐 모습: 막는 동안 흐림 → 끝나면 또렷. 켜지는 그 순간 한 번 '딸깍'.
func current_modulate() -> Color:
	if is_ready() and not _was_ready:
		_was_ready = true
		SoundPlayer.play("ui_click")
	return Color.WHITE if is_ready() else GUARDED_MODULATE


## 창 안 내용을 조이스틱 엄지 자리(아래 35%) 위쪽 칸의 가운데에 놓는다
static func place_above_thumb_zone(panel: Control, content: Control) -> void:
	var area := CenterContainer.new()
	area.anchor_right = 1.0
	area.anchor_bottom = 1.0 - THUMB_ZONE_RATIO
	area.offset_top = TOP_MARGIN
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(content)
	panel.add_child(area)
