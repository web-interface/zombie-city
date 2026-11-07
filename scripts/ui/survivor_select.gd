## [파일] scripts/ui/survivor_select.gd
## [하는 일] 생존자 고르기 화면: 아래 줄의 얼굴 칸을 누르면 위에 그 생존자가 크게 걸어 다니고, 이름·한 줄 소개·난이도 ★·시작 무기·특성·스킬·전직 갈래 3개·내 기록(최고 밤·최다 처치·최장 연속)을 보여 준다. 잠긴 생존자는 검은 실루엣과 해금 조건·지금까지 한 양. 감염도 고르기 줄, "출동!" 으로 한 판 시작. 생존자 목록은 data/survivors.json + 해금 조건 표(meta_rules.json unlocks)로 자동으로 만든다.
## [쓰는 곳] scenes/survivor_select.tscn. 타이틀·결과 화면에서 온다. scripts/ui/infection_picker.gd 를 품고, scripts/meta/unlocks.gd·records.gd 를 읽는다.
## [근거 문서] 05 화면 목록(생존자 고르기·출동 준비), 03 §1·§1-2·§10·§11 생존자 해금, 04 §2, 14 §3
extends Control

const PREVIEW_SCALE := 3.0
const BRANCH_PREVIEW_TOP := 152.0
const INFECTION_TOP := 201.0
const WALK_FRAME_SECONDS := 0.12
const INFO_WIDTH := 112.0   # 오른쪽 소개 글 너비 (넘으면 낱말 단위로 줄바꿈)
const RECORD_WIDTH := 58.0  # 왼쪽 미리보기 아래 기록 글 너비
const PORTRAIT_SIZE := Vector2(26, 34)
const SILHOUETTE := Color(0.0, 0.0, 0.0, 0.9)

var _survivor_ids: Array[String] = []
var _selected_id: String = ""
var _preview: Sprite2D
var _info_box: VBoxContainer
var _record_box: VBoxContainer
var _time: float = 0.0
var _portrait_buttons: Dictionary = {}
var _branch_heading: Label
var _branch_row: HBoxContainer
var _branch_sprites: Array[Sprite2D] = []
var _start_button: Button


func _ready() -> void:
	PixelUi.full_rect(self)
	MenuScreen.play_music_if_present("music_select")
	_survivor_ids = Unlocks.listed_survivor_ids()
	var background := ColorRect.new()
	background.color = Color("10131a")
	add_child(PixelUi.full_rect(background))
	var back := PixelUi.button("◀ 뒤로", PixelUi.MUTED)
	back.position = Vector2(5, 4)
	back.custom_minimum_size = Vector2(44, 18)
	PixelUi.on_press(back, SceneRouter.go_to_title, "ui_back")
	add_child(back)
	var title := PixelUi.label("생존자 고르기", PixelUi.INK, false, true)
	title.position = Vector2(56, 7)
	add_child(title)
	_preview = Sprite2D.new()
	_preview.hframes = SpriteSheetLayout.COLUMNS
	_preview.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	_preview.position = Vector2(34, 60)
	add_child(_preview)
	_record_box = _positioned_column(Vector2(5, 92), RECORD_WIDTH)
	_info_box = _positioned_column(Vector2(64, 28), INFO_WIDTH)
	_branch_heading = PixelUi.label("레벨 10 전직 — 셋 중 하나", PixelUi.GOLD, true)
	_branch_heading.position = Vector2(6, BRANCH_PREVIEW_TOP - 13.0)
	add_child(_branch_heading)
	_branch_row = HBoxContainer.new()
	_branch_row.position = Vector2(6, BRANCH_PREVIEW_TOP)
	_branch_row.add_theme_constant_override("separation", 2)
	add_child(_branch_row)
	var picker := InfectionPicker.new()
	picker.position = Vector2(6, INFECTION_TOP)
	picker.custom_minimum_size = Vector2(168, 0)
	add_child(picker)
	picker.setup(168.0)
	add_child(_build_portrait_row())
	add_child(_build_start_button())
	_select(SceneRouter.selected_survivor_id if Unlocks.is_playable(SceneRouter.selected_survivor_id) else _survivor_ids[0])


