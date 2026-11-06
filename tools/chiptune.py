"""
[파일] tools/chiptune.py
[하는 일] 8비트(칩튠)풍 소리 조각: 파형(사각·삼각·톱니·사인·노이즈), 음 높이 미끄러짐·떨림, 볼륨 엔벨로프, 걸러내기·메아리, 음표 읽기, 악보 한 줄 그리기, WAV 저장(반복 구간 표시).
[쓰는 곳] tools/build_sounds.py 가 효과음 정의 표와 audio/source/music_scores.txt 를 이 조각으로 소리로 만든다. 파이썬 기본 라이브러리(math·random·struct)만 쓴다.
[근거 문서] 06 사운드·"AI 티 안 나게"(같은 소리 3~4개 변형), 02 §12 위험할수록 악기가 더해지는 음악
"""
from __future__ import annotations

import math
import random
import struct
from pathlib import Path

SAMPLE_RATE = 22050
TWO_PI = 2.0 * math.pi
NOTE_SEMITONES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
ACCIDENTAL_SHIFT = {"#": 1, "b": -1}
DEFAULT_PERCUSSIVE_ENVELOPE = (0.001, 0.0, 1.5)
END_FADE_SECONDS = 0.006        # 효과음 끝을 이만큼 부드럽게 내려 '딱' 소리를 막는다


# ───────── 음 이름 · 음표 ─────────

def note_to_hz(note_name: str) -> float:
    """'A4' = 440Hz. 'C#5'·'Bb3' 처럼 # 과 b 를 붙인다."""
    has_accidental = note_name[1] in ACCIDENTAL_SHIFT
    octave = int(note_name[2:] if has_accidental else note_name[1:])
    semitone = NOTE_SEMITONES[note_name[0].upper()] + ACCIDENTAL_SHIFT.get(note_name[1], 0)
    midi_number = (octave + 1) * 12 + semitone
    return 440.0 * 2.0 ** ((midi_number - 69) / 12)


def count_steps(notes_text: str) -> int:
    """음표 글의 칸 수 합. 마디가 16칸인지 확인할 때 쓴다."""
    return sum(_token_steps(token) for token in notes_text.split())


def parse_notes(notes_text: str) -> list[tuple[int, list[str], int]]:
    """'D5:3 . A4:2 ~:2 F4+A4:2' → [(시작 칸, 음 이름들, 칸 수)].
    '.' = 쉼, '~' = 앞 음을 이어서 늘림, '+' = 함께 누르는 음(화음), 칸 수가 없으면 1칸."""
    events: list[tuple[int, list[str], int]] = []
    position = 0
    is_resting = True
    for token in notes_text.split():
        name = token.split(":")[0]
        steps = _token_steps(token)
        if name == ".":
            is_resting = True
        elif name == "~":
            if not is_resting:
                start, names, length = events[-1]
                events[-1] = (start, names, length + steps)
        else:
            events.append((position, name.split("+"), steps))
            is_resting = False
        position += steps
    return events


def _token_steps(token: str) -> int:
    count_text = token.partition(":")[2]
    return int(count_text) if count_text else 1


# ───────── 파형 ─────────

class NoiseRegister:
    """옛 게임기 노이즈 회로(15칸 밀기 레지스터). 쇠붙이 모드는 93걸음마다 되풀이돼 '챙' 하는 금속 소리가 난다."""

    def __init__(self, rng: random.Random, is_metallic: bool) -> None:
        self.state = rng.randint(1, 0x7FFF)
        self.tap = 6 if is_metallic else 1

    def step(self) -> float:
        feedback = (self.state & 1) ^ ((self.state >> self.tap) & 1)
        self.state = (self.state >> 1) | (feedback << 14)
        return 1.0 if self.state & 1 else -1.0


