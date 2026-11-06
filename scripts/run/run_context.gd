## [파일] scripts/run/run_context.gd
## [하는 일] 한 판 안의 주요 부분(생존자·좀비 무리·투사체·효과·빛·조각·장판·카메라·소리)을 한 묶음으로 들고 다니는 상자. 무기·스킬·시스템이 서로를 깊숙이 찾아가지 않고 이 상자로 쓴다 (문서 10 §7). 피해 계산(치명타)처럼 여러 곳이 같이 쓰는 계산도 둔다.
## [쓰는 곳] scripts/run/run.gd 가 만들어 각 부분의 setup() 에 넘긴다.
## [근거 문서] 11 §4·§5, 10 §7 연결 방식
class_name RunContext
extends RefCounted

const POISON_SPREAD_TARGETS := 2
const POISON_SPREAD_RADIUS := 30.0
const POISON_SPREAD_DAMAGE_PER_SECOND := 3.0
const POISON_SPREAD_SECONDS := 4.0

var survivor: Survivor
var horde: ZombieHorde
var projectiles: ProjectilePool
var effects: Effects
var lighting: Lighting
var shards: VaccineShardField
var area_effects: AreaEffects
var props: Props
var camera: RunCamera
## 빛과 어둠 숫자 (data/run_rules.json lighting)
var light_rules: Dictionary = {}
var juice_rules: Dictionary = {}
var spawn_distance: float = 200.0
## 판이 시작되고 지난 초 (일시정지 시간 제외)
var elapsed_seconds: float = 0.0


## 무기·스킬 피해를 생존자 능력치로 계산: 모든 피해 배율 + 치명타. {"amount": 피해, "is_crit": 치명타였나}
func roll_damage(base_damage: float) -> Dictionary:
	var stats := survivor.stats
	var amount := base_damage * stats.value("damage_multiplier")
	var is_crit := randf() < stats.value("crit_chance")
	if is_crit:
		amount *= stats.value("crit_damage_multiplier")
	return {"amount": amount, "is_crit": is_crit}


## 역학조사관 전직: 독으로 쓰러진 좀비 주변 2마리에 독을 옮긴다.
func spread_poison_from(dead_zombie: Zombie) -> void:
	var neighbors := horde.in_radius(dead_zombie.position, POISON_SPREAD_RADIUS)
	neighbors.sort_custom(func(first: Zombie, second: Zombie) -> bool:
		return first.position.distance_to(dead_zombie.position) < second.position.distance_to(dead_zombie.position))
	var poison_power := POISON_SPREAD_DAMAGE_PER_SECOND * survivor.stats.value("poison_damage_multiplier")
	for neighbor: Zombie in neighbors.slice(0, POISON_SPREAD_TARGETS):
		neighbor.apply_poison(poison_power, POISON_SPREAD_SECONDS)
		effects.burst(neighbor.position, Color("b388ff"), 3)


func play_sound(sound_name: String, pitch_offset: float = 0.0) -> void:
	SoundPlayer.play(sound_name, pitch_offset)


## event_name: "survivor_big_hit" · "boss_charge" · "explosion" · "boss_kill" · "skill" · "recoil"
## 충격 크기는 data/run_rules.json juice 의 "trauma_<이름>" (코드에 숫자를 두지 않으려고)
func shake(event_name: String) -> void:
	camera.add_trauma(float(juice_rules.get("trauma_" + event_name, 0.0)))
