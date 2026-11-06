"""
[파일] tools/build_sounds.py
[하는 일] 8비트풍 효과음(이름마다 3~4개 변형, 줍기 소리는 높이 5단계)과 음악(한 판 3층·타이틀·결과)을 만들어 audio/*.wav 로 저장하고 audio/README.md 를 새로 쓴다.
[쓰는 곳] `py -3 tools/build_sounds.py` 로 실행. tools/chiptune.py 의 소리 조각과 audio/source/music_scores.txt 악보를 쓴다 → scripts/autoload/sound_player.gd 가 audio/*.wav 를 튼다.
[근거 문서] 06 사운드·"AI 티 안 나게", 02 §12 위험할수록 악기가 더해지는 음악, 08 v0.2 손맛·소리
"""
from __future__ import annotations

import random
from pathlib import Path

from chiptune import (SAMPLE_RATE, count_steps, finish_sound, high_pass, parse_notes, render_drum_part,
                      render_effect, render_part, write_wav)

PROJECT = Path(__file__).resolve().parent.parent
AUDIO = PROJECT / "audio"
SCORE_FILE = AUDIO / "source" / "music_scores.txt"
STEPS_PER_BAR = 16
MUSIC_PEAK_DB = -3.0            # 한 곡의 층을 모두 켰을 때 가장 큰 소리
DRUM_VARIANT_COUNT = 3


def layer(wave: str, pitch: float | list, length: float, **options) -> dict:
    """효과음 레이어 한 겹. pitch = 높이 Hz(노이즈는 클럭) 하나 또는 [시작, 끝].
    options: start(초) · env=(올라가기, 버티기, 줄어드는 세기) · volume · lowpass · highpass · curve · duty · vibrato · tremolo · arpeggio"""
    return {"wave": wave, "pitch": pitch, "length": length, **options}


def notes(wave: str, text: str | list, step: float, **options) -> dict:
    """음표 레이어 한 겹. text 가 목록이면 변형마다 다른 멜로디. step = 한 칸 길이(초). glide_to = 음마다 끝 높이 비율."""
    return {"wave": wave, "notes": text, "step": step, **options}


