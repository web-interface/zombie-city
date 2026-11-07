## [파일] scripts/run/run.gd
## [하는 일] 한 판(밤마다 3분, 헬기를 타면 다음 밤)의 지휘자: 각 부분을 준비해 RunContext 로 잇고, 한 순간(프레임)에 도는 순서를 한곳에서 정하고(문서 11 §5), 레벨 업·전직 창을 띄울 때를 고르고, 연속 처치·정예 보상·손맛 연출과 승패(밤 생존 → 다음 밤, 쓰러짐·헬기 놓침·포기 → 판 끝)를 처리한다.
## [쓰는 곳] scenes/run.tscn 의 맨 위 노드. SceneRouter 가 이 장면을 열고, 판이 끝나면 SceneRouter.finish_run() 을 부른다.
## [근거 문서] 11 §4·§5·§6, 14 §1 끝없는 밤·§4 중독 설계, 02 §9 승패, 13 조사 반영(멈춤·숨 돌리기·앱 나가면 멈춤)
extends Node2D

const END_DELAY_SECONDS := 1.6        # 쓰러진 뒤 결과 화면까지 (연출 보여 줄 시간)
const DEATH_SLOW_MOTION_SECONDS := 0.9
const DEATH_SLOW_MOTION_SCALE := 0.3

var context := RunContext.new()
var _is_over: bool = false
var _combo := KillCombo.new()
var _time_effects := TimeEffects.new()
var _night_flow := NightFlow.new()
var _rewards := RunRewards.new()
var _input := RunInput.new()
var _chatter := SurvivorChatter.new()
var _meta_hooks := RunMetaHooks.new()
var _night_director := NightDirector.new()

@onready var _survivor: Survivor = $World/Survivor
@onready var _horde: ZombieHorde = $World/ZombieHorde
@onready var _rack: WeaponRack = $World/WeaponRack
@onready var _extraction: Extraction = $World/Extraction
@onready var _skill_runner: SkillRunner = $Systems/SkillRunner
@onready var _spawner: ZombieSpawner = $Systems/ZombieSpawner
@onready var _events: HordeEvents = $Systems/HordeEvents
@onready var _level_up: LevelUp = $Systems/LevelUp
@onready var _promotion: Promotion = $Systems/Promotion
@onready var _boss_director: BossDirector = $Systems/BossDirector
@onready var _recorder: RunRecorder = $Systems/RunRecorder
@onready var _hud: Hud = $Hud


func _ready() -> void:
	add_child(_time_effects)
	_combo.setup()
	_build_context()
	_survivor.setup(SceneRouter.selected_survivor_id)
	var survivor_info := GameData.entry("survivors", _survivor.survivor_id)
	_rack.add_weapon(String(survivor_info["start_weapon"]))
	_skill_runner.setup(context, String(survivor_info["skill"]))
	_level_up.setup(context, _rack)
	_promotion.setup(context, _skill_runner)
	_spawner.setup(context, _night_director)
	_events.setup(context, _spawner)
	_boss_director.setup(context, _spawner)
	_night_director.setup(context, _spawner, _events, _boss_director)
	_recorder.setup(context)
	_extraction.setup(context)
	_hud.setup(context, _rack, _level_up, _promotion, _skill_runner, _extraction)
	_hud.watch_bosses(_boss_director)
	_hud.watch_night(_night_director)
	_rewards.setup(context, _hud, _level_up, _combo)
	_rewards.watch_build(_skill_runner, _time_effects)
	add_child(_night_flow)
	_night_flow.setup(context, {"hud": _hud, "recorder": _recorder, "level_up": _level_up, "combo": _combo, "rewards": _rewards, "skill_runner": _skill_runner,
		"night_systems": [_spawner, _events, _boss_director, _night_director, _extraction]})
	_connect_signals()
	_meta_hooks.setup(context, _hud, _level_up, _boss_director)   # 신호를 이은 뒤에 (시작 레벨 업도 기록·전직에 잡히게 — 검수 지적)
	SoundPlayer.start_run_music()
	_hud.start_first_run_hints(_skill_runner)
	var autoplay: Node = null
	if SceneRouter.is_autoplay():
		autoplay = preload("res://tools/autoplay.gd").new()
		add_child(autoplay)
		autoplay.setup(context, _hud, _level_up, _promotion, _skill_runner, _extraction)
	_input.setup(_hud, autoplay)
	_chatter.setup(context, $World/SpeechBubble, {"boss_director": _boss_director, "promotion": _promotion, "hud": _hud})


