## [파일] scripts/ui/promotion_panel.gd
## [하는 일] 전직 창(레벨 10): 그 생존자의 갈래 카드 3장 — 바뀐 옷차림이 걷는 미리보기, 갈래 이름, 한 줄 요약, 1차 효과, 2차(레벨 20) 효과 맛보기. 탭 한 번으로 고른다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고, Promotion.branches_ready 신호를 받아 열린다. 고르면 Promotion.choose_branch() 를 부르고 닫힌다.
## [근거 문서] 02 §5 전직, 05 화면 목록(전직 창), 04 §2 전직 옷차림
class_name PromotionPanel
extends Control

signal closed

const CARD_SIZE := Vector2(164, 74)
const PREVIEW_FRAME_SECONDS := 0.12
const INPUT_GUARD_MILLISECONDS := 280.0 # 뜬 직후엔 눌러도 안 고름 (잘못 골리지 않게)

var _promotion: Promotion
var _card_box: VBoxContainer
var _branch_ids: Array[String] = []
var _previews: Array[Sprite2D] = []
var _preview_time: float = 0.0
var _opened_at_msec: int = 0


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
	if visible and index >= 0 and index < _branch_ids.size():
		_pick(_branch_ids[index])


func is_open() -> bool:
	return visible


func branch_ids() -> Array[String]:
	return _branch_ids


func _show_branches(shown_branch_ids: Array[String]) -> void:
	_branch_ids = shown_branch_ids
	_previews.clear()
	for child: Node in _card_box.get_children():
		child.queue_free()
	for branch_id: String in shown_branch_ids:
		_card_box.add_child(_build_card(branch_id))
	_opened_at_msec = Time.get_ticks_msec()
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
	preview.position = Vector2(20, 36)
	card_button.add_child(preview)
	_previews.append(preview)
	var texts := VBoxContainer.new()
	texts.position = Vector2(40, 3)
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(PixelUi.label(String(branch["name"]), PixelUi.GOLD, false, true))
	# 1차 효과는 2줄까지, 각성은 1줄 맛보기 (카드 밖으로 넘치지 않게)
	var text_width := CARD_SIZE.x - 44.0
	texts.add_child(PixelUi.label(PixelUi.wrap_words(String(branch["stage_1"]["text"]), PixelUi.FONT_SMALL, PixelUi.SIZE_SMALL, text_width, 2), PixelUi.INK, true))
	texts.add_child(PixelUi.label(PixelUi.wrap_words("각성: " + String(branch["stage_2"]["text"]), PixelUi.FONT_SMALL, PixelUi.SIZE_SMALL, text_width, 1), PixelUi.MUTED, true))
	card_button.add_child(texts)
	card_button.pressed.connect(_pick.bind(branch_id))
	return card_button


func _pick(branch_id: String) -> void:
	if Time.get_ticks_msec() - _opened_at_msec < INPUT_GUARD_MILLISECONDS:
		return
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
