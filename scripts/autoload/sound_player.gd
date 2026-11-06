## [파일] scripts/autoload/sound_player.gd
## [하는 일] 효과음·음악 재생 담당. audio/ 폴더의 '<이름>_<번호>.wav' 변형들을 모아 두고, play("zombie_hit") 처럼 부르면 변형 중 하나를 높이를 조금씩 바꿔 튼다 (같은 소리 반복 = AI 티). 같은 소리가 한 프레임에 너무 많이 겹치지 않게 막는다. 음악(밤마다 바뀌는 곡·위험도 층·보스·헬기 곡)은 자식 MusicMixer 에 맡긴다.
## [쓰는 곳] 자동 로드 'SoundPlayer'. RunContext.play_sound(), 화면 스크립트, scripts/run/run.gd(음악 위험도)가 부른다.
## [근거 문서] 06 사운드·AI 티 안 나게, 02 §12 위험할수록 악기가 더해지는 음악
extends Node

const AUDIO_FOLDER := "res://audio/"
const VOICE_COUNT := 16                    # 동시에 날 수 있는 효과음 수
const SAME_SOUND_GAP_SECONDS := 0.035      # 같은 소리는 이 간격보다 촘촘히 안 냄 (좀비 수십 마리가 한꺼번에 맞을 때)
const PITCH_VARIATION := 0.04       # 변형마다 이미 높이가 달라서 조금만 더 흔든다 (사운드 담당 권고)
## 길거나 중요한 소리는 공용 칸에서 끊기지 않게 전용 칸에서 튼다
const IMPORTANT_SOUNDS: Array[String] = ["promotion", "extraction_success", "game_over", "boss_warning", "boss_roar", "level_up",
	"evolution", "chest_jackpot", "night_clear", "night_start", "encircle_alarm", "stampede_rumble", "hidden_skill_cutin"]

## 설정: 0~1
var effects_volume: float = 1.0
var music_volume: float = 0.7:
	set(value):
		music_volume = value
		if _music != null:
			_music.volume = value

var _variants: Dictionary = {}             # 소리 이름 → [AudioStream…]
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _last_played: Dictionary = {}          # 소리 이름 → 마지막 재생 시각(초)
var _music: MusicMixer
var _important_voice: AudioStreamPlayer
var _loop_players: Dictionary = {}           # 반복 소리 이름 → 전용 플레이어 (헬기)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_collect_sound_files()
	for index: int in range(VOICE_COUNT):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	_music = MusicMixer.new()
	_music.volume = music_volume
	add_child(_music)
	_important_voice = AudioStreamPlayer.new()
	add_child(_important_voice)


## 변형 중 하나를 골라 높이를 살짝 바꿔 튼다. 소리 파일이 아직 없으면 조용히 넘어간다.
func play(sound_name: String, pitch_offset: float = 0.0) -> void:
	if not _variants.has(sound_name) or effects_volume <= 0.0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound_name, -1.0)) < SAME_SOUND_GAP_SECONDS:
		return
	_last_played[sound_name] = now
	var streams: Array = _variants[sound_name]
	var voice := _important_voice if IMPORTANT_SOUNDS.has(sound_name) else _voices[_next_voice]
	if voice != _important_voice:
		_next_voice = (_next_voice + 1) % VOICE_COUNT
	voice.stream = streams.pick_random()
	voice.pitch_scale = 1.0 + pitch_offset + randf_range(-PITCH_VARIATION, PITCH_VARIATION)
	voice.volume_db = linear_to_db(effects_volume)
	voice.play()


## 변형 없이 정확히 그 파일 하나 (예: 줍기 소리 높이 단계 'shard_pickup_3')
func play_exact(file_stem: String) -> void:
	var path := AUDIO_FOLDER + file_stem + ".wav"
	if effects_volume <= 0.0 or not ResourceLoader.exists(path):
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICE_COUNT
	voice.stream = load(path)
	voice.pitch_scale = 1.0
	voice.volume_db = linear_to_db(effects_volume * 0.8)
	voice.play()


## 끝없이 반복되는 소리(헬기)를 전용 플레이어로 튼다. stop_loop() 이나 stop_music() 으로 멈춘다.
func start_loop(sound_name: String) -> void:
	if not _variants.has(sound_name) or _loop_players.has(sound_name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = (_variants[sound_name] as Array).pick_random()
	player.volume_db = linear_to_db(effects_volume * 0.8)
	add_child(player)
	player.play()
	_loop_players[sound_name] = player


func stop_loop(sound_name: String) -> void:
	if _loop_players.has(sound_name):
		(_loop_players[sound_name] as AudioStreamPlayer).queue_free()
		_loop_players.erase(sound_name)


## 그 밤의 곡 묶음 세 층을 같이 튼다 (밤마다 다른 곡 — MusicMixer)
func start_run_music(night: int = 1) -> void:
	_music.start_run_music(night)


## danger: 0 = 평온, 1 = 위험(멜로디 추가), 2 = 아주 위험(긴장 리드 추가)
func set_music_danger(danger: int) -> void:
	_music.set_music_danger(danger)


## "night" · "boss" · "boss_rage" · "extraction" — 보스·헬기 곡으로 바꿨다가 돌아옴
func set_music_mode(mode: String) -> void:
	_music.set_music_mode(mode)


func play_single_music(track_name: String) -> void:
	stop_music()
	_music.play_single_music(track_name)


func stop_everything() -> void:
	stop_music()
	for voice: AudioStreamPlayer in _voices:
		voice.stop()
	_important_voice.stop()


func stop_music() -> void:
	_music.stop_music()
	for loop_name: String in _loop_players.keys():
		stop_loop(loop_name)


## audio/ 의 '이름_번호.wav' 를 이름별로 모은다. 내보낸 게임에서는 파일이 '.wav.import' 로 보이므로 그것도 센다.
func _collect_sound_files() -> void:
	var folder := DirAccess.open(AUDIO_FOLDER)
	if folder == null:
		return
	for file_name: String in folder.get_files():
		var clean_name := file_name.trim_suffix(".import")
		if not clean_name.ends_with(".wav"):
			continue
		var stem := clean_name.trim_suffix(".wav")
		var underscore := stem.rfind("_")
		if underscore < 0 or not stem.substr(underscore + 1).is_valid_int():
			continue
		var sound_name := stem.substr(0, underscore)
		if not _variants.has(sound_name):
			_variants[sound_name] = []
		_variants[sound_name].append(load(AUDIO_FOLDER + clean_name))
