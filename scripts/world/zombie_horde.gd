## [파일] scripts/world/zombie_horde.gd
## [하는 일] 좀비 무리 전부를 한곳에서 관리: 만들기, 생존자 쪽으로 움직이기(빛과 어둠에 따라 빠르기 다름), 서로 밀어내기, 생존자에게 닿으면 피해, 맞기·쓰러지기, 그림(걷기 4장·3방향, 맞으면 하얗게). 근처 좀비 찾기도 맡는다.
## [쓰는 곳] scenes/run.tscn 의 World/ZombieHorde. run.gd 가 setup()·update() 를 부르고, 무기·스킬·시스템이 hit()·nearest()·in_radius() 를 쓴다.
## [근거 문서] 03 §6·§7, 02 §4 빛과 어둠, 11 §4·§5·§6
class_name ZombieHorde
extends Node2D

signal zombie_died(zombie: Zombie)

const GRID_CELL_SIZE := 16.0
const CONTACT_MARGIN := 4.0          # 생존자 몸 크기 (좀비 반경에 더해 닿았는지 봄)
const RECYCLE_DISTANCE := 260.0      # 이보다 멀어진 좀비는 원래 있던 쪽 화면 밖 고리로 당겨 와 다시 씀
const DEATH_SHOW_SECONDS := 0.6      # 쓰러지는 동작을 보여 주는 시간
const WALK_FRAMES_PER_SECOND := 6.0
const HIDDEN_ZOMBIE_REVEAL_DISTANCE := 40.0
## 어둠 속 기어다니는 좀비도 아주 흐린 윤곽은 남긴다 — 어둠은 분위기, 적은 늘 보이게 (국내 조사, 문서 13)
const HIDDEN_ZOMBIE_MIN_ALPHA := 0.18
const HIT_FLASH_SECONDS := 0.06
const BASE_WALK_SPEED := 13.0        # 이 빠르기의 좀비가 기본 걸음 박자, 더 빠르면 다리를 더 빨리 놀린다
## 독 피해처럼 자주 들어오는 피해는 숫자·소리를 내지 않는다 (매번 새 묶음을 만들지 않게 상수로)
const QUIET_POISON_HIT := {"source": "poison", "show_number": false}
const SILENT_SOURCES: Array[String] = ["poison", "fire"]

var zombies: Array[Zombie] = []
var _dying: Array[Zombie] = []
var _grid := SpatialGrid.new(GRID_CELL_SIZE)
var _nearby_buffer: Array[int] = []      # 근처 찾기 결과를 담는 재사용 그릇 (매번 새로 만들지 않게)
## 이번 프레임에 생존자를 문 좀비 수 — 한 번에 무는 수를 제한해 둘러싸여도 빠져나갈 틈을 준다 (억울한 죽음 금지)
var _biters_this_frame: int = 0
var _bite_limit: int = 3
var _sprite_pool: Array[Sprite2D] = []
var _textures: Dictionary = {}       # 그림 이름 → [보통, 하얀 실루엣]
var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context


func spawn(kind_id: String, at_position: Vector2, health_multiplier: float) -> Zombie:
	var zombie := Zombie.new(kind_id, GameData.entry("zombies", kind_id), at_position, health_multiplier)
	zombie.sprite = _take_sprite(zombie)
	zombies.append(zombie)
	return zombie


func update(delta: float) -> void:
	_rebuild_grid()
	var survivor := _context.survivor
	_biters_this_frame = 0
	_bite_limit = int(_context.status_rules["max_zombies_hurting_at_once"])
	for zombie: Zombie in zombies:
		var poison_damage := zombie.tick_effects(delta)
		if poison_damage > 0.0:
			hit(zombie, poison_damage, QUIET_POISON_HIT)
		if zombie.is_dead:
			continue
		_move_toward_survivor(zombie, delta)
		_touch_survivor(zombie, survivor, delta)
	_separate_neighbors()
	_remove_dead_and_animate(delta)
	_rebuild_grid()   # 무기·스킬이 이번 프레임에 찾을 때 움직인 뒤의 위치로 찾게


