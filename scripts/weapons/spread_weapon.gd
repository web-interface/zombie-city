## [파일] scripts/weapons/spread_weapon.gd
## [하는 일] 산탄총: 짧은 사거리 안 가장 가까운 좀비 쪽으로 부채꼴(spread_degrees)에 여러 발을 한꺼번에 퍼뜨리고, 쏠 때 화면이 살짝 흔들린다(반동). 진화(슬러그 대포)하면 큰 한 발이 맞힌 자리에서 터진다 — 숫자 표대로. 쏘는 방식은 투사체 무기와 같아 이어받는다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "spread" 인 무기로 만든다.
## [근거 문서] 03 §2 무기(산탄총), 04 §3 산탄총 모습(부채꼴 불꽃·반동), 14 §2-4 슬러그 대포
class_name SpreadWeapon
extends ProjectileWeapon


func attack() -> bool:
	var target := context.horde.nearest(context.survivor.position, effective_range())
	if target == null:
		return false
	fire_volley((target.position - context.survivor.position).normalized())
	context.shake("recoil")
	return true
