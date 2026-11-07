## [파일] scripts/run/run_rewards.gd
## [하는 일] 판 중 '받는 맛' 보상과 연출: 정예를 잡으면 금빛 폭죽 + 보물 상자 + 줍기 하나, 보스를 잡으면 보물 상자, 좀비는 아주 가끔 자석·폭탄·냉각 스프레이를 떨굼. 주운 상자는 창을 띄울 수 있을 때 슬롯 창으로 열고(1·3·5개), 받으면 강화를 적용한다. 줍기 효과(조각 끌어오기·화면 폭발·얼리기), 연속 처치 보상(조각·소리·알림), 진화 순간(금색 띠·느린 화면)·히든 스킬(얻음 알림·쓸 때 컷인 멈춤)도 여기서.
## [쓰는 곳] scripts/run/run.gd 가 만들어 setup() 하고, 창 띄우기 차례에 open_pending_chest() 를 묻는다. 좀비 쓰러짐·줍기·연속 처치·상자 받기 신호를 스스로 잇는다.
## [근거 문서] 14 §1-2 정예·§2-6 보물 상자·줍기·§4 중독 설계, data/run_rules.json chest·pickups
class_name RunRewards
extends RefCounted

var _context: RunContext
var _hud: Hud
var _level_up: LevelUp
var _chest_rules: Dictionary = {}
var _pickup_rules: Dictionary = {}
var _pending_chests: int = 0
var _open_cards: Array = []
var _open_count: int = 0
var _skill_runner: SkillRunner
var _time_effects: TimeEffects


func setup(context: RunContext, hud: Hud, level_up: LevelUp, combo: KillCombo) -> void:
	_context = context
	_hud = hud
	_level_up = level_up
	_chest_rules = GameData.rules("chest")
	_pickup_rules = GameData.rules("pickups")
	context.horde.zombie_died.connect(_on_zombie_died)
	context.pickups.picked.connect(_on_picked)
	combo.milestone_reached.connect(_on_combo_milestone)
	hud.chest_claimed.connect(_on_chest_claimed)


## 진화·히든 스킬 연출을 붙인다 (무기·카드 쪽 신호 — LevelUp.evolved·hidden_skill_chosen, SkillRunner.hidden_skill_used)
func watch_build(skill_runner: SkillRunner, time_effects: TimeEffects) -> void:
	_skill_runner = skill_runner
	_time_effects = time_effects
	_level_up.evolved.connect(_on_weapon_evolved)
	_level_up.hidden_skill_chosen.connect(_on_hidden_skill_chosen)
	skill_runner.hidden_skill_used.connect(_on_hidden_skill_used)


## 밤을 넘길 때 바닥에 두고 온 상자를 쌓아 둔다 (다음 밤에 열림)
func add_pending_chests(count: int) -> void:
	_pending_chests += count


## 쌓인 상자가 있으면 슬롯 창을 연다 (run.gd 가 창을 띄워도 될 때만 부름). 열었으면 true.
func open_pending_chest() -> bool:
	if _pending_chests <= 0:
		return false
	_pending_chests -= 1
	_open_count = _roll_chest_size()
	_open_cards = _roll_cards(_open_count)
	_hud.open_chest(_open_cards, _open_count)
	return true


func _on_zombie_died(zombie: Zombie) -> void:
	if zombie.is_boss:
		_context.pickups.drop("chest", zombie.position)
		return
	if zombie.is_elite:
		_on_elite_killed(zombie)
		return
	_context.pickups.maybe_drop(zombie.position)


func _on_elite_killed(zombie: Zombie) -> void:
	_context.pickups.drop("chest", zombie.position)
	_context.pickups.drop(["magnet", "bomb", "freeze"].pick_random(), zombie.position + Vector2(10, 0))
	_context.effects.burst(zombie.position, PixelUi.GOLD, 18, 70.0)
	_context.effects.ring(zombie.position, 20.0, PixelUi.GOLD, 0.4)
	_context.shake("explosion")
	_hud.show_banner("정예 처치! 보물 상자", "good")


func _on_picked(kind: String, at_position: Vector2) -> void:
	match kind:
		"chest":
			_pending_chests += 1
			_context.play_sound("chest_drop")
		"magnet":
			_context.shards.collect_all()
			_context.effects.ring(_context.survivor.position, 60.0, Color("8fd3ff"), 0.5)
			_context.play_sound("magnet_pickup")
		"bomb":
			_blow_up_screen(at_position)
		"freeze":
			_freeze_everyone()