# ───────── 효과음 정의 표 ─────────
# variants = 변형 수, spread = 변형끼리 높이 차(반음), peak_db = 가장 큰 소리. 자주 나는 소리일수록 작게 (귀가 안 지치게).
FANFARE_LEAD = dict(duty=0.25, gate=0.92, vibrato=(5.5, 0.2, 0.15), env=(0.004, 0.05, 0.9), volume=0.5)
EFFECTS: dict[str, dict] = {
    "pistol_shot": {"about": "권총 '탕' — 딸깍 + 떨어지는 사각파 + 낮은 쿵 + 짧은 꼬리", "variants": 4, "spread": 2.5, "peak_db": -5.0, "layers": [
        layer("noise", 22050, 0.012, env=(0, 0, 1.0), volume=0.9),
        layer("square", [900, 140], 0.09, curve=2.5, env=(0.001, 0.005, 2.0), lowpass=6000, volume=0.6),
        layer("sine", [170, 50], 0.08, curve=2.0, volume=0.8),
        layer("noise", [9000, 2500], 0.2, env=(0.0, 0.01, 3.0), lowpass=4000, volume=0.45)]},
    "shotgun_shot": {"about": "산탄총 '쾅' — 두꺼운 폭발음 + 깊은 반동 + 펌프 '철컥'", "variants": 4, "spread": 2.0, "peak_db": -3.5, "drive": 1.6, "layers": [
        layer("noise", 22050, 0.015, env=(0, 0, 1.0)),
        layer("noise", [12000, 1800], 0.42, curve=1.5, env=(0.001, 0.02, 2.4), lowpass=[6000, 900]),
        layer("sine", [130, 38], 0.22, curve=2.0, env=(0.001, 0.01, 1.6)),
        layer("square", [420, 70], 0.14, curve=2.0, duty=0.25, env=(0.001, 0, 2.0), lowpass=3000, volume=0.4),
        layer("metal", 6500, 0.035, start=0.32, env=(0.001, 0, 2.0), lowpass=5000, volume=0.18),
        layer("metal", 5200, 0.04, start=0.4, env=(0.001, 0, 2.0), lowpass=5000, volume=0.15)]},
    "nail_shot": {"about": "네일건 '탁' — 쇠붙이 노이즈 + 짧은 사각파 + 공기 '칙' (빨리 연사해도 안 거슬리게 작게)", "variants": 4, "spread": 3.0, "peak_db": -8.0, "layers": [
        layer("metal", 15000, 0.03, env=(0, 0.002, 2.5), highpass=1500, volume=0.8),
        layer("square", [2000, 650], 0.035, curve=2.0, duty=0.125, env=(0.0005, 0, 1.8), volume=0.45),
        layer("noise", 22050, 0.06, env=(0.004, 0, 2.5), highpass=3000, lowpass=9000, volume=0.3),
        layer("sine", [300, 120], 0.03, volume=0.4)]},
    "syringe_shot": {"about": "주사기 총 '퓨슉' — 바람 빠지는 소리 + 올라가는 '뿅'(주입) + 유리 '틱'", "variants": 4, "spread": 2.5, "peak_db": -8.0, "layers": [
        layer("noise", 22050, 0.1, env=(0.008, 0.01, 2.2), highpass=1800, lowpass=7500, volume=0.55),
        layer("triangle", [1100, 1900], 0.06, curve=0.7, env=(0.002, 0.01, 1.5), volume=0.45),
        layer("square", 2600, 0.018, start=0.045, duty=0.25, env=(0.001, 0, 2.0), volume=0.18)]},
    "axe_swing": {"about": "소방 도끼 '휙' — 걸러내는 높이가 올라가는 바람 소리 + 낮게 떨어지는 휘두름", "variants": 4, "spread": 2.0, "peak_db": -6.0, "layers": [
        layer("noise", 22050, 0.24, env=(0.07, 0.02, 2.0), lowpass=[700, 3800], highpass=200),
        layer("triangle", [260, 120], 0.18, curve=1.5, env=(0.04, 0, 1.8), volume=0.35)]},
    "saw_drone_hit": {"about": "톱날 드론 '지징' — 떨리는 톱니파 + 쇠 긁힘 (비트를 줄여 까끌하게)", "variants": 4, "spread": 3.0, "peak_db": -9.0, "crush": 20, "layers": [
        layer("saw", [1250, 1050], 0.11, tremolo=(55, 0.6, 2), env=(0.001, 0.03, 1.5), lowpass=5000, volume=0.6),
        layer("metal", 11000, 0.05, env=(0, 0, 2.0), volume=0.5)]},
    "zombie_hit": {"about": "좀비 맞음 '퍽' — 축축한 노이즈 + 낮은 쿵 + 짧은 바삭함 (가장 자주 나서 총소리보다 작게)", "variants": 4, "spread": 3.0, "peak_db": -9.0, "layers": [
        layer("noise", [3200, 900], 0.09, env=(0.001, 0.005, 2.0), lowpass=2600, volume=0.85),
        layer("sine", [230, 85], 0.08, curve=1.8, volume=0.8),
        layer("square", [320, 140], 0.045, duty=0.25, env=(0.001, 0, 2.0), lowpass=2500, volume=0.3)]},
    "zombie_die": {"about": "좀비 쓰러짐 — 낮아지는 '그르륵' + 초록 체액 '철퍽' + 바닥에 닿는 두 번째 '철퍽'", "variants": 4, "spread": 3.0, "peak_db": -7.0, "layers": [
        layer("saw", [190, 65], 0.38, curve=0.8, vibrato=(17, 1.2), env=(0.01, 0.06, 1.5), lowpass=1400, volume=0.55),
        layer("noise", [6000, 1200], 0.28, curve=1.5, env=(0.002, 0.02, 2.2), lowpass=3200, volume=0.6),
        layer("triangle", [420, 110], 0.12, curve=1.5, volume=0.35),
        layer("noise", 1400, 0.1, start=0.18, env=(0.005, 0, 2.0), lowpass=1200, volume=0.25)]},
    "boss_hit": {"about": "보스 맞음 — 묵직한 쿵 + 단단한 껍질에 맞는 쇠 소리", "variants": 4, "spread": 2.0, "peak_db": -4.0, "drive": 1.4, "layers": [
        layer("sine", [125, 40], 0.2, curve=2.0),
        layer("noise", [5000, 1300], 0.22, env=(0.001, 0.01, 2.2), lowpass=3000, volume=0.8),
        layer("metal", 2800, 0.09, env=(0, 0.01, 2.0), lowpass=4500, volume=0.3),
        layer("square", [240, 90], 0.12, lowpass=1800, volume=0.35)]},
    "survivor_hurt": {"about": "생존자 다침 — 둔한 충격 + 떨리는 '윽' + 반음 부딪히는 경고음", "variants": 4, "spread": 2.0, "peak_db": -4.5, "layers": [
        layer("noise", [2500, 700], 0.11, env=(0.001, 0.01, 2.0), lowpass=2000, volume=0.7),
        layer("square", [430, 260], 0.16, vibrato=(28, 0.8), env=(0.005, 0.03, 1.6), lowpass=2200, volume=0.5),
        layer("square", 880, 0.11, start=0.02, duty=0.25, env=(0.002, 0.04, 1.4), volume=0.18),
        layer("square", 932, 0.11, start=0.02, duty=0.25, env=(0.002, 0.04, 1.4), volume=0.18)]},
    "shard_pickup": {"about": "백신 조각 줍기 '삐릭' — 1→5 로 높이가 한 칸씩 올라감(도·레·미·솔·라)", "steps": [0, 2, 4, 7, 9], "peak_db": -14.0, "layers": [
        notes("square", "C6 G6 C7:2", 0.022, duty=0.25, env=(0.001, 0.008, 1.4), volume=0.6),
        layer("triangle", 2093, 0.05, start=0.03, env=(0.001, 0, 1.6), volume=0.3)]},
    "level_up": {"about": "레벨 업 — 빠르게 올라가는 펼침화음 + 끝에 반짝이 (변형마다 오르는 모양이 다름)", "variants": 3, "spread": 2.0, "peak_db": -5.0, "layers": [
        notes("square", ["C5 E5 G5 C6 E6 G6 C7:6", "G4 C5 E5 G5 C6 E6 G6:6", "C5 G5 E5 C6 G5 E6 C7:6"], 0.05,
              env=(0.002, 0.02, 1.2), vibrato=(6, 0.15, 0.1), volume=0.55),
        notes("triangle", "C4:3 G4:3 C5:6", 0.05, env=(0.002, 0.05, 1.0), volume=0.6),
        layer("square", 2093, 0.45, start=0.32, duty=0.125, arpeggio=(30, [0, 12, 7, 19]), env=(0.005, 0.1, 1.6), volume=0.16)]},
    "card_select": {"about": "카드 고름 '딩동' — 두 음 확인 소리", "variants": 4, "spread": 2.0, "peak_db": -9.0, "layers": [
        notes("square", "B5 E6:4", 0.04, duty=0.25, env=(0.001, 0.01, 1.4), volume=0.6),
        notes("triangle", ". E5:4", 0.04, env=(0.001, 0, 1.4), volume=0.4),
        layer("noise", 22050, 0.008, env=(0, 0, 1.0), highpass=3000, volume=0.3)]},
    "promotion": {"about": "전직 — '빰빰빰 빠-암' 금관 팡파르 + 팀파니 + 심벌 + 반짝이", "variants": 3, "spread": 2.0, "peak_db": -3.0, "layers": [
        notes("square", ["C5 C5 C5 G5:5 F5 E5 F5 G5:10", "C5 C5 C5 G5:5 A5 G5 F5 G5:10", "G4 C5 E5 G5:5 F5 E5 F5 G5:10"], 0.1, **FANFARE_LEAD),
        notes("square", "G4 G4 G4 E5:5 D5 C5 D5 E5:10", 0.1, gate=0.92, env=(0.004, 0.05, 0.9), lowpass=3500, volume=0.32),
        notes("triangle", "C3:3 C3:5 F3:3 C3:10", 0.1, env=(0.003, 0.1, 1.0), volume=0.7),
        notes("sine", "C2:3 C2:5 . . . C2:10", 0.1, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.9),
        layer("noise", 22050, 1.3, start=1.1, env=(0.001, 0.02, 2.2), highpass=2500, volume=0.35),
        layer("square", 2093, 1.0, start=1.1, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), vibrato=(6, 0.1), env=(0.01, 0.3, 1.5), volume=0.14)]},
    "skill_flashbang": {"about": "섬광탄 — 핀 '팅' → '펑' → 귀가 먹먹한 '삐-' 울림", "variants": 3, "spread": 1.5, "peak_db": -3.0, "drive": 1.5, "layers": [
        layer("metal", 14000, 0.04, env=(0, 0, 2.0), volume=0.35),
        layer("triangle", 2600, 0.07, env=(0.001, 0, 1.6), volume=0.3),
        layer("noise", [22050, 3500], 0.55, start=0.13, env=(0.001, 0.03, 2.4)),
        layer("sine", [150, 40], 0.3, start=0.13, curve=2.0, volume=0.9),
        layer("sine", 3700, 1.3, start=0.16, env=(0.12, 0.25, 1.3), vibrato=(5, 0.06), volume=0.16)]},
    "skill_sprint": {"about": "질주 — 점점 밝아지는 바람 + 올라가는 사각파 + 발 구르기 두 번", "variants": 3, "spread": 2.0, "peak_db": -5.5, "layers": [
        layer("noise", 22050, 0.36, env=(0.13, 0.02, 1.8), lowpass=[450, 6500], volume=0.85),
        layer("square", [220, 900], 0.22, curve=0.6, duty=0.125, env=(0.004, 0.05, 1.5), lowpass=4500, volume=0.35),
        notes("sine", "A2 . A2", 0.07, glide_to=0.5, env=(0.001, 0, 2.0), volume=0.6)]},
    "skill_heal": {"about": "응급 처치 — 부드럽게 올라가는 음 + 따뜻한 삼각파 + 반짝이", "variants": 3, "spread": 2.0, "peak_db": -6.5, "layers": [
        notes("square", ["C5 E5 G5 C6 E6:6", "E5 G5 C6 E6 G6:6", "G4 C5 E5 G5 C6:6"], 0.07, duty=0.25,
              env=(0.005, 0.02, 1.2), vibrato=(6, 0.15, 0.08), lowpass=5000, volume=0.45),
        layer("triangle", 523.25, 0.9, env=(0.15, 0.3, 1.5), vibrato=(5.5, 0.12), volume=0.35),
        layer("square", 2093, 0.55, start=0.3, duty=0.125, arpeggio=(24, [0, 7, 12, 19]), env=(0.03, 0.1, 1.5), volume=0.12),
        layer("noise", 22050, 0.6, env=(0.2, 0.1, 1.5), highpass=3500, lowpass=9000, volume=0.08)]},
    "skill_extinguisher": {"about": "소화기 분사 — 밸브 '퍽' + 치익 뿜는 소리(살짝 끊김) + 낮은 웅웅", "variants": 3, "spread": 1.5, "peak_db": -5.5, "layers": [
        layer("noise", 22050, 0.05, env=(0, 0, 1.5), volume=0.6),
        layer("sine", [320, 120], 0.05, volume=0.4),
        layer("noise", 22050, 1.0, start=0.03, env=(0.04, 0.55, 1.6), highpass=1200, lowpass=6500, tremolo=(23, 0.25, 1), volume=0.8),
        layer("noise", 1800, 1.0, start=0.03, env=(0.05, 0.5, 1.5), lowpass=450, volume=0.45)]},
    "explosion": {"about": "폭발(차·기름통·터지는 좀비) — 어두워지는 폭음 + 깊은 쿵 + 타닥타닥 잔불", "variants": 4, "spread": 2.5, "peak_db": -3.0, "drive": 2.2, "layers": [
        layer("noise", [9000, 450], 1.3, curve=2.0, env=(0.002, 0.03, 2.2), lowpass=[5500, 380]),
        layer("sine", [110, 30], 0.75, curve=2.0, env=(0.001, 0.02, 1.8)),
        layer("noise", 2600, 0.9, start=0.08, env=(0.04, 0.1, 2.0), lowpass=1400, tremolo=(19, 0.75, 4), volume=0.4),
        layer("square", [230, 40], 0.25, curve=2.0, lowpass=1500, volume=0.3)]},
    "boss_warning": {"about": "보스 예고 — 높낮이 번갈아 우는 경보 + 차오르는 낮은 웅웅 + 심장 '쿵-쿵'", "variants": 3, "spread": 1.5, "peak_db": -3.5, "layers": [
        notes("square", "E6:3 . B5:3 . E6:3 . B5:3 . E6:3 . B5:3 .", 0.075, env=(0.003, 0.15, 0.8), lowpass=4500, volume=0.32),
        layer("saw", [46, 55], 2.2, curve=0.8, env=(0.8, 0.9, 1.5), lowpass=[350, 1100], volume=0.85),
        layer("square", [92, 110], 2.2, duty=0.25, env=(0.8, 0.9, 1.5), lowpass=[300, 900], volume=0.35),
        notes("sine", "A2:2 A2:6 A2:2 A2:6", 0.125, glide_to=0.55, env=(0.001, 0.02, 2.0), volume=0.9)]},
    "boss_roar": {"about": "보스 포효 — 떨리는 낮은 톱니파 + 갈라지는 고음 + 거친 숨 (찌그러뜨리고 비트를 줄임)", "variants": 3, "spread": 2.0, "peak_db": -3.0, "drive": 1.8, "crush": 28, "layers": [
        layer("saw", [96, 60], 1.5, curve=0.7, vibrato=(24, 1.4), env=(0.06, 0.45, 1.4), lowpass=1800, volume=0.85),
        layer("square", [310, 185], 1.3, curve=0.8, duty=0.25, vibrato=(17, 2.2), env=(0.1, 0.35, 1.6), lowpass=2600, volume=0.35),
        layer("noise", [1900, 650], 1.5, env=(0.05, 0.45, 1.5), lowpass=1700, tremolo=(31, 0.6, 1), volume=0.65),
        layer("sine", [62, 34], 0.55, curve=1.5, volume=0.6)]},
    "helicopter_loop": {"about": "헬기 날개 '두두두' 반복(2초, 이음매 없음) — 변형마다 날개 빠르기가 다름", "variants": 3, "spread": 2.5, "peak_db": -6.0, "loop_seconds": 2.0, "layers": [
        layer("noise", 2800, 2.0, env=None, lowpass=950, tremolo=(12, 0.9, 3)),
        layer("sine", 52, 2.0, env=None, tremolo=(12, 0.95, 6), volume=0.75),
        layer("square", 1650, 2.0, env=None, duty=0.125, lowpass=3000, volume=0.06),
        layer("noise", 22050, 2.0, env=None, highpass=4000, lowpass=8000, volume=0.08)]},
    "extraction_success": {"about": "탈출 성공 — 밝게 올라가는 팡파르 + 북 + 심벌 + 반짝이", "variants": 3, "spread": 2.0, "peak_db": -3.0, "layers": [
        notes("square", ["G4 C5 E5 G5:3 E5 G5:5 C6:10", "C5 E5 G5 C6:3 G5 C6:5 E6:10", "E5 G5 C6 E6:3 C6 E6:5 G6:10"], 0.1, **FANFARE_LEAD),
        notes("square", "E4 G4 C5 E5:3 C5 E5:5 G5:10", 0.1, gate=0.92, env=(0.004, 0.05, 0.9), lowpass=3500, volume=0.3),
        notes("triangle", "C3:6 G2:6 C3:10", 0.1, env=(0.003, 0.1, 1.0), volume=0.7),
        notes("sine", "C2:6 G1:6 C2:10", 0.1, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.8),
        layer("noise", 22050, 1.4, start=1.2, env=(0.001, 0.02, 2.2), highpass=2500, volume=0.3),
        layer("square", 2093, 1.1, start=1.2, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), env=(0.01, 0.3, 1.5), volume=0.13)]},
    "game_over": {"about": "게임 오버 — 천천히 내려가는 단조 멜로디 + 낮은 삼각파 + 끝에 바람", "variants": 3, "spread": 2.0, "peak_db": -6.0, "layers": [
        notes("square", ["A4:2 G4:2 E4:2 F4:3 E4 D4:2 C4:2 B3:2 A3:10", "C5:2 B4:2 A4:2 F4:3 E4 D4:2 C4:2 B3:2 A3:10",
                         "E5:2 D5:2 C5:2 A4:3 G4 F4:2 E4:2 D4:2 C4:10"], 0.14,
              gate=0.95, vibrato=(5, 0.22, 0.2), env=(0.01, 0.08, 1.0), lowpass=2600, volume=0.5),
        notes("triangle", "A2:6 D2:6 E2:4 A1:10", 0.14, env=(0.01, 0.2, 1.0), volume=0.7),
        layer("noise", 1500, 1.6, start=2.2, env=(0.5, 0.3, 1.5), lowpass=500, volume=0.18)]},
    "ui_click": {"about": "버튼 누름 '틱' — 아주 짧은 사각파 + 딸깍", "variants": 4, "spread": 1.5, "peak_db": -14.0, "layers": [
        layer("square", [2300, 1900], 0.026, env=(0.0005, 0.004, 2.0), lowpass=7000, volume=0.6),
        layer("noise", 22050, 0.006, env=(0, 0, 1.5), highpass=2500, volume=0.35)]},
    "ui_back": {"about": "뒤로·닫기 '뽁' — 내려가는 두 음", "variants": 4, "spread": 1.5, "peak_db": -16.5, "layers": [
        notes("square", "E6 A5:2", 0.035, env=(0.0005, 0.005, 1.8), lowpass=6000, volume=0.6)]},
}