func _positioned_column(at: Vector2, width: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.position = at
	column.custom_minimum_size = Vector2(width, 0)
	add_child(column)
	return column


func _build_portrait_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -78.0
	row.offset_bottom = -42.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for survivor_id: String in _survivor_ids:
		var portrait := PixelUi.button("", PixelUi.MUTED)
		portrait.custom_minimum_size = PORTRAIT_SIZE
		var face := Sprite2D.new()
		face.texture = load("res://art/sprites/survivor_%s.png" % _outfit_of(survivor_id))
		face.hframes = SpriteSheetLayout.COLUMNS
		face.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
		face.scale = Vector2.ONE * 2.0
		face.position = PORTRAIT_SIZE * Vector2(0.5, 0.45)
		face.modulate = Color.WHITE if Unlocks.is_playable(survivor_id) else SILHOUETTE
		portrait.add_child(face)
		if not Unlocks.is_playable(survivor_id):
			var lock_mark := PixelUi.label("?", PixelUi.MUTED, true)
			lock_mark.position = Vector2(PORTRAIT_SIZE.x - 8.0, 1.0)
			portrait.add_child(lock_mark)
		portrait.pressed.connect(_select.bind(survivor_id))
		_portrait_buttons[survivor_id] = portrait
		row.add_child(portrait)
	return row


func _build_start_button() -> Button:
	_start_button = PixelUi.button("출동!", PixelUi.GOOD)
	_start_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_start_button.offset_left = 30.0
	_start_button.offset_right = -30.0
	_start_button.offset_top = -34.0
	_start_button.offset_bottom = -10.0
	PixelUi.on_press(_start_button, func() -> void: SceneRouter.start_run(_selected_id))
	return _start_button


## 아직 표에 없는 생존자(해금 조건만 정해진)는 다른 생존자 그림을 검게 칠해 실루엣으로 쓴다
func _outfit_of(survivor_id: String) -> String:
	if GameData.table("survivors").has(survivor_id):
		return String(GameData.entry("survivors", survivor_id)["outfit"])
	return String(GameData.entry("survivors", GameData.entry_ids("survivors")[0])["outfit"])


func _select(survivor_id: String) -> void:
	if not _selected_id.is_empty():   # 화면을 처음 열 때는 소리 없이 (누른 적이 없는데 소리가 나면 어색함)
		SoundPlayer.play("card_select")
	_selected_id = survivor_id
	_preview.texture = load("res://art/sprites/survivor_%s.png" % _outfit_of(survivor_id))
	_preview.modulate = Color.WHITE if Unlocks.is_playable(survivor_id) else SILHOUETTE
	for id: String in _portrait_buttons.keys():
		var button: Button = _portrait_buttons[id]
		button.modulate = Color.WHITE if id == survivor_id else Color(0.6, 0.6, 0.65)
	_clear(_info_box)
	_clear(_record_box)
	var is_playable := Unlocks.is_playable(survivor_id)
	_start_button.disabled = not is_playable
	_start_button.text = "출동!" if is_playable else "잠김"
	if not is_playable and Unlocks.is_unlocked(survivor_id):
		_start_button.text = "준비 중"   # 조건은 채웠지만 생존자가 아직 게임에 안 들어옴
	if is_playable:
		_show_survivor_info(survivor_id)
	else:
		_show_locked_info(survivor_id)


func _show_survivor_info(survivor_id: String) -> void:
	var info := GameData.entry("survivors", survivor_id)
	_info_box.add_child(PixelUi.label(String(info["role"]), PixelUi.INK, false, true))   # 사람 이름 없이 직업만 (문서 15 부록 B)
	_info_box.add_child(PixelUi.label("★".repeat(int(info["difficulty_stars"])) + "☆".repeat(3 - int(info["difficulty_stars"])), PixelUi.GOLD, true))
	_info_box.add_child(_wrapped(String(info["intro"]), PixelUi.MUTED))
	var weapon := GameData.entry("weapons", String(info["start_weapon"]))
	var skill := GameData.entry("skills", String(info["skill"]))
	_info_box.add_child(_wrapped("무기  %s" % weapon["name"], PixelUi.INK))
	_info_box.add_child(_wrapped("특성  %s" % info["trait_text"], PixelUi.INK))
	_info_box.add_child(_wrapped("스킬  %s (%d초)" % [skill["name"], int(skill["cooldown_seconds"])], PixelUi.INK))
	_show_records(survivor_id)
	_branch_heading.visible = true
	_show_branch_previews(info["branches"])


## 잠긴 생존자: 이름, 해금 조건, 지금까지 한 양 ("지금 처치 4,680 / 5,000").
## 조건은 채웠지만 아직 게임에 안 들어온 생존자는 "해금됨 · 곧 들어와요"
func _show_locked_info(survivor_id: String) -> void:
	_info_box.add_child(PixelUi.label(Unlocks.display_name(survivor_id), PixelUi.INK, false, true))
	_branch_heading.visible = false
	_show_branch_previews([])
	if Unlocks.is_unlocked(survivor_id):
		_info_box.add_child(PixelUi.label("해금됨", PixelUi.GOOD, true))
		_info_box.add_child(_wrapped("곧 들어와요", PixelUi.MUTED))
		return
	_info_box.add_child(PixelUi.label("잠김", PixelUi.ALERT, true))
	_info_box.add_child(_wrapped(Unlocks.condition_text(survivor_id), PixelUi.GOLD))
	var condition := Unlocks.condition(survivor_id)
	var metrics := RunMetrics.totals_from_save()
	metrics["nights_survived"] = metrics["best_night_any"]   # 한 판 조건(셋째 밤)은 지금까지의 최고 기록으로 보여 줌
	var current := int(metrics.get(String(condition.get("key", "")), 0))
	var progress_word := Unlocks.progress_word(survivor_id)
	var target := RunMetrics.format_count(int(condition.get("at_least", 0)))
	_info_box.add_child(_wrapped("지금 %s %s / %s" % [progress_word, RunMetrics.format_count(current), target], PixelUi.MUTED))
	if not GameData.table("survivors").has(survivor_id):
		_info_box.add_child(_wrapped("곧 들어와요", PixelUi.MUTED))


## 왼쪽 미리보기 아래: 이 생존자의 최고 기록 (깰 목표가 늘 보이게 — 문서 14 §4)
func _show_records(survivor_id: String) -> void:
	if not Records.has_played(survivor_id):
		_record_box.add_child(PixelUi.small_lines("기록 없음", PixelUi.MUTED, RECORD_WIDTH))
		return
	var record := Records.of(survivor_id)
	_record_box.add_child(PixelUi.small_lines("최고 밤 %d" % int(record["best_night"]), PixelUi.GOLD, RECORD_WIDTH))
	_record_box.add_child(PixelUi.small_lines("처치 %s" % RunMetrics.format_count(int(record["best_kills"])), PixelUi.MUTED, RECORD_WIDTH))
	_record_box.add_child(PixelUi.small_lines("연속 %s" % RunMetrics.format_count(int(record["best_combo"])), PixelUi.MUTED, RECORD_WIDTH))


## 레벨 10 에 고를 전직 갈래 3개의 옷차림을 미리 보여 준다 (고르는 재미)
func _show_branch_previews(branch_ids: Array) -> void:
	_clear(_branch_row)
	_branch_sprites.clear()
	for branch_id: String in branch_ids:
		var branch := GameData.entry("promotions", branch_id)
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(54, 46)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(54, 34)
		var sprite := Sprite2D.new()
		sprite.texture = load("res://art/sprites/survivor_%s.png" % branch["outfit"])
		sprite.hframes = SpriteSheetLayout.COLUMNS
		sprite.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
		sprite.scale = Vector2.ONE * 2.0
		sprite.position = Vector2(27, 18)
		holder.add_child(sprite)
		_branch_sprites.append(sprite)
		cell.add_child(holder)
		var name_label := PixelUi.label(String(branch["name"]), PixelUi.GOLD, true)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(name_label)
		_branch_row.add_child(cell)


func _clear(container: Container) -> void:
	for child: Node in container.get_children():
		child.queue_free()


func _wrapped(text: String, color: Color) -> VBoxContainer:
	return PixelUi.small_lines(text, color, INFO_WIDTH)


## 안드로이드 뒤로 가기 = 타이틀로
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneRouter.go_to_title()


func _process(delta: float) -> void:
	_time += delta
	_preview.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "walk_down", int(_time / WALK_FRAME_SECONDS))
	for sprite: Sprite2D in _branch_sprites:
		sprite.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "idle_down", int(_time * 2.0))
	for survivor_id: String in _portrait_buttons.keys():
		var face: Sprite2D = (_portrait_buttons[survivor_id] as Button).get_child(0)
		var action := "walk_down" if survivor_id == _selected_id else "idle_down"
		face.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, action, int(_time / WALK_FRAME_SECONDS))
