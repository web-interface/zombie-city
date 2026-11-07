"""
[파일] tools/sound_table_core.py
[하는 일] 효과음 정의 표 ① 기본: 레이어 적는 도구(layer·notes) + 처음부터 있던 효과음 26종(무기 6·좀비·보스·생존자·줍기·레벨 업·카드·전직·스킬 4·폭발·헬기·탈출·게임 오버·UI) + 심장 소리(체력 낮음).
[쓰는 곳] tools/build_sounds.py 가 다른 표(sound_table_night·weapons·rewards)와 합쳐 audio/<이름>_<번호>.wav 로 만든다. 다른 표들도 여기의 layer·notes 를 쓴다.
[근거 문서] 06 사운드·"AI 티 안 나게", 08 v0.2 손맛·소리, audio/README.md 크기 기준(효과음 −6dBFS 이하)
"""
from __future__ import annotations


def layer(wave: str, pitch: float | list, length: float, **options) -> dict:
    """효과음 레이어 한 겹. pitch = 높이 Hz(노이즈는 클럭) 하나 또는 [시작, 끝].
    options: start(초) · env=(올라가기, 버티기, 줄어드는 세기) · volume · lowpass · highpass · curve · duty · vibrato · tremolo · arpeggio
    · in_variants=[번호…] (그 변형에서만 소리 냄 — 연속 처치처럼 변형마다 화려함이 다를 때)"""
    return {"wave": wave, "pitch": pitch, "length": length, **options}


def notes(wave: str, text: str | list, step: float, **options) -> dict:
    """음표 레이어 한 겹. text 가 목록이면 변형마다 다른 멜로디. step = 한 칸 길이(초). glide_to = 음마다 끝 높이 비율.
    노이즈로 박자만 치려면 pitch=클럭 을 주고 음 이름은 아무거나(C4) 쓴다."""
    return {"wave": wave, "notes": text, "step": step, **options}