def poly_blep(phase: float, phase_step: float) -> float:
    """꺾이는 곳을 아주 살짝 둥글게 → 높은 음에서 생기는 '지직' 겹침 잡음(앨리어싱)을 줄인다. 싼 소리와 다듬은 소리의 차이."""
    if phase < phase_step:
        position = phase / phase_step
        return position + position - position * position - 1.0
    if phase > 1.0 - phase_step:
        position = (phase - 1.0) / phase_step
        return position * position + position + position + 1.0
    return 0.0


def wave_value(wave: str, phase: float, phase_step: float, duty: float) -> float:
    """한 주기 안 위치(phase 0~1)의 파형 값(-1~1)."""
    if wave == "square":
        value = 1.0 if phase < duty else -1.0
        value += poly_blep(phase, phase_step) - poly_blep((phase - duty) % 1.0, phase_step)
        return value - (2.0 * duty - 1.0)   # 폭이 좁은 사각파는 한쪽으로 쏠려서(직류) 가운데로 되돌린다
    if wave == "triangle":
        value = 1.0 - 4.0 * abs(phase - 0.5)
        return round(value * 7.5) / 7.5     # 옛 게임기처럼 16계단 → 특유의 까끌한 베이스
    if wave == "saw":
        return 2.0 * phase - 1.0 - poly_blep(phase, phase_step)
    return math.sin(TWO_PI * phase)


def render_oscillator(wave: str, frequencies: list[float], rng: random.Random, duty: float = 0.5) -> list[float]:
    """샘플마다 정해진 높이로 파형을 그린다. noise·metal 은 높이 대신 노이즈 회로의 빠르기(클럭)로 쓴다."""
    if wave in ("noise", "metal"):
        return _render_noise(frequencies, NoiseRegister(rng, is_metallic=wave == "metal"))
    samples: list[float] = []
    phase = 0.0
    for frequency in frequencies:
        phase_step = min(frequency / SAMPLE_RATE, 0.45)
        samples.append(wave_value(wave, phase, phase_step, duty))
        phase += phase_step
        if phase >= 1.0:
            phase -= 1.0
    return samples


def _render_noise(frequencies: list[float], register: NoiseRegister) -> list[float]:
    """클럭이 낮을수록 '쿠르릉', 높을수록 '치익'."""
    samples: list[float] = []
    value = register.step()
    clock = 0.0
    for frequency in frequencies:
        clock += frequency / SAMPLE_RATE
        if clock >= 1.0:
            clock %= 1.0
            value = register.step()
        samples.append(value)
    return samples


# ───────── 높이 · 엔벨로프 ─────────

def pitch_curve(start_hz: float, end_hz: float, sample_count: int, curve: float = 1.0,
                vibrato: list | tuple | None = None, arpeggio: tuple | None = None) -> list[float]:
    """샘플마다 음 높이(Hz). curve 가 1보다 크면 처음에 확 떨어지고(총소리 '탕'), 작으면 천천히 가다 끝에서 꺾인다.
    vibrato = (빠르기 Hz, 깊이 반음[, 늦게 시작 초]), arpeggio = (빠르기 Hz, [반음…]) — 옛 게임기가 화음 대신 쓰던 빠른 음 돌리기."""
    if start_hz == end_hz and not vibrato and not arpeggio:
        return [start_hz] * sample_count
    frequencies: list[float] = []
    last_index = max(sample_count - 1, 1)
    for index in range(sample_count):
        shaped = 1.0 - (1.0 - index / last_index) ** curve
        semitones = _modulation_semitones(index / SAMPLE_RATE, vibrato, arpeggio)
        frequencies.append(start_hz * (end_hz / start_hz) ** shaped * 2.0 ** (semitones / 12))
    return frequencies


