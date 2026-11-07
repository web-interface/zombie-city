## [파일] scripts/skills/trait_effects.gd
## [하는 일] 시간에 따라 도는 생존자 효과: 야근 수당(이 밤 지난 시간만큼 피해가 오름 — 밤이 바뀌면 0부터), 잠깐 능력치 바꾸기(카페인 충전·칼퇴근 — 끝나면 뒤 효과), 팀장 전직의 인턴(따라다니며 서류를 던짐, 빛 층에 그림), 간호사 '넘친 회복은 주변 피해'(체력이 가득일 때 회복한 양을 모았다가 둘레 좀비에게).
## [쓰는 곳] scripts/skills/skill_runner.gd 가 만들고 매 프레임 update() 를, 효과 조각 stat_boost 면 start_boost() 를 부른다. 히든 칼퇴근(hidden_skill_effects.gd)도 start_boost() 를 쓴다. 숫자는 data/survivors.json interns·skills.json·run_rules.json survivor_base_stats(overtime_*·intern_count·overheal_*)·status_effects overheal_pulse_seconds.
## [근거 문서] 15 부록 B 직장인(야근 수당·카페인 충전·팀장 인턴)·간호사(넘친 회복)
class_name TraitEffects
extends RefCounted

const OVERTIME_COLOR := Color("ffe066")
const BOOST_COLOR := Color("bfe9ff")
const BOOST_SPARKLE_SECONDS := 0.12
const INTERN_FRAME_SIZE := Vector2(16, 16)
const INTERN_STEPS_PER_SECOND := 8.0
const INTERN_SPREAD_RADIANS := 1.1     # 인턴끼리 벌어지는 각도 (생존자 뒤쪽 부채꼴)
const HAND_HEIGHT := Vector2(0, -4)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const OVERHEAL_COLOR := Color("e8f8ff")
const OVERHEAL_RING_MIN_DAMAGE := 3.0   # 초당 회복처럼 아주 작은 넘침은 고리 없이 (화면이 시끄럽지 않게)

var _context: RunContext
var _overtime_bonus: float = 0.0
## 이름 → {"time_left", "after_seconds", "after_multiply"} (뒤 효과가 시작되면 after_seconds 는 0)
var _boosts: Dictionary = {}
var _sparkle_timer: float = 0.0
var _interns: Array[Dictionary] = []
var _intern_rules: Dictionary = {}
var _intern_texture: Texture2D = null
var _is_drawing_registered: bool = false
## 넘친 회복량을 모아 둔 것 (overheal_pulse_seconds 마다 터짐)
var _overheal_pool: float = 0.0
var _overheal_timer: float = 0.0


func _init(context: RunContext) -> void:
	_context = context
	_intern_rules = GameData.entry("survivors", context.survivor.survivor_id).get("interns", {})
	if not _intern_rules.is_empty():
		_intern_texture = load("res://art/sprites/survivor_%s.png" % _intern_rules["outfit"])
	context.survivor.overhealed.connect(_on_overhealed)


func update(delta: float) -> void:
	_update_overtime()
	_update_boosts(delta)
	_update_interns(delta)
	_update_overheal(delta)


## seconds 동안 능력치를 multiply 로 바꾸고, 끝나면 after_seconds 동안 after_multiply (카페인 충전 뒤 2초 느려짐)
func start_boost(source_name: String, seconds: float, multiply: Dictionary, after_seconds: float = 0.0, after_multiply: Dictionary = {}) -> void:
	_boosts[source_name] = {"time_left": seconds, "after_seconds": after_seconds, "after_multiply": after_multiply}
	_context.survivor.stats.set_source("boost:" + source_name, [{"multiply": multiply}])


func is_boosting(source_name: String) -> bool:
	return _boosts.has(source_name)


## ── 야근 수당: overtime_step_seconds 마다 피해 +overtime_bonus_per_step (최대 overtime_max_bonus). 바뀔 때만 능력치를 다시 계산 ──
func _update_overtime() -> void:
	var stats := _context.survivor.stats
	var per_step := stats.value("overtime_bonus_per_step")
	if per_step <= 0.0 and _overtime_bonus <= 0.0:
		return
	var steps := floorf(_context.elapsed_seconds / maxf(stats.value("overtime_step_seconds"), 1.0))
	var bonus := minf(steps * per_step, stats.value("overtime_max_bonus"))
	if is_equal_approx(bonus, _overtime_bonus):
		return
	var went_up := bonus > _overtime_bonus
	_overtime_bonus = bonus
	stats.set_source("overtime", [{"multiply": {"damage_multiplier": 1.0 + bonus}}])
	if went_up:   # 수당이 붙는 순간이 보이게 금빛 고리
		_context.effects.ring(_context.survivor.position, 18.0, OVERTIME_COLOR, 0.5)
		_context.effects.burst(_context.survivor.position + HAND_HEIGHT, OVERTIME_COLOR, 8, 30.0)


func _update_boosts(delta: float) -> void:
	for source_name: String in _boosts.keys():
		var boost: Dictionary = _boosts[source_name]
		boost["time_left"] = float(boost["time_left"]) - delta
		if float(boost["time_left"]) > 0.0:
			continue
		if float(boost["after_seconds"]) > 0.0:
			boost["time_left"] = boost["after_seconds"]
			boost["after_seconds"] = 0.0
			_context.survivor.stats.set_source("boost:" + source_name, [{"multiply": boost["after_multiply"]}])
			continue
		_context.survivor.stats.set_source("boost:" + source_name, [])
		_boosts.erase(source_name)
	_sparkle_timer -= delta
	if _boosts.has("caffeine_rush") and _sparkle_timer <= 0.0:   # 카페인 충전 중: 머리 위로 하늘색 김
		_sparkle_timer = BOOST_SPARKLE_SECONDS
		var offset := Vector2(randf_range(-4.0, 4.0), -9.0)
		_context.weapon_rack.visuals.add_particle(_context.survivor.position + offset, Vector2(0, -14), 0.5, BOOST_COLOR, 0.0)