func _build_context() -> void:
	var world := $World
	context.survivor = _survivor
	context.horde = _horde
	context.projectiles = world.get_node("Projectiles")
	context.effects = world.get_node("Effects")
	context.lighting = world.get_node("Lighting")
	context.shards = world.get_node("VaccineShards")
	context.health_packs = world.get_node("HealthPacks")
	context.area_effects = world.get_node("AreaEffects")
	context.hazards = world.get_node("Hazards")
	context.pickups = world.get_node("Pickups")
	context.weather = $Weather
	context.props = world.get_node("Props")
	context.weapon_rack = _rack
	context.camera = $Camera
	context.night_cycle = NightCycle.new()
	context.light_rules = GameData.rules("lighting")
	context.juice_rules = GameData.rules("juice")
	context.status_rules = GameData.rules("status_effects")
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
	context.health_packs.setup(context)
	context.area_effects.setup(context)
	context.hazards.setup(context)
	context.pickups.setup(context)
	context.weather.setup(context)
	world.get_node("Shadows").setup(context)


func _connect_signals() -> void:
	_horde.zombie_died.connect(_on_zombie_died)
	context.shards.collected.connect(_level_up.add_experience)
	_level_up.level_changed.connect(_on_level_changed)
	_level_up.card_applied.connect(_recorder.note_card)
	_promotion.promoted.connect(_on_promoted)
	_boss_director.boss_appeared.connect(_on_alert_event)
	_boss_director.boss_defeated.connect(_on_boss_defeated)
	_boss_director.boss_enraged.connect(_on_alert_event)
	_events.event_started.connect(_on_alert_event)
	_recorder.watch_night(_night_director)
	_survivor.damaged.connect(_on_survivor_damaged)
	_survivor.died.connect(_on_survivor_died)
	_survivor.healed.connect(func(amount: float) -> void: context.effects.show_heal_number(_survivor.position, amount))
	_hud.give_up_requested.connect(_end_run.bind("gave_up"))
	_hud.next_night_requested.connect(_night_flow.start_next_night)
	_extraction.landing_zone_revealed.connect(_on_landing_zone_revealed)
	_extraction.helicopter_arrived.connect(_on_helicopter_arrived)
	_extraction.extracted.connect(_on_night_survived)
	_extraction.helicopter_left.connect(_on_helicopter_left)
	_skill_runner.used.connect(func(_skill_id: String) -> void: _recorder.note_event())


## 한 프레임에 도는 순서 (문서 11 §5) — 순서를 여기 한곳에서만 정한다.
func _physics_process(delta: float) -> void:
	if _is_over:
		_survivor.move_step(delta, Vector2.ZERO)
		context.camera.follow(_survivor.position, delta, Vector2.ZERO)
		return
	context.elapsed_seconds += delta
	context.run_seconds += delta
	_survivor.move_step(delta, _input.move_direction())                               # 1·2 입력 → 생존자
	_survivor.position = context.props.push_out(_survivor.position, 4.0)
	if _input.wants_skill():
		_skill_runner.try_use()
	_skill_runner.update(delta)
	_night_director.update(delta)                                                     # 3 박자·큰 일 → 좀비 나오기·이벤트
	_spawner.update(delta)
	_events.update(delta)
	_horde.update(delta)                                                              # 4 좀비 움직이기·특수 행동
	_boss_director.update(delta)
	context.hazards.update(delta)                                                     #   침·웅덩이·예고 원
	_rack.update(delta)                                                               # 5 무기
	context.projectiles.update(delta)                                                 # 6 투사체
	context.area_effects.update(delta)
	context.shards.update(delta)                                                      # 8 조각·구급함 줍기
	context.health_packs.update(delta)
	context.pickups.update(delta)
	_extraction.update(delta)                                                         # 9 규칙
	_open_choice_panels_if_due()
	context.lighting.update(delta)                                                    # 10 빛·그리기
	_combo.update(delta)
	_chatter.update(delta)
	_update_view(delta)
	_recorder.sample(_horde.alive_count())
	_update_music_danger()


## 전직 → 보물 상자 → 레벨 업 카드 차례. 헬기 버티기 중이나 보스 공격 중엔 미룬다 (흐름 끊지 않게 — 문서 13).
func _open_choice_panels_if_due() -> void:
	if _is_over or get_tree().paused or _extraction.phase == "landed" or _boss_director.is_boss_attacking():
		return
	if _promotion.open_choice_if_waiting() or _rewards.open_pending_chest() or _level_up.open_next_choice():
		get_tree().paused = true


func _update_view(delta: float) -> void:
	context.camera.follow(_survivor.position, delta, _survivor.moving_direction)
	var view_size := context.camera.view_size()
	$World/Ground.update(context.camera.global_position, view_size)
	context.props.update(context.camera.global_position)
	_hud.update_display(context.elapsed_seconds, _horde.alive_count(), _recorder.kills)
	_hud.update_run_status(context.night_cycle.night_name(), _combo.count, _combo.time_left_ratio())


