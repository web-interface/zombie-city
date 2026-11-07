## [파일] scripts/run/hit_feedback.gd
## [하는 일] 맞았을 때 소리·손맛으로 알게: 큰 한 방은 흔들림·잠깐 멈춤·아픈 소리, 작은 피해도 짧은 아픈 소리(간격을 두고), 적 웅덩이 안에 서 있으면 '치익' 소리가 계속, 체력 30% 아래면 심장 소리(화면 두근과 같은 박자). 적 장판이 처음 깔리면 한 번만 "빨간 테두리 = 적 장판!" 알림. 맞은 기록(기록 담당·연속 처치)도 여기서 넘긴다.
## [쓰는 곳] scripts/run/run.gd 가 자식으로 만들어 setup(). Survivor.damaged·Hazards.zone_appeared 를 듣는다. 화면 표시는 scripts/ui/damage_vignette.gd.
## [근거 문서] 15 §7-3 맞았을 때 알기·§8 첫 판 안내, 02 §12 손맛, 13 조사 반영(맞을 때 잠깐 멈춤)
class_name HitFeedback
extends Node

const SMALL_HURT_SOUND_GAP_SECONDS := 0.45
const SMALL_HURT_PITCH := 0.15
const SIZZLE_GAP_SECONDS := 0.4
const FIRST_ZONE_FLAG := "seen_enemy_zone_hint"
const FIRST_ZONE_TEXT := "빨간 테두리 = 적 장판! 밟지 마세요"

var _context: RunContext
var _parts: Dictionary = {}
var _hurt_sound_timer: float = 0.0
var _sizzle_timer: float = 0.0
var _heartbeat_time: float = 0.0
var _last_beat_index: int = -1


## parts = {"recorder", "combo", "time_effects", "extraction", "hud"}
func setup(context: RunContext, parts: Dictionary) -> void:
	_context = context
	_parts = parts
	context.survivor.damaged.connect(_on_survivor_damaged)
	context.hazards.zone_appeared.connect(_on_zone_appeared)


func _physics_process(delta: float) -> void:
	_hurt_sound_timer = maxf(_hurt_sound_timer - delta, 0.0)
	_sizzle_timer -= delta
	if _context.hazards.is_survivor_in_zone and _sizzle_timer <= 0.0:
		_sizzle_timer = SIZZLE_GAP_SECONDS
		_context.play_sound("acid_sizzle")
	_play_heartbeat(delta)


## 체력 30% 아래: DamageVignette 와 같은 박자로 '쿵' (박자 한 바퀴에 한 번)
func _play_heartbeat(delta: float) -> void:
	var survivor := _context.survivor
	if survivor.is_dead or survivor.health_ratio() >= Survivor.CRITICAL_HEALTH_RATIO:
		_last_beat_index = -1
		return
	_heartbeat_time += delta
	var beat_index := int(_heartbeat_time / DamageVignette.HEARTBEAT_SECONDS)
	if beat_index != _last_beat_index:
		_last_beat_index = beat_index
		_context.play_sound("heartbeat")


func _on_survivor_damaged(amount: float) -> void:
	var extraction: Extraction = _parts["extraction"]
	_parts["recorder"].note_survivor_damaged(extraction.phase == "landed")
	_parts["combo"].note_damage(amount)
	var rules := _context.juice_rules
	# 이보다 큰 한 방이면 흔들림·잠깐 멈춤·아픈 소리 (계속 닿는 작은 피해와 구분)
	if amount >= float(rules["big_hit_damage"]):
		_context.shake("survivor_big_hit")
		_parts["time_effects"].play(float(rules["hit_stop_on_survivor_big_hit_seconds"]), 0.0)
		_context.play_sound("survivor_hurt")
		_hurt_sound_timer = SMALL_HURT_SOUND_GAP_SECONDS
		return
	_context.camera.add_trauma(float(rules["trauma_survivor_contact_per_second"]) * get_physics_process_delta_time())
	if _hurt_sound_timer <= 0.0:   # 물리는 동안 매 프레임 울리지 않게 간격을 두고 작게
		_hurt_sound_timer = SMALL_HURT_SOUND_GAP_SECONDS
		_context.play_sound("survivor_hurt", SMALL_HURT_PITCH)


func _on_zone_appeared() -> void:
	if SaveData.flag(FIRST_ZONE_FLAG):
		return
	SaveData.set_flag(FIRST_ZONE_FLAG, true)
	_parts["hud"].show_banner(FIRST_ZONE_TEXT, "alert")
