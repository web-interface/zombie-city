## [파일] tools/autoplay.gd
## [하는 일] 자동 플레이 봇(초보·보통·고수): 사람 대신 움직이고(좀비 피하기·조각 줍기·가로등 빛 이용·보스 돌진 피하기·착륙 지점 가기), 레벨 업 카드·전직 갈래·스킬을 고른다. --capture=폴더 를 주면 정해진 순간마다 화면을 저장한다.
## [쓰는 곳] scripts/run/run.gd 가 명령줄에 --autoplay 가 있으면 만든다. 예: Godot --path . --fixed-fps 60 -- --autoplay=보통 --survivor=police --branch=random --runs=20 --stats=tools/out/balance/police.jsonl
## [근거 문서] 12 §4 봇 실력 3단계·돌리는 법, 07 시험 방법
extends Node

const DANGER_RADIUS := 70.0
const SHARD_SEARCH_RADIUS := 90.0
const ZONE_WAIT_DISTANCE := 45.0       # 헬기 오기 전엔 착륙 원 바깥 이 거리에서 기다린다 (원 안 좀비 떼에 미리 갇히지 않게)
const ZONE_ENTER_SECONDS_BEFORE := 12.0 # 헬기 도착 이 초 전부터 원 안으로
const HEAL_SEEK_HEALTH_RATIO := 0.6    # 체력이 이보다 낮으면 구급함을 먼저 주우러
const MELEE_KEEP_DISTANCE := 18.0     # 근접 무기는 좀비와 이 정도 거리를 유지해야 닿는다
const MELEE_BRAVE_HEALTH_RATIO := 0.5 # 체력이 이보다 많으면 과감하게, 적으면 조심스럽게 (그래도 싸움은 계속 — 도망만 치면 조각·구급함이 안 생겨 판 내내 못 살아남)
const ZONE_SLOW_DOWN_DISTANCE := 30.0 # 기다리는 자리에 이만큼 가까워지면 끌림을 줄여 좀비 피하기가 이기게
const BOSS_ENGAGE_DISTANCE := 75.0    # 원거리 무기는 보스와 이 거리 안을 지킨다 (네일건 사거리 100 보다 안쪽)
const NORMAL_REACTION_SECONDS := 0.15 # 보통은 방향을 0.15초마다 다시 정한다 (매 프레임 완벽하게 피하는 건 사람 같지 않음)
const CAPTURE_SECONDS: Array[float] = [4.0, 45.0, 95.0, 150.0, 215.0, 268.0, 302.0]

var skill_level: String = "보통"
var _context: RunContext
var _hud: Hud
var _level_up: LevelUp
var _promotion: Promotion
var _skill_runner: SkillRunner
var _extraction: Extraction
var _decision_delay: float = 0.0
var _reaction_direction: Vector2 = Vector2.ZERO
var _reaction_timer: float = 0.0
var _wander_angle: float = randf() * TAU
var _capture_folder: String = ""
var _captured: Dictionary = {}


func setup(context: RunContext, hud: Hud, level_up: LevelUp, promotion: Promotion, skill_runner: SkillRunner, extraction: Extraction) -> void:
	_context = context
	_hud = hud
	_level_up = level_up
	_promotion = promotion
	_skill_runner = skill_runner
	_extraction = extraction
	process_mode = Node.PROCESS_MODE_ALWAYS
	var option := String(SceneRouter.test_options.get("autoplay", "보통"))
	skill_level = {"beginner": "초보", "normal": "보통", "expert": "고수", "true": "보통"}.get(option, option)
	_capture_folder = String(SceneRouter.test_options.get("capture", ""))


## 매 프레임 run.gd 가 묻는 이동 방향
func move_direction() -> Vector2:
	if _context.survivor.is_dead:
		return Vector2.ZERO
	var wanted := _danger_escape() * _escape_weight() + _goal_pull() + Vector2.from_angle(_wander_angle) * 0.25
	if _is_melee_fighter() and not _is_heading_to_zone():
		wanted += _melee_approach() * (1.0 if _context.survivor.health_ratio() > MELEE_BRAVE_HEALTH_RATIO else 0.6)
	elif skill_level != "초보" and not _is_heading_to_zone():
		wanted += _boss_engage() * 0.7
	if skill_level == "고수":
		wanted += _boss_dodge() * 2.5 + _light_pull() * 0.5
	_wander_angle += randf_range(-0.3, 0.3)
	match skill_level:
		"초보":
			return _react_late(wanted, 0.5, 0.1)   # 초보는 0.5초 늦고, 10%는 멍하니 선다
		"보통":
			return _react_late(wanted, NORMAL_REACTION_SECONDS, 0.0)
		_:
			return wanted.normalized() if wanted.length() > 0.05 else Vector2.ZERO


## 좀비 피하기를 얼마나 세게 할지: 착륙 지점으로 뛰어들 땐 뚫고 가고, 근접 무기는 붙어야 닿으니 덜 피한다
func _escape_weight() -> float:
	if _is_heading_to_zone():
		return 0.7
	if _is_melee_fighter():
		return 0.5 if _context.survivor.health_ratio() > MELEE_BRAVE_HEALTH_RATIO else 0.8
	return 1.1


