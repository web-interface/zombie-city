## [파일] scripts/systems/promotion.gd
## [하는 일] 전직 담당: 레벨 10 이 되면 그 생존자의 갈래 3개를 보여 달라고 알리고, 고른 갈래의 1차(능력치·스킬 바꾸기·옷 그림)를 적용한다. 레벨 20 이 되면 같은 갈래의 2차(각성)를 자동으로 적용한다.
## [쓰는 곳] scenes/run.tscn 의 Systems/Promotion. 레벨 업(level_changed 신호)을 듣고, 전직 창(scripts/ui/promotion_panel.gd)이 choose_branch() 를 부른다.
## [근거 문서] 02 §5 전직, 03 §1-2 전직 숫자, data/promotions.json
class_name Promotion
extends Node

signal branches_ready(branch_ids: Array[String])
signal promoted(branch_id: String, stage: int)

var chosen_branch_id: String = ""
var stage: int = 0
var is_choosing: bool = false
var _waiting_for_first: bool = false
var _context: RunContext
var _skill_runner: SkillRunner
var _first_level: int
var _second_level: int


func setup(context: RunContext, skill_runner: SkillRunner) -> void:
	_context = context
	_skill_runner = skill_runner
	var rules := GameData.rules("promotion")
	_first_level = int(rules["first_promotion_level"])
	_second_level = int(rules["second_promotion_level"])


func on_level_changed(new_level: int) -> void:
	if new_level >= _first_level and stage == 0:
		_waiting_for_first = true
	if new_level >= _second_level and stage == 1:
		_apply_stage(chosen_branch_id, 2)


## 1차 전직을 고를 차례면 갈래를 알린다 (run.gd 가 레벨 업 카드보다 먼저 부름).
func open_choice_if_waiting() -> bool:
	if not _waiting_for_first or is_choosing:
		return false
	is_choosing = true
	var branches: Array[String] = []
	branches.assign(GameData.entry("survivors", _context.survivor.survivor_id)["branches"])
	branches_ready.emit(branches)
	return true


func choose_branch(branch_id: String) -> void:
	chosen_branch_id = branch_id
	_waiting_for_first = false
	is_choosing = false
	_apply_stage(branch_id, 1)


func branch_name() -> String:
	return "" if chosen_branch_id.is_empty() else String(GameData.entry("promotions", chosen_branch_id)["name"])


func _apply_stage(branch_id: String, new_stage: int) -> void:
	var branch := GameData.entry("promotions", branch_id)
	var stage_data: Dictionary = branch["stage_%d" % new_stage]
	stage = new_stage
	_context.survivor.stats.set_source("promotion_%d" % new_stage, [stage_data])
	_skill_runner.apply_changes(stage_data.get("skill_changes", []))
	if new_stage == 1:
		_context.survivor.set_outfit(String(branch["outfit"]))
	_context.effects.ring(_context.survivor.position, 40.0, Color("ffd166"), 0.6)
	_context.effects.burst(_context.survivor.position, Color("ffd166"), 20, 60.0)
	_context.play_sound("promotion")
	_context.shake("skill")
	promoted.emit(branch_id, new_stage)