MUSIC_ABOUT = {
    "music_run_layer1": "한 판 음악 1층(늘 켬) — 사각파 베이스 + 북·작은북·하이햇. 레단조 126 BPM 24마디",
    "music_run_layer2": "한 판 음악 2층(위험 2단계) — 멜로디 + 9마디부터 펼침화음",
    "music_run_layer3": "한 판 음악 3층(위험 3단계) — 반음으로 떠는 고음 + 낮은 웅웅 + 17마디부터 비명 같은 리드 + 셰이커·탐·심벌·차오르는 노이즈",
    "music_title": "타이틀 — 쓸쓸한 밤 도시: 메아리 걸린 펼침화음, 느린 멜로디, 멀리 바람과 사이렌. 가단조 75 BPM 16마디",
    "music_result": "결과 화면 — 밤을 버틴 뒤의 담담함. 바장조 90 BPM 12마디",
}


def main() -> None:
    made = build_effects() + build_music()
    remove_stale_files({file_name for file_name, _, _, _ in made})
    write_readme(made)
    total_bytes = sum((AUDIO / file_name).stat().st_size for file_name, _, _, _ in made)
    print(f"소리 {len(made)}개를 만들었어요 → {AUDIO}  (합계 {total_bytes / 1_000_000:.2f}MB)")


