## [파일] scripts/systems/level_up.gd
## [하는 일] 경험치와 레벨: 백신 조각을 모아 레벨을 올리고(다음 레벨까지 기본 + 레벨당 양 × 지금 레벨 — data/run_rules.json experience, 연구 노트는 경험치 더 받음), 레벨마다 카드 3장을 뽑아(CardDeck — 생존자 카드 풀·진화 먼저·가끔 금색 히든) 보여 달라고 알린다. 고른 카드를 적용한다(새 무기·강화·장비·진화·히든 스킬·구급상자). 다시 뽑기·빼 버리기·건너뛰기(체력 조금 회복)·보스 보상 카드 한 번 더도 맡는다. 보물 상자가 쓰는 API(roll_upgrade_cards·apply_card·has_evolution_ready)도 여기.
## [쓰는 곳] scenes/run.tscn 의 Systems/LevelUp. 조각(vaccine_shard_field.gd)이 add_experience() 를, 레벨 업 창(scripts/ui/level_up_panel.gd)이 choose()·reroll()·banish()·skip() 을, 보물 상자가 roll_upgrade_cards()·apply_card() 를 부른다. run.gd 가 evolved·hidden_skill_chosen 을 듣는다.
## [근거 문서] 02 §5 성장과 조합, 03 §5 레벨과 경험치, 14 §2-1·§2-4·§2-5·§2-6, data/run_rules.json build·experience
class_name LevelUp
extends Node

signal level_changed(new_level: int)
signal cards_ready(cards: Array)
signal card_applied(card: Dictionary)
## 무기가 진화한 순간 (run.gd: "진화!" 띠·느린 화면, 기록)
signal evolved(weapon_id: String)
## 히든 스킬 카드를 골랐다 (run.gd 가 스킬 버튼을 히든 스킬로 바꾼다)
signal hidden_skill_chosen(skill_id: String)

var level: int = 1
var experience: float = 0.0
var rerolls_left: int = 0
var pending_choices: int = 0
var is_choosing: bool = false
## 카드 뽑기 규칙 (빼 버리기 남은 횟수·히든 카드 한 번 등)
var deck: CardDeck
var _context: RunContext
var _rack: WeaponRack
var _build_rules: Dictionary = {}
var _current_cards: Array[Dictionary] = []


func setup(context: RunContext, rack: WeaponRack) -> void:
	_context = context
	_rack = rack
	_build_rules = GameData.rules("build")
	rerolls_left = int(_build_rules["rerolls_per_run"])
	deck = CardDeck.new(context, rack)


## 다음 레벨까지: shards_needed_base + shards_needed_per_level × 지금 레벨 (목표 레벨 10 ≈ 1:30, 레벨 20 ≈ 3:30 — 문서 13)
func experience_needed() -> float:
	var rules := GameData.rules("experience")
	return float(rules["shards_needed_base"]) + float(rules["shards_needed_per_level"]) * level


func add_experience(amount: float) -> void:
	experience += amount * _context.survivor.stats.value("experience_multiplier")
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
	_current_cards = deck.draw_level_up_cards(level, false)
	cards_ready.emit(_current_cards)
	return true


func choose(card: Dictionary) -> void:
	_apply_effect(card)
	_finish_choice(card)


func reroll() -> void:
	if rerolls_left <= 0:
		return
	rerolls_left -= 1
	_redraw()


## 빼 버리기: 이 카드(무기·장비)를 그 판에서 다시 안 나오게 하고 다시 뽑는다. 못 빼면 false.
func banish(card: Dictionary) -> bool:
	if not deck.can_banish(card):
		return false
	deck.banish(card)
	_context.play_sound("banish")
	_redraw()
	return true


func skip() -> void:
	_context.survivor.heal(float(_build_rules["skip_card_heal_ratio"]))
	_finish_choice({"kind": "skip"})


## ── 보물 상자용 API (총책임관 — 문서 14 §2-6) ──
## 상자에서 받을 강화 count 개를 미리 정한다. 진화할 수 있으면 진화가 먼저. 같은 무기를 여러 번 올릴 수도 있다.
func roll_upgrade_cards(count: int) -> Array[Dictionary]:
	return deck.draw_chest_cards(count)


## 창 없이 카드 하나를 바로 적용한다 (상자 슬롯이 멈출 때마다). 기록(card_applied)도 남긴다.
func apply_card(card: Dictionary) -> void:
	_apply_effect(card)
	card_applied.emit(card)


## 진화할 수 있는 무기가 하나라도 있나 (상자 연출에서 "진화!" 를 먼저 보여 줄지)
func has_evolution_ready() -> bool:
	return not deck.evolution_cards().is_empty()


func _apply_effect(card: Dictionary) -> void:
	var item_id := String(card["id"])
	match String(card["kind"]):
		"new_weapon":
			_rack.add_weapon(item_id)
		"weapon_upgrade":
			_rack.upgrade_weapon(item_id)
		"new_gear", "gear_upgrade":
			_rack.add_or_upgrade_gear(item_id)
		"evolution":
			if _rack.evolve_weapon(item_id):
				evolved.emit(item_id)
		"hidden_skill":
			hidden_skill_chosen.emit(item_id)
		"heal":
			_context.survivor.heal(float(_build_rules["heal_card_ratio"]))


## 다시 뽑기·빼 버리기 뒤: 이미 떠 있던 히든 카드는 남긴다 (금색 카드를 다시 뽑기로 잃으면 억울함)
func _redraw() -> void:
	var is_hidden_showing := false
	for card: Dictionary in _current_cards:
		is_hidden_showing = is_hidden_showing or card["kind"] == "hidden_skill"
	_current_cards = deck.draw_level_up_cards(level, is_hidden_showing)
	cards_ready.emit(_current_cards)


func _finish_choice(card: Dictionary) -> void:
	pending_choices -= 1
	is_choosing = false
	_context.play_sound("card_select")
	card_applied.emit(card)
