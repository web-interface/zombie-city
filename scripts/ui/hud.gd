## [파일] scripts/ui/hud.gd
## [하는 일] 한 판 화면 위 UI 묶음(CanvasLayer): 맞았을 때 가장자리 빨강·받은 피해 숫자(DamageVignette, 맨 아래 칸), 레벨 업 직전 '레벨 업!' 번쩍, 맨 위 정보 줄·앞으로 올 일 시간 줄, 조이스틱, 스킬 버튼, 알림 띠, 착륙 화살표, 레벨 업 창, 전직 창, 일시정지를 만들고 run.gd 와 이어 준다. 창을 고르면 멈춤을 푼다. 멈춘 동안에도 돌아간다.
## [쓰는 곳] scenes/run.tscn 의 Hud. run.gd 가 setup()·update_display()·show_banner() 를 부르고, 자동 플레이가 choose_card()·choose_branch() 를 부른다.
## [근거 문서] 05 화면 목록·게임 화면 배치, 11 §4
class_name Hud
extends CanvasLayer

## 일시정지 창에서 '포기하기'를 눌렀다 (run.gd 가 판을 끝낸다)
signal give_up_requested
signal next_night_requested
signal chest_claimed

const SKILL_BUTTON_MARGIN := Vector2(8, 16)
const LEVEL_UP_FLASH_SECONDS := 0.35
const LEVEL_UP_FLASH_SIZE := 22
## 첫 판 안내: (보여 줄 때, 사라질 때, 글) — 글 설명 대신 처음 몇 초에 자연스럽게 (문서 02 §12)
const FIRST_RUN_HINTS: Array[Array] = [
	[0.6, 4.6, "화면 아무 데나 끌어서 움직여요"],
	[5.2, 9.2, "공격은 자동! 오른쪽 아래는 스킬"],
	[10.0, 14.0, "초록 조각을 모으면 강해져요"],
]
## 터치 화면이 없는 PC 에서 보여 줄 안내 (키보드도 된다는 걸 알려 줌 — 마지막 검수)
const PC_RUN_HINTS: Array[Array] = [
	[0.6, 4.6, "WASD·방향키·끌기로 움직여요"],
	[5.2, 9.2, "공격은 자동! 스페이스는 스킬"],
	[10.0, 14.0, "초록 조각을 모으면 강해져요"],
]

var level_up_panel: LevelUpPanel
var promotion_panel: PromotionPanel
var night_clear_panel: NightClearPanel
var _boss_bar: BossHealthBar
var chest_panel: ChestPanel
var _top_bar: HudTopBar
var _timeline: NightTimeline
var _joystick: FloatingJoystick
var _skill_button: SkillButton
var _banner: Banner
var _pause_menu: PauseMenu
var _arrow: ExtractionArrow
var _run_seconds: float = 300.0
var _hint_label: Label
var _hint_time: float = -1.0
var _hints: Array[Array] = FIRST_RUN_HINTS


func setup(context: RunContext, rack: WeaponRack, level_up: LevelUp, promotion: Promotion, skill_runner: SkillRunner, extraction: Extraction) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_run_seconds = float(GameData.rules("extraction")["helicopter_arrive_second"])
	var root := PixelUi.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_play_parts(root, context, rack, level_up, skill_runner, extraction)
	_build_windows(root, rack, level_up, promotion)


## 판 중 늘 보이는 것: 조이스틱·위 표시줄·보스 체력 줄·착륙 화살표·알림 띠·스킬 버튼·컷인
func _build_play_parts(root: Control, context: RunContext, rack: WeaponRack, level_up: LevelUp, skill_runner: SkillRunner, extraction: Extraction) -> void:
	var vignette := DamageVignette.new()   # 맨 아래 칸: 적 테두리 위, 다른 HUD 아래 (문서 15 §7-2)
	root.add_child(vignette)
	vignette.setup(context)
	_joystick = FloatingJoystick.new()
	root.add_child(_joystick)
	_top_bar = HudTopBar.new()
	root.add_child(_top_bar)
	_top_bar.setup(context, level_up, rack)
	_timeline = NightTimeline.new()
	root.add_child(_timeline)
	_boss_bar = BossHealthBar.new()
	root.add_child(_boss_bar)
	_arrow = ExtractionArrow.new()
	root.add_child(_arrow)
	_arrow.setup(context, extraction)
	_banner = Banner.new()
	_banner.process_mode = Node.PROCESS_MODE_PAUSABLE   # 창이 떠 있는 동안 알림 시간이 흘러 못 보고 지나가지 않게
	root.add_child(_banner)
	_skill_button = SkillButton.new()
	root.add_child(_skill_button)
	_skill_button.setup(skill_runner)
	_skill_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skill_button.offset_left = -SkillButton.SIZE - SKILL_BUTTON_MARGIN.x
	_skill_button.offset_top = -SkillButton.SIZE - SKILL_BUTTON_MARGIN.y
	_skill_button.offset_right = -SKILL_BUTTON_MARGIN.x
	_skill_button.offset_bottom = -SKILL_BUTTON_MARGIN.y
	root.add_child(SkillCutin.create(skill_runner, context))   # 히든 스킬 컷인 (문서 14 §2-5)