# ───────── 효과음 ─────────

def build_effects() -> list[tuple[str, str, str, float]]:
    """정의 표의 소리마다 변형을 만들어 '<이름>_<번호>.wav' 로 저장. 돌려주는 값: (파일, 묶음 이름, 설명, 초)."""
    made: list[tuple[str, str, str, float]] = []
    for name, effect in EFFECTS.items():
        rng = random.Random(name)      # 이름이 씨앗 → 다시 돌려도 같은 소리 (원본을 안 고치면 파일도 안 바뀜)
        loop_seconds = effect.get("loop_seconds", 0.0)
        for number, (pitch_ratio, time_ratio) in enumerate(variant_settings(effect, rng), start=1):
            samples = render_effect(effect["layers"], rng, pitch_ratio, time_ratio, number - 1, loop_seconds)
            samples = finish_sound(samples, effect["peak_db"], effect.get("drive", 0.0), effect.get("crush", 0), loop_seconds > 0)
            file_name = f"{name}_{number}.wav"
            write_wav(AUDIO / file_name, samples, is_loop=loop_seconds > 0)
            made.append((file_name, name, effect["about"], len(samples) / SAMPLE_RATE))
    return made


def variant_settings(effect: dict, rng: random.Random) -> list[tuple[float, float]]:
    """변형마다 (높이 비율, 길이 비율). 높이는 고르게 퍼뜨린 뒤 섞어서 '1번이 늘 제일 낮음' 같은 규칙이 안 보이게 한다.
    줍기 소리처럼 'steps'(반음 단계)가 있으면 그 순서가 곧 높이다."""
    if "steps" in effect:
        return [(2.0 ** (semitones / 12), 1.0) for semitones in effect["steps"]]
    count = effect["variants"]
    offsets = [effect["spread"] * (index / (count - 1) - 0.5) for index in range(count)]
    rng.shuffle(offsets)
    settings: list[tuple[float, float]] = []
    for offset in offsets:
        pitch_ratio = 2.0 ** ((offset + rng.uniform(-0.15, 0.15)) / 12)
        time_ratio = 1.0 if "loop_seconds" in effect else rng.uniform(0.94, 1.06)   # 반복 소리는 길이가 정확해야 이음매가 맞는다
        settings.append((pitch_ratio, time_ratio))
    return settings


