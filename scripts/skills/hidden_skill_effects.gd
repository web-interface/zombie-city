## [파일] scripts/skills/hidden_skill_effects.gd
## [하는 일] 히든 스킬 4개의 큰 효과 조각을 시간에 맞춰 실행한다: 항공 지원 요청(예고 원 → 폭격 20발을 3초에 걸쳐), 백드래프트(화염 고리 3번 + 큰 불 장판), 총알 배송(무적 돌진 3번 연속, 지나간 길 폭발), 기적의 처방(체력 전부 회복 + 10초 무적 + 주변 독, 무적 동안 금빛 반짝임). 숫자는 data/skills.json 의 효과 조각에.
## [쓰는 곳] scripts/skills/skill_runner.gd 가 만들고, 효과 조각 종류가 airstrike·backdraft·express·miracle 이면 start() 를, 매 프레임 update() 를 부른다.
## [근거 문서] 14 §2-5 히든 스킬·§2-7 (히든 = 컷인 + 화면 번쩍 + 큰 흔들림), 03 §4-2
class_name HiddenSkillEffects
extends RefCounted

const AIRSTRIKE_MISS_RADIUS := 0.7     # 노릴 좀비가 없으면 생존자 둘레 이 비율 안 아무 데나
const MIRACLE_SPARKLE_SECONDS := 0.1   # 무적 동안 금빛 알갱이를 뿌리는 간격
const BLAST_KNOCKBACK_RATIO := 0.5     # 폭격·돌진 폭발에 반경의 절반만큼 밀려남
const GOLD := Color("ffd166")
const POISON_COLOR := Color("b388ff")

## 정해진 시각에 터질 일들: {"at": 초, "kind": "airstrike_warn"·"airstrike_boom"·"backdraft_ring"·"backdraft_fire", …}
var _events: Array[Dictionary] = []
var _time: float = 0.0
## 총알 배송: 남은 돌진 수·다음 돌진까지·폭발 간격 (빈 사전이면 안 하는 중)
var _express: Dictionary = {}
var _miracle_time_left: float = 0.0
var _sparkle_timer: float = 0.0
var _context: RunContext


func _init(context: RunContext) -> void:
	_context = context


func start(effect: Dictionary) -> void:
	match String(effect["type"]):
		"airstrike":
			_schedule_airstrike(effect)
		"backdraft":
			_schedule_backdraft(effect)
		"express":
			_express = effect.duplicate()
			_express["dashes_left"] = int(effect["dashes"])
			_express["gap_left"] = 0.0
			_express["blast_timer"] = 0.0
		"miracle":
			_cast_miracle(effect)


func update(delta: float) -> void:
	_time += delta
	var count_before := _events.size()   # 실행하다 새로 붙는 일(예고 → 폭격)은 이번엔 건너뛰고 남긴다
	var write_index := 0
	for index: int in range(count_before):
		var event := _events[index]
		if float(event["at"]) <= _time:
			_run_event(event)
			continue
		_events[write_index] = event
		write_index += 1
	for index: int in range(count_before, _events.size()):
		_events[write_index] = _events[index]
		write_index += 1
	_events.resize(write_index)
	_update_express(delta)
	_update_miracle(delta)


## ── 항공 지원 요청: 폭격마다 예고 원(warning_seconds) 뒤에 펑 ──
func _schedule_airstrike(effect: Dictionary) -> void:
	var strikes := int(effect["strikes"])
	var gap := float(effect["seconds"]) / maxf(1.0, float(strikes))
	for index: int in range(strikes):
		_events.append({"at": _time + gap * index, "kind": "airstrike_warn", "effect": effect})
	_context.play_sound("airstrike_whistle")


func _warn_airstrike(effect: Dictionary) -> void:
	var survivor_position := _context.survivor.position
	var search_radius := float(effect["search_radius"])
	var target := survivor_position + Vector2.from_angle(randf() * TAU) * randf() * search_radius * AIRSTRIKE_MISS_RADIUS
	var candidates := _context.horde.in_radius(survivor_position, search_radius)
	if not candidates.is_empty():
		target = candidates[randi() % candidates.size()].position
	_visuals().warning_circle(target, float(effect["radius"]), float(effect["warning_seconds"]))
	_events.append({"at": _time + float(effect["warning_seconds"]), "kind": "airstrike_boom", "effect": effect, "position": target})


func _boom(center: Vector2, radius: float, damage: float, shake_trauma: float) -> void:
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		var rolled := _context.roll_damage(damage)
		_context.horde.hit(zombie, rolled["amount"], {"is_crit": rolled["is_crit"], "knockback_from": center, "knockback": radius * BLAST_KNOCKBACK_RATIO, "source": "skill"})
	_visuals().explosion(center, radius, true)
	_context.camera.add_trauma(shake_trauma)


