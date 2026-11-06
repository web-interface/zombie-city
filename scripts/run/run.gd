## [파일] scripts/run/run.gd
## [하는 일] 한 판(5분)의 지휘자: 각 부분을 준비해 RunContext 로 잇고, 한 순간(프레임)에 도는 순서를 한곳에서 정하고(문서 11 §5), 레벨 업·전직 창을 띄울 때를 고르고, 잠깐 멈춤·느린 화면 같은 손맛과 승패(탈출·쓰러짐·헬기 떠남)를 처리한다.
## [쓰는 곳] scenes/run.tscn 의 맨 위 노드. SceneRouter 가 이 장면을 열고, 판이 끝나면 SceneRouter.finish_run() 을 부른다.
## [근거 문서] 11 §4·§5·§6, 02 §3 시간표·§9 승패, 13 조사 반영(멈춤·숨 돌리기·앱 나가면 멈춤)
extends Node2D

const END_DELAY_SECONDS := 1.6        # 쓰러지거나 탈출한 뒤 결과 화면까지 (연출 보여 줄 시간)
const DANGER_HEALTH_RATIO := 0.35
const DEATH_SLOW_MOTION_SECONDS := 0.9
const DEATH_SLOW_MOTION_SCALE := 0.3

var context := RunContext.new()
var _is_over: bool = false
var _base_time_scale: float = 1.0
var _autoplay: Node = null

@onready var _survivor: Survivor = $World/Survivor
@onready var _horde: ZombieHorde = $World/ZombieHorde
@onready var _rack: WeaponRack = $World/WeaponRack
@onready var _extraction: Extraction = $World/Extraction
@onready var _skill_runner: SkillRunner = $Systems/SkillRunner
@onready var _spawner: ZombieSpawner = $Systems/ZombieSpawner
@onready var _level_up: LevelUp = $Systems/LevelUp
@onready var _promotion: Promotion = $Systems/Promotion
@onready var _boss_director: BossDirector = $Systems/BossDirector
@onready var _recorder: RunRecorder = $Systems/RunRecorder
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_base_time_scale = Engine.time_scale
	_build_context()
	_survivor.setup(SceneRouter.selected_survivor_id)
	var survivor_info := GameData.entry("survivors", _survivor.survivor_id)
	_rack.add_weapon(String(survivor_info["start_weapon"]))
	_skill_runner.setup(context, String(survivor_info["skill"]))
	_level_up.setup(context, _rack)
	_promotion.setup(context, _skill_runner)
	_spawner.setup(context)
	_boss_director.setup(context)
	_recorder.setup(context)
	_extraction.setup(context)
	_hud.setup(context, _rack, _level_up, _promotion, _skill_runner, _extraction)
	_connect_signals()
	SoundPlayer.start_run_music()
	_hud.start_first_run_hints(_skill_runner)
	if SceneRouter.is_autoplay():
		_autoplay = preload("res://tools/autoplay.gd").new()
		add_child(_autoplay)
		_autoplay.setup(context, _hud, _level_up, _promotion, _skill_runner, _extraction)


func _build_context() -> void:
	var world := $World
	context.survivor = _survivor
	context.horde = _horde
	context.projectiles = world.get_node("Projectiles")
	context.effects = world.get_node("Effects")
	context.lighting = world.get_node("Lighting")
	context.shards = world.get_node("VaccineShards")
	context.area_effects = world.get_node("AreaEffects")
	context.props = world.get_node("Props")
	context.camera = $Camera
	context.light_rules = GameData.rules("lighting")
	context.juice_rules = GameData.rules("juice")
	context.spawn_distance = float(GameData.table("spawn_curve")["spawn_distance"])
	context.camera.setup(context.juice_rules)
	context.effects.setup(int(context.juice_rules["max_damage_numbers"]))
	context.lighting.setup(context)
	context.props.setup(context, GameData.rules("city_layout"))
	world.get_node("Ground").setup(GameData.rules("city_layout"))
	_horde.setup(context)
	_rack.setup(context)
	context.projectiles.setup(context)
	context.shards.setup(context)
	context.area_effects.setup(context)
	world.get_node("Shadows").setup(context)


