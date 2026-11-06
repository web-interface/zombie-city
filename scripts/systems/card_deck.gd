## [파일] scripts/systems/card_deck.gd
## [하는 일] 카드 뽑기 규칙: 이 생존자의 카드 풀(전용 무기 4·전용 장비 1 + 공용 무기 3·장비 12)에서 새로 얻기·단계 올리기 카드를 만들고, 진화할 수 있는 무기가 있으면 진화 카드를 먼저, 레벨 8 이후 아주 가끔(2%) 금색 히든 스킬 카드를 한 판에 한 번 끼운다. 빼 버린 카드는 그 판에서 다시 안 나온다. 보물 상자용(카드 여러 장을 미리 정함)도 여기서.
## [쓰는 곳] scripts/systems/level_up.gd 가 만들어 쓴다 (레벨 업 창·보물 상자 API). 무기 칸(weapon_rack.gd)과 data/survivors.json·weapons.json·gear.json·skills.json·flavor_texts.json·run_rules.json build 를 읽는다.
## [근거 문서] 14 §2-1 카드 규칙·§2-4 진화·§2-5 히든 스킬, 02 §5 성장과 조합
class_name CardDeck
extends RefCounted

## 한글 받침 계산용 (가 ~ 힣, 받침 28가지)
const HANGUL_FIRST := 0xAC00
const HANGUL_LAST := 0xD7A3
const HANGUL_FINALS := 28

## 남은 빼 버리기 횟수 (판마다 data/run_rules.json build.banishes_per_run)
var banishes_left: int = 0
var banished_ids: Array[String] = []
## 히든 카드는 한 판에 한 번만 나온다 (안 고르고 넘기면 그 판엔 끝)
var is_hidden_card_used_up: bool = false
var _context: RunContext
var _rack: WeaponRack
var _rules: Dictionary = {}
var _weapon_pool: Array[String] = []
var _gear_pool: Array[String] = []
var _hidden_skill_id: String = ""
var _flavor: Dictionary = {}


func _init(context: RunContext, rack: WeaponRack) -> void:
	_context = context
	_rack = rack
	_rules = GameData.rules("build")
	_flavor = GameData.table("flavor_texts")
	var survivor_info := GameData.entry("survivors", context.survivor.survivor_id)
	_weapon_pool.assign(survivor_info.get("weapon_pool", [survivor_info["start_weapon"]]))
	for weapon_id: String in _rules["common_weapons"]:
		_weapon_pool.append(weapon_id)
	_gear_pool.assign(survivor_info.get("gear_pool", []))
	for gear_id: String in _rules["common_gear"]:
		_gear_pool.append(gear_id)
	_hidden_skill_id = String(survivor_info.get("hidden_skill", ""))
	banishes_left = int(_rules["banishes_per_run"])


## 레벨 업 카드 3장: 진화 카드가 먼저, 나머지는 무작위. 히든 카드는 맨 앞에 (keep_hidden = 다시 뽑기라도 이미 뜬 히든 카드는 남김).
func draw_level_up_cards(level: int, keep_hidden: bool) -> Array[Dictionary]:
	var count := int(_rules["cards_per_level_up"])
	var cards := evolution_cards()
	var pool := upgrade_cards()
	pool.shuffle()
	for card: Dictionary in pool:
		if cards.size() >= count:
			break
		cards.append(card)
	_ensure_weapon_card(cards, pool, count)
	if cards.is_empty():
		cards.append(heal_card())
	if keep_hidden or _rolls_hidden_card(level):
		cards.insert(0, hidden_card())
		cards.resize(mini(cards.size(), count))
	return cards


## 보물 상자: count 장을 미리 정한다. 진화 → 가진 것 단계 올리기(같은 것 여러 번도 됨) → 새로 얻기 → 구급상자 순.
func draw_chest_cards(count: int) -> Array[Dictionary]:
	var cards := evolution_cards()
	var planned_levels: Dictionary = {}   # 이 상자에서 이미 올리기로 한 단계 수 (id → 몇 번)
	while cards.size() < count:
		var options := _owned_upgrade_cards(planned_levels)
		if options.is_empty():
			options = _new_item_cards(cards)
		if options.is_empty():
			cards.append(heal_card())
			continue
		var card: Dictionary = options.pick_random()
		planned_levels[card["id"]] = int(planned_levels.get(card["id"], 0)) + 1
		cards.append(card)
	cards.resize(mini(cards.size(), count))
	return cards


