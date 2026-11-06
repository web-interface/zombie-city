## [파일] scripts/skills/skill_runner.gd
## [하는 일] 생존자 스킬 버튼 담당: 지금 스킬(효과 조각 목록)과 다시 쓰기 시간을 들고 있다가, 누르면 조각을 차례로 실행한다(기절·밀기·부채꼴 밀기·빛·돌진·회복·보호막·저격·불 장판·독 폭발·조각 끌어오기 + 히든 스킬 조각은 HiddenSkillEffects 에 맡김). 전직이 스킬을 바꾸면 apply_changes() 로 숫자·조각·스킬 자체를 바꾼다. 히든 스킬을 고르면 버튼이 히든 스킬로 바뀌고 전직보다 우선한다.
## [쓰는 곳] scenes/run.tscn 의 Systems/SkillRunner. 스킬 버튼(scripts/ui/skill_button.gd)·자동 플레이가 try_use() 를, 전직(scripts/systems/promotion.gd)이 apply_changes() 를, run.gd 가 히든 카드를 고르면 set_hidden_skill() 을 부른다. 컷인(scripts/ui/skill_cutin.gd)이 hidden_skill_used 를 듣는다.
## [근거 문서] 03 §1 스킬, 03 §1-2 전직, 14 §2-5 히든 스킬, data/skills.json
class_name SkillRunner
extends Node

signal used(skill_id: String)
signal skill_changed(skill_id: String)
## 히든 스킬을 썼다 (컷인·화면 멈춤 — 효과 조각보다 먼저 알린다)
signal hidden_skill_used(skill_id: String)

const SNIPE_RANGE := 400.0

var skill_id: String = ""
var skill: Dictionary = {}
var cooldown_left: float = 0.0
## 고른 히든 스킬 (없으면 빈 글자). 한번 고르면 그 판 끝까지 버튼이 이 스킬.
var hidden_skill_id: String = ""
var _context: RunContext
var _hidden_effects: HiddenSkillEffects


func setup(context: RunContext, starting_skill_id: String) -> void:
	_context = context
	_hidden_effects = HiddenSkillEffects.new(context)
	_load_skill(starting_skill_id)


