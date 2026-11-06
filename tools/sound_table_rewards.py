"""
[파일] tools/sound_table_rewards.py
[하는 일] 효과음 정의 표 ④ 보상·연출: 진화 팡파르, 히든 카드·컷인, 히든 스킬 4종(폭격·백드래프트·총알 배송·기적), 보물 상자(떨어짐·슬롯·열림·대박), 필드 줍기 3종, 카드 빼기, 해금·업적.
[쓰는 곳] tools/build_sounds.py 가 sound_table_core 의 layer·notes 로 적은 이 표를 audio/<이름>_<번호>.wav 로 만든다.
[근거 문서] 14 §2-1 빼 버리기·히든 카드, §2-4 진화, §2-5 히든 스킬, §2-6 보물 상자·줍기, §3 업적·해금, 06 사운드·"AI 티 안 나게"
"""
from __future__ import annotations

from sound_table_core import FANFARE_LEAD, layer, notes

CHEST_TICKS = "E6:2 C6:2 G6:2 D6:2 A6:2 E6:2 C6:2 G6:3 D6:3 A6:3 E6:3 C6:4 G6:4 D6:4 A6:5 E6:5 C6:6 G6:6"   # 60칸 × 0.025초 = 1.5초, 점점 느려짐
CHEST_CLICKS = "C4:2 C4:2 C4:2 C4:2 C4:2 C4:2 C4:2 C4:3 C4:3 C4:3 C4:3 C4:4 C4:4 C4:4 C4:5 C4:5 C4:6 C4:6"   # 같은 박자의 '딸깍'
BRASS_PAD = dict(duty=0.5, gate=0.92, env=(0.004, 0.05, 0.9), lowpass=3500, volume=0.3)