# ───────── 음악 ─────────

def build_music() -> list[tuple[str, str, str, float]]:
    """악보 파일의 곡마다 파일(층)을 만든다. 한 곡의 층들은 같은 비율로 크기를 맞춰, 다 같이 틀어도 클리핑이 없다."""
    instruments, drums, songs = read_score(SCORE_FILE)
    rng = random.Random("music")
    drum_hits = {name: [render_effect(layers, rng, rng.uniform(0.97, 1.03)) for _ in range(DRUM_VARIANT_COUNT)]
                 for name, layers in drums.items()}
    made: list[tuple[str, str, str, float]] = []
    for song in songs:
        files = scale_song(render_song(song, instruments, drum_hits, rng), song.get("peak_db", MUSIC_PEAK_DB))
        for stem, samples in files.items():
            write_wav(AUDIO / f"{stem}.wav", samples, is_loop=True)
            made.append((f"{stem}.wav", stem, MUSIC_ABOUT.get(stem, ""), len(samples) / SAMPLE_RATE))
    return made


def render_song(song: dict, instruments: dict, drum_hits: dict, rng: random.Random) -> dict[str, list[float]]:
    """곡 하나의 파트들을 파일별로 섞는다. 같은 곡의 파일은 샘플 수까지 같아서 동시에 틀면 박자가 맞는다."""
    step_length = SAMPLE_RATE * 60 / (song["bpm"] * 4)
    if step_length != int(step_length):
        raise ValueError(f"{SCORE_FILE.name}: '{song['name']}' bpm {song['bpm']} — 16분음표가 샘플 수로 딱 안 떨어져 층·이음매가 어긋남")
    step_count = int(step_length)
    total_count = int(song["bars"]) * STEPS_PER_BAR * step_count
    files: dict[str, list[float]] = {}
    for part in song["parts"]:
        is_drum = part["instrument"] in drum_hits
        if not is_drum and part["instrument"] not in instruments:
            raise ValueError(f"{SCORE_FILE.name}: {part['file']} — 악기 '{part['instrument']}' 가 @instrument·@drum 에 없음")
        bars = part_bars(part, int(song["bars"]), is_drum)
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