## ── 백드래프트: 화염 고리 rings 번 → 큰 불 장판 ──
func _schedule_backdraft(effect: Dictionary) -> void:
	for index: int in range(int(effect["rings"])):
		_events.append({"at": _time + float(effect["ring_gap_seconds"]) * index, "kind": "backdraft_ring", "effect": effect, "ring": index})
	_events.append({"at": _time + float(effect["ring_gap_seconds"]) * int(effect["rings"]), "kind": "backdraft_fire", "effect": effect})
	_context.play_sound("backdraft_roar")


func _backdraft_ring(effect: Dictionary, ring_index: int) -> void:
	var center := _context.survivor.position
	var radius := float(effect["radius_start"]) + float(effect["radius_step"]) * ring_index
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		zombie.push(zombie.position - center, float(effect["push_distance"]))
		var rolled := _context.roll_damage(float(effect["damage"]))
		_context.horde.hit(zombie, rolled["amount"], {"is_crit": rolled["is_crit"], "source": "skill"})
	_visuals().fire_ring(center, radius)
	_context.camera.add_trauma(float(effect["shake_trauma"]))
	_context.play_sound("explosion")


func _run_event(event: Dictionary) -> void:
	var effect: Dictionary = event["effect"]
	match String(event["kind"]):
		"airstrike_warn":
			_warn_airstrike(effect)
		"airstrike_boom":
			_boom(event["position"], float(effect["radius"]), float(effect["damage"]), float(effect["shake_trauma"]))
			_context.play_sound("airstrike_boom")
		"backdraft_ring":
			_backdraft_ring(effect, int(event["ring"]))
		"backdraft_fire":
			_context.weapon_rack.zones.add_zone("fire", _context.survivor.position, float(effect["fire_radius"]), float(effect["fire_seconds"]), float(effect["fire_damage_per_second"]), 1.0, 0.0, true)


## ── 총알 배송: 무적 돌진이 끝나면 잠깐 쉬고 다음 돌진 (방향은 그때 손가락 방향), 돌진 중엔 지나간 길이 터진다 ──
func _update_express(delta: float) -> void:
	if _express.is_empty():
		return
	var survivor := _context.survivor
	if survivor.is_dashing():
		_express["blast_timer"] = float(_express["blast_timer"]) - delta
		if float(_express["blast_timer"]) <= 0.0:
			_express["blast_timer"] = float(_express["blast_gap_seconds"])
			_boom(survivor.position, float(_express["blast_radius"]), float(_express["blast_damage"]), float(_express["shake_trauma"]))
		return
	if int(_express["dashes_left"]) <= 0:
		_express = {}
		return
	_express["gap_left"] = float(_express["gap_left"]) - delta
	if float(_express["gap_left"]) > 0.0:
		return
	_express["dashes_left"] = int(_express["dashes_left"]) - 1
	_express["gap_left"] = float(_express["gap_seconds"])
	survivor.start_dash(float(_express["dash_seconds"]), float(_express["speed_multiplier"]), float(_express["contact_damage"]), float(_express["knockback"]), true)
	_visuals().spray(survivor.position, GOLD, 8, 50.0)
	_context.play_sound("express_dash")


## ── 기적의 처방: 전부 회복 + 무적(받는 피해 0) + 주변 독 ──
func _cast_miracle(effect: Dictionary) -> void:
	var survivor := _context.survivor
	survivor.heal(float(effect["heal_ratio"]))
	survivor.add_guard(float(effect["invulnerable_seconds"]), 0.0)
	_context.area_effects.add_poison_cloud(survivor.position, float(effect["poison_radius"]), float(effect["poison_seconds"]), float(effect["poison_damage_per_second"]))
	for zombie: Zombie in _context.horde.in_radius(survivor.position, float(effect["poison_radius"])):
		zombie.apply_poison(float(effect["poison_damage_per_second"]) * survivor.stats.value("poison_damage_multiplier"), float(effect["poison_seconds"]))
	_visuals().shockwave(survivor.position, float(effect["poison_radius"]), true)
	_visuals().puff(survivor.position, POISON_COLOR, 12, float(effect["poison_radius"]) * 0.6)
	_miracle_time_left = float(effect["invulnerable_seconds"])
	_context.play_sound("miracle_chime")


func _update_miracle(delta: float) -> void:
	if _miracle_time_left <= 0.0:
		return
	_miracle_time_left -= delta
	_sparkle_timer -= delta
	if _sparkle_timer <= 0.0:
		_sparkle_timer = MIRACLE_SPARKLE_SECONDS
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(4.0, 9.0)
		_visuals().add_particle(_context.survivor.position + offset + Vector2(0, -5), Vector2(0, -12), 0.5, GOLD, 0.0)


func _visuals() -> WeaponVisuals:
	return _context.weapon_rack.visuals
