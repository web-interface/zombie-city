## [파일] scripts/weapons/bear_traps.gd
## [하는 일] 바닥에 놓인 곰 덫들: 좀비가 덫 반경에 들어오면 철컥 닫혀 그 좀비들을 묶고(기절) 큰 피해를 준다. 지뢰밭(진화)은 닫힐 때 둘레까지 폭발. 열린 덫·닫힌 덫 그림(art/sprites/bear_trap.png 두 칸)을 그리고, 오래 안 밟히면 깜빡이다 사라진다.
## [쓰는 곳] scripts/weapons/weapon_zones.gd 가 하나 들고 update()·draw_on()·clear() 를 부른다. 곰 덫 무기(lob_area_weapon.gd, look "trap")가 WeaponZones.add_trap() 으로 놓는다.
## [근거 문서] 14 §3-1 사냥꾼 곰 덫·지뢰밭, data/weapons.json bear_trap
class_name BearTraps
extends RefCounted

const TEXTURE: Texture2D = preload("res://art/sprites/bear_trap.png")
const FRAME_SIZE := Vector2(12, 8)          # 왼쪽 칸 열림 · 오른쪽 칸 닫힘
const MAX_TRAPS := 16                        # 덫이 너무 많이 깔리면 가장 오래된 것부터 (성능·가독성)
const CHECK_SECONDS := 0.1                   # 밟았나 보는 간격
const CLOSED_SHOW_SECONDS := 0.7             # 닫힌 덫을 보여 주는 시간
const BLINK_BEFORE_GONE_SECONDS := 1.5       # 사라지기 전 깜빡임
const SPARK_COLOR := Color("c9ced8")
const TRIGGER_PITCH := -0.2                  # 덫 닫히는 소리는 낮고 묵직하게

var _traps: Array[Dictionary] = []
var _check_timer: float = 0.0
var _context: RunContext
var _visuals: WeaponVisuals


func _init(context: RunContext, visuals: WeaponVisuals) -> void:
	_context = context
	_visuals = visuals


func add(center: Vector2, trigger_radius: float, seconds: float, damage: float, bind_seconds: float, blast_radius: float, trigger_sound: String, is_evolved: bool) -> void:
	if _traps.size() >= MAX_TRAPS:
		_traps.pop_front()
	_traps.append({"center": center, "radius": trigger_radius, "time_left": seconds, "damage": damage, "bind_seconds": bind_seconds,
		"blast_radius": blast_radius, "sound": trigger_sound, "is_evolved": is_evolved, "is_closed": false})


func clear() -> void:
	_traps.clear()


func update(delta: float) -> void:
	_check_timer -= delta
	var is_check := _check_timer <= 0.0
	if is_check:
		_check_timer = CHECK_SECONDS
	var write_index := 0
	for trap: Dictionary in _traps:
		trap["time_left"] = float(trap["time_left"]) - delta
		if is_check and not bool(trap["is_closed"]):
			_check_trap(trap)
		if float(trap["time_left"]) > 0.0:
			_traps[write_index] = trap
			write_index += 1
	_traps.resize(write_index)


func _check_trap(trap: Dictionary) -> void:
	var caught := _context.horde.in_radius(trap["center"], float(trap["radius"]))
	if caught.is_empty():
		return
	trap["is_closed"] = true
	trap["time_left"] = CLOSED_SHOW_SECONDS
	var center: Vector2 = trap["center"]
	var blast_radius := float(trap["blast_radius"])
	if blast_radius > 0.0:   # 지뢰밭: 둘레까지 터진다
		caught = _context.horde.in_radius(center, blast_radius)
		_visuals.explosion(center, blast_radius, true)
		_context.shake("explosion")
	var boss_multiplier := float(_context.status_rules["boss_stun_multiplier"])
	for zombie: Zombie in caught:
		var rolled := _context.roll_damage(float(trap["damage"]))
		_context.horde.hit(zombie, rolled["amount"], {"is_crit": rolled["is_crit"], "source": "bear_trap"})
		zombie.stun(float(trap["bind_seconds"]) * (boss_multiplier if zombie.is_boss else 1.0))
	_visuals.sparks(center, Vector2.UP, 6)
	_visuals.spray(center, SPARK_COLOR, 4, 30.0)
	if not String(trap["sound"]).is_empty():
		_context.play_sound(String(trap["sound"]), TRIGGER_PITCH)


## 열린 덫(왼쪽 칸)·닫힌 덫(오른쪽 칸). 진화는 금색, 곧 사라질 덫은 깜빡인다.
func draw_on(canvas: CanvasItem, time: float) -> void:
	for trap: Dictionary in _traps:
		var is_closed := bool(trap["is_closed"])
		if not is_closed and float(trap["time_left"]) < BLINK_BEFORE_GONE_SECONDS and int(time * 8.0) % 2 == 0:
			continue
		var region := Rect2(Vector2(FRAME_SIZE.x if is_closed else 0.0, 0.0), FRAME_SIZE)
		var top_left := (Vector2(trap["center"]) - FRAME_SIZE * 0.5).round()
		var tint := Weapon.EVOLVED_COLOR if bool(trap["is_evolved"]) else Color.WHITE
		canvas.draw_texture_rect_region(TEXTURE, Rect2(top_left, FRAME_SIZE), region, tint)
