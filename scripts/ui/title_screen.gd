## [파일] scripts/ui/title_screen.gd
## [하는 일] 타이틀 화면: 밤거리 바닥 위로 좀비 몇 마리가 비틀거리며 지나가고, 가로등이 깜빡이고, 게임 이름과 "화면을 눌러 시작"을 보여 준다. 누르면 생존자 고르기로 간다. 자동 플레이면 바로 넘어간다.
## [쓰는 곳] scenes/title.tscn (게임을 켜면 처음 여는 장면).
## [근거 문서] 05 화면 목록(타이틀), 04 §1 설정, 06 밤 분위기
extends Control

const ZOMBIE_SHEETS: Array[String] = ["zombie_walker", "zombie_runner", "zombie_hazmat"]
const WALKING_ZOMBIES := 5

var _time: float = 0.0
var _zombies: Array[Sprite2D] = []
var _press_label: Label


func _ready() -> void:
	PixelUi.full_rect(self)
	SoundPlayer.play_single_music("music_title")
	if SceneRouter.is_autoplay():
		SceneRouter.start_run(SceneRouter.selected_survivor_id)
		return
	_build()


func _build() -> void:
	for index: int in range(WALKING_ZOMBIES):
		var zombie := Sprite2D.new()
		zombie.texture = load("res://art/sprites/%s.png" % ZOMBIE_SHEETS[index % ZOMBIE_SHEETS.size()])
		zombie.hframes = SpriteSheetLayout.COLUMNS
		zombie.vframes = SpriteSheetLayout.ZOMBIE_ROW_COUNT
		zombie.position = Vector2(randf_range(-40.0, 200.0), 190.0 + index * 22.0)
		zombie.modulate = Color(0.55, 0.6, 0.75)
		add_child(zombie)
		_zombies.append(zombie)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var small_title := PixelUi.label("새벽시의 마지막 밤", PixelUi.MUTED, true)
	small_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(small_title)
	var title := PixelUi.label("좀비 도시", PixelUi.INK, false, true)
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := PixelUi.label("구조 헬기까지 5분", PixelUi.GOLD)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	var top_area := PixelUi.centered(column)
	top_area.offset_bottom = -120.0
	add_child(top_area)
	_press_label = PixelUi.label("화면을 눌러 시작", PixelUi.INK)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_press_label.offset_top = -40.0
	_press_label.offset_bottom = -24.0
	add_child(_press_label)


func _process(delta: float) -> void:
	_time += delta
	if _press_label != null:
		_press_label.modulate.a = 0.45 + 0.55 * absf(sin(_time * 2.2))
	for index: int in range(_zombies.size()):
		var zombie := _zombies[index]
		zombie.position.x += (6.0 + index * 1.5) * delta
		if zombie.position.x > 200.0:
			zombie.position.x = -20.0
		zombie.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.ZOMBIE_ROWS, "walk_side", int(_time * 5.0 + index))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0f1117"))   # 배경 (자식 노드보다 먼저 그려져 가로등 빛을 가리지 않게 여기서)
	# 가로등 하나가 가끔 깜빡인다 (계단식 빛 원 세 겹)
	var is_on := fmod(_time, 3.1) > 0.18
	var lamp := Vector2(size.x * 0.72, 176.0)
	if is_on:
		for step: int in range(3):
			draw_circle(lamp, 34.0 - step * 10.0, Color(1.0, 0.85, 0.55, 0.05 + step * 0.04))
	draw_rect(Rect2(lamp - Vector2(1, 1), Vector2(3, 3)), Color("f0e3a0") if is_on else Color("5a5440"))
	draw_rect(Rect2(0, 224, size.x, 1), Color("2a2f3b"))


func _gui_input(event: InputEvent) -> void:
	var is_press := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if is_press:
		SoundPlayer.play("ui_click")
		SceneRouter.go_to_survivor_select()