REWARD_EFFECTS: dict[str, dict] = {
    # ───────── 진화 · 히든 ─────────
    "evolution": {"about": "진화 — '슈와앙' 올라가는 소리 뒤 '빰-빠밤-빠-밤!' 세 화음(A♭→B♭→C) 금관 팡파르 + 팀파니 + 심벌 + 반짝이", "variants": 1, "peak_db": -6.0, "layers": [
        layer("square", [200, 1600], 0.42, curve=0.6, duty=0.25, arpeggio=(40, [0, 4, 7, 12]), env=(0.35, 0.05, 1.0), lowpass=5000, volume=0.3),
        layer("noise", 22050, 0.42, env=(0.4, 0, 1.0), lowpass=[800, 9000], volume=0.35),
        notes("square", "Eb5:2 Ab5:2 C6:3 . F5:2 Bb5:2 D6:3 . G5 C6 E6 G6:13", 0.075, start=0.42, **FANFARE_LEAD),
        notes("square", "C5:2 Eb5:2 Ab5:3 . D5:2 F5:2 Bb5:3 . E5 G5 C6 E6:13", 0.075, start=0.42, **BRASS_PAD),
        notes("triangle", "Ab2:7 . Bb2:7 . C3:16", 0.075, start=0.42, env=(0.003, 0.1, 1.0), volume=0.7),
        notes("sine", "Ab1:4 . . . . Bb1:4 . . . . C2:16", 0.075, start=0.42, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.8),
        layer("noise", 22050, 1.3, start=1.62, env=(0.001, 0.02, 2.2), highpass=2500, volume=0.35),
        layer("square", 2093, 1.1, start=1.62, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), vibrato=(6, 0.1), env=(0.01, 0.3, 1.5), volume=0.14)]},
    "hidden_card_appear": {"about": "히든 카드 등장 — 온음으로 올라가는 신비한 펼침음(메아리 두 번) + 떠 있는 증3화음 + 반짝이", "variants": 1, "peak_db": -8.0, "layers": [
        notes("square", "C6 D6 E6 F#6 G#6 A#6 C7:4", 0.06, duty=0.125, env=(0.002, 0.02, 1.4), lowpass=7000, volume=0.4),
        notes("square", "C6 D6 E6 F#6 G#6 A#6 C7:4", 0.06, start=0.18, duty=0.125, env=(0.002, 0.02, 1.4), lowpass=5000, volume=0.2),
        notes("square", "C6 D6 E6 F#6 G#6 A#6 C7:4", 0.06, start=0.36, duty=0.125, env=(0.002, 0.02, 1.4), lowpass=4000, volume=0.1),
        layer("triangle", 329.6, 1.6, env=(0.4, 0.6, 1.5), vibrato=(5, 0.15), volume=0.25),
        layer("triangle", 415.3, 1.6, env=(0.45, 0.55, 1.5), vibrato=(5.3, 0.15), volume=0.22),
        layer("triangle", 523.25, 1.6, env=(0.5, 0.5, 1.5), vibrato=(4.7, 0.15), volume=0.2),
        layer("square", 2093, 1.2, start=0.4, duty=0.125, arpeggio=(22, [0, 4, 8, 12]), env=(0.2, 0.3, 1.5), volume=0.1),
        layer("noise", 22050, 1.4, start=0.2, env=(0.5, 0.2, 1.5), highpass=6000, lowpass=11000, tremolo=(3, 0.6, 1), volume=0.08)]},
    "hidden_skill_cutin": {"about": "히든 스킬 컷인 '슈욱-쾅!' — 빨려 드는 바람 + 크게 내려치는 소리 + 길게 우는 쇠 울림과 높은 화음", "variants": 1, "peak_db": -6.0, "drive": 1.8, "layers": [
        layer("noise", 22050, 0.3, env=(0.28, 0, 1.0), lowpass=[500, 9000], volume=0.6),
        layer("square", [150, 900], 0.3, curve=0.5, duty=0.125, env=(0.28, 0, 1.0), lowpass=3500, volume=0.2),
        layer("noise", 22050, 0.015, start=0.3, env=(0, 0, 1.0)),
        layer("noise", [10000, 900], 0.6, start=0.3, curve=1.8, env=(0.001, 0.02, 2.2), lowpass=[7000, 900]),
        layer("sine", [130, 35], 0.6, start=0.3, curve=2.0, env=(0.001, 0.03, 1.5)),
        layer("metal", 2400, 0.9, start=0.3, env=(0.001, 0.05, 2.0), lowpass=5000, volume=0.25),
        layer("square", 1046.5, 0.8, start=0.3, duty=0.25, vibrato=(6, 0.2), env=(0.001, 0.1, 1.8), lowpass=5000, volume=0.18),
        layer("square", 1568, 0.8, start=0.3, duty=0.25, vibrato=(6.4, 0.2), env=(0.001, 0.1, 1.8), lowpass=5000, volume=0.14)]},
    "airstrike_whistle": {"about": "항공 지원 폭격 예고 '휘이이-' — 높은 데서 떨어지며 낮아지는 휘파람 (가까워질수록 커짐)", "variants": 3, "spread": 3.0, "peak_db": -11.0, "layers": [
        layer("sine", [2300, 800], 1.0, curve=0.8, vibrato=(7, 0.12), env=(0.85, 0.1, 1.0), volume=0.8),
        layer("square", [2300, 800], 1.0, curve=0.8, duty=0.125, env=(0.85, 0.1, 1.0), lowpass=4000, volume=0.1),
        layer("noise", 22050, 1.0, env=(0.9, 0.05, 1.0), highpass=3000, lowpass=7000, volume=0.1)]},
    "airstrike_boom": {"about": "폭격 '쿠웅' — 짧고 깊은 폭음 + 땅 울림 + 흙 쏟아지는 소리 (20발이 겹쳐서 폭발보다 작게)", "variants": 3, "spread": 3.0, "peak_db": -8.0, "drive": 2.0, "layers": [
        layer("noise", [7000, 350], 0.8, curve=2.2, env=(0.001, 0.02, 2.4), lowpass=[4500, 300]),
        layer("sine", [100, 30], 0.55, curve=2.0, env=(0.001, 0.02, 1.6)),
        layer("square", [240, 45], 0.2, curve=2.2, duty=0.375, lowpass=1300, volume=0.35),
        layer("noise", 4000, 0.4, start=0.15, env=(0.05, 0.05, 2.0), lowpass=2500, tremolo=(23, 0.8, 4), volume=0.25)]},
    "backdraft_roar": {"about": "백드래프트 '후욱-콰아아' — 공기를 빨아들이는 소리 + 불길이 터져 나오는 굵은 폭음 + 길게 으르렁대는 불꽃", "variants": 3, "spread": 2.0, "peak_db": -6.5, "drive": 1.9, "layers": [
        layer("noise", 22050, 0.3, env=(0.27, 0, 1.0), lowpass=[300, 2500], volume=0.5),
        layer("noise", [9000, 700], 1.2, start=0.28, curve=1.5, env=(0.002, 0.08, 1.8), lowpass=[6000, 900]),
        layer("sine", [110, 35], 0.6, start=0.28, curve=2.0, env=(0.001, 0.03, 1.6), volume=0.9),
        layer("noise", 1500, 1.1, start=0.33, env=(0.08, 0.3, 1.6), lowpass=1100, tremolo=(13, 0.6, 3), volume=0.6),
        layer("saw", [85, 60], 1.0, start=0.3, vibrato=(19, 1.2), env=(0.05, 0.3, 1.5), lowpass=900, volume=0.35)]},
    "express_dash": {"about": "총알 배송 돌진 '빵-부앙' — 오토바이 경적 + 확 올라가는 엔진 + 빠르게 스치는 바람", "variants": 3, "spread": 2.0, "peak_db": -9.0, "layers": [
        layer("square", 740, 0.09, env=(0.003, 0.06, 1.0), lowpass=3000, volume=0.18),
        layer("square", 932, 0.09, env=(0.003, 0.06, 1.0), lowpass=3000, volume=0.18),
        layer("saw", [110, 330], 0.32, start=0.06, curve=1.6, tremolo=(32, 0.5, 2), env=(0.005, 0.1, 1.3), lowpass=2200, volume=0.6),
        layer("square", [220, 660], 0.32, start=0.06, curve=1.6, duty=0.25, tremolo=(32, 0.5, 2), env=(0.005, 0.08, 1.5), lowpass=2500, volume=0.2),
        layer("noise", 22050, 0.4, start=0.1, env=(0.12, 0.05, 1.6), lowpass=[1200, 7000], highpass=300, volume=0.32)]},
    "miracle_chime": {"about": "기적의 처방 — 하프처럼 올라가는 음 + 맑은 종소리 화음 '디잉-' + 따뜻하게 감싸는 소리 + 반짝이", "variants": 1, "peak_db": -7.0, "layers": [
        notes("triangle", "C5 E5 G5 C6 E6 G6 C7:6", 0.06, env=(0.002, 0.04, 1.3), volume=0.5),
        layer("sine", 1046.5, 1.8, start=0.4, env=(0.002, 0.05, 2.0), volume=0.35),
        layer("sine", 2888, 0.9, start=0.4, env=(0.002, 0.02, 2.5), volume=0.1),
        layer("sine", 1318.5, 1.6, start=0.42, env=(0.002, 0.05, 2.0), volume=0.25),
        layer("sine", 1568, 1.5, start=0.44, env=(0.002, 0.05, 2.0), volume=0.2),
        layer("triangle", 261.6, 1.8, start=0.1, env=(0.5, 0.6, 1.5), vibrato=(5, 0.1), volume=0.35),
        layer("triangle", 392, 1.8, start=0.1, env=(0.55, 0.55, 1.5), vibrato=(5.4, 0.1), volume=0.25),
        layer("square", 2093, 1.2, start=0.6, duty=0.125, arpeggio=(24, [0, 4, 7, 12]), env=(0.05, 0.2, 1.5), volume=0.1),
        layer("noise", 22050, 1.2, start=0.4, env=(0.3, 0.2, 1.5), highpass=5000, lowpass=10000, volume=0.07)]},
    # ───────── 보물 상자 ─────────
    "chest_drop": {"about": "보물 상자 떨어짐 '쿵-철컥' — 묵직한 나무 상자 + 쇠 장식 '철컥' 두 번 + 살짝 '반짝'", "variants": 3, "spread": 2.0, "peak_db": -9.0, "layers": [
        layer("sine", [150, 55], 0.2, curve=2.0, volume=0.8),
        layer("noise", [3000, 900], 0.12, env=(0.001, 0.005, 2.0), lowpass=1800, volume=0.6),
        layer("square", [300, 130], 0.08, duty=0.375, lowpass=1500, volume=0.35),
        layer("metal", 6000, 0.04, start=0.09, env=(0.001, 0, 2.0), lowpass=6000, volume=0.3),
        layer("metal", 7400, 0.035, start=0.13, env=(0.001, 0, 2.0), lowpass=6000, volume=0.22),
        notes("square", ". . . . . G6 C7:3", 0.035, duty=0.125, env=(0.001, 0.01, 1.5), volume=0.12)]},
    "chest_roll": {"about": "상자 슬롯 '째깍째깍'(1.5초) — 빠르게 돌다 점점 느려지는 딸깍 + 칸마다 바뀌는 높이 + 낮게 도는 '드르르'", "variants": 1, "peak_db": -10.0, "layers": [
        notes("square", CHEST_TICKS, 0.025, duty=0.25, gate=0.45, env=(0.001, 0.005, 2.5), lowpass=6000, volume=0.45),
        notes("noise", CHEST_CLICKS, 0.025, pitch=22050, gate=0.3, env=(0.0005, 0, 2.5), highpass=3000, volume=0.35),
        layer("noise", 6000, 1.5, env=(0.01, 0.4, 1.2), highpass=2000, lowpass=6000, tremolo=(20, 0.7, 2), volume=0.12)]},
    "chest_open_small": {"about": "상자 열림(강화 1~3개) — 뚜껑 '끼익-탁' + 밝은 세 음 '띠링' + 반짝이", "variants": 3, "spread": 2.0, "peak_db": -9.0, "layers": [
        layer("square", [500, 700], 0.12, curve=0.7, duty=0.125, vibrato=(30, 0.5), env=(0.02, 0.05, 1.5), lowpass=3000, volume=0.15),
        layer("noise", 3500, 0.03, start=0.12, env=(0.001, 0, 2.0), lowpass=3000, volume=0.4),
        notes("square", [". . . C6 E6 G6:6", ". . . D6 G6 B6:6", ". . . E6 G6 C7:6"], 0.05, duty=0.25,
              env=(0.001, 0.02, 1.3), vibrato=(6, 0.15, 0.1), volume=0.5),
        notes("triangle", ". . . C5:3 G5:6", 0.05, env=(0.002, 0.05, 1.2), volume=0.4),
        layer("square", 2637, 0.4, start=0.3, duty=0.125, arpeggio=(26, [0, 5, 12]), env=(0.01, 0.1, 1.6), volume=0.1)]},
    "chest_jackpot": {"about": "상자 대박(강화 5개) — '빰빰빰 빠-밤' 팡파르 + 폭죽 '피융-팡' 세 번 + 쏟아지는 반짝이", "variants": 1, "peak_db": -6.0, "layers": [
        notes("square", "C6 C6 C6 E6:3 D6 E6 F6 G6:12", 0.085, **FANFARE_LEAD),
        notes("square", "G5 G5 G5 C6:3 B5 C6 D6 E6:12", 0.085, **BRASS_PAD),
        notes("triangle", "C3:3 C3:3 G2:3 C3:12", 0.085, env=(0.003, 0.1, 1.0), volume=0.7),
        notes("sine", "C2:3 . . . G1:3 C2:12", 0.085, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.8),
        layer("noise", 22050, 1.4, start=0.77, env=(0.001, 0.02, 2.2), highpass=2500, volume=0.3),
        layer("square", 2093, 1.4, start=0.77, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), vibrato=(6, 0.1), env=(0.01, 0.4, 1.5), volume=0.13),
        layer("sine", [700, 2200], 0.3, start=0.75, curve=0.6, env=(0.05, 0.2, 1.0), volume=0.15),
        layer("noise", [9000, 2500], 0.5, start=1.05, env=(0.001, 0.02, 2.0), highpass=1200, tremolo=(29, 0.8, 4), volume=0.4),
        layer("sine", [800, 2500], 0.28, start=1.2, curve=0.6, env=(0.05, 0.18, 1.0), volume=0.13),
        layer("noise", [9000, 2500], 0.5, start=1.48, env=(0.001, 0.02, 2.0), highpass=1200, tremolo=(33, 0.8, 4), volume=0.35),
        layer("sine", [650, 2000], 0.32, start=1.6, curve=0.6, env=(0.05, 0.22, 1.0), volume=0.13),
        layer("noise", [9000, 2500], 0.55, start=1.92, env=(0.001, 0.02, 2.0), highpass=1200, tremolo=(25, 0.8, 4), volume=0.4)]},
    # ───────── 필드 줍기 ─────────
    "magnet_pickup": {"about": "자석 줍기 '위이잉~' — 빨려 드는 듯 올라가는 떨리는 소리 + 빠른 펼침음 + 조각이 끌려오는 '찰찰찰'", "variants": 3, "spread": 2.0, "peak_db": -10.0, "layers": [
        layer("square", [300, 1200], 0.55, curve=0.8, duty=0.25, vibrato=(16, 0.5), env=(0.05, 0.35, 1.2), lowpass=4000, volume=0.4),
        layer("triangle", [600, 2400], 0.55, curve=0.8, arpeggio=(30, [0, 7, 12]), env=(0.1, 0.3, 1.4), volume=0.3),
        notes("square", ". . . . G6 C7 E7 G6 C7 E7 G7:2", 0.05, duty=0.125, env=(0.001, 0.005, 2.0), volume=0.15)]},
    "bomb_blast": {"about": "폭탄 줍기 — 화면 전체 '콰광' 큰 폭음 + 번쩍이는 높은 '삐잉' + 길게 우르릉", "variants": 3, "spread": 2.0, "peak_db": -6.0, "drive": 2.2, "layers": [
        layer("noise", 22050, 0.015, env=(0, 0, 1.0)),
        layer("noise", [10000, 400], 1.4, curve=2.0, env=(0.001, 0.04, 2.0), lowpass=[6500, 350]),
        layer("sine", [120, 28], 0.8, curve=2.0, env=(0.001, 0.03, 1.6)),
        layer("square", [280, 40], 0.3, curve=2.0, duty=0.375, lowpass=1500, volume=0.35),
        layer("sine", 3000, 0.9, start=0.03, env=(0.01, 0.1, 2.0), vibrato=(5, 0.08), volume=0.12),
        layer("noise", 1200, 1.2, start=0.3, env=(0.2, 0.2, 1.6), lowpass=600, tremolo=(9, 0.5, 2), volume=0.35)]},
    "freeze_spray": {"about": "냉각 스프레이 '치이익-쨍' — 차가운 분사 + 얼어붙으며 내려가는 높은 유리 소리 + '쩍' 갈라짐", "variants": 3, "spread": 2.0, "peak_db": -9.0, "layers": [
        layer("noise", 22050, 0.55, env=(0.02, 0.2, 1.5), highpass=3000, lowpass=[11000, 6000], volume=0.3),
        notes("square", [". . . E7 B6 G6 E6 B5:4", ". . . D7 A6 F#6 D6 A5:4", ". . . F7 C7 A6 F6 C6:4"], 0.045, duty=0.125,
              env=(0.001, 0.02, 1.8), lowpass=7000, volume=0.45),
        layer("sine", 3951, 0.5, start=0.14, env=(0.002, 0.05, 2.2), vibrato=(7, 0.06), volume=0.15),
        layer("metal", 9000, 0.05, start=0.42, env=(0.001, 0, 2.2), highpass=2000, volume=0.3)]},
    # ───────── 카드 · 메뉴 ─────────
    "banish": {"about": "카드 빼기 '휙-퍽' — 아래로 떨어지는 사각파 + 종이 찢는 '찌익' + 끝에 둔한 '퍽'", "variants": 3, "spread": 2.0, "peak_db": -12.0, "layers": [
        layer("square", [1400, 220], 0.22, curve=1.4, duty=0.25, env=(0.002, 0.05, 1.4), lowpass=5000, volume=0.45),
        layer("noise", [6000, 10000], 0.12, start=0.03, env=(0.005, 0.04, 1.4), highpass=2000, tremolo=(90, 0.6, 2), volume=0.4),
        layer("sine", [180, 80], 0.08, start=0.18, volume=0.5)]},
    "ui_unlock": {"about": "새 해금 — 자물쇠 '철컥' + 밝게 올라가는 네 음(끝은 높은 도) + 반짝이", "variants": 1, "peak_db": -9.0, "layers": [
        layer("metal", 6800, 0.03, env=(0.001, 0, 2.0), lowpass=6000, volume=0.4),
        layer("metal", 5200, 0.04, start=0.06, env=(0.001, 0, 2.0), lowpass=6000, volume=0.35),
        layer("square", [800, 500], 0.04, start=0.06, duty=0.25, lowpass=3000, volume=0.2),
        notes("square", ". . . G5 C6 E6 G6:2 C7:6", 0.06, duty=0.25, env=(0.002, 0.02, 1.3), vibrato=(6, 0.15, 0.1), volume=0.5),
        notes("triangle", ". . . . . . C5:2 G5:6", 0.06, env=(0.002, 0.05, 1.2), volume=0.4),
        layer("square", 2093, 0.5, start=0.5, duty=0.125, arpeggio=(26, [0, 7, 12, 19]), env=(0.01, 0.1, 1.6), volume=0.1)]},
    "achievement": {"about": "업적 달성 '빠밤-빠바바밤!' — 바장조 트로피 팡파르(두 번 끊고 크게) + 낮은 받침 + 종소리 + 반짝이", "variants": 1, "peak_db": -8.0, "layers": [
        notes("square", "A5 C6:2 F6:2 . E6 F6 A6 C7:9", 0.065, duty=0.25, gate=0.9, env=(0.002, 0.03, 1.0), vibrato=(6, 0.15, 0.12), volume=0.45),
        notes("square", "F5 A5:2 C6:2 . C6 C6 F6 A6:9", 0.065, **BRASS_PAD),
        notes("triangle", "F3:5 . C3:3 F3:9", 0.065, env=(0.003, 0.08, 1.0), volume=0.6),
        layer("sine", 2093, 0.9, start=0.45, env=(0.002, 0.05, 2.2), volume=0.15),
        layer("square", 2794, 0.7, start=0.5, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), env=(0.01, 0.15, 1.6), volume=0.1)]},
}
