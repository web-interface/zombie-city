## [파일] scripts/ui/hud.gd
## [하는 일] 한 판 화면 위 UI 묶음(CanvasLayer): 맨 위 정보 줄, 조이스틱, 스킬 버튼, 알림 띠, 착륙 화살표, 레벨 업 창, 전직 창, 일시정지를 만들고 run.gd 와 이어 준다. 창을 고르면 멈춤을 푼다. 멈춘 동안에도 돌아간다.
## [쓰는 곳] scenes/run.tscn 의 Hud. run.gd 가 setup()·update_display()·show_banner() 를 부르고, 자동 플레이가 choose_card()·choose_branch() 를 부른다.
## [근거 문서] 05 화면 목록·게임 화면 배치, 11 §4
class_name Hud
extends CanvasLayer

const SKILL_BUTTON_MARGIN := Vector2(8, 16)
## 첫 판 안내: (보여 줄 때, 사라질 때, 글) — 글 설명 대신 처음 몇 초에 자연스럽게 (문서 02 §12)
const FIRST_RUN_HINTS: Array[Array] = [
	[0.6, 4.6, "화면 아무 데나 끌어서 움직여요"],
	[5.2, 9.2, "공격은 자동! 오른쪽 아래는 스킬"],
	[10.0, 14.0, "초록 조각을 모으면 강해져요"],
]

var level_up_panel: LevelUpPanel
var promotion_panel: PromotionPanel
var _top_bar: HudTopBar
var _joystick: FloatingJoystick
var _skill_button: SkillButton
var _banner: Banner
var _pause_menu: PauseMenu
var _arrow: ExtractionArrow
var _run_seconds: float = 300.0
var _hint_label: Label
var _hint_time: float = -1.0


func setup(context: RunContext, rack: WeaponRack, level_up: LevelUp, promotion: Promotion, skill_runner: SkillRunner, extraction: Extraction) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_run_seconds = float(GameData.rules("extraction")["helicopter_arrive_second"])
	var root := PixelUi.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_joystick = FloatingJoystick.new()
	root.add_child(_joystick)
	_top_bar = HudTopBar.new()
	root.add_child(_top_bar)
	_top_bar.setup(context, level_up, rack)
	_arrow = ExtractionArrow.new()
	root.add_child(_arrow)
	_arrow.setup(context, extraction)
	_banner = Banner.new()
	root.add_child(_banner)
	_skill_button = SkillButton.new()
	root.add_child(_skill_button)
	_skill_button.setup(skill_runner)
	_skill_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skill_button.offset_left = -SkillButton.SIZE - SKILL_BUTTON_MARGIN.x
	_skill_button.offset_top = -SkillButton.SIZE - SKILL_BUTTON_MARGIN.y
	_skill_button.offset_right = -SKILL_BUTTON_MARGIN.x
	_skill_button.offset_bottom = -SKILL_BUTTON_MARGIN.y
	_pause_menu = PauseMenu.new()
	root.add_child(_pause_menu)
	_pause_menu.setup(promotion, rack)
	_pause_menu.give_up_requested.connect(func() -> void: context.survivor.take_damage(99999.0, "포기"))
	level_up_panel = LevelUpPanel.new()
	root.add_child(level_up_panel)
	level_up_panel.setup(level_up)
	level_up_panel.closed.connect(_on_choice_closed)
	promotion_panel = PromotionPanel.new()
	root.add_child(promotion_panel)
	promotion_panel.setup(promotion)
	promotion_panel.closed.connect(_on_choice_closed)


## 이번에 켠 뒤 첫 판이면 처음 몇 초 동안 조작 안내를 차례로 보여 준다.
func start_first_run_hints(_skill_runner: SkillRunner) -> void:
	if SceneRouter.has_seen_first_run_hints or SceneRouter.is_autoplay():
		return
	SceneRouter.has_seen_first_run_hints = true
	_hint_label = PixelUi.label("", PixelUi.INK)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top = -76.0
	_hint_label.offset_bottom = -60.0
	get_child(0).add_child(_hint_label)
	_hint_time = 0.0


func _process(delta: float) -> void:
	if _hint_time < 0.0 or get_tree().paused:
		return
	_hint_time += delta
	var shown := ""
	for hint: Array in FIRST_RUN_HINTS:
		if _hint_time >= float(hint[0]) and _hint_time < float(hint[1]):
			shown = String(hint[2])
	_hint_label.text = shown
	_hint_label.modulate.a = 0.6 + 0.4 * absf(sin(_hint_time * 3.0))
	if _hint_time > float(FIRST_RUN_HINTS.back()[1]):
		_hint_label.queue_free()
		_hint_time = -1.0


func joystick_direction() -> Vector2:
	return _joystick.direction


func consume_skill_press() -> bool:
	return _skill_button.consume_press()


func update_display(elapsed_seconds: float, _alive_zombies: int, kills: int) -> void:
	_top_bar.refresh(_run_seconds - elapsed_seconds, kills, get_physics_process_delta_time())


func show_banner(text: String, style_name: String) -> void:
	_banner.show_message(text, style_name)


func show_pause_menu() -> void:
	_joystick.release()
	_pause_menu.open()


func choose_card(index: int) -> void:
	level_up_panel.choose(index)


func choose_branch(index: int) -> void:
	promotion_panel.choose(index)


func _on_choice_closed() -> void:
	_joystick.release()
	get_tree().paused = false