def _modulation_semitones(seconds: float, vibrato: list | tuple | None, arpeggio: tuple | None) -> float:
    semitones = 0.0
    if vibrato:
        delay = vibrato[2] if len(vibrato) > 2 else 0.0
        fade_in = min(max((seconds - delay) / 0.15, 0.0), 1.0)   # 사람이 부르듯 음을 낸 뒤 조금 있다 떨기 시작
        semitones += vibrato[1] * fade_in * math.sin(TWO_PI * vibrato[0] * seconds)
    if arpeggio:
        rate, steps = arpeggio
        semitones += steps[int(seconds * rate) % len(steps)]
    return semitones


def percussive_envelope(sample_count: int, attack: float, hold: float, power: float) -> list[float]:
    """치는 소리: 올라가기 → 버티기 → 0까지 줄기. power 가 클수록 빨리 꺼져 짧고 단단하게 들린다."""
    attack_count = max(int(attack * SAMPLE_RATE), 1)
    hold_end = attack_count + int(hold * SAMPLE_RATE)
    decay_count = max(sample_count - hold_end, 1)
    levels: list[float] = []
    for index in range(sample_count):
        if index < attack_count:
            levels.append(index / attack_count)
        elif index < hold_end:
            levels.append(1.0)
        else:
            levels.append((1.0 - (index - hold_end) / decay_count) ** power)
    return levels


def sustained_envelope(sample_count: int, attack: float, decay: float, sustain: float, release: float) -> list[float]:
    """악기 음: 올라가기 → 유지 높이까지 줄기 → 음 끝에서 놓기. 놓기가 음 길이 안에서 끝나 다음 음과 '딱' 부딪히지 않는다."""
    attack_count = max(int(attack * SAMPLE_RATE), 1)
    decay_count = max(int(decay * SAMPLE_RATE), 1)
    release_start = sample_count - max(int(release * SAMPLE_RATE), 1)
    levels: list[float] = []
    for index in range(sample_count):
        if index < attack_count:
            level = index / attack_count
        else:
            level = sustain + (1.0 - sustain) * max(1.0 - (index - attack_count) / decay_count, 0.0)
        if index > release_start:
            level *= (sample_count - index) / (sample_count - release_start)
        levels.append(level)
    return levels


def apply_tremolo(samples: list[float], rate: float, depth: float, sharpness: float) -> None:
    """볼륨을 주기적으로 흔든다. sharpness 가 크면 '툭, 툭' 끊기는 박동이 된다(헬기 날개, 그르렁)."""
    for index in range(len(samples)):
        pulse = (0.5 + 0.5 * math.cos(TWO_PI * rate * index / SAMPLE_RATE)) ** sharpness
        samples[index] *= 1.0 - depth * (1.0 - pulse)


# ───────── 걸러내기 · 메아리 ─────────

def low_pass(samples: list[float], start_hz: float, end_hz: float = 0.0, is_looped: bool = False) -> list[float]:
    """높은 소리를 깎아 둥글게. end_hz 를 주면 깎는 높이가 시간에 따라 움직인다('휙' 지나가는 소리).
    반복 소리는 끝 상태로 한 번 미리 돌려서, 이어 붙이는 곳에서 튀지 않게 한다."""
    count = len(samples)
    end_hz = end_hz or start_hz
    if start_hz == end_hz:
        coefficients = [_low_pass_coefficient(start_hz)] * count
    else:
        coefficients = [_low_pass_coefficient(start_hz * (end_hz / start_hz) ** (index / count)) for index in range(count)]
    state = 0.0
    filtered: list[float] = []
    for _ in range(2 if is_looped else 1):
        filtered = []
        for sample, coefficient in zip(samples, coefficients):
            state += coefficient * (sample - state)
            filtered.append(state)
    return filtered


def _low_pass_coefficient(cutoff_hz: float) -> float:
    return 1.0 - math.exp(-TWO_PI * min(cutoff_hz, SAMPLE_RATE * 0.45) / SAMPLE_RATE)


def high_pass(samples: list[float], cutoff_hz: float, is_looped: bool = False) -> list[float]:
    """낮은 소리를 깎는다. 소리가 한쪽으로 쏠린 것(직류)을 없애는 데도 쓴다."""
    smoothed = low_pass(samples, cutoff_hz, is_looped=is_looped)
    return [sample - low for sample, low in zip(samples, smoothed)]


