## [파일] scripts/autoload/music_mixer.gd
## [하는 일] 음악 담당: 밤마다 다른 곡 묶음(첫째 밤 music_run_*, 둘째·셋째·넷째 밤 이후 music_night2~4_*)의 세 층을 동시에 틀어 위험도에 따라 볼륨을 섞고, 보스가 나오면 보스 곡(분노하면 더 격한 곡), 착륙 지점이 뜨면 헬기 곡으로 부드럽게 바꿨다가 끝나면 밤 곡으로 돌아온다. 화면 음악(타이틀·결과·고르기·은신처) 한 곡도 튼다. 곡 파일이 없으면 조용히 넘어간다.
## [쓰는 곳] 자동 로드 SoundPlayer 가 자식으로 만들어 음악 함수(start_run_music·set_music_danger·set_music_mode·play_single_music·stop_music)를 넘겨준다.
## [근거 문서] 02 §12 위험할수록 악기가 더해지는 음악, 14 §4 중독 설계(사용자 "BGM 도 계속 바뀌게"), audio/README.md 음악 표
class_name MusicMixer
extends Node

const AUDIO_FOLDER := "res://audio/"
const LAYER_FADE_SPEED := 0.8       # 층 볼륨이 바뀌는 빠르기 (초당)
const SPECIAL_FADE_SPEED := 1.2     # 보스·헬기 곡으로 넘어가는 빠르기
const LAST_NIGHT_THEME := 4         # 넷째 밤 뒤로는 넷째 밤 곡
const SPECIAL_TRACKS := {"boss": "music_boss", "boss_rage": "music_boss_rage", "extraction": "music_extraction"}

var volume: float = 0.7
var _layers: Array[AudioStreamPlayer] = []
var _layer_targets: Array[float] = [1.0, 0.0, 0.0]
var _single: AudioStreamPlayer
var _special: AudioStreamPlayer
var _special_track: String = ""
var _special_level: float = 0.0      # 보스·헬기 곡이 얼마나 올라왔나 (0~1) — 그만큼 밤 곡이 내려감


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_single = AudioStreamPlayer.new()
	add_child(_single)
	_special = AudioStreamPlayer.new()
	add_child(_special)


## 그 밤의 곡 묶음 세 층을 같이 튼다 (바닥만 들리게 시작, 같은 길이라 맞물림)
func start_run_music(night: int) -> void:
	stop_music()
	for layer_number: int in range(1, 4):
		var path := AUDIO_FOLDER + _layer_name(night, layer_number) + ".wav"
		if not ResourceLoader.exists(path):
			path = AUDIO_FOLDER + _layer_name(1, layer_number) + ".wav"   # 그 밤 곡이 아직 없으면 첫째 밤 곡
		if not ResourceLoader.exists(path):
			continue
		var layer := AudioStreamPlayer.new()
		layer.stream = load(path)
		layer.volume_db = -80.0
		add_child(layer)
		layer.play()
		_layers.append(layer)


## danger: 0 = 평온, 1 = 위험(멜로디 추가), 2 = 아주 위험(긴장 리드 추가)
func set_music_danger(danger: int) -> void:
	_layer_targets = [1.0, 1.0 if danger >= 1 else 0.0, 1.0 if danger >= 2 else 0.0]


## mode: "night"(밤 곡) · "boss" · "boss_rage" · "extraction" — 같은 걸 매 프레임 불러도 된다
func set_music_mode(mode: String) -> void:
	var track := String(SPECIAL_TRACKS.get(mode, ""))
	if track == _special_track:
		return
	if track.is_empty() or not ResourceLoader.exists(AUDIO_FOLDER + track + ".wav"):
		_special_track = ""
		return
	# 보스 곡 ↔ 분노 곡은 빠르기·길이가 같아서 듣던 자리에서 이어 튼다 (박자가 안 끊기게 — audio/README.md)
	var keep_position := _special.playing and _special_track.begins_with("music_boss") and track.begins_with("music_boss")
	var position := _special.get_playback_position() if keep_position else 0.0
	_special_track = track
	_special.stream = load(AUDIO_FOLDER + track + ".wav")
	_special.volume_db = linear_to_db(maxf(_special_level * volume, 0.0001))
	_special.play(position)


func play_single_music(track_name: String) -> void:
	stop_music()
	var path := AUDIO_FOLDER + track_name + ".wav"
	if ResourceLoader.exists(path):
		_single.stream = load(path)
		_single.volume_db = linear_to_db(maxf(volume, 0.0001))
		_single.play()


func stop_music() -> void:
	for layer: AudioStreamPlayer in _layers:
		layer.queue_free()
	_layers.clear()
	_single.stop()
	_special.stop()
	_special_track = ""
	_special_level = 0.0


func _process(delta: float) -> void:
	var special_target := 1.0 if not _special_track.is_empty() else 0.0
	_special_level = move_toward(_special_level, special_target, SPECIAL_FADE_SPEED * delta)
	if _special.playing:
		_special.volume_db = linear_to_db(maxf(_special_level * volume, 0.0001))
		if _special_level <= 0.0:
			_special.stop()
	for index: int in range(_layers.size()):
		var layer := _layers[index]
		var current := db_to_linear(layer.volume_db) / maxf(volume, 0.001)
		var target := _layer_targets[mini(index, _layer_targets.size() - 1)] * (1.0 - _special_level)
		var next_level := move_toward(current, target, LAYER_FADE_SPEED * delta)
		layer.volume_db = linear_to_db(maxf(next_level * volume, 0.0001))
	if _single.playing:
		_single.volume_db = linear_to_db(maxf(volume, 0.0001))


func _layer_name(night: int, layer_number: int) -> String:
	if night <= 1:
		return "music_run_layer%d" % layer_number
	return "music_night%d_layer%d" % [mini(night, LAST_NIGHT_THEME), layer_number]
