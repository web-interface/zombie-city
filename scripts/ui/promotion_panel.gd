## [파일] scripts/ui/promotion_panel.gd
## [하는 일] 전직 창(레벨 10): 그 생존자의 갈래 카드 3장 — 바뀐 옷차림이 걷는 미리보기, 갈래 이름, 한 줄 요약, 1차 효과, 2차(레벨 20) 효과 맛보기. 탭 한 번으로 고른다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고, Promotion.branches_ready 신호를 받아 열린다. 고르면 Promotion.choose_branch() 를 부르고 닫힌다.
## [근거 문서] 02 §5 전직, 05 화면 목록(전직 창), 04 §2 전직 옷차림
class_name PromotionPanel
extends Control

signal closed

const CARD_SIZE := Vector2(164, 62)
const PREVIEW_FRAME_SECONDS := 0.12

var _promotion: Promotion
var _card_box: VBoxContainer
var _branch_ids: Array[String] = []
var _previews: Array[Sprite2D] = []
var _preview_time: float = 0.0


func setup(promotion: Promotion) -> void:
	_promotion = promotion
	_promotion.branches_ready.connect(_show_branches)
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.0, 0.8)
	add_child(PixelUi.full_rect(dim))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(PixelUi.centered(column))
	var title := PixelUi.label("전직! 갈래를 골라요", PixelUi.GOLD, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var hint := PixelUi.label("레벨 20에 한 번 더 강해져요", PixelUi.MUTED, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	_card_box = VBoxContainer.new()
	_card_box.add_theme_constant_override("separation", 4)
	column.add_child(_card_box)


func choose(index: int) -> void:
	if index >= 0 and index < _branch_ids.size():
		_pick(_branch_ids[index])


func is_open() -> bool:
	return visible


func branch_ids() -> Array[String]:
	return _branch_ids


func _show_branches(branch_ids: Array[String]) -> void:
	_branch_ids = branch_ids
	_previews.clear()
	for child: Node in _card_box.get_children():
		child.queue_free()
	for branch_id: String in branch_ids:
		_card_box.add_child(_build_card(branch_id))
	visible = true


func _build_card(branch_id: String) -> Button:
	var branch := GameData.entry("promotions", branch_id)
	var card_button := PixelUi.button("", PixelUi.GOLD)
	card_button.custom_minimum_size = CARD_SIZE
	var preview := Sprite2D.new()
	preview.texture = load("res://art/sprites/survivor_%s.png" % branch["outfit"])
	preview.hframes = SpriteSheetLayout.COLUMNS
	preview.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
	preview.scale = Vector2.ONE * 2.0
	preview.position = Vector2(20, 30)
	card_button.add_child(preview)
	_previews.append(preview)
	var texts := VBoxContainer.new()
	texts.position = Vector2(40, 3)
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(PixelUi.label("%s — %s" % [branch["name"], branch["summary"]], PixelUi.GOLD))
	for line: String in [String(branch["stage_1"]["text"]), "각성: " + String(branch["stage_2"]["text"])]:
		var description := PixelUi.label(line, PixelUi.INK if not line.begins_with("각성") else PixelUi.MUTED, true)
		description.custom_minimum_size = Vector2(CARD_SIZE.x - 44, 0)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(description)
	card_button.add_child(texts)
	card_button.pressed.connect(_pick.bind(branch_id))
	return card_button


func _pick(branch_id: String) -> void:
	visible = false
	_promotion.choose_branch(branch_id)
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_preview_time += delta
	var frame_number := int(_preview_time / PREVIEW_FRAME_SECONDS)
	for preview: Sprite2D in _previews:
		preview.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "walk_down", frame_number)
