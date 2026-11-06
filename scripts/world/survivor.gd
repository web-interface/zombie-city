## [파일] scripts/world/survivor.gd
## [하는 일] 생존자(플레이어): 이동, 체력, 맞기·회복, 능력치(SurvivorStats), 스킬이 거는 상태(돌진·보호막·마지막 버티기). 그림은 자식 SurvivorAnimator 가 그린다.
## [쓰는 곳] scenes/run.tscn 의 World/Survivor. run.gd 가 매 프레임 move_step() 을 부르고, 좀비·스킬·시스템이 take_damage()·heal()·start_dash() 를 부른다. 판 시작 때 은신처·오늘의 도전·감염도 바꾸기(RunModifiers)를 능력치에 얹는다.
## [근거 문서] 02 §2 조작, 03 §1 생존자, 11 §4·§6
class_name Survivor
extends Node2D

signal damaged(amount: float)
signal healed(amount: float)
signal died

const HURT_FLASH_SECONDS := 0.08
const HURT_FLASH_GAP_SECONDS := 0.25   # 계속 닿아 있을 때 화면이 하얗게 번쩍거리지 않게
const LAST_STAND_GUARD_SECONDS := 1.5
## 체력이 이 비율 밑이면 '위험' (체력 막대 빨강·음악 긴장 — 한곳에서 정함)
const LOW_HEALTH_RATIO := 0.35

var survivor_id: String = ""
var stats: SurvivorStats
var health: float = 1.0
var facing: Vector2 = Vector2.DOWN
var moving_direction: Vector2 = Vector2.ZERO
var is_dead: bool = false
var last_damage_source: String = ""

var _guard_time_left: float = 0.0
var _guard_damage_multiplier: float = 1.0
var _dash_time_left: float = 0.0
var _dash_speed_multiplier: float = 1.0
var _dash_is_invulnerable: bool = false
var _last_stand_used: bool = false
var _hurt_flash_cooldown: float = 0.0
var _last_max_health: float = 1.0

## 돌진 중 부딪힌 좀비에게 줄 피해·밀기 (스킬이 정함, 0 이면 없음)
var dash_contact_damage: float = 0.0
var dash_knockback: float = 0.0

@onready var animator: SurvivorAnimator = $Animator


func setup(new_survivor_id: String) -> void:
	survivor_id = new_survivor_id
	var info := GameData.entry("survivors", survivor_id)
	var base_values: Dictionary = GameData.table("run_rules")["survivor_base_stats"].duplicate()
	base_values["max_health"] = float(info["max_health"])
	base_values["move_speed"] = float(info["move_speed"])
	stats = SurvivorStats.new(base_values)
	stats.set_source("trait", [info["trait"]])
	stats.set_source("meta", RunModifiers.survivor_stat_modifiers())   # 은신처 강화 + 오늘의 도전 규칙 (문서 14 §3)
	health = stats.value("max_health")
	_last_max_health = health
	stats.changed.connect(_on_stats_changed)
	animator.set_outfit(info["outfit"])


func set_outfit(outfit_name: String) -> void:
	animator.set_outfit(outfit_name)


## 한 프레임 이동. input_direction 은 조이스틱(또는 자동 플레이) 방향, 길이 0~1.
func move_step(delta: float, input_direction: Vector2) -> void:
	_tick_timers(delta)
	if is_dead:
		animator.animate(delta, Vector2.ZERO, facing)
		return
	moving_direction = input_direction.limit_length(1.0)
	if is_dashing():
		moving_direction = facing   # 돌진 중에는 방향을 바꾸지 않고 곧게 달린다
	elif moving_direction.length() > 0.05:
		facing = moving_direction.normalized()
	var speed := stats.value("move_speed") * (_dash_speed_multiplier if is_dashing() else 1.0)
	position += moving_direction * speed * delta
	_regenerate(delta)
	animator.animate(delta, moving_direction, facing)


## source = 무엇에 맞았는지 (결과 화면 "○○에게 당함" — 커뮤니티: 뭐에 죽었는지 모르면 짜증)
func take_damage(amount: float, source: String = "") -> void:
	var is_protected_by_dash := _dash_is_invulnerable and is_dashing()
	if is_dead or is_protected_by_dash:
		return
	if not source.is_empty():
		last_damage_source = source
	var guard_multiplier := _guard_damage_multiplier if _guard_time_left > 0.0 else 1.0
	var final_amount := amount * stats.value("damage_taken_multiplier") * guard_multiplier
	health -= final_amount
	if _hurt_flash_cooldown <= 0.0:
		animator.flash(HURT_FLASH_SECONDS)
		_hurt_flash_cooldown = HURT_FLASH_GAP_SECONDS
	damaged.emit(final_amount)
	if health <= 0.0:
		_on_health_depleted()


## ratio = 최대 체력의 몇 배를 회복할지 (회복 효과 능력치가 곱해짐)
func heal(ratio: float) -> void:
	if is_dead:
		return
	var amount := stats.value("max_health") * ratio * stats.value("heal_multiplier")
	var before := health
	health = minf(health + amount, stats.value("max_health"))
	healed.emit(health - before)


func start_dash(seconds: float, speed_multiplier: float, contact_damage: float, knockback: float, is_invulnerable: bool) -> void:
	_dash_time_left = seconds
	_dash_speed_multiplier = speed_multiplier
	_dash_is_invulnerable = is_invulnerable
	dash_contact_damage = contact_damage
	dash_knockback = knockback


func add_guard(seconds: float, damage_taken_multiplier: float) -> void:
	_guard_time_left = maxf(_guard_time_left, seconds)
	_guard_damage_multiplier = damage_taken_multiplier


func is_dashing() -> bool:
	return _dash_time_left > 0.0


func is_guarding() -> bool:
	return _guard_time_left > 0.0


func health_ratio() -> float:
	return clampf(health / stats.value("max_health"), 0.0, 1.0)


func _on_health_depleted() -> void:
	if stats.is_on("last_stand") and not _last_stand_used:
		_last_stand_used = true
		health = 1.0
		add_guard(LAST_STAND_GUARD_SECONDS, 0.0)
		return
	health = 0.0
	is_dead = true
	animator.play_death()
	died.emit()


func _regenerate(delta: float) -> void:
	var regen := stats.value("regen_per_second") * stats.value("heal_multiplier")
	if regen > 0.0:
		health = minf(health + regen * delta, stats.value("max_health"))


func _tick_timers(delta: float) -> void:
	_guard_time_left = maxf(_guard_time_left - delta, 0.0)
	_dash_time_left = maxf(_dash_time_left - delta, 0.0)
	_hurt_flash_cooldown = maxf(_hurt_flash_cooldown - delta, 0.0)


## 최대 체력이 늘면 늘어난 만큼 바로 채운다 (방탄조끼·전직).
func _on_stats_changed() -> void:
	var new_max := stats.value("max_health")
	if new_max > _last_max_health:
		health += new_max - _last_max_health
	health = minf(health, new_max)
	_last_max_health = new_max