## 위험도에 따라 밤 곡의 층을 더하고, 보스(분노)·헬기 때는 그 곡으로 바꾼다 (사용자 "BGM 도 계속 바뀌게")
func _update_music_danger() -> void:
	var boss_alive := _boss_director.alive_boss_count() > 0
	var danger := 1 if boss_alive or _horde.alive_count() > int(GameData.rules("music")["busy_horde_size"]) else 0
	if _survivor.health_ratio() < Survivor.LOW_HEALTH_RATIO or _extraction.phase == "landed":
		danger = 2
	SoundPlayer.set_music_danger(danger)
	var mode := "boss_rage" if _boss_director.is_any_boss_raging() else ("boss" if boss_alive else "night")
	SoundPlayer.set_music_mode("extraction" if _extraction.phase in ["revealed", "landed"] else mode)


func _on_zombie_died(zombie: Zombie) -> void:
	_recorder.note_kill(zombie)
	_combo.note_kill()
	context.shards.drop(zombie.position, zombie.shard_value)
	context.health_packs.maybe_drop(zombie.position)
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


## 보스 등장·포위·떼 돌진 같은 재난문자 알림
func _on_alert_event(banner_text: String) -> void:
	_recorder.note_event()
	_hud.show_banner(banner_text, "alert")


func _on_boss_defeated(seconds_to_kill: float, boss_name: String) -> void:
	_recorder.note_boss_kill(seconds_to_kill)
	_hud.show_banner("%s 처치! 카드 한 장 더" % boss_name, "good")
	context.play_sound("explosion")
	_play_boss_kill_moment()


## 보스 처치 순간: 잠깐 멈췄다가 → 느린 화면 → 원래 빠르기 (차례대로)
func _play_boss_kill_moment() -> void:
	await _time_effects.play(float(context.juice_rules["hit_stop_on_boss_kill_seconds"]), 0.0)
	await _time_effects.play(float(context.juice_rules["slow_motion_after_boss_kill_seconds"]), float(context.juice_rules["slow_motion_scale"]))
	_level_up.grant_bonus_choice()   # 연출이 끝난 뒤에 카드 (창 뒤로 연출이 묻히지 않게 — 검수 지적)


func _on_survivor_damaged(amount: float) -> void:
	_recorder.note_survivor_damaged(_extraction.phase == "landed")
	_combo.note_damage(amount)
	# 이보다 큰 한 방이면 흔들림·잠깐 멈춤·아픈 소리 (계속 닿는 작은 피해와 구분)
	if amount >= float(context.juice_rules["big_hit_damage"]):
		context.shake("survivor_big_hit")
		_time_effects.play(float(context.juice_rules["hit_stop_on_survivor_big_hit_seconds"]), 0.0)
		context.play_sound("survivor_hurt")
	else:
		context.camera.add_trauma(float(context.juice_rules["trauma_survivor_contact_per_second"]) * get_physics_process_delta_time())


func _on_survivor_died() -> void:
	if _meta_hooks.try_revive():
		return
	_hud.show_banner("물렸어요…", "alert")
	context.play_sound("game_over")
	_time_effects.play(DEATH_SLOW_MOTION_SECONDS, DEATH_SLOW_MOTION_SCALE)   # 쓰러지는 순간을 느리게 보여 준다
	_end_run("died")


func _on_landing_zone_revealed(_zone_position: Vector2) -> void:
	_recorder.note_event()
	_hud.show_banner("[새벽시청] 구조 헬기 접근 중. 착륙 지점으로 이동하세요", "alert")


func _on_helicopter_arrived() -> void:
	_recorder.note_event()
	_hud.show_banner("헬기 도착! 원 안에서 버텨요", "good")


func _on_helicopter_left() -> void:
	_hud.show_banner("헬기가 떠났어요…", "alert")
	_end_run("helicopter_left")


## 헬기를 탔다 → '밤 생존' 창 (시험 봇이 정한 밤 수를 채웠으면 판 끝)
func _on_night_survived() -> void:
	if not _is_over and _night_flow.on_night_survived():
		_end_run("test_night_limit")


## end_reason: "died"(쓰러짐) · "helicopter_left"(헬기 놓침) · "gave_up"(포기) · "test_night_limit"(시험)
func _end_run(end_reason: String) -> void:
	if _is_over:
		return
	_is_over = true
	_hud.on_run_over()
	var result := _recorder.build_result(end_reason, _level_up.level, _promotion.branch_name(), _combo.best)
	var delay := 0.05 if SceneRouter.is_autoplay() else END_DELAY_SECONDS
	await get_tree().create_timer(delay, true, false, true).timeout
	_time_effects.clear()
	SoundPlayer.stop_music()
	SceneRouter.finish_run(result)


## 앱을 나가거나 전화가 오면 바로 일시정지 (문서 12 §6, 13)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if not _is_over and not SceneRouter.is_autoplay() and is_node_ready():
			_hud.show_pause_menu()