## 착륙 원 안으로 들어가는 중인지 (헬기 도착 직전·착륙 뒤). 원 바깥에서 기다리는 동안은 아님.
func _is_heading_to_zone() -> bool:
	if _extraction.phase == "landed":
		return true
	if _extraction.phase != "revealed" or skill_level == "초보":
		return false
	var arrive_second := float(GameData.rules("extraction")["helicopter_arrive_second"])
	return _context.elapsed_seconds >= arrive_second - ZONE_ENTER_SECONDS_BEFORE


## 사람처럼 늦게 반응: 정해진 간격마다만 방향을 다시 정하고, 그 사이엔 같은 방향으로 간다
func _react_late(wanted: Vector2, interval_seconds: float, idle_chance: float) -> Vector2:
	_reaction_timer -= get_physics_process_delta_time()
	if _reaction_timer <= 0.0:
		_reaction_timer = interval_seconds
		var is_idle := randf() < idle_chance or wanted.length() <= 0.05
		_reaction_direction = Vector2.ZERO if is_idle else wanted.normalized()
	return _reaction_direction


func wants_skill() -> bool:
	if not _skill_runner.is_ready():
		return false
	var crowd := _context.horde.in_radius(_context.survivor.position, 28.0).size()
	match skill_level:
		"초보":
			return randf() < 0.01
		"고수":
			return crowd >= 7 or _context.survivor.health_ratio() < 0.45
		_:
			return crowd >= 4 or _context.survivor.health_ratio() < 0.4


func _process(delta: float) -> void:
	_capture_if_due()
	if _hud.night_clear_panel.is_open():
		_capture_once("night_clear_panel")
		_hud.continue_night()
		return
	if not (_hud.level_up_panel.is_open() or _hud.promotion_panel.is_open()):
		_decision_delay = 0.25
		return
	_decision_delay -= delta
	if _decision_delay > 0.0:
		return
	# 창이 다 나타난 뒤(0.25초)에 찍고, 한 번 더 기다렸다가 고른다 (기다리는 동안 두 번 고르지 않게 잠가 둠)
	_decision_delay = 10.0
	if _hud.promotion_panel.is_open():
		_capture_once("promotion_panel")
		await get_tree().create_timer(0.05, true, false, true).timeout
		_hud.choose_branch(_pick_branch_index())
	elif _hud.level_up_panel.is_open():
		_capture_once("level_up_panel")
		await get_tree().create_timer(0.05, true, false, true).timeout
		_hud.choose_card(_pick_card_index(_hud.level_up_panel.current_cards()))
	_decision_delay = 0.25


## 둘러싼 좀비 반대쪽 (가까울수록 세게)
func _danger_escape() -> Vector2:
	var away := Vector2.ZERO
	var survivor_position := _context.survivor.position
	for zombie: Zombie in _context.horde.in_radius(survivor_position, DANGER_RADIUS):
		var offset := survivor_position - zombie.position
		away += offset.normalized() / maxf(offset.length() * offset.length(), 16.0) * 400.0 * (3.0 if zombie.is_boss else 1.0)
	away += _hazard_escape(survivor_position)
	return away.limit_length(1.5)


## 산성 웅덩이·빨간 예고 원 안이거나 가까우면 바깥으로 (초보는 반만 신경 씀)
func _hazard_escape(survivor_position: Vector2) -> Vector2:
	var away := Vector2.ZERO
	for zone: Dictionary in _context.hazards.danger_zones():
		var offset := survivor_position - Vector2(zone["center"])
		if offset.length() < float(zone["radius"]) + 8.0:
			away += offset.normalized() * (0.5 if skill_level == "초보" else 1.2)
	return away


func _is_melee_fighter() -> bool:
	for weapon: Weapon in _context.weapon_rack.weapons:
		if weapon is MeleeArcWeapon:
			return true
	return false


## 가장 가까운 좀비와 근접 거리를 유지하도록 다가가거나 물러선다
func _melee_approach() -> Vector2:
	var target := _context.horde.nearest(_context.survivor.position, 90.0)
	if target == null:
		return Vector2.ZERO
	var to_target := target.position - _context.survivor.position
	return to_target.normalized() * clampf((to_target.length() - MELEE_KEEP_DISTANCE) / 20.0, -1.0, 1.0)


## 목표: 착륙 지점 → 없으면 가까운 백신 조각
func _goal_pull() -> Vector2:
	var survivor_position := _context.survivor.position
	var zone_goal := _zone_goal()
	if zone_goal != Vector2.INF:
		var to_goal := zone_goal - survivor_position
		if _is_heading_to_zone():
			return to_goal.normalized() * (2.5 if to_goal.length() > 8.0 else 0.0)
		# 원 바깥에서 기다릴 땐 자리에 가까울수록 살살 끌어서, 좀비가 오면 피하는 쪽이 이기게 (2차: 기다리다 떼 속에서 쓰러짐)
		return to_goal.normalized() * clampf(to_goal.length() / ZONE_SLOW_DOWN_DISTANCE, 0.0, 1.5)
	var targets := _context.shards.positions()
	if _context.survivor.health_ratio() < HEAL_SEEK_HEALTH_RATIO and not _context.health_packs.positions().is_empty():
		targets = _context.health_packs.positions()   # 위험하면 구급함 먼저
	var best := Vector2.ZERO
	var best_distance := SHARD_SEARCH_RADIUS * (2.0 if targets != _context.shards.positions() else 1.0)
	for shard_position: Vector2 in targets:
		var distance := survivor_position.distance_to(shard_position)
		if distance < best_distance:
			best_distance = distance
			best = shard_position - survivor_position
	return best.normalized() * 1.0