def apply_filters(samples: list[float], settings: dict, is_looped: bool = False) -> list[float]:
    """설정의 lowpass(두 겹으로 걸어 더 부드럽게)·highpass 를 차례로 건다."""
    if "lowpass" in settings:
        start_hz, end_hz = pair(settings["lowpass"])
        for _ in range(2):
            samples = low_pass(samples, start_hz, end_hz, is_looped)
    if "highpass" in settings:
        samples = high_pass(samples, settings["highpass"], is_looped)
    return samples


def add_echo(samples: list[float], delay_count: int, feedback: float, wet: float, is_looped: bool = False) -> list[float]:
    """메아리: wet = 첫 메아리 크기, feedback = 되풀이마다 줄어드는 비율. 반복 음악은 끝의 메아리가 처음으로 돌아와 이어진다."""
    count = len(samples)
    echoes = [0.0] * count
    for _ in range(3 if is_looped else 1):
        for index in range(count):
            source = index - delay_count     # 음수 = 끝에서부터 (반복 음악의 이음매)
            if source >= 0 or is_looped:
                echoes[index] = samples[source] + feedback * echoes[source]
    return [dry + wet * echo for dry, echo in zip(samples, echoes)]


def pair(value: float | list | tuple) -> tuple[float, float]:
    """숫자 하나면 (그 숫자, 그 숫자), 여럿이면 (처음, 끝)."""
    if isinstance(value, (int, float)):
        return float(value), float(value)
    return float(value[0]), float(value[-1])


# ───────── 레이어 · 효과음 · 악보 ─────────

def render_layer(layer: dict, rng: random.Random, pitch_ratio: float = 1.0, loop_seconds: float = 0.0) -> list[float]:
    """정의 표의 레이어 한 줄(파형·높이·길이·엔벨로프·걸러내기)을 소리로 만든다."""
    sample_count = max(int(layer["length"] * SAMPLE_RATE), 1)
    start_hz, end_hz = (_fit_loop(hz * pitch_ratio, loop_seconds) for hz in pair(layer["pitch"]))
    frequencies = pitch_curve(start_hz, end_hz, sample_count, layer.get("curve", 1.0), layer.get("vibrato"), layer.get("arpeggio"))
    samples = render_oscillator(layer["wave"], frequencies, rng, layer.get("duty", 0.5))
    samples = apply_filters(samples, layer, is_looped=loop_seconds > 0)
    if "tremolo" in layer:
        rate, depth, sharpness = layer["tremolo"]
        apply_tremolo(samples, _fit_loop(rate * pitch_ratio, loop_seconds), depth, sharpness)
    envelope = _layer_envelope(layer, sample_count)
    volume = layer.get("volume", 1.0)
    return [sample * level * volume for sample, level in zip(samples, envelope)]


def _fit_loop(rate: float, loop_seconds: float) -> float:
    """반복 소리는 반복 길이 안에 딱 떨어지는 횟수로 반올림 → 이음매에서 파형이 끊기지 않는다."""
    if not loop_seconds:
        return rate
    return max(round(rate * loop_seconds), 1) / loop_seconds


def _layer_envelope(layer: dict, sample_count: int) -> list[float]:
    if "adsr" in layer:
        return sustained_envelope(sample_count, *layer["adsr"])
    shape = layer.get("env", DEFAULT_PERCUSSIVE_ENVELOPE)
    if shape is None:
        return [1.0] * sample_count     # 반복 소리: 처음부터 끝까지 같은 크기
    return percussive_envelope(sample_count, *shape)


