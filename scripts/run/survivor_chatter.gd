## [파일] scripts/run/survivor_chatter.gd
## [하는 일] 생존자마다 다른 말투의 한마디(data/survivor_lines.json): 판 시작·다음 밤·보스 등장·보스 분노·보스 처치·전직·체력이 바닥일 때·보물 상자. 너무 자주 떠들지 않게 사이를 두고(체력 위험은 예외), 같은 말이 연달아 나오지 않게 고른다.
## [쓰는 곳] scripts/run/run.gd 가 만들어 setup() 으로 신호를 잇고 매 프레임 update() 를 부른다. 말풍선은 scripts/world/speech_bubble.gd.
## [근거 문서] 14 §4 중독 설계(사용자 "개성 넘치게"), 04 §2 생존자 이야기, 06 AI 티 안 나게(동네 말투)
class_name SurvivorChatter
extends RefCounted

const MIN_GAP_SECONDS := 6.0
const START_DELAY_SECONDS := 1.2
const LOW_HEALTH_RATIO := 0.3

var _context: RunContext
var _bubble: SpeechBubble
var _lines: Dictionary = {}
var _seconds_since_line: float = 0.0
var _start_said: bool = false
var _was_low_health: bool = false
var _last_line: String = ""


## parts = {"boss_director": BossDirector, "promotion": Promotion, "hud": Hud}
func setup(context: RunContext, bubble: SpeechBubble, parts: Dictionary) -> void:
	_context = context
	_bubble = bubble
	_bubble.setup(context.survivor)
	_lines = GameData.table("survivor_lines").get(context.survivor.survivor_id, {})
	var bosses: BossDirector = parts["boss_director"]
	bosses.boss_appeared.connect(func(_text: String) -> void: _say("boss", true))
	bosses.boss_enraged.connect(func(_text: String) -> void: _say("boss_rage", true))
	bosses.boss_defeated.connect(func(_seconds: float, _name: String) -> void: _say("boss_down", false))
	(parts["promotion"] as Promotion).promoted.connect(func(_branch: String, _stage: int) -> void: _say("promoted", true))
	(parts["hud"] as Hud).next_night_requested.connect(func() -> void: _say("night_start", true))
	context.pickups.picked.connect(_on_picked)
	context.survivor.damaged.connect(_on_damaged)


func update(delta: float) -> void:
	_seconds_since_line += delta
	if not _start_said and _context.run_seconds >= START_DELAY_SECONDS:
		_start_said = true
		_say("start", true)


func _on_picked(kind: String, _at_position: Vector2) -> void:
	if kind == "chest":
		_say("chest", false)


func _on_damaged(_amount: float) -> void:
	var is_low := _context.survivor.health_ratio() < LOW_HEALTH_RATIO
	if is_low and not _was_low_health:
		_say("low_health", true)
	_was_low_health = is_low


## is_important 이면 사이를 두지 않고 바로 (보스·체력 위험처럼 꼭 반응할 때)
func _say(moment: String, is_important: bool) -> void:
	var choices: Array = _lines.get(moment, [])
	if choices.is_empty() or (not is_important and _seconds_since_line < MIN_GAP_SECONDS):
		return
	var line := String(choices.pick_random())
	if line == _last_line and choices.size() > 1:
		line = String(choices[(choices.find(line) + 1) % choices.size()])
	_last_line = line
	_seconds_since_line = 0.0
	_bubble.say(line)
