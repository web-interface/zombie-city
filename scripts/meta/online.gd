## [파일] scripts/meta/online.gd
## [하는 일] 온라인 입구: 웹판은 로그인해야 게임을 시작한다(require_login). web/account.js 를 JavaScriptBridge 로 불러 로그인 상태 읽기·로그인 창 열기·판 결과 올리기·순위 받아오기를 한다. 웹이 아니거나 화면 없는 실행·자동 플레이 봇·시험 옵션 판이면 아무것도 안 하고 조용히 넘어간다. 답은 콜백으로 받아 화면이 멈추지 않고, 인터넷·서버가 안 돼도 게임은 그대로.
## [쓰는 곳] title_screen.gd(로그인 상태·창), leaderboard_screen.gd(순위), online_rank_line.gd(결과 화면에서 올리기). 서버는 야구 Worker 의 /zc/ 경로(baseball/worker/src/zc.ts).
## [근거 문서] 07 온라인 순위표, 05 순위 화면
class_name Online
extends RefCounted

const BRIDGE_NAME := "ZombieCityAccount"
const BOARD_ALL := "all"
const STATE_IN := "in"
const STATE_OFFLINE := "offline"

static var _account: JavaScriptObject = null
static var _state_callback: JavaScriptObject = null
## JS 가 부를 때까지 콜백을 붙잡아 둔다 (붙잡지 않으면 Godot 쪽에서 지워져 답이 사라짐) — 번호 → JavaScriptObject
static var _pending_callbacks: Dictionary = {}
static var _next_callback_id: int = 0
static var _state_listeners: Array[Callable] = []
## 이미 올린 판 (결과 화면을 다시 만들어도 같은 판을 두 번 올리지 않게) — 판 결과 hash → true
static var _submitted_runs: Dictionary = {}


## 웹판이고, 사람이 하는 판(시험 옵션 없음)이고, account.js 가 있을 때만 true
static func is_available() -> bool:
	if not OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return false
	if not SceneRouter.test_options.is_empty():
		return false   # --autoplay · --speed · --invincible … 시험 판은 절대 온라인에 닿지 않는다
	return _bridge() != null


## {"state": "out|checking|in|offline", "username": "...", "notice": "..."}
static func state() -> Dictionary:
	if not is_available():
		return {"state": "out", "username": "", "notice": ""}
	return _parse(String(_bridge().call("state")))


static func is_logged_in() -> bool:
	var current := String(state()["state"])
	return current == STATE_IN or current == STATE_OFFLINE


static func open_login() -> void:
	if is_available():
		_bridge().call("open")


## 웹판은 로그인해야 시작 (사용자 요청 2026-11-07): 로그아웃 상태면 닫을 수 없는 로그인 창을 띄우고 false.
## 자동 로그인 확인 중("checking")이면 창을 띄우지 않고 false — 끝나면 watch_state 가 다시 부른다. 웹이 아니거나 시험 판이면 늘 true.
static func require_login() -> bool:
	if not is_available():
		return true
	var current := String(state()["state"])
	if current == STATE_IN or current == STATE_OFFLINE:
		return true
	if current != "checking":
		_bridge().call("open", true)
	return false


## 로그인 상태가 바뀌면 on_changed(state: Dictionary). 화면이 사라진 콜백은 알아서 빠진다
static func watch_state(on_changed: Callable) -> void:
	if not is_available():
		return
	_state_listeners.append(on_changed)
	if _state_callback == null:
		_state_callback = JavaScriptBridge.create_callback(_on_state_changed)
		_bridge().call("watch", _state_callback)


## 올려도 되는 판인가: 시험 봇·시험 옵션 판·시험 밤 제한으로 끝난 판은 절대 안 올린다
static func can_submit(result: Dictionary) -> bool:
	if not is_available() or SceneRouter.is_autoplay():
		return false
	if not String(result.get("bot", "")).is_empty() or String(result.get("end_reason", "")) == "test_night_limit":
		return false
	return not String(result.get("survivor", "")).is_empty()


static func was_submitted(result: Dictionary) -> bool:
	return _submitted_runs.has(result.hash())


## 판 결과 올리기 → on_done(answer: Dictionary) — answer.ok · boards[{board, isNewBest, runRank, rank, total}] 또는 error
static func submit_run(result: Dictionary, on_done: Callable) -> void:
	if not can_submit(result) or was_submitted(result):
		return
	_submitted_runs[result.hash()] = true
	var is_daily := bool(result.get("daily_challenge", false))
	var run := {
		"survivor": String(result.get("survivor", "")),
		"nights": int(result.get("nights_survived", 0)),
		"kills": int(result.get("kills", 0)),
		"seconds": float(result.get("total_seconds", 0.0)),
		"level": int(result.get("level", 1)),
		"infection": int(result.get("infection_level", 0)),
		"daily": DailyChallenge.today_key() if is_daily else "",
	}
	_bridge().call("submitRun", JSON.stringify(run), _keep_callback(on_done))


## 순위 받아오기 → on_done(answer: Dictionary) — answer.ok · rows[{rank, username, survivor, nights, kills, seconds, me}] · me · total
static func fetch_rank(board: String, on_done: Callable) -> void:
	if not is_available():
		on_done.call({"ok": false, "status": -1})
		return
	_bridge().call("rank", board, _keep_callback(on_done))


static func board_for_survivor(survivor_id: String) -> String:
	return "survivor:" + survivor_id


static func board_for_daily(date_key: String) -> String:
	return "daily:" + date_key


static func _bridge() -> JavaScriptObject:
	if _account == null:
		_account = JavaScriptBridge.get_interface(BRIDGE_NAME)
	return _account


## JS 에 넘길 일회용 콜백: 답이 오면 JSON 을 사전으로 바꿔 on_done 에 주고 붙잡아 둔 것을 놓는다
static func _keep_callback(on_done: Callable) -> JavaScriptObject:
	_next_callback_id += 1
	var callback_id := _next_callback_id
	var callback := JavaScriptBridge.create_callback(func(arguments: Array) -> void:
		_pending_callbacks.erase(callback_id)
		if on_done.is_valid():   # 답이 오기 전에 화면을 떠났으면 조용히 버린다
			on_done.call(_parse(String(arguments[0]) if not arguments.is_empty() else "")))
	_pending_callbacks[callback_id] = callback
	return callback


static func _on_state_changed(arguments: Array) -> void:
	var current := _parse(String(arguments[0]) if not arguments.is_empty() else "")
	_state_listeners = _state_listeners.filter(func(listener: Callable) -> bool: return listener.is_valid())
	for listener: Callable in _state_listeners:
		listener.call(current)


static func _parse(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