## 멈추고 뜨는 창: 멈춤 메뉴·레벨 업 카드·전직·밤 생존·보물 상자
func _build_windows(root: Control, rack: WeaponRack, level_up: LevelUp, promotion: Promotion) -> void:
	_pause_menu = PauseMenu.new()
	root.add_child(_pause_menu)
	_pause_menu.setup(promotion, rack)
	_pause_menu.give_up_requested.connect(func() -> void: give_up_requested.emit())
	_pause_menu.is_other_window_open = _is_choice_window_open
	level_up_panel = LevelUpPanel.new()
	root.add_child(level_up_panel)
	level_up_panel.setup(level_up)
	level_up_panel.closed.connect(_on_choice_closed)
	promotion_panel = PromotionPanel.new()
	root.add_child(promotion_panel)
	promotion_panel.setup(promotion)
	promotion_panel.closed.connect(_on_choice_closed)
	night_clear_panel = NightClearPanel.new()
	root.add_child(night_clear_panel)
	night_clear_panel.setup()
	night_clear_panel.next_requested.connect(_on_night_continue)
	chest_panel = ChestPanel.new()
	root.add_child(chest_panel)
	chest_panel.setup()
	chest_panel.claimed.connect(_on_chest_claimed)


## 이번에 켠 뒤 첫 판이면 처음 몇 초 동안 조작 안내를 차례로 보여 준다.
func start_first_run_hints(_skill_runner: SkillRunner) -> void:
	if SceneRouter.has_seen_first_run_hints or SceneRouter.is_autoplay():
		return
	SceneRouter.has_seen_first_run_hints = true
	_hints = FIRST_RUN_HINTS if DisplayServer.is_touchscreen_available() else PC_RUN_HINTS
	_hint_label = PixelUi.label("", PixelUi.INK)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top = -76.0
	_hint_label.offset_bottom = -60.0
	get_child(0).add_child(_hint_label)
	_hint_time = 0.0


func _process(delta: float) -> void:
	if _hint_time < 0.0:
		return
	_hint_label.visible = not get_tree().paused   # 카드 창 위에 안내 글이 겹쳐 보이지 않게
	if get_tree().paused:
		return
	_hint_time += delta
	var shown := ""
	for hint: Array in _hints:
		if _hint_time >= float(hint[0]) and _hint_time < float(hint[1]):
			shown = String(hint[2])
	_hint_label.text = shown
	_hint_label.modulate.a = 0.6 + 0.4 * absf(sin(_hint_time * 3.0))
	if _hint_time > float(_hints.back()[1]):
		_hint_label.queue_free()
		_hint_time = -1.0


## 레벨 업 창 직전(0.15초 느린 화면 동안) 가운데 큰 '레벨 업!'이 번쩍 — 창이 왜 뜨는지 먼저 알게 (문서 15 §8)
func flash_level_up() -> void:
	var flash := PixelUi.label("레벨 업!", PixelUi.GOOD, false, true)
	flash.add_theme_font_size_override("font_size", LEVEL_UP_FLASH_SIZE)
	flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	flash.offset_top = get_viewport().get_visible_rect().size.y * 0.3
	flash.grow_horizontal = Control.GROW_DIRECTION_BOTH
	get_child(0).add_child(flash)
	var tween := flash.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	tween.tween_property(flash, "modulate:a", 0.0, LEVEL_UP_FLASH_SECONDS).set_delay(LEVEL_UP_FLASH_SECONDS * 0.4)
	tween.tween_callback(flash.queue_free)


func joystick_direction() -> Vector2:
	return _joystick.direction


func consume_skill_press() -> bool:
	return _skill_button.consume_press()


func update_display(elapsed_seconds: float, _alive_zombies: int, kills: int) -> void:
	_top_bar.refresh(_run_seconds - elapsed_seconds, kills, get_physics_process_delta_time())


## 보스 체력 줄이 볼 보스 담당 (run.gd 가 준비 뒤 부름)
func watch_bosses(director: BossDirector) -> void:
	_boss_bar.watch(director)


## 위쪽 시간 줄이 볼 밤 감독 (앞으로 올 정예·보스·헬기)
func watch_night(director: NightDirector) -> void:
	_timeline.watch(director)


## 위 표시줄의 '둘째 밤'·연속 처치
func update_run_status(night_name: String, combo_count: int, combo_time_ratio: float) -> void:
	_top_bar.set_run_status(night_name, combo_count, combo_time_ratio)


## 헬기를 타면 run.gd 가 부른다 (멈춘 채로 뜸)
func open_night_clear(summary: Dictionary) -> void:
	_joystick.release()
	night_clear_panel.open(summary)


## 보물 상자 슬롯 창 (run.gd 가 이미 멈춘 뒤 부름)
func open_chest(cards: Array, count: int) -> void:
	_joystick.release()
	chest_panel.open(cards, count)


## 자동 플레이 봇용
func continue_night() -> void:
	night_clear_panel.press_next()


func show_banner(text: String, style_name: String) -> void:
	_banner.show_message(text, style_name)


## 카드·전직 창이 떠 있으면 이미 멈춰 있으니 일시정지 창을 겹쳐 열지 않는다 (검수 지적)
func show_pause_menu() -> void:
	if _is_choice_window_open():
		return
	_joystick.release()
	_pause_menu.open()


## 판이 끝나면 run.gd 가 부른다: 결과 화면으로 넘어가는 동안 멈춤 버튼을 숨김
func on_run_over() -> void:
	_pause_menu.hide_button()


func _is_choice_window_open() -> bool:
	return level_up_panel.is_open() or promotion_panel.is_open() or night_clear_panel.is_open() or chest_panel.is_open()


func choose_card(index: int) -> void:
	level_up_panel.choose(index)


func choose_branch(index: int) -> void:
	promotion_panel.choose(index)


func _on_choice_closed() -> void:
	_joystick.release()
	get_tree().paused = false


func _on_chest_claimed() -> void:
	_joystick.release()
	get_tree().paused = false
	chest_claimed.emit()


func _on_night_continue() -> void:
	_joystick.release()
	get_tree().paused = false
	next_night_requested.emit()
