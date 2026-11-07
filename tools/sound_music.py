"""
[파일] tools/sound_music.py
[하는 일] 악보 파일 3개(audio/source/music_scores·nights·battle.txt)를 읽어 곡마다 끊김 없이 반복되는 음악 파일을 만든다: 밤 4종 × 3층·보스·보스 분노·탈출·타이틀·고르기·결과·은신처. 한 곡의 층들은 길이·템포가 같고 함께 틀어도 클리핑이 없다. 곡마다 '언제 나오는지' 표도 가진다.
[쓰는 곳] tools/build_sounds.py 가 build_music() 과 MUSIC_INFO(README 음악 표)를 쓴다. 소리 조각은 tools/chiptune.py.
[근거 문서] 02 §12 위험할수록 악기가 더해지는 음악, 06 사운드, 14 §1 끝없는 밤·보스·탈출, 14 §3 은신처
"""
from __future__ import annotations

import random
from pathlib import Path

from chiptune import SAMPLE_RATE, count_steps, high_pass, parse_notes, render_drum_part, render_effect, render_part, write_wav

STEPS_PER_BAR = 16
MUSIC_PEAK_DB = -3.0            # 한 곡의 층을 모두 켰을 때 가장 큰 소리 (조용한 곡은 악보에서 peak_db 로 낮춤)
DRUM_VARIANT_COUNT = 3

SCORE_FILE_NAMES =["music_scores.txt", "music_nights.txt", "music_battle.txt"]   # 이 순서로 읽는다 (뒤 파일이 앞 파일 악기를 씀)

# 파일 → (언제 나오는지, 무엇). 언제 = SoundPlayer 연결 기준, 무엇 = 조·빠르기·악기 (README 음악 표에 그대로 나감)
MUSIC_INFO: dict[str, tuple[str, str]] = {
    "music_run_layer1": ("첫째 밤 — 늘 켬", "1층: 사각파 베이스 + 북·작은북·하이햇. 레단조 126 BPM 24마디"),
    "music_run_layer2": ("첫째 밤 — 위험 1부터", "2층: 멜로디 + 9마디부터 펼침화음"),
    "music_run_layer3": ("첫째 밤 — 위험 2", "3층: 반음으로 떠는 고음 + 낮은 웅웅 + 17마디부터 비명 같은 리드 + 셰이커·탐·심벌·차오르는 노이즈"),
    "music_night2_layer1": ("둘째 밤 — 늘 켬", "1층: '따그닥' 달리는 톱니파 베이스 + 북·작은북·하이햇. 마단조 147 BPM 24마디 (첫째 밤보다 17% 빠름)"),
    "music_night2_layer2": ("둘째 밤 — 위험 1부터", "2층: 앞에서 끄는 사각파 멜로디 + 뒷박 파워 코드 '짠 짠'"),
    "music_night2_layer3": ("둘째 밤 — 위험 2", "3층: 반음 떨림 '따다다다 땃' → 17마디부터 16분음표 속주 + 라이드 심벌·탐·심벌"),
    "music_night3_layer1": ("셋째 밤 — 늘 켬", "1층: 3박에만 치는 무거운 북(반 박자) + 끊어 치는 낮은 베이스 + 바닥에 깔린 톱니파. 다단조(D♭ 섞임) 135 BPM 20마디"),
    "music_night3_layer2": ("셋째 밤 — 위험 1부터", "2층: 느리고 어두운 멜로디 + 곡 내내 맴도는 '솔-라♭' 반음 종소리"),
    "music_night3_layer3": ("셋째 밤 — 위험 2", "3층: 반음씩 기어오르내리는 소리 + 9마디부터 떨리는 고음 + 큰북(타이코) + 끝마다 차오르는 노이즈"),
    "music_night4_layer1": ("넷째 밤 이후 — 늘 켬", "1층: 16분음표 옥타브 베이스 + 네 박 북 + 16분 하이햇. 올림바단조 175 BPM 32마디 (가장 빠름)"),
    "music_night4_layer2": ("넷째 밤 이후 — 위험 1부터", "2층: 쉬지 않는 16분음표 펼침화음 + 후렴 멜로디"),
    "music_night4_layer3": ("넷째 밤 이후 — 위험 2", "3층: 한 음 안에서 화음을 1초에 50번 돌리는 옛 게임기 아르페지오 + 25마디부터 비명 리드 + 뒷박 심벌·탐"),
    "music_boss": ("보스가 살아 있는 동안(밤 음악 대신)", "보스전: 낮은 나팔 부름 → 톱니파 금관 '빰 빰' + '다다다 둥-' 몰아치는 베이스 + 큰북·징. 사단조 150 BPM 20마디"),
    "music_boss_rage": ("보스 체력 절반 아래(분노) — music_boss 대신", "보스 분노: 보스전과 화음·자리가 같고, 16분음표 톱니파 베이스 + 두 배 북 + 한 옥타브 위 나팔 부름 → 날카로운 사각파 멜로디와 3도 아래 화음 + 뒤에서 계속 우는 반음 경보. 사단조 150 BPM 20마디"),
    "music_extraction": ("착륙 지점 이동(2:30)부터 헬기 버티기 끝까지", "탈출: 박자에 맞춘 헬기 날개 '두두두' + 무전 '삐 삐-' + 달리는 옥타브 베이스, 12·19마디에 다장조로 밝아짐. 다단조 189 BPM 20마디"),
    "music_title": ("타이틀 화면", "쓸쓸한 밤 도시: 메아리 걸린 펼침화음, 느린 멜로디, 멀리 바람과 사이렌. 가단조 75 BPM 16마디"),
    "music_select": ("생존자 고르기 화면", "두근두근: 심장 같은 북(9마디부터 빨라짐), 튕기는 화음, 통통 베이스, 5마디부터 실로폰 멜로디·손뼉. 사장조 125 BPM 12마디"),
    "music_result": ("결과 화면", "밤을 버틴 뒤의 담담함. 바장조 90 BPM 12마디"),
    "music_shelter": ("은신처·업적·도감 화면", "폐건물 안 작은 모닥불 곁: 오르골 같은 삼각파, 따뜻한 화음, 5마디부터 느린 멜로디, 타닥 불꽃. 라장조 75 BPM 12마디"),
}
MUSIC_ABOUT = {stem: about for stem, (_, about) in MUSIC_INFO.items()}