func _on_overhealed(amount: float) -> void:
	_overheal_pool += amount


## ── 간호사 특성: 넘친 회복 × overheal_damage_ratio 를 둘레 overheal_radius 안 좀비에게 ──
func _update_overheal(delta: float) -> void:
	_overheal_timer -= delta
	if _overheal_pool <= 0.0 or _overheal_timer > 0.0:
		return
	_overheal_timer = float(_context.status_rules["overheal_pulse_seconds"])
	var stats := _context.survivor.stats
	var damage := _overheal_pool * stats.value("overheal_damage_ratio")
	_overheal_pool = 0.0
	var center := _context.survivor.position
	var radius := stats.value("overheal_radius")
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		_context.horde.hit(zombie, damage, {"source": "overheal", "show_number": damage >= OVERHEAL_RING_MIN_DAMAGE})
	if damage >= OVERHEAL_RING_MIN_DAMAGE:
		_context.effects.ring(center, radius, OVERHEAL_COLOR, 0.35)


## ── 팀장 인턴: intern_count 만큼 생존자 뒤를 따라다니며 가까운 좀비에게 서류를 던진다 ──
func _update_interns(delta: float) -> void:
	if _intern_rules.is_empty():
		return
	var wanted := int(_context.survivor.stats.value("intern_count"))
	while _interns.size() < wanted:
		_interns.append({"position": _context.survivor.position, "facing": Vector2.DOWN, "is_moving": false, "step": randf(),
			"cooldown": randf() * float(_intern_rules["throw_interval_seconds"])})
	if _interns.is_empty():
		return
	if not _is_drawing_registered:   # 무기 칸(빛 층)이 다 만들어진 뒤라 처음 생길 때 붙는다
		_context.weapon_rack.visuals.glow_drawers.append(self)
		_is_drawing_registered = true
	for index: int in range(_interns.size()):
		_move_intern(_interns[index], index, delta)
		_throw_paper(_interns[index], delta)


func _move_intern(intern: Dictionary, index: int, delta: float) -> void:
	var survivor := _context.survivor
	var side := (index - (_interns.size() - 1) * 0.5) * INTERN_SPREAD_RADIANS
	var slot := survivor.position + (-survivor.facing).rotated(side) * float(_intern_rules["follow_distance"])
	var offset := slot - Vector2(intern["position"])
	var speed := survivor.stats.value("move_speed") * float(_intern_rules["follow_speed_ratio"])
	intern["is_moving"] = offset.length() > 2.0
	if bool(intern["is_moving"]):
		intern["facing"] = offset.normalized()
		intern["position"] = Vector2(intern["position"]) + offset.normalized() * minf(speed * delta, offset.length())
		intern["step"] = float(intern["step"]) + delta


func _throw_paper(intern: Dictionary, delta: float) -> void:
	intern["cooldown"] = float(intern["cooldown"]) - delta * _context.survivor.stats.value("attack_speed_multiplier")
	if float(intern["cooldown"]) > 0.0:
		return
	var from_position: Vector2 = Vector2(intern["position"]) + HAND_HEIGHT
	var target := _context.horde.nearest(from_position, float(_intern_rules["range"]))
	if target == null:
		return
	intern["cooldown"] = float(_intern_rules["throw_interval_seconds"])
	var speed := float(_intern_rules["projectile_speed"])
	var rolled := _context.roll_damage(float(_intern_rules["damage"]))
	_context.projectiles.launch("paper", from_position, (target.position - from_position).normalized() * speed, {
		"damage": rolled["amount"], "is_crit": rolled["is_crit"], "source": "intern", "pierce": int(_intern_rules["pierce"]),
		"life_seconds": float(_intern_rules["range"]) / speed, "knockback": 1.5})


## 빛 층에 인턴을 그린다: 그림자 + 걷기 그림(옆모습은 뒤집어 왼쪽)
func draw_glow_on(canvas: CanvasItem) -> void:
	for intern: Dictionary in _interns:
		var facing: Vector2 = intern["facing"]
		var direction_name := SpriteSheetLayout.direction_name(facing)
		var action := ("walk_" if bool(intern["is_moving"]) else "idle_") + direction_name
		var frame := SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, action, int(float(intern["step"]) * INTERN_STEPS_PER_SECOND))
		var region := Rect2(Vector2(frame % SpriteSheetLayout.COLUMNS, floori(frame / float(SpriteSheetLayout.COLUMNS))) * INTERN_FRAME_SIZE, INTERN_FRAME_SIZE)
		var top_left := (Vector2(intern["position"]) - INTERN_FRAME_SIZE * 0.5 - Vector2(0.0, 4.0)).round()
		canvas.draw_rect(Rect2(top_left + Vector2(4, 14), Vector2(8, 2)), SHADOW_COLOR)
		var size := INTERN_FRAME_SIZE
		if direction_name == "side" and facing.x < 0.0:
			size.x = -size.x
			top_left.x += INTERN_FRAME_SIZE.x
		canvas.draw_texture_rect_region(_intern_texture, Rect2(top_left, size), region)
