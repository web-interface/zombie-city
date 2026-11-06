## [파일] scripts/ui/hud.gd
## [하는 일] 한 판 화면 위 UI 묶음(CanvasLayer): 맨 위 정보 줄, 조이스틱, 스킬 버튼, 알림 띠, 착륙 화살표, 레벨 업 창, 전직 창, 일시정지를 만들고 run.gd 와 이어 준다. 창을 고르면 멈춤을 푼다. 멈춘 동안에도 돌아간다.
## [쓰는 곳] scenes/run.tscn 의 Hud. run.gd 가 setup()·update_display()·show_banner() 를 부르고, 자동 플레이가 choose_card()·choose_branch() 를 부른다.
## [근거 문서] 05 화면 목록·게임 화면 배치, 11 §4
class_name Hud
extends CanvasLayer

const SKILL_BUTTON_MARGIN := Vector2(8, 16)

var level_up_panel: LevelUpPanel
var promotion_panel: PromotionPanel
var _top_bar: HudTopBar
var _joystick: FloatingJoystick
var _skill_button: SkillButton
var _banner: Banner
var _pause_menu: PauseMenu
var _arrow: ExtractionArrow
var _run_seconds: float = 300.0


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