## 폭탄: 둘레의 일반 좀비는 쓰러지고 보스는 체력이 조금 깎인다
func _blow_up_screen(center: Vector2) -> void:
	var radius := float(_pickup_rules["bomb_radius"])
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		var amount := zombie.max_health * float(_pickup_rules["bomb_boss_damage_ratio"]) if zombie.is_boss else zombie.health + 1.0
		_context.horde.hit(zombie, amount, {"source": "explosion", "show_number": zombie.is_boss})
	_context.effects.ring(center, radius * 0.5, Color("ffd25a"), 0.5)
	_context.effects.burst(center, Color("fff2b0"), 30, 120.0)
	_context.shake("boss_kill")
	_context.play_sound("bomb_blast")


func _freeze_everyone() -> void:
	for zombie: Zombie in _context.horde.zombies:
		zombie.stun(float(_pickup_rules["freeze_boss_seconds"]) if zombie.is_boss else float(_pickup_rules["freeze_seconds"]))
	_context.effects.ring(_context.survivor.position, 90.0, Color("bfe9ff"), 0.6)
	_context.play_sound("freeze_spray")
	_hud.show_banner("좀비가 얼어붙었어요!", "good")


func _on_combo_milestone(count: int, shard_bonus: int) -> void:
	var survivor_position := _context.survivor.position
	_context.shards.drop(survivor_position, shard_bonus)
	_context.effects.ring(survivor_position, 30.0, PixelUi.GOLD, 0.5)
	SoundPlayer.play_exact("combo_milestone_%d" % _milestone_sound_step(count))   # 50·100·200 차례로 더 화려한 소리
	_hud.show_banner("연속 %d!" % count, "good")


func _on_chest_claimed() -> void:
	if _open_cards.is_empty():
		for index: int in range(_open_count):   # 카드 목록을 못 받았으면 카드 고르기로 대신
			_level_up.grant_bonus_choice()
		return
	for card: Dictionary in _open_cards:
		_level_up.call("apply_card", card)
	_context.effects.ring(_context.survivor.position, 26.0, PixelUi.GOLD, 0.5)


## 1개 70% · 3개 25% · 5개 5% (data/run_rules.json chest). 훈장: 행운 상자(chest_luck — 3·5개 무게 ↑), 정예 사냥꾼(chest_size_bonus — 한 단계 크게)
func _roll_chest_size() -> int:
	var stats := _context.survivor.stats
	var weights: Array = _chest_rules["count_weights"].map(func(weight: Variant) -> float: return float(weight))
	for index: int in range(1, weights.size()):
		weights[index] = float(weights[index]) * (1.0 + stats.value("chest_luck"))
	var roll := randf() * float(weights.reduce(func(total: float, weight: float) -> float: return total + weight, 0.0))
	var picked := 0
	while picked < weights.size() - 1 and roll > float(weights[picked]):
		roll -= float(weights[picked])
		picked += 1
	picked = mini(picked + int(stats.value("chest_size_bonus")), weights.size() - 1)
	return int(_chest_rules["upgrade_counts"][picked])


## 받을 강화 카드 (진화할 수 있으면 진화 먼저 — LevelUp.roll_upgrade_cards, 무기·카드 담당)
func _roll_cards(count: int) -> Array:
	if not _level_up.has_method("roll_upgrade_cards"):
		return []
	return _level_up.call("roll_upgrade_cards", count)


## 연속 소리 단계: 50 → 1, 100 → 2, 200 이상 → 3 (audio/README.md 순서 있는 소리)
func _milestone_sound_step(count: int) -> int:
	if count >= 200:
		return 3
	return 2 if count >= 100 else 1


## 진화 순간: 금색 "진화!" 띠 + 느린 화면 (문서 14 §2-7)
func _on_weapon_evolved(weapon_id: String) -> void:
	_hud.show_banner("진화! %s" % _context.weapon_rack.weapon_of(weapon_id).display_name(), "evolution")
	_context.play_sound("evolution")
	_context.shake("skill")
	_time_effects.play(float(GameData.rules("build")["evolution_slow_motion_seconds"]), float(_context.juice_rules["slow_motion_scale"]))


func _on_hidden_skill_chosen(skill_id: String) -> void:
	_skill_runner.set_hidden_skill(skill_id)
	_hud.show_banner("히든 스킬! %s" % GameData.entry("skills", skill_id)["name"], "hidden")


## 히든 스킬을 쓰면 컷인(Hud)이 지나가는 동안 화면을 멈춘다
func _on_hidden_skill_used(_skill_id: String) -> void:
	_context.play_sound("hidden_skill_cutin")
	_time_effects.play(float(GameData.rules("build")["hidden_skill_cutin_seconds"]), 0.0)
