## [파일] scripts/weapons/pulse_weapon.gd
## [하는 일] 몸 주변 고리 무기: 반경 안 좀비 모두에게 한꺼번에 — 확성기(look "shockwave", 밀기·기절, 진화 = 화면 전체), 소독약 분무(look "fog", 몸 둘레에 늘 떠 있는 독 안개, 진화 = 2배·독 두 겹), 제세동기(look "electric", 전기 고리 + 고리 밖 가까운 좀비로 번개, 진화 = 화면 번쩍·큰 피해). 반경 안에 좀비가 없으면 쉬었다가 들어오면 바로.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "pulse" 인 무기로 만들고, WeaponVisuals 가 그리기 때 draw_glow_on()(안개)을 부른다. 고리·번개 그림은 WeaponVisuals.
## [근거 문서] 14 §2-2 확성기·소독약 분무·제세동기, §2-4 민방위 사이렌·방역 안개·심정지, §2-7 (충격파 = 넓어지는 고리)
class_name PulseWeapon
extends Weapon

const FOG_DOTS := 48                      # 안개 점 수 (미리 정한 자리를 천천히 돌린다 — 매 프레임 새로 만들지 않게)
const FOG_SPIN_SPEED := 0.5
const FOG_COLOR := Color("bfe3ff")
const FLASH_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const FLASH_SECONDS := 0.12
const MUZZLE_HEIGHT := Vector2(0, -4)

var _fog_offsets: Array[Vector2] = []     # 단위 원 안 무작위 자리 (안개 모양)
var _fog_time: float = 0.0
var _outer: Array[Zombie] = []            # 고리 밖 번개 대상 (재사용)


func _init(new_weapon_id: String, run_context: RunContext) -> void:
	super(new_weapon_id, run_context)
	for index: int in range(FOG_DOTS):
		_fog_offsets.append(Vector2.from_angle(randf() * TAU) * sqrt(randf()))


func update(delta: float) -> void:
	_fog_time += delta
	super.update(delta)


func attack() -> bool:
	var stats := numbers()
	var center := context.survivor.position
	var radius := area_radius(float(stats["radius"]))
	var nearby := context.horde.in_radius(center, radius)
	if nearby.is_empty():
		return false
	for zombie: Zombie in nearby:
		_pulse_hit(zombie, stats, center)
	_show_pulse(center, radius, stats)
	if int(stats.get("chain_count", 0)) > 0:
		_zap_outward(center, radius, stats)
	play_attack_sound()
	return true


func _pulse_hit(zombie: Zombie, stats: Dictionary, center: Vector2) -> void:
	strike(zombie, float(stats["damage"]), center, float(stats["knockback"]))
	stun_zombie(zombie, float(stats["stun_seconds"]))
	var poison_power := float(stats.get("poison_damage_per_second", 0.0)) * context.survivor.stats.value("poison_damage_multiplier")
	if poison_power > 0.0:
		for layer: int in range(int(stats.get("poison_applications", 1))):
			zombie.apply_poison(poison_power, float(stats["poison_seconds"]))


func _show_pulse(center: Vector2, radius: float, stats: Dictionary) -> void:
	match look:
		"shockwave":
			visuals().shockwave(center, radius, is_evolved)
			shake_screen()
		"electric":
			visuals().electric_ring(center, radius, is_evolved)
			if bool(stats.get("screen_flash", false)):
				visuals().screen_flash(FLASH_COLOR, FLASH_SECONDS)
				shake_screen()


## 제세동기: 고리 밖 chain_range 안에서 가장 가까운 좀비들에게 번개
func _zap_outward(center: Vector2, radius: float, stats: Dictionary) -> void:
	_outer.clear()
	for zombie: Zombie in context.horde.in_radius(center, float(stats["chain_range"])):
		if zombie.position.distance_to(center) > radius:
			_outer.append(zombie)
	_outer.sort_custom(func(first: Zombie, second: Zombie) -> bool:
		return first.position.distance_squared_to(center) < second.position.distance_squared_to(center))
	for index: int in range(mini(int(stats["chain_count"]), _outer.size())):
		visuals().lightning(center + MUZZLE_HEIGHT, _outer[index].position, is_evolved)
		strike(_outer[index], float(stats["damage"]), center, 0.0)
		stun_zombie(_outer[index], float(stats["stun_seconds"]))


## 소독약 안개: 몸 둘레에 늘 떠 있는 민트색 점들 (천천히 돌고 깜빡인다, 어둠 속에서도 보이게 빛 층에)
func draw_glow_on(canvas: CanvasItem) -> void:
	if look != "fog":
		return
	var radius := area_radius(float(numbers()["radius"]))
	var center := context.survivor.position
	var color := EVOLVED_COLOR if is_evolved else FOG_COLOR
	for index: int in range(FOG_DOTS):
		var offset := _fog_offsets[index].rotated(_fog_time * FOG_SPIN_SPEED * (1.0 if index % 2 == 0 else -1.0))
		var alpha := 0.25 + 0.2 * sin(_fog_time * 3.0 + index)
		canvas.draw_rect(Rect2((center + offset * radius).round(), Vector2.ONE * 2.0), Color(color, alpha))