func update(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	_hidden_effects.update(delta)


func is_hidden_active() -> bool:
	return not hidden_skill_id.is_empty()


## 히든 스킬 카드를 골랐다: 버튼이 히든 스킬로 바뀌고 바로 쓸 수 있다 (문서 14 §2-5)
func set_hidden_skill(new_skill_id: String) -> void:
	hidden_skill_id = new_skill_id
	_load_skill(new_skill_id)
	cooldown_left = 0.0


func is_ready() -> bool:
	return cooldown_left <= 0.0 and not _context.survivor.is_dead


## 0 = 방금 씀, 1 = 다 참 (버튼 테두리 채우기)
func ready_ratio() -> float:
	var total := cooldown_seconds()
	return 1.0 if total <= 0.0 else 1.0 - cooldown_left / total


func cooldown_seconds() -> float:
	return float(skill["cooldown_seconds"]) * _context.survivor.stats.value("skill_cooldown_multiplier")


func try_use() -> bool:
	if not is_ready():
		return false
	if is_hidden_active():
		hidden_skill_used.emit(skill_id)
	for effect: Dictionary in skill["effects"]:
		_run_effect(effect)
	cooldown_left = cooldown_seconds()
	used.emit(skill_id)
	return true


## 전직이 스킬을 바꾼다 (data/promotions.json skill_changes). 히든 스킬을 고른 뒤라면 히든 스킬이 우선이라 바꾸지 않는다.
func apply_changes(changes: Array) -> void:
	if is_hidden_active():
		return
	for change: Dictionary in changes:
		match String(change["change"]):
			"replace_skill":
				_load_skill(String(change["skill"]))
			"scale_cooldown":
				skill["cooldown_seconds"] = float(skill["cooldown_seconds"]) * float(change["by"])
			"add_effect":
				skill["effects"].append(Dictionary(change["effect"]).duplicate(true))
			"scale_effect", "add_to_effect":
				_change_effect_number(change)
			_:
				push_error("data/promotions.json: 모르는 스킬 바꾸기 '%s'" % change["change"])
	skill_changed.emit(skill_id)


func _load_skill(new_skill_id: String) -> void:
	skill_id = new_skill_id
	skill = GameData.entry("skills", new_skill_id).duplicate(true)
	skill_changed.emit(skill_id)


func _change_effect_number(change: Dictionary) -> void:
	for effect: Dictionary in skill["effects"]:
		if effect["type"] != change["effect"]:
			continue
		var field := String(change["field"])
		if String(change["change"]) == "scale_effect":
			effect[field] = float(effect[field]) * float(change["by"])
		else:
			effect[field] = float(effect[field]) + float(change["by"])


func _run_effect(effect: Dictionary) -> void:
	var survivor := _context.survivor
	var center := survivor.position
	match String(effect["type"]):
		"radial_stun":
			_stun_around(center, float(effect["radius"]), float(effect["seconds"]), float(effect.get("damage", 0.0)))
		"radial_push":
			_push_around(center, float(effect["radius"]), float(effect["push_distance"]), float(effect.get("damage", 0.0)))
		"cone_push":
			_push_cone(effect)
		"light_burst":
			_context.lighting.add_temporary_light(center, float(effect["radius"]), float(effect["seconds"]))
			_context.effects.ring(center, float(effect["radius"]), Color("fff6d8"), 0.35)
			_context.play_sound("skill_flashbang")
		"dash":
			survivor.start_dash(float(effect["seconds"]), float(effect["speed_multiplier"]), float(effect.get("contact_damage", 0.0)), float(effect.get("knockback", 0.0)), bool(effect.get("invulnerable", false)))
			_context.effects.burst(center, Color("f4f4f4"), 6, 50.0)
			_context.play_sound("skill_sprint")
		"heal":
			survivor.heal(float(effect["ratio"]))
			_context.effects.ring(center, 20.0, Color("8ff59a"), 0.4)
			_context.play_sound("skill_heal")
		"guard":
			survivor.add_guard(float(effect["seconds"]), float(effect["damage_taken_multiplier"]))
			_context.effects.ring(center, 14.0, Color("8fd3ff"), 0.5)
		"line_shot":
			_snipe(float(effect["damage"]), float(effect["width"]))
		"fire_zone":
			_context.area_effects.add_fire_zone(center, float(effect["radius"]), float(effect["seconds"]), float(effect["damage_per_second"]))
		"poison_burst":
			_context.area_effects.add_poison_cloud(center, float(effect["radius"]), float(effect["seconds"]), float(effect["damage_per_second"]))
		"collect_all_shards":
			_context.shards.collect_all()
		"airstrike", "backdraft", "express", "miracle":
			_hidden_effects.start(effect)
		_:
			push_error("data/skills.json: 모르는 효과 조각 '%s'" % effect["type"])


func _stun_around(center: Vector2, radius: float, seconds: float, damage: float) -> void:
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		var boss_multiplier := float(_context.status_rules["boss_stun_multiplier"])
		zombie.stun(seconds * (boss_multiplier if zombie.is_boss else 1.0))   # 보스는 짧게만 기절
		if damage > 0.0:
			_context.horde.hit(zombie, _context.roll_damage(damage)["amount"], {"source": "skill"})
	_context.effects.ring(center, radius, Color("ffffff"), 0.3)


func _push_around(center: Vector2, radius: float, distance: float, damage: float) -> void:
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		zombie.push(zombie.position - center, distance)
		if damage > 0.0:
			var rolled := _context.roll_damage(damage)
			_context.horde.hit(zombie, rolled["amount"], {"is_crit": rolled["is_crit"], "source": "skill"})
	_context.effects.ring(center, radius, Color("ffd166"), 0.3)
	_context.shake("skill")


func _push_cone(effect: Dictionary) -> void:
	var survivor := _context.survivor
	var half_angle := deg_to_rad(float(effect["angle_degrees"])) * 0.5
	for zombie: Zombie in _context.horde.in_radius(survivor.position, float(effect["range"])):
		var to_zombie := zombie.position - survivor.position
		if absf(survivor.facing.angle_to(to_zombie)) > half_angle:
			continue
		zombie.push(to_zombie, float(effect["push_distance"]))
		zombie.slow(float(effect["slow_ratio"]), float(effect["slow_seconds"]))
		if float(effect.get("damage", 0.0)) > 0.0:
			_context.horde.hit(zombie, float(effect["damage"]), {"source": "skill", "show_number": false})
	for index: int in range(14):
		var spray := survivor.facing.rotated(randf_range(-half_angle, half_angle)) * randf_range(10.0, float(effect["range"]))
		_context.effects.burst(survivor.position + spray, Color("e9ecef"), 1, 20.0)
	_context.play_sound("skill_extinguisher")


## 바라보는 방향으로 화면 끝까지 꿰뚫는 한 발. 가는 길의 좀비를 모두 맞힌다.
func _snipe(damage: float, width: float) -> void:
	var start := _context.survivor.position + Vector2(0, -4)
	var direction := _context.survivor.facing
	var target := _context.horde.nearest(start, SNIPE_RANGE)
	if target != null:
		direction = (target.position - start).normalized()
	var finish := start + direction * SNIPE_RANGE
	for zombie: Zombie in _context.horde.in_radius(start + direction * SNIPE_RANGE * 0.5, SNIPE_RANGE * 0.5):
		var closest := Geometry2D.get_closest_point_to_segment(zombie.position, start, finish)
		if closest.distance_to(zombie.position) <= width + zombie.radius:
			var rolled := _context.roll_damage(damage)
			_context.horde.hit(zombie, rolled["amount"], {"is_crit": rolled["is_crit"], "source": "skill"})
	_context.effects.line(start, finish, Color("fff2b0"), 2.0, 0.25)
	_context.shake("skill")
	_context.play_sound("pistol_shot", -0.3)
