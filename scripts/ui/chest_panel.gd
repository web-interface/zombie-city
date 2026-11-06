## [파일] scripts/ui/chest_panel.gd
## [하는 일] 보물 상자 창: 상자가 열리고 슬롯 칸(1·3·5개)에서 아이콘이 빠르게 돌다가 하나씩 멈추며 받을 강화를 보여 준다. 5개면 금빛 '대박' 연출. [받기]를 누르면 claimed 를 보내고 닫힌다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 open() 으로 연다. scripts/run/run_rewards.gd 가 claimed 를 받아 강화를 적용한다. 자동 플레이 봇은 press_claim().
## [근거 문서] 14 §2-6 보물 상자·§4 중독 설계(쉴 새 없는 보상), data/run_rules.json chest
class_name ChestPanel
extends Control

signal claimed

const CHEST_TEXTURE: Texture2D = preload("res://art/sprites/chest.png")
const SLOT_SIZE := Vector2(30, 30)
const FALLBACK_ICONS: Array[String] = ["icon_pistol", "icon_vest", "icon_sneakers", "icon_backpack", "icon_shotgun", "icon_saw_drone"]
const REEL_SPIN_INTERVAL := 0.05

var _chest_image: TextureRect
var _title: Label
var _slot_row: HBoxContainer
var _name_box: VBoxContainer
var _claim_button: Button
var _slots: Array[TextureRect] = []
var _final_icons: Array[String] = []
var _spin_pool: Array[String] = []
var _stopped_count: int = 0
var _spin_time: float = 0.0
var _rules: Dictionary = {}


func setup() -> void:
	PixelUi.full_rect(self)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_rules = GameData.rules("chest")
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.0, 0.85)
	add_child(PixelUi.full_rect(dim))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(PixelUi.centered(column))
	_title = PixelUi.label("보물 상자!", PixelUi.GOLD, false, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_chest_image = _make_chest_image()
	column.add_child(PixelUi.centered(_chest_image))
	_slot_row = HBoxContainer.new()
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slot_row.add_theme_constant_override("separation", 3)
	column.add_child(_slot_row)
	_name_box = VBoxContainer.new()
	_name_box.add_theme_constant_override("separation", 0)
	column.add_child(_name_box)
	_claim_button = PixelUi.button("받기", PixelUi.GOLD)
	_claim_button.custom_minimum_size = Vector2(120, 26)
	_claim_button.pressed.connect(_on_claim)
	column.add_child(_claim_button)


## cards: 받을 강화 카드들 (없으면 카드 한 장 더를 count 번), count: 1·3·5
func open(cards: Array, count: int) -> void:
	_final_icons.clear()
	for index: int in range(count):
		_final_icons.append(String(cards[index].get("icon", "icon_pistol")) if index < cards.size() else "icon_backpack")
	_spin_pool = _final_icons.duplicate()
	_spin_pool.append_array(FALLBACK_ICONS)
	_build_slots(count)
	_fill_names(cards, count)
	_title.text = "대박! 보물 상자" if count >= 5 else "보물 상자!"
	_chest_image.texture = _chest_frame(0)
	_name_box.visible = false
	_claim_button.visible = false
	_stopped_count = 0
	_spin_time = 0.0
	visible = true
	SoundPlayer.play("chest_roll")


func is_open() -> bool:
	return visible


func press_claim() -> void:
	if visible and _claim_button.visible:
		_on_claim()


func _process(delta: float) -> void:
	if not visible or _stopped_count >= _slots.size():
		return
	_spin_time += delta
	var roll_seconds := float(_rules["roll_seconds"])
	var stop_index := int((_spin_time - roll_seconds) / float(_rules["reveal_gap_seconds"]))
	while _stopped_count < _slots.size() and _spin_time >= roll_seconds and _stopped_count <= stop_index:
		_stop_slot(_stopped_count)
	for index: int in range(_stopped_count, _slots.size()):   # 아직 도는 칸
		var tick := int(_spin_time / REEL_SPIN_INTERVAL) + index * 3
		_slots[index].texture = _load_icon(_spin_pool[tick % _spin_pool.size()])


func _stop_slot(index: int) -> void:
	_slots[index].texture = _load_icon(_final_icons[index])
	_slots[index].modulate = Color(1.3, 1.2, 0.7)
	_stopped_count += 1
	SoundPlayer.play("chest_open_small" if _stopped_count < _slots.size() else ("chest_jackpot" if _slots.size() >= 5 else "chest_open_small"))
	if _stopped_count >= _slots.size():
		_chest_image.texture = _chest_frame(1)
		_name_box.visible = true
		_claim_button.visible = true


func _on_claim() -> void:
	visible = false
	SoundPlayer.play("card_select")
	claimed.emit()


func _build_slots(count: int) -> void:
	for child: Node in _slot_row.get_children():
		child.queue_free()
	_slots.clear()
	var slot_scale := 2 if count <= 3 else 1
	for index: int in range(count):
		var frame := PixelUi.panel(PixelUi.PANEL, PixelUi.GOLD)
		var icon := PixelUi.icon("icon_pistol", slot_scale + (1 if count == 1 else 0))
		frame.add_child(icon)
		_slot_row.add_child(frame)
		_slots.append(icon)


func _fill_names(cards: Array, count: int) -> void:
	for child: Node in _name_box.get_children():
		child.queue_free()
	for index: int in range(count):
		var text := "%s %s" % [cards[index].get("name", ""), cards[index].get("level_text", "")] if index < cards.size() else "카드 한 장 더"
		var line := PixelUi.label(text.strip_edges(), PixelUi.INK, true)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name_box.add_child(line)


func _make_chest_image() -> TextureRect:
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(32, 32)
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return image


## chest.png 는 16×16 두 칸 (닫힘 · 열림)
func _chest_frame(frame_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = CHEST_TEXTURE
	atlas.region = Rect2(16 * frame_index, 0, 16, 16)
	return atlas


func _load_icon(icon_name: String) -> Texture2D:
	var path := "res://art/sprites/icons/%s.png" % icon_name
	return load(path) if ResourceLoader.exists(path) else load("res://art/sprites/icons/icon_pistol.png")
