## [파일] scripts/world/zombie.gd
## [하는 일] 좀비 한 마리의 상태 묶음: 위치·체력·속도와 걸린 효과(독·기절·느려짐·밀려남·비명에 빨라짐), 같은 무기에 너무 자주 맞지 않게 하는 시간, 정예 여부, 특수 행동·보스 행동 상태. 계산만 하고 그리지는 않는다.
## [쓰는 곳] scripts/world/zombie_horde.gd 가 만들고 움직인다. 무기·스킬·보스 담당·zombie_abilities.gd 가 상태를 바꾼다.
## [근거 문서] 03 §6 좀비, 11 §4, 14 §1-2 새 좀비·정예
class_name Zombie
extends RefCounted

const MAX_POISON_STACKS := 3
const KNOCKBACK_SETTLE_SPEED := 10.0   # 밀려난 힘이 줄어드는 빠르기 (클수록 빨리 멈춤)

var kind_id: String
var info: Dictionary
var position: Vector2
var health: float
var max_health: float
var radius: float
var move_speed: float
var contact_damage_per_second: float
var shard_value: int
var is_boss: bool
var is_elite: bool = false
## 밀려나는 정도 (1 = 그대로). 보스·덩치·진압복은 덜 밀린다
var push_resistance: float = 1.0
var is_hidden_in_dark: bool
var is_dead: bool = false
var facing: Vector2 = Vector2.DOWN
var animation_time: float = 0.0
var sprite: Sprite2D

var flash_time_left: float = 0.0
var stun_time_left: float = 0.0
var slow_time_left: float = 0.0
var slow_speed_ratio: float = 1.0
var poison_damage_per_second: float = 0.0
var poison_time_left: float = 0.0
var poison_stacks: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO
## 비명 좀비가 소리치면 잠깐 빨라짐
var speed_boost_time_left: float = 0.0
var speed_boost_multiplier: float = 1.0
## 특수 행동(침·비명)까지 남은 초 — zombie_abilities.gd 만 쓴다
var ability_cooldown: float = 0.0
var death_time_left: float = 0.0
## 무기 이름 → 다시 맞을 수 있을 때까지 남은 초 (드론·돌진처럼 계속 닿는 공격용)
var hit_cooldowns: Dictionary = {}
## 보스 담당(boss_director.gd)만 쓰는 상태 (돌진 예고·돌진 중)
var boss_state: Dictionary = {}


func _init(new_kind_id: String, new_info: Dictionary, start_position: Vector2, health_multiplier: float) -> void:
	kind_id = new_kind_id
	info = new_info
	position = start_position
	max_health = float(info["max_health"]) * health_multiplier
	health = max_health
	radius = float(info["radius"])
	move_speed = float(info["move_speed"])
	contact_damage_per_second = float(info["contact_damage_per_second"])
	shard_value = int(info["shard_value"])
	is_boss = bool(info.get("is_boss", false))
	is_hidden_in_dark = bool(info.get("hidden_in_dark", false))
	push_resistance = float(info.get("push_resistance", 0.25 if is_boss else 1.0))
	if info.has("ability"):
		ability_cooldown = float(info["ability"].get("first_delay_seconds", 1.0))
	animation_time = randf() * 2.0   # 좀비마다 걸음 박자가 조금씩 다르게 (06 AI 티 안 나게)


## max_stacks = 몇 번까지 겹치나 (보통 3, 간호사 특성 5 — run_rules poison_max_stacks + 생존자 특성)
func apply_poison(damage_per_second: float, seconds: float, max_stacks: int = MAX_POISON_STACKS) -> void:
	poison_stacks = mini(poison_stacks + 1, max_stacks)
	poison_damage_per_second = damage_per_second * poison_stacks
	poison_time_left = seconds


func stun(seconds: float) -> void:
	stun_time_left = maxf(stun_time_left, seconds)


func slow(speed_ratio: float, seconds: float) -> void:
	slow_speed_ratio = minf(slow_speed_ratio, speed_ratio) if slow_time_left > 0.0 else speed_ratio
	slow_time_left = maxf(slow_time_left, seconds)


## direction 쪽으로 distance 만큼 밀려난다 (몇 프레임에 걸쳐 미끄러지듯). 보스·덩치는 덜 밀린다.
func push(direction: Vector2, distance: float) -> void:
	knockback_velocity += direction.normalized() * distance * KNOCKBACK_SETTLE_SPEED * push_resistance


## 금빛 정예로 바꾼다: 체력·크기·조각이 커지고 조금 느려진다 (data/spawn_curve.json elite)
func make_elite(elite_rules: Dictionary) -> void:
	is_elite = true
	max_health *= float(elite_rules["health_multiplier"])
	health = max_health
	radius *= float(elite_rules["size_multiplier"])
	shard_value *= int(elite_rules["shard_multiplier"])
	move_speed *= float(elite_rules["speed_multiplier"])
	push_resistance *= 0.5


func boost_speed(multiplier: float, seconds: float) -> void:
	speed_boost_multiplier = maxf(speed_boost_multiplier, multiplier) if speed_boost_time_left > 0.0 else multiplier
	speed_boost_time_left = maxf(speed_boost_time_left, seconds)


## 지금 걷는 빠르기 (느려짐·비명 효과 반영, 빛과 어둠은 무리가 따로 곱함)
func current_speed() -> float:
	return move_speed * slow_speed_ratio * speed_boost_multiplier


func is_stunned() -> bool:
	return stun_time_left > 0.0


## 무기 key 로 지금 맞을 수 있나 (맞으면 interval 초 동안 다시 안 맞음)
func try_take_hit_from(key: String, interval_seconds: float) -> bool:
	if float(hit_cooldowns.get(key, 0.0)) > 0.0:
		return false
	hit_cooldowns[key] = interval_seconds
	return true


## 시간이 흐르며 줄어드는 것들. 이번 프레임의 독 피해를 돌려준다.
func tick_effects(delta: float) -> float:
	flash_time_left = maxf(flash_time_left - delta, 0.0)
	stun_time_left = maxf(stun_time_left - delta, 0.0)
	slow_time_left = maxf(slow_time_left - delta, 0.0)
	if slow_time_left <= 0.0:
		slow_speed_ratio = 1.0
	speed_boost_time_left = maxf(speed_boost_time_left - delta, 0.0)
	if speed_boost_time_left <= 0.0:
		speed_boost_multiplier = 1.0
	if not hit_cooldowns.is_empty():   # 대부분의 좀비는 비어 있다 — 빈 걸 훑느라 매번 배열을 만들지 않게
		for key: String in hit_cooldowns.keys():
			hit_cooldowns[key] = float(hit_cooldowns[key]) - delta
	position += knockback_velocity * delta
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_velocity.length() * KNOCKBACK_SETTLE_SPEED * delta)
	if poison_time_left <= 0.0:
		poison_stacks = 0
		return 0.0
	poison_time_left -= delta
	return poison_damage_per_second * delta
