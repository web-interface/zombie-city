## [파일] scripts/world/vaccine_shard_field.gd
## [하는 일] 백신 조각(경험치) 전부: 쓰러진 좀비 자리에 떨구기(양에 따라 작은·중간·큰 조각), 줍는 범위 안이면 생존자에게 끌려오기, 닿으면 줍기. 조각이 너무 많으면 합친다. 연달아 주우면 소리가 점점 높아진다.
## [쓰는 곳] scenes/run.tscn 의 World/VaccineShards. 좀비가 쓰러지면 run.gd 가 drop() 을, 매 프레임 update() 를 부른다. 물류왕 전직 스킬이 collect_all() 을 부른다.
## [근거 문서] 03 §5 레벨과 경험치, 13 커뮤니티 조사(줍기가 노동이 되지 않게)
class_name VaccineShardField
extends Node2D

signal collected(amount: float)

const MAX_SHARDS := 300
const COLLECT_DISTANCE := 5.0
const PICKUP_SOUND_STEPS := 5          # 줍는 소리 높이 단계 (shard_pickup_1~5)
const PICKUP_COMBO_RESET_SECONDS := 0.6
const MAGNET_ACCELERATION := 3.0      # 끌려오는 조각이 점점 빨라지는 정도 (빨려 오는 손맛)
const LARGE_SHARD_VALUE := 20
const MEDIUM_SHARD_VALUE := 5
const TEXTURES := {
	"small": preload("res://art/sprites/shard_small.png"),
	"medium": preload("res://art/sprites/shard_medium.png"),
	"large": preload("res://art/sprites/shard_large.png"),
}

var _shards: Array[Dictionary] = []
var _context: RunContext
var _pickup_combo: int = 0
var _pickup_combo_timer: float = 0.0
var _blink_time: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	z_index = -2


func drop(at_position: Vector2, amount: int) -> void:
	var remaining := amount
	while remaining > 0:
		var piece := _piece_size(remaining)
		remaining -= piece
		var scatter := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)) if amount > 1 else Vector2.ZERO
		_shards.append({"position": at_position + scatter, "value": piece, "is_pulled": false, "speed": 0.0})
	if _shards.size() > MAX_SHARDS:
		_merge_far_shards()


## 떨어져 있는 조각 위치들 (자동 플레이 봇이 주우러 갈 때)
func positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for shard: Dictionary in _shards:
		result.append(shard["position"])
	return result


## 화면의 조각을 모두 끌어온다 (물류왕 2차 전직)
func collect_all() -> void:
	for shard: Dictionary in _shards:
		shard["is_pulled"] = true


func update(delta: float) -> void:
	_blink_time += delta
	_pickup_combo_timer -= delta
	if _pickup_combo_timer <= 0.0:
		_pickup_combo = 0
	var survivor := _context.survivor
	var pickup_radius := survivor.stats.value("pickup_radius")
	var magnet_speed := float(GameData.rules("experience")["shard_magnet_speed"])
	var gained := 0.0
	for shard: Dictionary in _shards:
		var to_survivor := survivor.position - Vector2(shard["position"])
		if to_survivor.length() <= pickup_radius:
			shard["is_pulled"] = true
		if shard["is_pulled"]:
			shard["speed"] = float(shard["speed"]) + magnet_speed * MAGNET_ACCELERATION * delta
			shard["position"] = Vector2(shard["position"]) + to_survivor.normalized() * minf(float(shard["speed"]) * delta, to_survivor.length())
		if to_survivor.length() <= COLLECT_DISTANCE:
			gained += float(shard["value"])
			shard["value"] = 0
	if gained > 0.0:
		_play_pickup_sound()
		collected.emit(gained * (1.0 + survivor.stats.value("shard_bonus_ratio")))
	_shards.assign(_shards.filter(func(shard: Dictionary) -> bool: return int(shard["value"]) > 0))
	queue_redraw()


func _play_pickup_sound() -> void:
	_pickup_combo = mini(_pickup_combo + 1, PICKUP_SOUND_STEPS)
	_pickup_combo_timer = PICKUP_COMBO_RESET_SECONDS
	SoundPlayer.play_exact("shard_pickup_%d" % _pickup_combo)


## 생존자에게서 먼 작은 조각들을 큰 조각 하나로 합친다 (화면·성능 정리).
func _merge_far_shards() -> void:
	var survivor_position := _context.survivor.position
	_shards.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return Vector2(first["position"]).distance_to(survivor_position) > Vector2(second["position"]).distance_to(survivor_position))
	var merged_value := 0
	var merge_count := _shards.size() - MAX_SHARDS + 20
	var merge_position: Vector2 = _shards[0]["position"]
	for index: int in range(merge_count):
		merged_value += int(_shards[index]["value"])
	_shards.assign(_shards.slice(merge_count))
	_shards.append({"position": merge_position, "value": merged_value, "is_pulled": false, "speed": 0.0})


func _draw() -> void:
	var is_bright := int(_blink_time * 6.0) % 2 == 0
	for shard: Dictionary in _shards:
		var texture: Texture2D = TEXTURES[_size_name(int(shard["value"]))]
		var draw_position := Vector2(shard["position"]).round() - texture.get_size() * 0.5
		draw_texture(texture, draw_position, Color(1, 1, 1, 1.0 if is_bright else 0.8))


## 남은 양에서 떼어 낼 조각 크기 (큰 조각부터)
func _piece_size(remaining: int) -> int:
	if remaining >= LARGE_SHARD_VALUE:
		return LARGE_SHARD_VALUE
	if remaining >= MEDIUM_SHARD_VALUE:
		return MEDIUM_SHARD_VALUE
	return 1


func _size_name(value: int) -> String:
	if value >= LARGE_SHARD_VALUE:
		return "large"
	if value >= MEDIUM_SHARD_VALUE:
		return "medium"
	return "small"
