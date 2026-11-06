## [파일] scripts/ui/codex_screen.gd
## [하는 일] 도감 화면: 위에 칸 고르기(좀비·무기·진화·히든 스킬 — 항목이 있는 칸만), 그 칸의 찾은 수/전체, 아래에 3줄 격자. 만난 것은 그림(좀비는 걸어 다님)·이름, 못 만난 것은 검은 실루엣·'???'. 위 줄 오른쪽에 전체 %.
## [쓰는 곳] scenes/codex.tscn. 타이틀에서 SceneRouter.go_to_codex() 로 온다. scripts/meta/codex.gd 를 읽는다.
## [근거 문서] 04 §8 도감, 14 §3 도감·§4 모으기(빈칸이 보이게), 05 화면 목록(도감·업적)
extends MenuScreen

const GRID_COLUMNS := 3
const CELL_SIZE := Vector2(53, 58)
const PICTURE_HEIGHT := 34.0
const WALK_FRAME_SECONDS := 0.16
const SILHOUETTE := Color(0.0, 0.0, 0.0, 0.85)

var _category_id: String = ""
var _walking_sprites: Array[Sprite2D] = []
var _time: float = 0.0


func _ready() -> void:
	build_frame("도감", Color("0f1416"))
	set_header_value("%d%%" % Codex.total_percent())
	var categories := Codex.categories()
	if not categories.is_empty():
		_show_category(String(categories[0]["id"]))


func _process(delta: float) -> void:
	_time += delta
	for index: int in range(_walking_sprites.size()):
		# 칸마다 한 장씩 어긋나게 걸어서 다 같이 똑같이 움직이지 않게 (AI 티)
		_walking_sprites[index].frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.ZOMBIE_ROWS, "walk_down", int(_time / WALK_FRAME_SECONDS) + index)


func _show_category(category_id: String) -> void:
	_category_id = category_id
	clear_body()
	_walking_sprites.clear()
	body.add_child(_build_tabs())
	var found := Codex.found_count(category_id)
	var total := Codex.total_count(category_id)
	body.add_child(PixelUi.small_lines("찾은 것 %d / %d" % [found, total], PixelUi.MUTED, BODY_WIDTH))
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	var category := _category(category_id)
	for entry_id: String in Codex.entry_ids(category):
		grid.add_child(_build_cell(category, entry_id))
	body.add_child(grid)


func _build_tabs() -> HBoxContainer:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	for category: Dictionary in Codex.categories():
		var category_id := String(category["id"])
		var is_current := category_id == _category_id
		var tab := PixelUi.button(String(category["name"]), PixelUi.GOLD if is_current else PixelUi.MUTED)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size = Vector2(0, 18)
		PixelUi.on_press(tab, _show_category.bind(category_id))
		tabs.add_child(tab)
	return tabs


func _build_cell(category: Dictionary, entry_id: String) -> PanelContainer:
	var is_found := Codex.is_found(String(category["id"]), entry_id)
	var cell := PixelUi.panel(PixelUi.PANEL, PixelUi.GOLD.darkened(0.5) if is_found else PixelUi.PANEL_EDGE)
	cell.custom_minimum_size = CELL_SIZE
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(column)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(CELL_SIZE.x - 8.0, PICTURE_HEIGHT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(holder)
	_add_picture(holder, String(category["table"]), entry_id, is_found)
	var entry: Dictionary = GameData.table(String(category["table"]))[entry_id]
	var name_text := String(entry.get("name", entry_id)) if is_found else "???"
	var name_lines := PixelUi.small_lines(name_text, PixelUi.INK if is_found else PixelUi.MUTED, CELL_SIZE.x - 8.0, 2)
	for line_label: Node in name_lines.get_children():
		(line_label as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_lines)
	return cell


## 좀비는 걸어 다니는 그림, 무기·스킬은 아이콘. 못 만난 것은 검은 실루엣 (무엇이 남았는지 모양만 보이게)
func _add_picture(holder: Control, table_name: String, entry_id: String, is_found: bool) -> void:
	var center := Vector2((CELL_SIZE.x - 8.0) * 0.5, PICTURE_HEIGHT * 0.5)
	if table_name == "zombies":
		var zombie: Dictionary = GameData.entry("zombies", entry_id)
		var sprite := Sprite2D.new()
		sprite.texture = load("res://art/sprites/%s.png" % zombie.get("sprite", "zombie_" + entry_id))
		sprite.hframes = SpriteSheetLayout.COLUMNS
		sprite.vframes = SpriteSheetLayout.BOSS_ROW_COUNT if bool(zombie.get("is_boss", false)) else SpriteSheetLayout.ZOMBIE_ROW_COUNT
		sprite.scale = Vector2.ONE * (1.0 if int(zombie.get("frame_size", 16)) > 16 else 2.0)
		sprite.position = center
		sprite.modulate = Color.WHITE if is_found else SILHOUETTE
		holder.add_child(sprite)
		if is_found and not bool(zombie.get("is_boss", false)):
			_walking_sprites.append(sprite)
		return
	var icon_path := "res://art/sprites/icons/icon_%s.png" % entry_id
	if not ResourceLoader.exists(icon_path):
		var unknown := PixelUi.label("?", PixelUi.MUTED, false, true)
		unknown.position = center - Vector2(3, 7)
		holder.add_child(unknown)
		return
	var icon := PixelUi.icon("icon_" + entry_id, 3)
	icon.position = center - Vector2(15, 15)
	icon.modulate = Color.WHITE if is_found else SILHOUETTE
	holder.add_child(icon)


func _category(category_id: String) -> Dictionary:
	for category: Dictionary in Codex.categories():
		if String(category["id"]) == category_id:
			return category
	return {}