def part_bars(part: dict, bar_count: int, is_drum: bool) -> list[str]:
    """마디 줄을 '|' 로 나누고 '%'(앞 마디 그대로)를 풀어 쓴 뒤, 마디마다 16칸인지·마디 수가 맞는지 확인한다."""
    bars: list[str] = []
    for text in " | ".join(part["lines"]).split("|"):
        text = text.strip()
        if text:
            bars.append(bars[-1] if text == "%" else text)
    for number, bar in enumerate(bars, start=1):
        size = len(bar) if is_drum else count_steps(bar)
        if size != STEPS_PER_BAR:
            raise ValueError(f"{SCORE_FILE.name}: {part['file']} {part['instrument']} {number}번째 마디가 {size}칸 (16칸이어야 함): {bar}")
    if len(bars) != bar_count:
        raise ValueError(f"{SCORE_FILE.name}: {part['file']} {part['instrument']} 마디가 {len(bars)}개 (곡은 {bar_count}마디)")
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
            instruments[words[1]] = parse_settings(words[2:])
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


# ───────── 정리 · 설명서 ─────────

def remove_stale_files(made_names: set[str]) -> None:
    """이번에 안 만든 옛 .wav(변형 수를 줄였을 때 등)와 그 Godot 가져오기 파일을 지운다 → audio/ 에는 지금 정의된 소리만 남는다."""
    for path in AUDIO.glob("*.wav"):
        if path.name not in made_names:
            path.unlink()
            import_file = path.with_name(path.name + ".import")
            if import_file.exists():
                import_file.unlink()