def build_music(audio_folder: Path, score_files: list[Path]) -> list[tuple[str, str, str, float]]:
    """악보 파일들의 곡마다 파일(층)을 만든다. 뒤 파일은 앞 파일의 악기·타악기를 그대로 쓸 수 있다.
    무작위 씨앗은 파일마다 따로(첫 파일은 예전 씨앗 'music') → 새 악보를 더해도 기존 곡 파일은 한 바이트도 안 바뀐다.
    돌려주는 값: (파일, 묶음 이름, 설명, 초)."""
    instruments: dict[str, dict] = {}
    drum_hits: dict[str, list[list[float]]] = {}
    made: list[tuple[str, str, str, float]] = []
    for index, score_file in enumerate(score_files):
        file_instruments, drums, songs = read_score(score_file)
        rng = random.Random("music" if index == 0 else score_file.stem)
        for name in [*file_instruments, *drums]:
            if name in instruments or name in drum_hits:
                raise ValueError(f"{score_file.name}: 악기 이름 '{name}' 이 앞 악보에 이미 있음")
        instruments.update(file_instruments)
        for name, layers in drums.items():
            drum_hits[name] = [render_effect(layers, rng, rng.uniform(0.97, 1.03)) for _ in range(DRUM_VARIANT_COUNT)]
        for song in songs:
            files = scale_song(render_song(song, instruments, drum_hits, rng, score_file.name), song.get("peak_db", MUSIC_PEAK_DB))
            for stem, samples in files.items():
                write_wav(audio_folder / f"{stem}.wav", samples, is_loop=True)
                made.append((f"{stem}.wav", stem, MUSIC_ABOUT.get(stem, ""), len(samples) / SAMPLE_RATE))
    return made


def render_song(song: dict, instruments: dict, drum_hits: dict, rng: random.Random, score_name: str) -> dict[str, list[float]]:
    """곡 하나의 파트들을 파일별로 섞는다. 같은 곡의 파일은 샘플 수까지 같아서 동시에 틀면 박자가 맞는다."""
    step_length = SAMPLE_RATE * 60 / (song["bpm"] * 4)
    if step_length != int(step_length):
        raise ValueError(f"{score_name}: '{song['name']}' bpm {song['bpm']} — 16분음표가 샘플 수로 딱 안 떨어져 층·이음매가 어긋남")
    step_count = int(step_length)
    total_count = int(song["bars"]) * STEPS_PER_BAR * step_count
    files: dict[str, list[float]] = {}
    for part in song["parts"]:
        is_drum = part["instrument"] in drum_hits
        if not is_drum and part["instrument"] not in instruments:
            raise ValueError(f"{score_name}: {part['file']} — 악기 '{part['instrument']}' 가 @instrument·@drum 에 없음")
        bars = part_bars(part, int(song["bars"]), is_drum, score_name)
        volume = part.get("volume", 1.0)
        if is_drum:
            samples = render_drum_part("".join(bars), drum_hits[part["instrument"]], step_count, total_count, rng, volume)
        else:
            samples = render_part(parse_notes(" ".join(bars)), instruments[part["instrument"]], step_count, total_count, rng, volume)
        mixed = files.setdefault(part["file"], [0.0] * total_count)
        for index, sample in enumerate(samples):
            mixed[index] += sample
    return files


