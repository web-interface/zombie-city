## [파일] scripts/weapons/weapon.gd
## [하는 일] 무기 공통 틀: 단계(1~5)와 진화, 지금 숫자 꺼내기(진화하면 진화 숫자 전부), 다시 공격까지 남은 시간(공격 속도 능력치 반영), "공격할 때가 됐나". 이름·아이콘·금색 여부, 치명타 더하기·기절·범위 같은 무기끼리 같이 쓰는 계산도 둔다. 무기마다 이 틀을 이어받아 attack()(언제 어떻게 때리나)만 따로 쓴다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 만들고 매 프레임 update() 를 부른다. 이어받는 곳: projectile·spread·melee_arc·orbit·chain·lob_area·pulse·line _weapon.gd
## [근거 문서] 03 §2 무기·§4 진화, 14 §2-2·§2-4, 11 §9 무기 구조
class_name Weapon
extends RefCounted

## 진화 무기는 금색 (문서 14 §2-7 — 진화 무기 = 금색 테두리·더 큰 효과)
const EVOLVED_COLOR := Color("ffd166")
const EVOLVED_SHAKE_MULTIPLIER := 1.5   # 진화 무기는 흔들림도 크게 (더 큰 효과)
const EVOLVED_PITCH_OFFSET := -0.18     # 진화 무기 소리는 낮고 굵게

var weapon_id: String
var info: Dictionary
var level: int = 1
var is_evolved: bool = false
var context: RunContext
## 같은 공격 방식 안에서 모양·장판 종류 (data/weapons.json look)
var look: String = ""
var _cooldown_left: float = 0.0
var _attack_count: int = 0


func _init(new_weapon_id: String, run_context: RunContext) -> void:
	weapon_id = new_weapon_id
	info = GameData.entry("weapons", weapon_id)
	context = run_context
	look = String(info.get("look", ""))


## 지금 단계의 숫자 묶음 (data/weapons.json levels). 진화했으면 evolution.numbers 전부.
func numbers() -> Dictionary:
	if is_evolved:
		return info["evolution"]["numbers"]
	var levels: Array = info["levels"]
	return levels[level - 1]


func max_level() -> int:
	var levels: Array = info["levels"]
	return levels.size()


func level_up() -> void:
	level = mini(level + 1, max_level())


## 최고 단계이고 아직 진화 안 했으면 짝 장비만 있으면 진화할 수 있다 (문서 14 §2-4)
func can_evolve() -> bool:
	return info.has("evolution") and not is_evolved and level >= max_level()


func evolution_gear_id() -> String:
	return String(info["evolution"]["gear"]) if info.has("evolution") else ""


func evolve() -> void:
	is_evolved = true
	_cooldown_left = 0.0   # 진화한 순간 바로 한 번 보여 준다


## 화면·기록에 쓰는 이름·아이콘·id — 진화하면 진화 쪽
func display_name() -> String:
	return String(info["evolution"]["name"]) if is_evolved else String(info["name"])


func icon_name() -> String:
	return String(info["evolution"]["icon"]) if is_evolved else String(info["icon"])


func final_id() -> String:
	return String(info["evolution"]["id"]) if is_evolved else weapon_id


func update(delta: float) -> void:
	_cooldown_left -= delta * context.survivor.stats.value("attack_speed_multiplier")
	if _cooldown_left > 0.0:
		return
	if attack():
		_cooldown_left = float(numbers()["interval_seconds"])


## 이어받는 무기가 쓴다. 실제로 공격했으면 true (목표가 없으면 false → 다음 프레임에 다시 시도)
func attack() -> bool:
	return false


## 무기가 따로 그릴 것이 있으면 (예: 도는 드론) 이어받아 쓴다. 밤 어둠을 받는 세상 층에 그려진다.
func draw_on(_canvas: CanvasItem) -> void:
	pass


## 어둠을 받지 않고 빛나 보여야 하는 것 (예: 소독약 안개) — WeaponVisuals 층에 그려진다.
func draw_glow_on(_canvas: CanvasItem) -> void:
	pass


## 사거리 능력치(저격수 전직 등)를 반영한 거리
func effective_range() -> float:
	return float(numbers()["range"]) * context.survivor.stats.value("range_multiplier")


## 범위 능력치(덕트 테이프·철거반)를 반영한 반경
func area_radius(base_radius: float) -> float:
	return base_radius * context.survivor.stats.value("area_multiplier")


## 생존자 피해 계산 + 이 무기만의 치명타 더하기(수술 칼날 폭풍)
func roll_damage(base_damage: float) -> Dictionary:
	var rolled := context.roll_damage(base_damage)
	var extra_crit_chance := float(numbers().get("extra_crit_chance", 0.0))
	if extra_crit_chance > 0.0 and not bool(rolled["is_crit"]) and randf() < extra_crit_chance:
		rolled["amount"] = float(rolled["amount"]) * context.survivor.stats.value("crit_damage_multiplier")
		rolled["is_crit"] = true
	return rolled


## 좀비 한 마리를 때린다: 피해(치명타 포함)·밀기. knockback 이 0 이면 밀지 않는다.
func strike(zombie: Zombie, base_damage: float, knockback_from: Vector2, knockback: float) -> void:
	if base_damage <= 0.0 and knockback <= 0.0:
		return
	var rolled := roll_damage(base_damage)
	context.horde.hit(zombie, rolled["amount"], {
		"is_crit": rolled["is_crit"],
		"knockback_from": knockback_from,
		"knockback": knockback,
		"source": weapon_id,
	})


## 기절 — 보스는 짧게만 (data/run_rules.json status_effects.boss_stun_multiplier)
func stun_zombie(zombie: Zombie, seconds: float) -> void:
	if seconds <= 0.0:
		return
	var boss_multiplier := float(context.status_rules["boss_stun_multiplier"])
	zombie.stun(seconds * (boss_multiplier if zombie.is_boss else 1.0))


## 공격 소리. 아주 자주 때리는 무기(절단기·소독약)는 sound_every_attacks 번에 한 번만 낸다 (귀가 아프지 않게).
## 진화 무기는 같은 소리를 낮고 굵게 (진화 = 전용 소리 — 문서 14 §2-7)
func play_attack_sound() -> void:
	_attack_count += 1
	if _attack_count % maxi(1, int(info.get("sound_every_attacks", 1))) == 0:
		context.play_sound(String(info["sound"]), sound_pitch())


## 소리 높낮이: 같은 소리를 다른 무기에 다시 쓸 때 data 의 sound_pitch 로 차이를 두고, 진화하면 더 낮게
func sound_pitch() -> float:
	return float(info.get("sound_pitch", 0.0)) + (EVOLVED_PITCH_OFFSET if is_evolved else 0.0)


## 큰 공격의 화면 흔들림 (data/weapons.json shake_trauma — 무기마다)
func shake_screen() -> void:
	var trauma := float(info.get("shake_trauma", 0.0))
	if trauma > 0.0:
		context.camera.add_trauma(trauma * (EVOLVED_SHAKE_MULTIPLIER if is_evolved else 1.0))


## 무기 연출 그리는 곳·무기 장판 (무기 칸이 하나씩 들고 있다)
func visuals() -> WeaponVisuals:
	return context.weapon_rack.visuals


func zones() -> WeaponZones:
	return context.weapon_rack.zones