README_INTRO = """# audio — 효과음·음악 (직접 고치지 않음)
`tools/build_sounds.py` 가 만든 소리다. 바꾸려면 도구의 효과음 정의 표(`EFFECTS`)나 악보 `source/music_scores.txt` 를 고치고 `py -3 tools/build_sounds.py` 로 다시 만든다. (문서 10 §5 — 소리 파일엔 주석을 못 넣어서 여기 적음)

**출처: 이 프로젝트에서 도구로 직접 만듦 (외부 자료·AI 음성/음악 생성 없음).** 파이썬 기본 라이브러리로 파형을 한 샘플씩 계산했다. 사용 조건: 제한 없음(우리 것).

- 형식: 16비트 모노 WAV, 22050Hz (8비트풍이라 이걸로 충분하고 용량이 절반)
- 크기: 큰 소리(폭발·포효·전직·탈출) −3dBFS, 무기 −5 ~ −9, 좀비 맞음 −9, 줍기 −14, UI −14 ~ −16.5 — 자주 나는 소리일수록 작게 (폰 스피커로 들리는 크기 기준으로 맞춤). 음악: 한 판 음악은 세 층을 다 켰을 때 −3dBFS, 조용한 타이틀·결과는 −5dBFS 로 낮춰 들리는 크기를 맞춤 (1층만 켠 평온할 때는 약 5dB 작음 — 위험해질수록 커지게). 클리핑 없음
- 반복: `music_*.wav`·`helicopter_loop_*.wav` 는 WAV 안 'smpl' 칸에 처음~끝 반복 구간이 적혀 있어 Godot 가져오기 Loop Mode 기본값(Detect From WAV)으로 끊김 없이 반복된다

## 게임에서 쓸 때
- 같은 이름의 `_1`~`_4` 중 무작위 + 높이(pitch_scale) 조금씩 → 같은 소리 반복이 안 들림 (문서 06 AI 티)
- `shard_pickup_1`~`_5` 는 무작위가 아니라 **높이 순서**(도·레·미·솔·라). 잠깐(약 0.4초) 안에 또 주우면 다음 번호, 쉬면 1로, 5 다음은 5 유지. 높이를 따로 흔들지 말고 그대로 튼다
- `music_run_layer1~3` 은 길이가 샘플 하나까지 같고 템포도 같다 → **같은 순간에 셋 다 틀고 볼륨만** 바꾼다(1층 늘 켬, 위험 2단계에 2층, 3단계에 3층). 한 층만 멈췄다 다시 틀면 박자가 어긋난다
- `helicopter_loop_*` 는 끝없이 반복되므로 전용 플레이어에서 틀고 헬기가 떠날 때 멈춘다
- `boss_warning`(예고 약 2초) 다음에 `boss_roar`

## 파일
| 파일 | 길이 | 무엇 |
|---|---|---|
"""


def write_readme(made: list[tuple[str, str, str, float]]) -> None:
    """만든 파일을 소리 이름별로 묶어 한 줄씩 적는다."""
    groups: dict[str, list[tuple[str, str, float]]] = {}
    for file_name, group, about, seconds in made:
        groups.setdefault(group, []).append((file_name, about, seconds))
    rows: list[str] = []
    for group, files in groups.items():
        longest = max(seconds for _, _, seconds in files)
        shown = f"`{files[0][0]}`" if len(files) == 1 else f"`{group}_1.wav` ~ `_{len(files)}.wav`"
        length_text = f"{longest:.2f}초" if longest < 0.1 else f"{longest:.1f}초"
        rows.append(f"| {shown} | {length_text} | {files[0][1]} |")
    rows.append("| `source/music_scores.txt` | — | 음악 악보 원본(악기 설정 + 마디별 음표). 사람이 읽고 고칠 수 있음 |")
    (AUDIO / "README.md").write_text(README_INTRO + "\n".join(rows) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