func _connect_signals() -> void:
	_horde.zombie_died.connect(_on_zombie_died)
	context.shards.collected.connect(_level_up.add_experience)
	_level_up.level_changed.connect(_on_level_changed)
	_level_up.card_applied.connect(_recorder.note_card)
	_promotion.promoted.connect(_on_promoted)
	_boss_director.boss_appeared.connect(_on_boss_appeared)
	_boss_director.boss_defeated.connect(_on_boss_defeated)
	_survivor.damaged.connect(_on_survivor_damaged)
	_survivor.died.connect(_on_survivor_died)
	_extraction.landing_zone_revealed.connect(_on_landing_zone_revealed)
	_extraction.helicopter_arrived.connect(_on_helicopter_arrived)
	_extraction.extracted.connect(_end_run.bind(true))
	_extraction.helicopter_left.connect(_on_helicopter_left)
	_skill_runner.used.connect(func(_skill_id: String) -> void: _recorder.note_event())


## 한 프레임에 도는 순서 (문서 11 §5) — 순서를 여기 한곳에서만 정한다.
func _physics_process(delta: float) -> void:
	if _is_over:
		_survivor.move_step(delta, Vector2.ZERO)
		context.camera.follow(_survivor.position, delta, Vector2.ZERO)
		return
	context.elapsed_seconds += delta
	_survivor.move_step(delta, _read_move_input())                                   # 1·2 입력 → 생존자
	_survivor.position = context.props.push_out(_survivor.position, 4.0)
	if _wants_skill():
		_skill_runner.try_use()
	_skill_runner.update(delta)
	_spawner.update(delta)                                                            # 3 좀비 나오기
	_horde.update(delta)                                                              # 4 좀비 움직이기
	_boss_director.update(delta)
	_rack.update(delta)                                                               # 5 무기
	context.projectiles.update(delta)                                                 # 6 투사체
	context.area_effects.update(delta)
	context.shards.update(delta)                                                      # 8 조각 줍기
	_extraction.update(delta)                                                         # 9 규칙
	_open_choice_panels_if_due()
	context.lighting.update(delta)                                                    # 10 빛·그리기
	_update_view(delta)
	_recorder.sample(_horde.alive_count())
	_update_music_danger()


func _read_move_input() -> Vector2:
	if _autoplay != null:
		return _autoplay.move_direction()
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wasd := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	var keys := (keyboard + wasd).limit_length(1.0)
	return keys if keys.length() > 0.0 else _hud.joystick_direction()


func _wants_skill() -> bool:
	if _autoplay != null:
		return _autoplay.wants_skill()
	return Input.is_key_pressed(KEY_SPACE) or _hud.consume_skill_press()


## 전직을 먼저, 그다음 레벨 업 카드. 헬기 버티기 중이나 보스 돌진 중엔 미룬다 (흐름 끊지 않게 — 문서 13).
func _open_choice_panels_if_due() -> void:
	if get_tree().paused or _extraction.phase == "landed" or _is_boss_attacking():
		return
	if _promotion.open_choice_if_waiting() or _level_up.open_next_choice():
		get_tree().paused = true


func _is_boss_attacking() -> bool:
	for zombie: Zombie in _horde.zombies:
		if zombie.is_boss and (zombie.boss_state.get("is_warning", false) or zombie.boss_state.get("is_charging", false)):
			return true
	return false


## 창에서 고르고 나면 HUD 가 부른다.
func resume_after_choice() -> void:
	get_tree().paused = false


func _update_view(delta: float) -> void:
	context.camera.follow(_survivor.position, delta, _survivor.moving_direction)
	var view_size := context.camera.view_size()
	$World/Ground.update(context.camera.global_position, view_size)
	context.props.update(context.camera.global_position)
	_hud.update_display(context.elapsed_seconds, _horde.alive_count(), _recorder.kills)


func _update_music_danger() -> void:
	var danger := 0
	if _boss_director.alive_boss_count() > 0 or _horde.alive_count() > 150:
		danger = 1
	if _survivor.health_ratio() < DANGER_HEALTH_RATIO or _extraction.phase == "landed":
		danger = 2
	SoundPlayer.set_music_danger(danger)


