## [파일] scripts/ui/survivor_select.gd
## [하는 일] 생존자 고르기 화면: 아래 줄의 얼굴 칸을 누르면 위에 그 생존자가 크게 걸어 다니고, 이름·한 줄 소개·난이도 ★·시작 무기·특성·스킬·전직 갈래 3개를 보여 준다. "출동!"을 누르면 한 판을 시작한다. 생존자 목록은 data/survivors.json 을 읽어 자동으로 만든다.
## [쓰는 곳] scenes/survivor_select.tscn. 타이틀·결과 화면에서 온다.
## [근거 문서] 05 화면 목록(생존자 고르기), 03 §1·§1-2, 04 §2
extends Control

const PREVIEW_SCALE := 3.0
const BRANCH_PREVIEW_TOP := 168.0
const WALK_FRAME_SECONDS := 0.12
const INFO_WIDTH := 112.0   # 오른쪽 소개 글 너비 (넘으면 낱말 단위로 줄바꿈)

var _survivor_ids: Array[String] = []
var _selected_id: String = ""
var _preview: Sprite2D
var _info_box: VBoxContainer
var _time: float = 0.0
var _portrait_buttons: Dictionary = {}
var _branch_row: HBoxContainer
var _branch_sprites: Array[Sprite2D] = []


func _ready() -> void:
	PixelUi.full_rect(self)
	_survivor_ids = GameData.entry_ids("survivors")
	var background := ColorRect.new()
	background.color = Color("10131a")
	add_child(PixelUi.full_rect(background))
	var title := PixelUi.label("생존자 고르기", PixelUi.INK, false, true)
	title.position = Vector2(6, 8)
	add_child(title)
	_preview = Sprite2D.new()
	_preview.hframes = SpriteSheetLayout.COLUMNS
	_preview.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	_preview.position = Vector2(34, 62)
	add_child(_preview)
	_info_box = VBoxContainer.new()
	_info_box.add_theme_constant_override("separation", 1)
	_info_box.position = Vector2(64, 28)
	_info_box.custom_minimum_size = Vector2(112, 0)
	add_child(_info_box)
	var branch_heading := PixelUi.label("레벨 10 전직 — 셋 중 하나", PixelUi.GOLD, true)
	branch_heading.position = Vector2(6, BRANCH_PREVIEW_TOP - 13.0)
	add_child(branch_heading)
	_branch_row = HBoxContainer.new()
	_branch_row.position = Vector2(6, BRANCH_PREVIEW_TOP)
	_branch_row.add_theme_constant_override("separation", 2)
	add_child(_branch_row)
	add_child(_build_portrait_row())
	add_child(_build_start_button())
	_select(SceneRouter.selected_survivor_id if _survivor_ids.has(SceneRouter.selected_survivor_id) else _survivor_ids[0])


func _build_portrait_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -78.0
	row.offset_bottom = -42.0
	row.offset_left = 6.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for survivor_id: String in _survivor_ids:
		var info := GameData.entry("survivors", survivor_id)
		var portrait := PixelUi.button("", PixelUi.MUTED)
		portrait.custom_minimum_size = Vector2(38, 34)
		var face := Sprite2D.new()
		face.texture = load("res://art/sprites/survivor_%s.png" % info["outfit"])
		face.hframes = SpriteSheetLayout.COLUMNS
		face.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
		face.scale = Vector2.ONE * 2.0
		face.position = Vector2(19, 15)
		portrait.add_child(face)
		portrait.pressed.connect(_select.bind(survivor_id))
		_portrait_buttons[survivor_id] = portrait
		row.add_child(portrait)
	return row


func _build_start_button() -> Button:
	var start := PixelUi.button("출동!", PixelUi.GOOD)
	start.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	start.offset_left = 30.0
	start.offset_right = -30.0
	start.offset_top = -34.0
	start.offset_bottom = -10.0
	start.pressed.connect(func() -> void:
		SoundPlayer.play("ui_click")
		SceneRouter.start_run(_selected_id))
	return start


func _select(survivor_id: String) -> void:
	if not _selected_id.is_empty():   # 화면을 처음 열 때는 소리 없이 (누른 적이 없는데 소리가 나면 어색함)
		SoundPlayer.play("card_select")
	_selected_id = survivor_id
	var info := GameData.entry("survivors", survivor_id)
	_preview.texture = load("res://art/sprites/survivor_%s.png" % info["outfit"])
	for id: String in _portrait_buttons.keys():
		var button: Button = _portrait_buttons[id]
		button.modulate = Color.WHITE if id == survivor_id else Color(0.6, 0.6, 0.65)
	for child: Node in _info_box.get_children():
		child.queue_free()
	_add_info(PixelUi.label("%s %s" % [info["role"], info["name"]], PixelUi.INK, false, true))
	_add_info(PixelUi.label("★".repeat(int(info["difficulty_stars"])) + "☆".repeat(3 - int(info["difficulty_stars"])), PixelUi.GOLD, true))
	_add_info(_wrapped(String(info["intro"]), PixelUi.MUTED))
	var weapon := GameData.entry("weapons", String(info["start_weapon"]))
	var skill := GameData.entry("skills", String(info["skill"]))
	_add_info(_wrapped("무기  %s" % weapon["name"], PixelUi.INK))
	_add_info(_wrapped("특성  %s" % info["trait_text"], PixelUi.INK))
	_add_info(_wrapped("스킬  %s (%d초)" % [skill["name"], int(skill["cooldown_seconds"])], PixelUi.INK))
	_show_branch_previews(info["branches"])


## 레벨 10 에 고를 전직 갈래 3개의 옷차림을 미리 보여 준다 (고르는 재미)
func _show_branch_previews(branch_ids: Array) -> void:
	for child: Node in _branch_row.get_children():
		child.queue_free()
	_branch_sprites.clear()
	for branch_id: String in branch_ids:
		var branch := GameData.entry("promotions", branch_id)
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(54, 52)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(54, 40)
		var sprite := Sprite2D.new()
		sprite.texture = load("res://art/sprites/survivor_%s.png" % branch["outfit"])
		sprite.hframes = SpriteSheetLayout.COLUMNS
		sprite.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
		sprite.scale = Vector2.ONE * 2.0
		sprite.position = Vector2(27, 22)
		holder.add_child(sprite)
		_branch_sprites.append(sprite)
		cell.add_child(holder)
		var name_label := PixelUi.label(String(branch["name"]), PixelUi.GOLD, true)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(name_label)
		_branch_row.add_child(cell)


func _add_info(control: Control) -> void:
	_info_box.add_child(control)


func _wrapped(text: String, color: Color) -> VBoxContainer:
	return PixelUi.small_lines(text, color, INFO_WIDTH)


func _process(delta: float) -> void:
	_time += delta
	_preview.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "walk_down", int(_time / WALK_FRAME_SECONDS))
	for sprite: Sprite2D in _branch_sprites:
		sprite.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "idle_down", int(_time * 2.0))
	for survivor_id: String in _portrait_buttons.keys():
		var face: Sprite2D = (_portrait_buttons[survivor_id] as Button).get_child(0)
		var action := "walk_down" if survivor_id == _selected_id else "idle_down"
		face.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, action, int(_time / WALK_FRAME_SECONDS))