def render_note(instrument: dict, hz: float, sample_count: int, rng: random.Random) -> list[float]:
    """악기 설정으로 음 하나. 'pitch' 가 정해진 악기(바람·노이즈)는 음 이름과 상관없이 그 높이를 쓴다."""
    pitch = instrument.get("pitch", [hz, hz * instrument.get("glide_to", 1.0)])
    note = dict(instrument, pitch=pitch, length=sample_count * instrument.get("gate", 1.0) / SAMPLE_RATE)
    return render_layer(note, rng)


def render_note_layer(layer: dict, rng: random.Random, pitch_ratio: float = 1.0, variant_index: int = 0) -> list[float]:
    """음표가 있는 레이어(짧은 멜로디·박동). 'notes' 가 목록이면 변형 번호에 따라 다른 멜로디를 고른다."""
    notes_text = layer["notes"]
    if not isinstance(notes_text, str):
        notes_text = notes_text[variant_index % len(notes_text)]
    step_count = int(layer["step"] * SAMPLE_RATE)
    output = [0.0] * (count_steps(notes_text) * step_count)
    for start_step, names, length_steps in parse_notes(notes_text):
        for name in names:
            note = render_note(layer, note_to_hz(name) * pitch_ratio, length_steps * step_count, rng)
            mix_into(output, note, start_step * step_count)
    return output


def render_effect(layers: list[dict], rng: random.Random, pitch_ratio: float = 1.0, time_ratio: float = 1.0,
                  variant_index: int = 0, loop_seconds: float = 0.0) -> list[float]:
    """레이어 여러 겹을 각자 시작 시각에 놓고 섞어 효과음 하나를 만든다."""
    placed: list[tuple[int, list[float]]] = []
    for layer in layers:
        timed = dict(layer, start=layer.get("start", 0.0) * time_ratio)
        if "notes" in layer:
            timed["step"] = layer["step"] * time_ratio
            samples = render_note_layer(timed, rng, pitch_ratio, variant_index)
        else:
            timed["length"] = loop_seconds or layer["length"] * time_ratio
            detune = 1.0 if loop_seconds else rng.uniform(0.985, 1.015)   # 겹마다 아주 조금 어긋나게 → 찍어 낸 느낌을 줄인다
            samples = render_layer(timed, rng, pitch_ratio * detune, loop_seconds)
        placed.append((int(timed["start"] * SAMPLE_RATE), samples))
    total = int(loop_seconds * SAMPLE_RATE) or max(offset + len(samples) for offset, samples in placed)
    output = [0.0] * total
    for offset, samples in placed:
        mix_into(output, samples, offset, is_looped=loop_seconds > 0)
    return output


def render_part(events: list[tuple[int, list[str], int]], instrument: dict, step_count: int, total_count: int,
                rng: random.Random, volume: float = 1.0) -> list[float]:
    """악보 한 파트를 반복 길이 버퍼에 그린다. 끝에서 넘친 꼬리(놓기·메아리)는 처음으로 돌아가 붙어 이음매가 안 들린다."""
    output = [0.0] * total_count
    for start_step, names, length_steps in events:
        for name in names:
            velocity = volume * rng.uniform(0.88, 1.0)      # 사람이 치듯 세기를 조금씩 다르게
            note = render_note(instrument, note_to_hz(name), length_steps * step_count, rng)
            mix_into(output, note, start_step * step_count, velocity, is_looped=True)
    if "echo" in instrument:
        delay_steps, feedback, wet = instrument["echo"]
        output = add_echo(output, int(delay_steps * step_count), feedback, wet, is_looped=True)
    return output


def render_drum_part(pattern: str, hit_variants: list[list[float]], step_count: int, total_count: int,
                     rng: random.Random, volume: float = 1.0) -> list[float]:
    """타악기 줄('X...x...'): X = 세게, x = 보통. 칠 때마다 미리 만든 변형 중 하나를 골라 똑같은 소리 반복을 피한다."""
    output = [0.0] * total_count
    for step, mark in enumerate(pattern):
        if mark == ".":
            continue
        strength = 1.0 if mark.isupper() else 0.62
        hit = rng.choice(hit_variants)
        mix_into(output, hit, step * step_count, volume * strength * rng.uniform(0.9, 1.0), is_looped=True)
    return output