## 좀비에게 피해를 준다. options: knockback_from(Vector2) · knockback(float) · is_crit(bool) · source(String) · show_number(bool)
func hit(zombie: Zombie, amount: float, options: Dictionary = {}) -> void:
	if zombie.is_dead:
		return
	var in_light := _context.lighting.is_in_light(zombie.position)
	var light_bonus: float = float(_context.light_rules["zombie_damage_taken_in_light"]) if in_light else 1.0
	var final_amount: float = amount * light_bonus
	zombie.health -= final_amount
	zombie.flash_time_left = HIT_FLASH_SECONDS
	if options.has("knockback_from") and float(options.get("knockback", 0.0)) > 0.0:
		var away: Vector2 = zombie.position - Vector2(options["knockback_from"])
		zombie.push(away, float(options["knockback"]) * _context.survivor.stats.value("knockback_multiplier"))
	# 피해 숫자는 치명타·큰 피해·보스만 (화면이 숫자로 덮이지 않게 — 문서 13)
	var is_crit := bool(options.get("is_crit", false))
	var is_notable: bool = is_crit or zombie.is_boss or final_amount >= float(_context.juice_rules["damage_number_min_amount"])
	if bool(options.get("show_number", true)) and is_notable:
		_context.effects.show_damage_number(zombie.position, final_amount, is_crit)
	var source := String(options.get("source", ""))
	if not SILENT_SOURCES.has(source):
		_context.play_sound("boss_hit" if zombie.is_boss else "zombie_hit")
	if zombie.health <= 0.0:
		_kill(zombie, source)


func nearest(from_position: Vector2, max_distance: float) -> Zombie:
	var best: Zombie = null
	var best_distance := max_distance
	_grid.collect_nearby(from_position, max_distance, _nearby_buffer)
	for index: int in _nearby_buffer:
		var zombie := zombies[index]
		var distance := zombie.position.distance_to(from_position)
		if not zombie.is_dead and distance < best_distance and _is_visible_target(zombie):
			best = zombie
			best_distance = distance
	return best


func in_radius(center: Vector2, radius: float) -> Array[Zombie]:
	var found: Array[Zombie] = []
	_grid.collect_nearby(center, radius + 12.0, _nearby_buffer)
	for index: int in _nearby_buffer:
		var zombie := zombies[index]
		if not zombie.is_dead and zombie.position.distance_to(center) <= radius + zombie.radius:
			found.append(zombie)
	return found


func alive_count() -> int:
	return zombies.size()


func _move_toward_survivor(zombie: Zombie, delta: float) -> void:
	if zombie.is_stunned() or zombie.boss_state.get("is_charging", false) or zombie.boss_state.get("is_warning", false):
		return
	var to_survivor := _context.survivor.position - zombie.position
	if to_survivor.length() < zombie.radius + CONTACT_MARGIN:
		return
	var light_speed: float = _context.light_rules["zombie_speed_in_light"] if _context.lighting.is_in_light(zombie.position) else _context.light_rules["zombie_speed_in_dark"]
	zombie.facing = to_survivor.normalized()
	zombie.position += zombie.facing * zombie.move_speed * zombie.slow_speed_ratio * light_speed * delta
	if to_survivor.length() > RECYCLE_DISTANCE and not zombie.is_boss:
		zombie.position = _context.survivor.position - to_survivor.normalized() * _context.spawn_distance


func _touch_survivor(zombie: Zombie, survivor: Survivor, delta: float) -> void:
	if zombie.position.distance_to(survivor.position) > zombie.radius + CONTACT_MARGIN:
		return
	if survivor.is_dashing() and survivor.dash_contact_damage > 0.0:
		if zombie.try_take_hit_from("dash", float(_context.status_rules["dash_hit_interval_seconds"])):
			hit(zombie, survivor.dash_contact_damage, {"knockback_from": survivor.position, "knockback": survivor.dash_knockback, "source": "dash"})
		return
	if zombie.is_stunned():
		return
	if zombie.is_boss:   # 보스는 제한 밖에서 따로 문다 (졸개 2마리가 먼저 물고 있으면 보스 피해가 통째로 빠지던 것 — 마지막 검수)
		survivor.take_damage(zombie.contact_damage_per_second * delta, String(zombie.info["name"]))
	elif _biters_this_frame < _bite_limit:
		_biters_this_frame += 1
		survivor.take_damage(zombie.contact_damage_per_second * delta, String(zombie.info["name"]))


## 좀비끼리 겹치지 않게 살짝 밀어낸다. 칸 나누기로 가까운 것만 본다.
func _separate_neighbors() -> void:
	for index: int in range(zombies.size()):
		var zombie := zombies[index]
		_grid.collect_nearby(zombie.position, zombie.radius * 2.0, _nearby_buffer)
		for other_index: int in _nearby_buffer:
			if other_index <= index:
				continue
			var other := zombies[other_index]
			var gap := other.position - zombie.position
			var needed := zombie.radius + other.radius - 1.0
			var distance := gap.length()
			if distance > 0.01 and distance < needed:
				var push := gap / distance * (needed - distance) * 0.5
				zombie.position -= push * (0.2 if zombie.is_boss else 1.0)
				other.position += push * (0.2 if other.is_boss else 1.0)


func _kill(zombie: Zombie, source: String) -> void:
	zombie.is_dead = true
	zombie.death_time_left = DEATH_SHOW_SECONDS
	zombie.animation_time = 0.0
	_dying.append(zombie)
	zombie_died.emit(zombie)
	if source == "poison" and _context.survivor.stats.is_on("poison_spread"):
		_context.spread_poison_from(zombie)


