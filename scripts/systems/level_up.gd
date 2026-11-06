## [파일] scripts/systems/level_up.gd
## [하는 일] 경험치와 레벨: 백신 조각을 모아 레벨을 올리고(다음 레벨까지 기본 + 레벨당 양 × 지금 레벨 — data/run_rules.json experience), 레벨마다 카드 3장(새 무기·무기 강화·새 장비·장비 강화)을 뽑아 보여 달라고 알린다. 고른 카드를 무기 칸에 적용한다. 다시 뽑기·건너뛰기(체력 조금 회복)도 맡는다. 보스 보상으로 카드 한 번 더 받기.
## [쓰는 곳] scenes/run.tscn 의 Systems/LevelUp. 조각(vaccine_shard_field.gd)이 add_experience() 를, 레벨 업 창(scripts/ui/level_up_panel.gd)이 choose()·reroll()·skip() 을 부른다.
## [근거 문서] 02 §5 성장과 조합, 03 §5 레벨과 경험치, data/run_rules.json build·experience
class_name LevelUp
extends Node

signal level_changed(new_level: int)
signal cards_ready(cards: Array)
signal card_applied(card: Dictionary)

var level: int = 1
var experience: float = 0.0
var rerolls_left: int = 0
var pending_choices: int = 0
var is_choosing: bool = false
var _context: RunContext
var _rack: WeaponRack
var _build_rules: Dictionary = {}
var _current_cards: Array = []


func setup(context: RunContext, rack: WeaponRack) -> void:
	_context = context
	_rack = rack
	_build_rules = GameData.rules("build")
	rerolls_left = int(_build_rules["rerolls_per_run"])


## 다음 레벨까지: shards_needed_base + shards_needed_per_level × 지금 레벨 (목표 레벨 10 ≈ 1:30, 레벨 20 ≈ 3:30 — 문서 13)
func experience_needed() -> float:
	var rules := GameData.rules("experience")
	return float(rules["shards_needed_base"]) + float(rules["shards_needed_per_level"]) * level


func add_experience(amount: float) -> void:
	experience += amount
	while experience >= experience_needed():
		experience -= experience_needed()
		level += 1
		pending_choices += 1
		level_changed.emit(level)
		_context.play_sound("level_up")


## 보스 보상: 카드 한 번 더
func grant_bonus_choice() -> void:
	pending_choices += 1


## 고를 차례가 남았고 지금 고르는 중이 아니면 카드를 뽑아 알린다 (run.gd 가 알맞은 때 부름).
func open_next_choice() -> bool:
	if pending_choices <= 0 or is_choosing:
		return false
	is_choosing = true
	_current_cards = _draw_cards()
	cards_ready.emit(_current_cards)
	return true


func choose(card: Dictionary) -> void:
	match String(card["kind"]):
		"new_weapon":
			_rack.add_weapon(String(card["id"]))
		"weapon_upgrade":
			_rack.upgrade_weapon(String(card["id"]))
		"new_gear", "gear_upgrade":
			_rack.add_or_upgrade_gear(String(card["id"]))
		"heal":
			_context.survivor.heal(_heal_card_ratio())
	_finish_choice(card)


func reroll() -> void:
	if rerolls_left <= 0:
		return
	rerolls_left -= 1
	_current_cards = _draw_cards()
	cards_ready.emit(_current_cards)


func skip() -> void:
	_context.survivor.heal(float(_build_rules["skip_card_heal_ratio"]))
	_finish_choice({"kind": "skip"})


func _finish_choice(card: Dictionary) -> void:
	pending_choices -= 1
	is_choosing = false
	_context.play_sound("card_select")
	card_applied.emit(card)


## 고를 수 있는 것 중 3장을 무작위로. 없으면 '회복' 카드.
func _draw_cards() -> Array:
	var pool := _possible_cards()
	pool.shuffle()
	var cards := pool.slice(0, int(_build_rules["cards_per_level_up"]))
	if cards.is_empty():
		var heal_text := "체력 %d%% 회복" % roundi(_heal_card_ratio() * 100.0)
		cards.append({"kind": "heal", "id": "heal", "name": "구급상자", "icon": "icon_first_aid", "description": heal_text, "level_text": ""})
	return cards


## 고를 게 없을 때 나오는 구급상자: 건너뛰기 회복의 2배 (고르는 쪽이 더 이득이게)
func _heal_card_ratio() -> float:
	return float(_build_rules["skip_card_heal_ratio"]) * 2.0


func _possible_cards() -> Array:
	var cards: Array = []
	var max_level := int(_build_rules["max_item_level"])
	var has_weapon_room := _rack.weapons.size() < int(_build_rules["weapon_slots"])
	var has_gear_room := _rack.gear_levels.size() < int(_build_rules["gear_slots"])
	for weapon_id: String in GameData.entry_ids("weapons"):
		var info := GameData.entry("weapons", weapon_id)
		var owned := _rack.weapon_of(weapon_id)
		if owned == null and has_weapon_room:
			cards.append(_card("new_weapon", weapon_id, info, "새로 얻기"))
		elif owned != null and owned.level < max_level:
			cards.append(_card("weapon_upgrade", weapon_id, info, "%d→%d단계" % [owned.level, owned.level + 1]))
	for gear_id: String in GameData.entry_ids("gear"):
		var info := GameData.entry("gear", gear_id)
		var gear_level := int(_rack.gear_levels.get(gear_id, 0))
		if gear_level == 0 and has_gear_room:
			cards.append(_card("new_gear", gear_id, info, "새로 얻기"))
		elif gear_level > 0 and gear_level < max_level:
			cards.append(_card("gear_upgrade", gear_id, info, "%d→%d단계" % [gear_level, gear_level + 1]))
	return cards


func _card(kind: String, item_id: String, info: Dictionary, level_text: String) -> Dictionary:
	return {"kind": kind, "id": item_id, "name": info["name"], "icon": info["icon"], "description": info["description"], "level_text": level_text}