## 진화할 수 있는 무기마다 진화 카드 (문서 14 §2-4 — 무기 최고 단계 + 짝 장비)
func evolution_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for weapon: Weapon in _rack.weapons:
		if _rack.is_evolution_ready(weapon):
			cards.append(_evolution_card(weapon))
	return cards


## 진화·히든을 뺀 보통 카드 전부 (빼 버린 것 제외)
func upgrade_cards() -> Array[Dictionary]:
	var cards := _owned_upgrade_cards({})
	cards.append_array(_new_item_cards([]))
	return cards


## 빼 버릴 수 있는 카드인가 (무기·장비만 — 진화·히든·구급상자는 안 됨)
func can_banish(card: Dictionary) -> bool:
	return banishes_left > 0 and String(card["kind"]) in ["new_weapon", "weapon_upgrade", "new_gear", "gear_upgrade"]


func banish(card: Dictionary) -> void:
	banishes_left -= 1
	banished_ids.append(String(card["id"]))


## 고를 게 없을 때 나오는 구급상자 (건너뛰기 회복보다 크게 — 고르는 쪽이 더 이득이게)
func heal_card() -> Dictionary:
	var heal_text := "체력 %d%% 회복" % roundi(float(_rules["heal_card_ratio"]) * 100.0)
	return {"kind": "heal", "id": "heal", "name": "구급상자", "icon": "icon_first_aid", "description": heal_text, "level_text": "", "flavor": String(_flavor["heal"])}


func hidden_card() -> Dictionary:
	var skill := GameData.entry("skills", _hidden_skill_id)
	var flavor := String(Dictionary(_flavor.get("hidden_skills", {})).get(_hidden_skill_id, ""))
	return {"kind": "hidden_skill", "id": _hidden_skill_id, "name": skill["name"], "icon": skill["icon"], "description": skill["description"], "level_text": "히든", "flavor": flavor}


## 무기 카드가 한 장도 없으면 하나는 끼운다 — 장비가 16종이라 장비만 3장 뜨는 일이 잦아 무기를 못 키우고
## (도끼 하나로 버티다 처치 0 '끼임' — 첫 시험), 고르는 맛도 없었다. 개수는 data build.min_weapon_cards.
func _ensure_weapon_card(cards: Array[Dictionary], pool: Array[Dictionary], count: int) -> void:
	var weapon_cards := 0
	for card: Dictionary in cards:
		weapon_cards += 1 if String(card["kind"]).contains("weapon") or card["kind"] == "evolution" else 0
	for card: Dictionary in pool:
		if weapon_cards >= int(_rules["min_weapon_cards"]):
			return
		if not String(card["kind"]).contains("weapon") or cards.has(card):
			continue
		if cards.size() < count:
			cards.append(card)
		else:
			cards[cards.size() - 1] = card
		weapon_cards += 1


## 레벨 hidden_skill_min_level 부터 레벨 업마다 hidden_skill_chance(+행운 부적), 한 판에 한 번 (문서 14 §2-5)
func _rolls_hidden_card(level: int) -> bool:
	if is_hidden_card_used_up or _hidden_skill_id.is_empty() or level < int(_rules["hidden_skill_min_level"]):
		return false
	var chance := float(_rules["hidden_skill_chance"]) + _context.survivor.stats.value("hidden_skill_chance_bonus")
	if randf() >= chance:
		return false
	is_hidden_card_used_up = true
	return true