# ───────── 섞기 · 크기 · 저장 ─────────

def mix_into(target: list[float], source: list[float], offset: int, gain: float = 1.0, is_looped: bool = False) -> None:
    """source 를 target 의 offset 위치에 더한다. 반복 소리는 끝을 넘친 부분을 처음으로 돌려 붙인다."""
    length = len(target)
    for index, sample in enumerate(source):
        position = offset + index
        if position >= length:
            if not is_looped:
                break
            position %= length
        target[position] += sample * gain


def saturate(samples: list[float], drive: float) -> list[float]:
    """살짝 찌그러뜨려 소리를 두껍고 앞으로 나오게(폭발·포효). 크기를 1로 맞춘 뒤 tanh 로 부드럽게 누른다."""
    peak = max(abs(sample) for sample in samples) or 1.0
    return [math.tanh(drive * sample / peak) / math.tanh(drive) for sample in samples]


def crush(samples: list[float], levels: int) -> list[float]:
    """높낮이 단계를 줄여(비트 줄이기) 옛 게임기의 까끌한 맛을 더한다."""
    peak = max(abs(sample) for sample in samples) or 1.0
    return [round(sample / peak * levels) / levels for sample in samples]


def finish_sound(samples: list[float], peak_db: float, drive: float = 0.0, crush_levels: int = 0,
                 is_looped: bool = False) -> list[float]:
    """마무리: (찌그러뜨리기·비트 줄이기) → 직류 없애기 → 끝 다듬기 → 목표 크기(dBFS). 목표가 0 아래라 클리핑이 없다."""
    if drive:
        samples = saturate(samples, drive)
    if crush_levels:
        samples = crush(samples, crush_levels)
    samples = high_pass(samples, 25.0, is_looped)
    if not is_looped:
        fade_count = min(int(END_FADE_SECONDS * SAMPLE_RATE), len(samples))
        for index in range(fade_count):
            samples[-1 - index] *= index / fade_count
    return scale_to_peak(samples, peak_db)


def scale_to_peak(samples: list[float], peak_db: float) -> list[float]:
    """가장 큰 값이 peak_db(dBFS)가 되게 전체를 같은 비율로 키우거나 줄인다."""
    peak = max((abs(sample) for sample in samples), default=0.0)
    if peak == 0.0:
        return samples
    gain = 10.0 ** (peak_db / 20.0) / peak
    return [sample * gain for sample in samples]


def write_wav(path: Path, samples: list[float], is_loop: bool = False) -> None:
    """16비트 모노 WAV. 반복용이면 'smpl' 덩어리에 처음~끝 반복 구간을 적어, Godot 가져오기(Loop Mode: Detect From WAV)가 저절로 반복한다."""
    frames = struct.pack(f"<{len(samples)}h", *(max(-32768, min(32767, round(sample * 32767))) for sample in samples))
    body = _chunk(b"fmt ", struct.pack("<HHIIHH", 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16)) + _chunk(b"data", frames)
    if is_loop:
        # 머리 9칸(만든 곳·기기·샘플 간격 ns·기준 음 60 …·반복 1개) + 반복 1개(번호·앞으로 반복·시작·끝·…)
        loop_info = struct.pack("<15I", 0, 0, 1_000_000_000 // SAMPLE_RATE, 60, 0, 0, 0, 1, 0, 0, 0, 0, len(samples), 0, 0)
        body += _chunk(b"smpl", loop_info)
    path.write_bytes(b"RIFF" + struct.pack("<I", 4 + len(body)) + b"WAVE" + body)


def _chunk(chunk_id: bytes, content: bytes) -> bytes:
    padding = b"\x00" if len(content) % 2 else b""
    return chunk_id + struct.pack("<I", len(content)) + content + padding
