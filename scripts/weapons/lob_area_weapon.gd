## [파일] scripts/weapons/lob_area_weapon.gd
## [하는 일] 던져서 떨어진 자리에 터지는·남는 무기: 최루탄(look "gas", 연기 구름 — 느려짐), 화염병(look "fire", 불 장판), 조명탄(look "flare", 폭발 + 불타는 빛 기둥), 배달 드론(look "parcel", 머리 위 드론이 소포 폭탄을 떨굼 — 폭발만), 구장 조명(look "stadium", 하얀 빛 기둥 — 빛 안 좀비는 느리고 더 아픔), 곰 덫(look "trap", 바닥에 놓여 밟으면 닫힘), 노트북(look "laptop", 떨어진 자리 폭발). 사거리 안 무작위 좀비 쪽으로 throw_count 개를 포물선으로 던지고(드론은 위에서 떨굼), 떨어지면 impact_damage 폭발·zone_seconds 장판. 불바다(화염병 진화)는 장판이 줄줄이 이어진다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "lob_area" 인 무기로 만들고, 그리기 때 draw_on()(날아가는 물건·드론)을 부른다. 장판은 WeaponZones, 폭발 그림은 WeaponVisuals.
## [근거 문서] 14 §2-2 최루탄·조명탄·배달 드론·화염병, §2-4 진압 작전·대낮·드론 편대·불바다, §2-7 (폭발 = 원 + 파편 + 흔들림)
class_name LobAreaWeapon
extends Weapon

const FLIGHT_SECONDS := 0.45
const FLIGHT_STAGGER_SECONDS := 0.08     # 여러 개를 던질 때 하나씩 늦게 떨어지게 (줄줄이 터지는 맛)
const ARC_HEIGHT := 18.0                 # 포물선 꼭대기 높이(점)
const HAND_HEIGHT := Vector2(0, -6)
const DRONE_HOVER := Vector2(0, -20)     # 배달 드론이 떠 있는 자리 (머리 위)
const DRONE_SPACING := 10.0
const DRONE_BOB_SPEED := 5.0
const DRONE_BOB_HEIGHT := 1.5
const IMPACT_KNOCKBACK := 4.0            # 폭발에 살짝 밀려나는 거리
## 날아가는 물건 모양: 몸통 색 · 크기 · 위에 붙은 점 색 (불꽃·심지)
const THROWN_LOOKS := {
	"gas": {"body": Color("8d949e"), "size": Vector2(2, 3), "tip": Color("c9d6c3")},
	"fire": {"body": Color("5f8f4e"), "size": Vector2(2, 3), "tip": Color("8fd3ff")},
	"flare": {"body": Color("c9d6ff"), "size": Vector2(1, 4), "tip": Color("fff2b0")},
	"parcel": {"body": Color("c8aa78"), "size": Vector2(3, 3), "tip": Color("e8d9a8")},
	"stadium": {"body": Color("9aa3b5"), "size": Vector2(1, 5), "tip": Color("fffbe0")},
	"trap": {"body": Color("5b5f6b"), "size": Vector2(3, 2), "tip": Color("c9ced8")},
	"laptop": {"body": Color("4a5262"), "size": Vector2(4, 3), "tip": Color("8fd3ff")},
}
## 모양 → 장판 종류 (구장 조명은 '빛' 장판, 나머지는 이름 그대로)
const ZONE_KINDS := {"stadium": "light"}
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const GLASS_COLOR := Color("cfe8d6")

var _flights: Array[Dictionary] = []
var _drone_time: float = 0.0


func update(delta: float) -> void:
	_drone_time += delta
	super.update(delta)
	var write_index := 0
	for flight: Dictionary in _flights:
		flight["time"] = float(flight["time"]) + delta
		if float(flight["time"]) >= float(flight["duration"]):
			_land(flight["to"])
			continue
		_flights[write_index] = flight
		write_index += 1
	_flights.resize(write_index)


func attack() -> bool:
	var stats := numbers()
	var candidates := context.horde.in_radius(context.survivor.position, effective_range())
	if candidates.is_empty():
		return false
	var throw_count := int(stats["throw_count"])
	var line_spacing := float(stats.get("line_spacing", 0.0))
	var first_target := candidates[randi() % candidates.size()].position
	var line_direction := (first_target - context.survivor.position).normalized()
	for index: int in range(throw_count):
		var target := first_target
		if line_spacing > 0.0:   # 불바다: 첫 자리에서 바깥쪽으로 줄줄이
			target = first_target + line_direction * line_spacing * index
		elif index > 0:
			target = candidates[randi() % candidates.size()].position
		_flights.append({"from": _launch_position(index), "to": target, "time": 0.0, "duration": FLIGHT_SECONDS + FLIGHT_STAGGER_SECONDS * index})
	return true


## 판이 새로 시작될 때 날아가던 것을 비운다
func clear_flights() -> void:
	_flights.clear()


func _launch_position(index: int) -> Vector2:
	if look != "parcel":
		return context.survivor.position + HAND_HEIGHT
	return _drone_position(index % maxi(1, int(numbers().get("drone_count", 1))))