def scale_song(files: dict[str, list[float]], peak_db: float) -> dict[str, list[float]]:
    """층들을 같은 비율로 키운다 → 층끼리의 크기 비율이 유지되고, 모든 층을 합친 소리가 peak_db 가 된다."""
    cleaned = {stem: high_pass(samples, 25.0, is_looped=True) for stem, samples in files.items()}
    loudest = max(abs(sum(values)) for values in zip(*cleaned.values()))
    gain = 10.0 ** (peak_db / 20.0) / loudest
    return {stem: [sample * gain for sample in samples] for stem, samples in cleaned.items()}


def part_bars(part: dict, bar_count: int, is_drum: bool, score_name: str) -> list[str]:
    """마디 줄을 '|' 로 나누고 '%'(앞 마디 그대로)를 풀어 쓴 뒤, 마디마다 16칸인지·마디 수가 맞는지 확인한다."""
    bars: list[str] = []
    for text in " | ".join(part["lines"]).split("|"):
        text = text.strip()
        if text:
            bars.append(bars[-1] if text == "%" else text)
    for number, bar in enumerate(bars, start=1):
        size = len(bar) if is_drum else count_steps(bar)
        if size != STEPS_PER_BAR:
            raise ValueError(f"{score_name}: {part['file']} {part['instrument']} {number}번째 마디가 {size}칸 (16칸이어야 함): {bar}")
    if len(bars) != bar_count:
        raise ValueError(f"{score_name}: {part['file']} {part['instrument']} 마디가 {len(bars)}개 (곡은 {bar_count}마디)")
    return bars


def read_score(path: Path) -> tuple[dict, dict, list]:
    """악보 파일 → (악기 설정, 타악기 겹 목록, 곡 목록). '#' 로 시작하는 줄과 빈 줄은 건너뛴다."""
    instruments: dict[str, dict] = {}
    drums: dict[str, list[dict]] = {}
    songs: list[dict] = []
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        words = line.split()
        if words[0] == "@instrument":
            instruments[words[1]] = instrument_settings(words[2:])
        elif words[0] == "@drum":
            drums.setdefault(words[1], []).append(parse_settings(words[2:]))
        elif words[0] == "@song":
            songs.append({"name": words[1], **parse_settings(words[2:]), "parts": []})
        elif words[0] == "@part" and songs:
            songs[-1]["parts"].append({"file": words[1], "instrument": words[2], **parse_settings(words[3:]), "lines": []})
        elif songs and songs[-1]["parts"]:
            songs[-1]["parts"][-1]["lines"].append(line)
        else:
            raise ValueError(f"{path.name}:{line_number} — 어느 @part 에 딸린 줄인지 모름: {line}")
    return instruments, drums, songs


def instrument_settings(words: list[str]) -> dict:
    """악기 설정. 'arpeggio=빠르기,반음,반음…' 은 (빠르기, [반음…]) 으로 바꾼다 — 한 음 안에서 화음을 빠르게 돌리는 옛 게임기 소리."""
    settings = parse_settings(words)
    if isinstance(settings.get("arpeggio"), list):
        values = settings["arpeggio"]
        settings["arpeggio"] = (values[0], values[1:])
    return settings


def parse_settings(words: list[str]) -> dict:
    """'wave=square duty=0.25 adsr=0.002,0.09,0.7,0.02' → {'wave': 'square', 'duty': 0.25, 'adsr': [0.002, …]}."""
    settings: dict = {}
    for word in words:
        key, _, value = word.partition("=")
        try:
            numbers = [float(part) for part in value.split(",")]
        except ValueError:
            settings[key] = value
            continue
        settings[key] = numbers[0] if len(numbers) == 1 else numbers
    return settings
