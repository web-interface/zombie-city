## [파일] scripts/ui/online_rank_line.gd
## [하는 일] 결과 화면 목록 맨 앞 '순위' 띠: 로그인했으면 판 결과를 바로 올리고 "이번 기록 전체 7위"(새 최고면 크게 금색 "전체 3위!" + "새 최고 기록", 오늘의 도전 판이면 오늘의 도전 순위), 안 했으면 [로그인하고 순위에 올리기] — 로그인하면 그때 올린다. 못 올리면 이유 한 줄. 게임은 기다리지 않는다.
## [쓰는 곳] scripts/ui/result_screen.gd 가 Online.can_submit(결과) 일 때만 만든다(시험 봇·시험 옵션 판은 안 만듦). scripts/meta/online.gd 로 올린다.
## [근거 문서] 05 화면 목록(결과), 07 온라인 순위표
class_name OnlineRankLine
extends PanelContainer

const EDGE := Color("6cc6ff")
const BIG_FONT_SIZE := 16
const SMALL := 0
const REGULAR := 1
const BIG := 2

var _result: Dictionary = {}
var _column: VBoxContainer


func _init(result: Dictionary, width: float) -> void:
	_result = result
	custom_minimum_size = Vector2(width, 0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", PixelUi.panel_style(PixelUi.PANEL, EDGE))
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 1)
	add_child(_column)
	if Online.is_logged_in():
		_submit()
	else:
		_show_login_button()


func _show_login_button() -> void:
	_set_lines([])
	var login := PixelUi.button("로그인하고 순위에 올리기", EDGE)
	PixelUi.on_press(login, Online.open_login)
	_column.add_child(login)
	Online.watch_state(_on_login_state_changed)


func _on_login_state_changed(_current: Dictionary) -> void:
	if Online.is_logged_in() and not Online.was_submitted(_result):
		_submit()


func _submit() -> void:
	_set_lines([["순위에 올리는 중…", PixelUi.MUTED, SMALL]])
	Online.submit_run(_result, _on_submitted)


func _on_submitted(answer: Dictionary) -> void:
	if not bool(answer.get("ok", false)):
		var reason := "인터넷이 안 돼서 순위에 못 올렸어요" if int(answer.get("status", 0)) == 0 else String(answer.get("error", "순위에 못 올렸어요"))
		_set_lines([[reason, PixelUi.ALERT, SMALL]])
		return
	var standing := _pick_board(answer.get("boards", []))
	var board_name := "오늘의 도전" if String(standing.get("board", "")).begins_with("daily:") else "전체"
	if bool(standing.get("isNewBest", false)):
		_set_lines([["%s %d위!" % [board_name, int(standing.get("rank", 0))], PixelUi.GOLD, BIG],
			["새 최고 기록 · %d명 중" % int(standing.get("total", 0)), PixelUi.GOLD, SMALL]])
		return
	_set_lines([["이번 기록 %s %d위" % [board_name, int(standing.get("runRank", 0))], PixelUi.INK, REGULAR],
		["내 최고 %d위 · %d명 중" % [int(standing.get("rank", 0)), int(standing.get("total", 0))], PixelUi.MUTED, SMALL]])


## 오늘의 도전 판이면 오늘의 도전 순위, 아니면 전체 순위를 보여 준다
func _pick_board(boards: Array) -> Dictionary:
	var wanted := "daily:" if bool(_result.get("daily_challenge", false)) else Online.BOARD_ALL
	for standing: Dictionary in boards:
		if String(standing.get("board", "")).begins_with(wanted):
			return standing
	return boards[0] if not boards.is_empty() else {}


## lines: [[글, 색, 크기(SMALL·REGULAR·BIG)], …]
func _set_lines(lines: Array) -> void:
	for child: Node in _column.get_children():
		child.queue_free()
	for line: Array in lines:
		var size_kind := int(line[2])
		var text := PixelUi.label(String(line[0]), line[1], size_kind == SMALL, size_kind == BIG)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if size_kind == BIG:
			text.add_theme_font_size_override("font_size", BIG_FONT_SIZE)
		_column.add_child(text)