func _drone_position(index: int) -> Vector2:
	var count := maxi(1, int(numbers().get("drone_count", 1)))
	var side := (index - (count - 1) * 0.5) * DRONE_SPACING
	var bob := roundf(sin(_drone_time * DRONE_BOB_SPEED + index) * DRONE_BOB_HEIGHT)
	return context.survivor.position + DRONE_HOVER + Vector2(side, bob)


## 떨어진 자리: 폭발 피해 → 장판 → 소리·흔들림. 곰 덫은 터지지 않고 바닥에 놓인다 (밟으면 닫힘 — WeaponZones).
func _land(center: Vector2) -> void:
	var stats := numbers()
	var radius := area_radius(float(stats["radius"]))
	var impact := float(stats["impact_damage"])
	if look == "trap":
		zones().add_trap(center, radius, float(stats["zone_seconds"]), impact, float(stats["stun_seconds"]), area_radius(float(stats.get("trap_blast_radius", 0.0))), String(info.get("trigger_sound", "")), is_evolved)
		context.play_sound(String(info["sound"]), sound_pitch())
		return
	if impact > 0.0:
		for zombie: Zombie in context.horde.in_radius(center, radius):
			strike(zombie, impact, center, IMPACT_KNOCKBACK)
		visuals().explosion(center, radius, is_evolved)
		shake_screen()
	var zone_seconds := float(stats["zone_seconds"])
	if zone_seconds > 0.0:
		zones().add_zone(ZONE_KINDS.get(look, look), center, radius, zone_seconds, float(stats["damage_per_second"]), float(stats["slow_ratio"]), float(stats["stun_seconds"]), is_evolved)
	if look == "fire":
		visuals().spray(center, GLASS_COLOR, 5, 35.0)   # 병 깨지는 유리 조각
	elif look == "gas":
		visuals().puff(center, THROWN_LOOKS["gas"]["tip"], 6, radius * 0.6)
	context.play_sound(String(info["sound"]), sound_pitch())


func draw_on(canvas: CanvasItem) -> void:
	if look == "parcel":
		_draw_drones(canvas)
	for flight: Dictionary in _flights:
		_draw_flight(canvas, flight)


## 날아가는 물건 위의 불꽃·심지·연기 한 점 — 밤에도 반짝여 보이게 빛 층에
func draw_glow_on(canvas: CanvasItem) -> void:
	var tip_color: Color = THROWN_LOOKS.get(look, THROWN_LOOKS["fire"])["tip"]
	for flight: Dictionary in _flights:
		var tip := _body_position(flight) + Vector2(0.0, -2.0)
		canvas.draw_rect(Rect2(tip.round(), Vector2.ONE), tip_color)
		if int(float(flight["time"]) * 20.0) % 2 == 0:
			canvas.draw_rect(Rect2((tip + Vector2(0.0, -1.0)).round(), Vector2.ONE), Color(tip_color, 0.5))


func _draw_flight(canvas: CanvasItem, flight: Dictionary) -> void:
	var progress := clampf(float(flight["time"]) / float(flight["duration"]), 0.0, 1.0)
	var from_position: Vector2 = flight["from"]
	var to_position: Vector2 = flight["to"]
	var thrown: Dictionary = THROWN_LOOKS.get(look, THROWN_LOOKS["fire"])
	var ground := to_position if look == "parcel" else from_position.lerp(to_position, progress)
	var body_position := _body_position(flight)
	var size: Vector2 = thrown["size"]
	canvas.draw_rect(Rect2((ground - Vector2(1.5, 0.0)).round(), Vector2(3, 1)), SHADOW_COLOR)
	var body := Rect2((body_position - size * 0.5).round(), size)
	if is_evolved:
		canvas.draw_rect(body.grow(1.0), EVOLVED_COLOR)
	canvas.draw_rect(body, thrown["body"])


## 포물선(던지기) 또는 곧장 떨어지기(드론 소포 — 점점 빠르게) 위의 지금 자리
func _body_position(flight: Dictionary) -> Vector2:
	var progress := clampf(float(flight["time"]) / float(flight["duration"]), 0.0, 1.0)
	var from_position: Vector2 = flight["from"]
	var to_position: Vector2 = flight["to"]
	if look == "parcel":
		return from_position.lerp(to_position, progress * progress)
	return from_position.lerp(to_position, progress) + Vector2(0.0, -sin(progress * PI) * ARC_HEIGHT)


## 배달 드론: 머리 위에서 까딱이며 떠 있다 (드론 편대는 3대·금색)
func _draw_drones(canvas: CanvasItem) -> void:
	var texture := OrbitWeapon.DRONE_TEXTURES[int(_drone_time * 14.0) % 2]
	var tint := EVOLVED_COLOR if is_evolved else Color.WHITE
	for index: int in range(maxi(1, int(numbers().get("drone_count", 1)))):
		canvas.draw_texture(texture, (_drone_position(index) - texture.get_size() * 0.5).round(), tint)