func _on_zombie_died(zombie: Zombie) -> void:
	_recorder.note_kill()
	context.shards.drop(zombie.position, zombie.shard_value)
	context.effects.burst(zombie.position, Color("6f9a52") if randf() < 0.5 else Color("a5c46a"), 5)
	context.play_sound("zombie_die")


func _on_level_changed(new_level: int) -> void:
	_recorder.note_level_up()
	_promotion.on_level_changed(new_level)
	context.effects.ring(_survivor.position, 26.0, Color("8ff59a"), 0.45)


func _on_promoted(branch_id: String, stage: int) -> void:
	_recorder.note_promotion(stage)
	var branch_name := String(GameData.entry("promotions", branch_id)["name"])
	_hud.show_banner("%s %s!" % [branch_name, "전직" if stage == 1 else "각성"], "promotion")


func _on_boss_appeared(banner_text: String) -> void:
	_recorder.note_event()
	_hud.show_banner(banner_text, "alert")


func _on_boss_defeated(seconds_to_kill: float) -> void:
	_recorder.note_boss_kill(seconds_to_kill)
	_level_up.grant_bonus_choice()
	_spawner.start_calm()
	_hud.show_banner("도살자 처치! 카드 한 장 더", "good")
	context.play_sound("explosion")
	_play_boss_kill_moment()


## 보스 처치 순간: 잠깐 멈췄다가 → 느린 화면 → 원래 빠르기 (차례대로)
func _play_boss_kill_moment() -> void:
	await _play_hit_stop(float(context.juice_rules["hit_stop_on_boss_kill_seconds"]), 0.0)
	await _play_hit_stop(float(context.juice_rules["slow_motion_after_boss_kill_seconds"]), float(context.juice_rules["slow_motion_scale"]))


func _on_survivor_damaged(amount: float) -> void:
	_recorder.note_survivor_damaged(_extraction.phase == "landed")
	if amount >= 10.0:
		context.shake("survivor_big_hit")
		_play_hit_stop(float(context.juice_rules["hit_stop_on_survivor_big_hit_seconds"]), 0.0)
		context.play_sound("survivor_hurt")
	else:
		context.camera.add_trauma(float(context.juice_rules["trauma_survivor_contact_per_second"]) * get_physics_process_delta_time())


func _on_survivor_died() -> void:
	_hud.show_banner("물렸어요…", "alert")
	context.play_sound("game_over")
	_play_hit_stop(DEATH_SLOW_MOTION_SECONDS, DEATH_SLOW_MOTION_SCALE)   # 쓰러지는 순간을 느리게 보여 준다
	_end_run(false)


func _on_landing_zone_revealed(_zone_position: Vector2) -> void:
	_recorder.note_event()
	_hud.show_banner("[새벽시청] 구조 헬기 접근 중. 착륙 지점으로 이동하세요", "alert")


func _on_helicopter_arrived() -> void:
	_recorder.note_event()
	_spawner.is_extraction_rush = true
	_hud.show_banner("헬기 도착! 원 안에서 버텨요", "good")


func _on_helicopter_left() -> void:
	_hud.show_banner("헬기가 떠났어요…", "alert")
	_end_run(false)


func _end_run(is_escaped: bool) -> void:
	if _is_over:
		return
	_is_over = true
	if is_escaped:
		_hud.show_banner("구조 성공!", "good")
	var result := _recorder.build_result(is_escaped, _level_up.level, _promotion.branch_name())
	var delay := 0.05 if SceneRouter.is_autoplay() else END_DELAY_SECONDS
	await get_tree().create_timer(delay, true, false, true).timeout
	Engine.time_scale = _base_time_scale
	SoundPlayer.stop_music()
	SceneRouter.finish_run(result)


## 잠깐 멈춤(scale 0)이나 느린 화면(scale 0.3)을 seconds 동안. 실제 시간으로 잰다 (게임 시간은 멈춰 있으니까).
func _play_hit_stop(seconds: float, scale: float) -> void:
	if SceneRouter.is_autoplay() or seconds <= 0.0:
		return
	Engine.time_scale = _base_time_scale * maxf(scale, 0.01)
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = _base_time_scale


## 앱을 나가거나 전화가 오면 바로 일시정지 (문서 12 §6, 13)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if not _is_over and not SceneRouter.is_autoplay() and is_node_ready():
			_hud.show_pause_menu()