## 착륙 지점 쪽 목표: 헬기 오기 직전까진 원 바깥에서 기다리고, 그때부터 원 안으로. 갈 곳이 없으면 INF.
func _zone_goal() -> Vector2:
	if _is_heading_to_zone():
		return _extraction.zone_position
	if _extraction.phase != "revealed" or skill_level == "초보":
		return Vector2.INF
	var from_zone := (_context.survivor.position - _extraction.zone_position).normalized()
	return _extraction.zone_position + from_zone * ZONE_WAIT_DISTANCE


## 원거리 무기: 보스가 사거리 밖으로 멀어지면 다시 다가간다 (3차: 빠른 택배기사가 보스를 피해 멀리만 돌아 보스 처치에 51~80초)
## 돌진 예고 중에는 다가가지 않는다.
func _boss_engage() -> Vector2:
	for zombie: Zombie in _context.horde.zombies:
		if zombie.is_boss and not bool(zombie.boss_state.get("is_warning", false)):
			var to_boss := zombie.position - _context.survivor.position
			if to_boss.length() > BOSS_ENGAGE_DISTANCE:
				return to_boss.normalized()
	return Vector2.ZERO


## 고수: 보스 예고선이 보이면 돌진 방향의 옆으로 비킨다
func _boss_dodge() -> Vector2:
	for zombie: Zombie in _context.horde.zombies:
		if zombie.is_boss and bool(zombie.boss_state.get("is_warning", false)) and zombie.boss_state.has("direction"):
			var charge_direction: Vector2 = zombie.boss_state["direction"]
			var side := charge_direction.orthogonal()
			var to_survivor := _context.survivor.position - zombie.position
			return side * signf(side.dot(to_survivor) + 0.001)
	return Vector2.ZERO


## 고수: 좀비가 많으면 가까운 가로등 빛 쪽으로 (빛 안 좀비는 느리고 약함)
func _light_pull() -> Vector2:
	if _context.horde.alive_count() < 40:
		return Vector2.ZERO
	var survivor_position := _context.survivor.position
	var best := Vector2.ZERO
	var best_distance := 90.0
	for lamp: Vector2 in _context.lighting.lamp_positions():
		var distance := lamp.distance_to(survivor_position)
		if distance < best_distance:
			best_distance = distance
			best = lamp - survivor_position
	return best.normalized() if best_distance > 12.0 else Vector2.ZERO


func _pick_card_index(cards: Array) -> int:
	if skill_level == "초보" or cards.is_empty():
		return randi() % maxi(cards.size(), 1)
	var best_index := 0
	var best_score := -999.0
	for index: int in range(cards.size()):
		var score := _card_score(cards[index])
		if score > best_score:
			best_score = score
			best_index = index
	return best_index


func _card_score(card: Dictionary) -> float:
	var kind := String(card["kind"])
	var score := {"weapon_upgrade": 5.0, "new_weapon": 4.0, "gear_upgrade": 2.5, "new_gear": 3.0, "heal": 1.0}.get(kind, 0.0) as float
	if skill_level == "고수":
		# 고수는 키우던 무기를 집중해서 올리고(진화를 노리는 사람처럼), 피해·체력 장비를 챙긴다
		var owned := _context.weapon_rack.weapon_of(String(card["id"])) if kind == "weapon_upgrade" else null
		if owned != null:
			score += owned.level * 0.6
		if card["id"] in ["ammo", "vest"]:
			score += 1.0
	return score + randf() * 0.5


func _pick_branch_index() -> int:
	var option := String(SceneRouter.test_options.get("branch", "random"))
	var ids := _hud.promotion_panel.branch_ids()
	if option.is_valid_int():
		return clampi(int(option), 0, maxi(ids.size() - 1, 0))   # 범위 밖 번호여도 창이 닫히게
	if ids.has(option):
		return ids.find(option)
	return randi() % maxi(ids.size(), 1)


func _capture_if_due() -> void:
	for second: float in CAPTURE_SECONDS:
		if _context.elapsed_seconds >= second:
			_capture_once("t%03d" % int(second))


func _capture_once(capture_name: String) -> void:
	if _capture_folder.is_empty() or _captured.has(capture_name) or DisplayServer.get_name() == "headless":
		return
	_captured[capture_name] = true
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_capture_folder)
	image.save_png(_capture_folder.path_join("%s_%s_%s.png" % [_context.survivor.survivor_id, SceneRouter.finished_test_runs, capture_name]))