func _remove_dead_and_animate(delta: float) -> void:
	_keep_only(zombies, func(zombie: Zombie) -> bool: return not zombie.is_dead)
	for zombie: Zombie in zombies:
		_animate(zombie, delta)
	for zombie: Zombie in _dying:
		zombie.death_time_left -= delta
		zombie.animation_time += delta
		var rows := _rows_for(zombie)
		var frame_number := mini(int(zombie.animation_time / DEATH_SHOW_SECONDS * 3.0), 2)
		zombie.sprite.frame = SpriteSheetLayout.frame_index(rows, "death", frame_number)
		zombie.sprite.texture = _textures[zombie.info["sprite"]][0]
		zombie.sprite.modulate.a = clampf(zombie.death_time_left / DEATH_SHOW_SECONDS * 2.0, 0.0, 1.0)
		if zombie.death_time_left <= 0.0:
			_return_sprite(zombie.sprite)
	_keep_only(_dying, func(zombie: Zombie) -> bool: return zombie.death_time_left > 0.0)


## 배열을 새로 만들지 않고 그 자리에서 남길 것만 앞으로 당긴다 (매 프레임 300마리 — 성능)
func _keep_only(list: Array[Zombie], should_keep: Callable) -> void:
	var write_index := 0
	for zombie: Zombie in list:
		if should_keep.call(zombie):
			list[write_index] = zombie
			write_index += 1
	list.resize(write_index)


func _animate(zombie: Zombie, delta: float) -> void:
	zombie.animation_time += delta * (0.0 if zombie.is_stunned() else zombie.slow_speed_ratio)
	var direction_name := SpriteSheetLayout.direction_name(zombie.facing)
	var sprite := zombie.sprite
	sprite.position = zombie.position.round()
	sprite.flip_h = direction_name == "side" and zombie.facing.x < 0.0
	var speed_factor := zombie.move_speed / BASE_WALK_SPEED
	sprite.frame = SpriteSheetLayout.frame_index(_rows_for(zombie), SpriteSheetLayout.WALK_ACTIONS[direction_name], int(zombie.animation_time * WALK_FRAMES_PER_SECOND * speed_factor))
	sprite.texture = _textures[zombie.info["sprite"]][1 if zombie.flash_time_left > 0.0 else 0]
	var target_alpha := 1.0
	if zombie.is_hidden_in_dark and not _context.lighting.is_in_light(zombie.position):
		# 어둠 속이라도 가까이 오면 흐릿하게 보인다 (억울한 죽음 방지 — 문서 13)
		var is_close := zombie.position.distance_to(_context.survivor.position) < HIDDEN_ZOMBIE_REVEAL_DISTANCE
		target_alpha = 0.45 if is_close else HIDDEN_ZOMBIE_MIN_ALPHA
	sprite.modulate.a = move_toward(sprite.modulate.a, target_alpha, delta * 4.0)
	sprite.modulate.g = 0.55 if zombie.poison_time_left > 0.0 else 1.0   # 독에 걸리면 보랏빛


func _is_visible_target(zombie: Zombie) -> bool:
	return not zombie.is_hidden_in_dark or zombie.sprite.modulate.a > 0.3


func _rows_for(zombie: Zombie) -> Dictionary:
	return SpriteSheetLayout.BOSS_ROWS if zombie.is_boss else SpriteSheetLayout.ZOMBIE_ROWS


func _rebuild_grid() -> void:
	_grid.clear()
	for index: int in range(zombies.size()):
		_grid.insert(index, zombies[index].position)


func _take_sprite(zombie: Zombie) -> Sprite2D:
	var sprite_name: String = zombie.info["sprite"]
	if not _textures.has(sprite_name):
		_textures[sprite_name] = [load("res://art/sprites/%s.png" % sprite_name), load("res://art/sprites/%s_flash.png" % sprite_name)]
	var sprite: Sprite2D = _sprite_pool.pop_back() if not _sprite_pool.is_empty() else Sprite2D.new()
	if sprite.get_parent() == null:
		add_child(sprite)
	sprite.visible = true
	sprite.texture = _textures[sprite_name][0]
	sprite.hframes = SpriteSheetLayout.COLUMNS
	sprite.vframes = SpriteSheetLayout.BOSS_ROW_COUNT if zombie.is_boss else SpriteSheetLayout.ZOMBIE_ROW_COUNT
	sprite.offset = Vector2(0.0, -float(zombie.info["frame_size"]) / 2.0 + 3.0)   # 발밑이 좀비 위치에 오게
	sprite.modulate = Color(1, 1, 1, 0.0 if zombie.is_hidden_in_dark else 1.0)
	sprite.position = zombie.position.round()
	return sprite


func _return_sprite(sprite: Sprite2D) -> void:
	sprite.visible = false
	_sprite_pool.append(sprite)
