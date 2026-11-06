## [파일] scripts/weapons/chain_weapon.gd
## [하는 일] 번개 튀기기 무기(테이저건): 사거리 안 가장 가까운 좀비에게 번개를 쏘고, 맞은 좀비에서 아직 안 맞은 가장 가까운 좀비로 chain_count 마리까지 튄다. 맞은 좀비는 감전(피해)·잠깐 기절. 진화(낙뢰)하면 화면 곳곳의 좀비에게 하늘에서 번개가 내리꽂힌다(반경 피해).
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "chain" 인 무기로 만든다. 번개 그림은 WeaponVisuals.lightning()·sky_bolt().
## [근거 문서] 14 §2-2 테이저건·§2-4 낙뢰·§2-7 (번개 = 지그재그 하얀 번쩍)
class_name ChainWeapon
extends Weapon

const MUZZLE_HEIGHT := Vector2(0, -4)

var _chained: Array[Zombie] = []   # 이번 번개에 이미 맞은 좀비 (다시 튀지 않게 — 재사용)


func attack() -> bool:
	var stats := numbers()
	var first := context.horde.nearest(context.survivor.position, effective_range())
	if first == null:
		return false
	_zap_chain(first, stats)
	if int(stats.get("sky_strikes", 0)) > 0:
		_strike_from_sky(stats)
	play_attack_sound()
	return true


func _zap_chain(first: Zombie, stats: Dictionary) -> void:
	_chained.clear()
	var from_position := context.survivor.position + MUZZLE_HEIGHT
	var target := first
	var chain_range := area_radius(float(stats["chain_range"]))
	for index: int in range(int(stats["chain_count"])):
		if target == null:
			break
		visuals().lightning(from_position, target.position, is_evolved)
		_shock(target, stats)
		_chained.append(target)
		from_position = target.position
		target = _next_target(from_position, chain_range)


func _shock(zombie: Zombie, stats: Dictionary) -> void:
	strike(zombie, float(stats["damage"]), zombie.position, 0.0)
	stun_zombie(zombie, float(stats["stun_seconds"]))


## 아직 안 맞은 좀비 중 가장 가까운 것 (없으면 null — 번개가 거기서 멈춘다)
func _next_target(from_position: Vector2, max_distance: float) -> Zombie:
	var best: Zombie = null
	var best_distance := max_distance
	for zombie: Zombie in context.horde.in_radius(from_position, max_distance):
		var distance := zombie.position.distance_to(from_position)
		if distance < best_distance and not _chained.has(zombie):
			best = zombie
			best_distance = distance
	return best


## 낙뢰: 화면 곳곳 좀비 sky_strikes 마리 자리에 번개가 떨어져 둘레까지 맞힌다
func _strike_from_sky(stats: Dictionary) -> void:
	var candidates := context.horde.in_radius(context.survivor.position, float(stats["strike_range"]))
	var strike_radius := area_radius(float(stats["strike_radius"]))
	for index: int in range(mini(int(stats["sky_strikes"]), candidates.size())):
		var pick := randi_range(index, candidates.size() - 1)   # 앞쪽과 바꿔 같은 좀비를 두 번 고르지 않게
		var chosen := candidates[pick]
		candidates[pick] = candidates[index]
		candidates[index] = chosen
		visuals().sky_bolt(chosen.position)
		for zombie: Zombie in context.horde.in_radius(chosen.position, strike_radius):
			strike(zombie, float(stats["strike_damage"]), chosen.position, 0.0)
	if not candidates.is_empty():
		shake_screen()