## 가진 무기·장비의 단계 올리기 카드. planned_levels = 이미 올리기로 정한 단계 (상자에서 같은 것을 여러 번 고를 때)
func _owned_upgrade_cards(planned_levels: Dictionary) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var max_level := int(_rules["max_item_level"])
	for weapon: Weapon in _rack.weapons:
		var weapon_level := weapon.level + int(planned_levels.get(weapon.weapon_id, 0))
		if not weapon.is_evolved and weapon_level < max_level and not banished_ids.has(weapon.weapon_id):
			cards.append(_item_card("weapon_upgrade", weapon.weapon_id, "%d→%d단계" % [weapon_level, weapon_level + 1]))
	for gear_id: String in _rack.gear_levels.keys():
		var gear_level := int(_rack.gear_levels[gear_id]) + int(planned_levels.get(gear_id, 0))
		if gear_level < max_level and not banished_ids.has(gear_id):
			cards.append(_item_card("gear_upgrade", gear_id, "%d→%d단계" % [gear_level, gear_level + 1]))
	return cards


## 칸이 남았을 때 새로 얻기 카드 (already_picked = 이번 상자에서 이미 고른 카드 — 같은 것을 두 번 얻거나 칸을 넘기지 않게)
func _new_item_cards(already_picked: Array[Dictionary]) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var picked_ids: Array[String] = []
	var weapon_room := int(_rules["weapon_slots"]) - _rack.weapons.size()
	var gear_room := int(_rules["gear_slots"]) - _rack.gear_levels.size()
	for card: Dictionary in already_picked:
		picked_ids.append(String(card["id"]))
		weapon_room -= 1 if card["kind"] == "new_weapon" else 0
		gear_room -= 1 if card["kind"] == "new_gear" else 0
	if weapon_room > 0:
		for weapon_id: String in _weapon_pool:
			if _rack.weapon_of(weapon_id) == null and not banished_ids.has(weapon_id) and not picked_ids.has(weapon_id):
				cards.append(_item_card("new_weapon", weapon_id, "새로 얻기"))
	if gear_room > 0:
		for gear_id: String in _gear_pool:
			if not _rack.has_gear(gear_id) and not banished_ids.has(gear_id) and not picked_ids.has(gear_id):
				cards.append(_item_card("new_gear", gear_id, "새로 얻기"))
	return cards


func _item_card(kind: String, item_id: String, level_text: String) -> Dictionary:
	var is_weapon := kind.contains("weapon")
	var info := GameData.entry("weapons" if is_weapon else "gear", item_id)
	var flavor := String(Dictionary(_flavor["weapons" if is_weapon else "gear"]).get(item_id, ""))
	var hint := _evolution_hint(item_id, is_weapon) if kind != "gear_upgrade" else ""   # 짝 장비는 1단계만 있어도 진화
	return {"kind": kind, "id": item_id, "name": info["name"], "icon": info["icon"], "description": info["description"],
		"level_text": level_text, "flavor": flavor, "hint": hint}


func _evolution_card(weapon: Weapon) -> Dictionary:
	var evolution: Dictionary = weapon.info["evolution"]
	return {"kind": "evolution", "id": weapon.weapon_id, "name": evolution["name"], "icon": evolution["icon"],
		"base_icon": weapon.info["icon"], "description": evolution["description"], "level_text": "진화!",
		"flavor": String(_flavor.get("evolution", ""))}


## 진화 짝이 보이게: 가진 무기의 짝 장비 카드엔 "권총 진화 재료", 짝 장비를 가진 무기 카드엔 "무전기와 진화" (한 판 더 하고 싶게 — 문서 14 §4)
func _evolution_hint(item_id: String, is_weapon: bool) -> String:
	if is_weapon:
		var weapon_info := GameData.entry("weapons", item_id)
		if weapon_info.has("evolution") and _rack.has_gear(String(weapon_info["evolution"]["gear"])):
			var gear_name := String(GameData.entry("gear", String(weapon_info["evolution"]["gear"]))["name"])
			return "%s%s 5단계면 진화" % [gear_name, _with_particle(gear_name)]
		return ""
	for weapon: Weapon in _rack.weapons:
		if not weapon.is_evolved and weapon.evolution_gear_id() == item_id:
			return "%s 진화 재료" % weapon.info["name"]
	return ""


## 받침이 있으면 '과', 없으면 '와' (방화복과 / 무전기와)
func _with_particle(word: String) -> String:
	var last := word.unicode_at(word.length() - 1)
	var is_hangul := last >= HANGUL_FIRST and last <= HANGUL_LAST
	return "과" if is_hangul and (last - HANGUL_FIRST) % HANGUL_FINALS != 0 else "와"