# variants = 변형 수, spread = 변형끼리 높이 차(반음), peak_db = 가장 큰 소리(dBFS). 자주 나는 소리일수록 작게 (귀가 안 지치게).
# 2026-11-07: 웹판에서 여러 소리가 겹치면 합이 1.0 을 넘어 찢어져서 이 표의 peak_db 를 모두 3dB 낮춤 (예전 −3 → −6). 비율은 그대로.
FANFARE_LEAD = dict(duty=0.25, gate=0.92, vibrato=(5.5, 0.2, 0.15), env=(0.004, 0.05, 0.9), volume=0.5)
CORE_EFFECTS: dict[str, dict] = {
    "pistol_shot": {"about": "권총 '탕' — 딸깍 + 떨어지는 사각파 + 낮은 쿵 + 짧은 꼬리", "variants": 4, "spread": 2.5, "peak_db": -8.0, "layers": [
        layer("noise", 22050, 0.012, env=(0, 0, 1.0), volume=0.9),
        layer("square", [900, 140], 0.09, curve=2.5, env=(0.001, 0.005, 2.0), lowpass=6000, volume=0.6),
        layer("sine", [170, 50], 0.08, curve=2.0, volume=0.8),
        layer("noise", [9000, 2500], 0.2, env=(0.0, 0.01, 3.0), lowpass=4000, volume=0.45)]},
    "shotgun_shot": {"about": "산탄총 '쾅' — 두꺼운 폭발음 + 깊은 반동 + 펌프 '철컥'", "variants": 4, "spread": 2.0, "peak_db": -6.5, "drive": 1.6, "layers": [
        layer("noise", 22050, 0.015, env=(0, 0, 1.0)),
        layer("noise", [12000, 1800], 0.42, curve=1.5, env=(0.001, 0.02, 2.4), lowpass=[6000, 900]),
        layer("sine", [130, 38], 0.22, curve=2.0, env=(0.001, 0.01, 1.6)),
        layer("square", [420, 70], 0.14, curve=2.0, duty=0.25, env=(0.001, 0, 2.0), lowpass=3000, volume=0.4),
        layer("metal", 6500, 0.035, start=0.32, env=(0.001, 0, 2.0), lowpass=5000, volume=0.18),
        layer("metal", 5200, 0.04, start=0.4, env=(0.001, 0, 2.0), lowpass=5000, volume=0.15)]},
    "nail_shot": {"about": "네일건 '탁' — 쇠붙이 노이즈 + 짧은 사각파 + 공기 '칙' (빨리 연사해도 안 거슬리게 작게)", "variants": 4, "spread": 3.0, "peak_db": -11.0, "layers": [
        layer("metal", 15000, 0.03, env=(0, 0.002, 2.5), highpass=1500, volume=0.8),
        layer("square", [2000, 650], 0.035, curve=2.0, duty=0.125, env=(0.0005, 0, 1.8), volume=0.45),
        layer("noise", 22050, 0.06, env=(0.004, 0, 2.5), highpass=3000, lowpass=9000, volume=0.3),
        layer("sine", [300, 120], 0.03, volume=0.4)]},
    "syringe_shot": {"about": "주사기 총 '퓨슉' — 바람 빠지는 소리 + 올라가는 '뿅'(주입) + 유리 '틱'", "variants": 4, "spread": 2.5, "peak_db": -11.0, "layers": [
        layer("noise", 22050, 0.1, env=(0.008, 0.01, 2.2), highpass=1800, lowpass=7500, volume=0.55),
        layer("triangle", [1100, 1900], 0.06, curve=0.7, env=(0.002, 0.01, 1.5), volume=0.45),
        layer("square", 2600, 0.018, start=0.045, duty=0.25, env=(0.001, 0, 2.0), volume=0.18)]},
    "axe_swing": {"about": "소방 도끼 '휙' — 걸러내는 높이가 올라가는 바람 소리 + 낮게 떨어지는 휘두름", "variants": 4, "spread": 2.0, "peak_db": -9.0, "layers": [
        layer("noise", 22050, 0.24, env=(0.07, 0.02, 2.0), lowpass=[700, 3800], highpass=200),
        layer("triangle", [260, 120], 0.18, curve=1.5, env=(0.04, 0, 1.8), volume=0.35)]},
    "saw_drone_hit": {"about": "톱날 드론 '지징' — 떨리는 톱니파 + 쇠 긁힘 (비트를 줄여 까끌하게)", "variants": 4, "spread": 3.0, "peak_db": -12.0, "crush": 20, "layers": [
        layer("saw", [1250, 1050], 0.11, tremolo=(55, 0.6, 2), env=(0.001, 0.03, 1.5), lowpass=5000, volume=0.6),
        layer("metal", 11000, 0.05, env=(0, 0, 2.0), volume=0.5)]},
    "zombie_hit": {"about": "좀비 맞음 '퍽' — 축축한 노이즈 + 낮은 쿵 + 짧은 바삭함 (가장 자주 나서 총소리보다 작게)", "variants": 4, "spread": 3.0, "peak_db": -12.0, "layers": [
        layer("noise", [3200, 900], 0.09, env=(0.001, 0.005, 2.0), lowpass=2600, volume=0.85),
        layer("sine", [230, 85], 0.08, curve=1.8, volume=0.8),
        layer("square", [320, 140], 0.045, duty=0.25, env=(0.001, 0, 2.0), lowpass=2500, volume=0.3)]},
    "zombie_die": {"about": "좀비 쓰러짐 — 낮아지는 '그르륵' + 초록 체액 '철퍽' + 바닥에 닿는 두 번째 '철퍽'", "variants": 4, "spread": 3.0, "peak_db": -10.0, "layers": [
        layer("saw", [190, 65], 0.38, curve=0.8, vibrato=(17, 1.2), env=(0.01, 0.06, 1.5), lowpass=1400, volume=0.55),
        layer("noise", [6000, 1200], 0.28, curve=1.5, env=(0.002, 0.02, 2.2), lowpass=3200, volume=0.6),
        layer("triangle", [420, 110], 0.12, curve=1.5, volume=0.35),
        layer("noise", 1400, 0.1, start=0.18, env=(0.005, 0, 2.0), lowpass=1200, volume=0.25)]},
    "boss_hit": {"about": "보스 맞음 — 묵직한 쿵 + 단단한 껍질에 맞는 쇠 소리", "variants": 4, "spread": 2.0, "peak_db": -7.0, "drive": 1.4, "layers": [
        layer("sine", [125, 40], 0.2, curve=2.0),
        layer("noise", [5000, 1300], 0.22, env=(0.001, 0.01, 2.2), lowpass=3000, volume=0.8),
        layer("metal", 2800, 0.09, env=(0, 0.01, 2.0), lowpass=4500, volume=0.3),
        layer("square", [240, 90], 0.12, lowpass=1800, volume=0.35)]},
    "survivor_hurt": {"about": "생존자 다침 — 둔한 충격 + 떨리는 '윽' + 반음 부딪히는 경고음", "variants": 4, "spread": 2.0, "peak_db": -7.5, "layers": [
        layer("noise", [2500, 700], 0.11, env=(0.001, 0.01, 2.0), lowpass=2000, volume=0.7),
        layer("square", [430, 260], 0.16, vibrato=(28, 0.8), env=(0.005, 0.03, 1.6), lowpass=2200, volume=0.5),
        layer("square", 880, 0.11, start=0.02, duty=0.25, env=(0.002, 0.04, 1.4), volume=0.18),
        layer("square", 932, 0.11, start=0.02, duty=0.25, env=(0.002, 0.04, 1.4), volume=0.18)]},
    "shard_pickup": {"about": "백신 조각 줍기 '삐릭' — 1→5 로 높이가 한 칸씩 올라감(도·레·미·솔·라)", "steps": [0, 2, 4, 7, 9], "peak_db": -17.0, "layers": [
        notes("square", "C6 G6 C7:2", 0.022, duty=0.25, env=(0.001, 0.008, 1.4), volume=0.6),
        layer("triangle", 2093, 0.05, start=0.03, env=(0.001, 0, 1.6), volume=0.3)]},
    "heartbeat": {"about": "심장 소리 '쿵-쿵' — 체력 30% 아래에서 박자마다 (낮은 사인 두 번, 작게)", "variants": 2, "spread": 1.0, "peak_db": -10.0, "layers": [
        layer("sine", [95, 55], 0.12, curve=1.5, env=(0.004, 0.02, 1.8), volume=0.9),
        layer("sine", [85, 50], 0.1, start=0.2, curve=1.5, env=(0.004, 0.02, 1.8), volume=0.6)]},
    "level_up": {"about": "레벨 업 — 빠르게 올라가는 펼침화음 + 끝에 반짝이 (변형마다 오르는 모양이 다름)", "variants": 3, "spread": 2.0, "peak_db": -8.0, "layers": [
        notes("square", ["C5 E5 G5 C6 E6 G6 C7:6", "G4 C5 E5 G5 C6 E6 G6:6", "C5 G5 E5 C6 G5 E6 C7:6"], 0.05,
              env=(0.002, 0.02, 1.2), vibrato=(6, 0.15, 0.1), volume=0.55),
        notes("triangle", "C4:3 G4:3 C5:6", 0.05, env=(0.002, 0.05, 1.0), volume=0.6),
        layer("square", 2093, 0.45, start=0.32, duty=0.125, arpeggio=(30, [0, 12, 7, 19]), env=(0.005, 0.1, 1.6), volume=0.16)]},
    "card_select": {"about": "카드 고름 '딩동' — 두 음 확인 소리", "variants": 4, "spread": 2.0, "peak_db": -12.0, "layers": [
        notes("square", "B5 E6:4", 0.04, duty=0.25, env=(0.001, 0.01, 1.4), volume=0.6),
        notes("triangle", ". E5:4", 0.04, env=(0.001, 0, 1.4), volume=0.4),
        layer("noise", 22050, 0.008, env=(0, 0, 1.0), highpass=3000, volume=0.3)]},
    "promotion": {"about": "전직 — '빰빰빰 빠-암' 금관 팡파르 + 팀파니 + 심벌 + 반짝이", "variants": 3, "spread": 2.0, "peak_db": -6.0, "layers": [
        notes("square", ["C5 C5 C5 G5:5 F5 E5 F5 G5:10", "C5 C5 C5 G5:5 A5 G5 F5 G5:10", "G4 C5 E5 G5:5 F5 E5 F5 G5:10"], 0.1, **FANFARE_LEAD),
        notes("square", "G4 G4 G4 E5:5 D5 C5 D5 E5:10", 0.1, gate=0.92, env=(0.004, 0.05, 0.9), lowpass=3500, volume=0.32),
        notes("triangle", "C3:3 C3:5 F3:3 C3:10", 0.1, env=(0.003, 0.1, 1.0), volume=0.7),
        notes("sine", "C2:3 C2:5 . . . C2:10", 0.1, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.9),
        layer("noise", 22050, 1.3, start=1.1, env=(0.001, 0.02, 2.2), highpass=2500, volume=0.35),
        layer("square", 2093, 1.0, start=1.1, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), vibrato=(6, 0.1), env=(0.01, 0.3, 1.5), volume=0.14)]},
    "skill_flashbang": {"about": "섬광탄 — 핀 '팅' → '펑' → 귀가 먹먹한 '삐-' 울림", "variants": 3, "spread": 1.5, "peak_db": -6.0, "drive": 1.5, "layers": [
        layer("metal", 14000, 0.04, env=(0, 0, 2.0), volume=0.35),
        layer("triangle", 2600, 0.07, env=(0.001, 0, 1.6), volume=0.3),
        layer("noise", [22050, 3500], 0.55, start=0.13, env=(0.001, 0.03, 2.4)),
        layer("sine", [150, 40], 0.3, start=0.13, curve=2.0, volume=0.9),
        layer("sine", 3700, 1.3, start=0.16, env=(0.12, 0.25, 1.3), vibrato=(5, 0.06), volume=0.16)]},
    "skill_sprint": {"about": "질주 — 점점 밝아지는 바람 + 올라가는 사각파 + 발 구르기 두 번", "variants": 3, "spread": 2.0, "peak_db": -8.5, "layers": [
        layer("noise", 22050, 0.36, env=(0.13, 0.02, 1.8), lowpass=[450, 6500], volume=0.85),
        layer("square", [220, 900], 0.22, curve=0.6, duty=0.125, env=(0.004, 0.05, 1.5), lowpass=4500, volume=0.35),
        notes("sine", "A2 . A2", 0.07, glide_to=0.5, env=(0.001, 0, 2.0), volume=0.6)]},
    "skill_heal": {"about": "응급 처치 — 부드럽게 올라가는 음 + 따뜻한 삼각파 + 반짝이", "variants": 3, "spread": 2.0, "peak_db": -9.5, "layers": [
        notes("square", ["C5 E5 G5 C6 E6:6", "E5 G5 C6 E6 G6:6", "G4 C5 E5 G5 C6:6"], 0.07, duty=0.25,
              env=(0.005, 0.02, 1.2), vibrato=(6, 0.15, 0.08), lowpass=5000, volume=0.45),
        layer("triangle", 523.25, 0.9, env=(0.15, 0.3, 1.5), vibrato=(5.5, 0.12), volume=0.35),
        layer("square", 2093, 0.55, start=0.3, duty=0.125, arpeggio=(24, [0, 7, 12, 19]), env=(0.03, 0.1, 1.5), volume=0.12),
        layer("noise", 22050, 0.6, env=(0.2, 0.1, 1.5), highpass=3500, lowpass=9000, volume=0.08)]},
    "skill_extinguisher": {"about": "소화기 분사 — 밸브 '퍽' + 치익 뿜는 소리(살짝 끊김) + 낮은 웅웅", "variants": 3, "spread": 1.5, "peak_db": -8.5, "layers": [
        layer("noise", 22050, 0.05, env=(0, 0, 1.5), volume=0.6),
        layer("sine", [320, 120], 0.05, volume=0.4),
        layer("noise", 22050, 1.0, start=0.03, env=(0.04, 0.55, 1.6), highpass=1200, lowpass=6500, tremolo=(23, 0.25, 1), volume=0.8),
        layer("noise", 1800, 1.0, start=0.03, env=(0.05, 0.5, 1.5), lowpass=450, volume=0.45)]},
    "explosion": {"about": "폭발(차·기름통·터지는 좀비) — 어두워지는 폭음 + 깊은 쿵 + 타닥타닥 잔불", "variants": 4, "spread": 2.5, "peak_db": -6.0, "drive": 2.2, "layers": [
        layer("noise", [9000, 450], 1.3, curve=2.0, env=(0.002, 0.03, 2.2), lowpass=[5500, 380]),
        layer("sine", [110, 30], 0.75, curve=2.0, env=(0.001, 0.02, 1.8)),
        layer("noise", 2600, 0.9, start=0.08, env=(0.04, 0.1, 2.0), lowpass=1400, tremolo=(19, 0.75, 4), volume=0.4),
        layer("square", [230, 40], 0.25, curve=2.0, lowpass=1500, volume=0.3)]},
    "boss_warning": {"about": "보스 예고 — 높낮이 번갈아 우는 경보 + 차오르는 낮은 웅웅 + 심장 '쿵-쿵'", "variants": 3, "spread": 1.5, "peak_db": -6.5, "layers": [
        notes("square", "E6:3 . B5:3 . E6:3 . B5:3 . E6:3 . B5:3 .", 0.075, env=(0.003, 0.15, 0.8), lowpass=4500, volume=0.32),
        layer("saw", [46, 55], 2.2, curve=0.8, env=(0.8, 0.9, 1.5), lowpass=[350, 1100], volume=0.85),
        layer("square", [92, 110], 2.2, duty=0.25, env=(0.8, 0.9, 1.5), lowpass=[300, 900], volume=0.35),
        notes("sine", "A2:2 A2:6 A2:2 A2:6", 0.125, glide_to=0.55, env=(0.001, 0.02, 2.0), volume=0.9)]},
    "boss_roar": {"about": "보스 포효 — 떨리는 낮은 톱니파 + 갈라지는 고음 + 거친 숨 (찌그러뜨리고 비트를 줄임)", "variants": 3, "spread": 2.0, "peak_db": -6.0, "drive": 1.8, "crush": 28, "layers": [
        layer("saw", [96, 60], 1.5, curve=0.7, vibrato=(24, 1.4), env=(0.06, 0.45, 1.4), lowpass=1800, volume=0.85),
        layer("square", [310, 185], 1.3, curve=0.8, duty=0.25, vibrato=(17, 2.2), env=(0.1, 0.35, 1.6), lowpass=2600, volume=0.35),
        layer("noise", [1900, 650], 1.5, env=(0.05, 0.45, 1.5), lowpass=1700, tremolo=(31, 0.6, 1), volume=0.65),
        layer("sine", [62, 34], 0.55, curve=1.5, volume=0.6)]},
    "helicopter_loop": {"about": "헬기 날개 '두두두' 반복(2초, 이음매 없음) — 변형마다 날개 빠르기가 다름", "variants": 3, "spread": 2.5, "peak_db": -9.0, "loop_seconds": 2.0, "layers": [
        layer("noise", 2800, 2.0, env=None, lowpass=950, tremolo=(12, 0.9, 3)),
        layer("sine", 52, 2.0, env=None, tremolo=(12, 0.95, 6), volume=0.75),
        layer("square", 1650, 2.0, env=None, duty=0.125, lowpass=3000, volume=0.06),
        layer("noise", 22050, 2.0, env=None, highpass=4000, lowpass=8000, volume=0.08)]},
    "extraction_success": {"about": "탈출 성공 — 밝게 올라가는 팡파르 + 북 + 심벌 + 반짝이", "variants": 3, "spread": 2.0, "peak_db": -6.0, "layers": [
        notes("square", ["G4 C5 E5 G5:3 E5 G5:5 C6:10", "C5 E5 G5 C6:3 G5 C6:5 E6:10", "E5 G5 C6 E6:3 C6 E6:5 G6:10"], 0.1, **FANFARE_LEAD),
        notes("square", "E4 G4 C5 E5:3 C5 E5:5 G5:10", 0.1, gate=0.92, env=(0.004, 0.05, 0.9), lowpass=3500, volume=0.3),
        notes("triangle", "C3:6 G2:6 C3:10", 0.1, env=(0.003, 0.1, 1.0), volume=0.7),
        notes("sine", "C2:6 G1:6 C2:10", 0.1, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.8),
        layer("noise", 22050, 1.4, start=1.2, env=(0.001, 0.02, 2.2), highpass=2500, volume=0.3),
        layer("square", 2093, 1.1, start=1.2, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), env=(0.01, 0.3, 1.5), volume=0.13)]},
    "game_over": {"about": "게임 오버 — 천천히 내려가는 단조 멜로디 + 낮은 삼각파 + 끝에 바람", "variants": 3, "spread": 2.0, "peak_db": -9.0, "layers": [
        notes("square", ["A4:2 G4:2 E4:2 F4:3 E4 D4:2 C4:2 B3:2 A3:10", "C5:2 B4:2 A4:2 F4:3 E4 D4:2 C4:2 B3:2 A3:10",
                         "E5:2 D5:2 C5:2 A4:3 G4 F4:2 E4:2 D4:2 C4:10"], 0.14,
              gate=0.95, vibrato=(5, 0.22, 0.2), env=(0.01, 0.08, 1.0), lowpass=2600, volume=0.5),
        notes("triangle", "A2:6 D2:6 E2:4 A1:10", 0.14, env=(0.01, 0.2, 1.0), volume=0.7),
        layer("noise", 1500, 1.6, start=2.2, env=(0.5, 0.3, 1.5), lowpass=500, volume=0.18)]},
    "ui_click": {"about": "버튼 누름 '틱' — 아주 짧은 사각파 + 딸깍", "variants": 4, "spread": 1.5, "peak_db": -17.0, "layers": [
        layer("square", [2300, 1900], 0.026, env=(0.0005, 0.004, 2.0), lowpass=7000, volume=0.6),
        layer("noise", 22050, 0.006, env=(0, 0, 1.5), highpass=2500, volume=0.35)]},
    "ui_back": {"about": "뒤로·닫기 '뽁' — 내려가는 두 음", "variants": 4, "spread": 1.5, "peak_db": -19.5, "layers": [
        notes("square", "E6 A5:2", 0.035, env=(0.0005, 0.005, 1.8), lowpass=6000, volume=0.6)]},
}
