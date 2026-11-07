"""
[파일] tools/sound_table_weapons.py
[하는 일] 효과음 정의 표 ③ 새 무기 13종: 경찰(테이저건·최루탄·확성기), 소방관(소방 호스·구조용 절단기·조명탄), 택배기사(상자·테이프 건·소포 폭탄), 직장인(스테이플러·서류 폭풍·결재 도장·노트북·카페인 충전·칼퇴근 종소리), 메스 소리는 던지는 칼이 씀, 공용 화염병.
[쓰는 곳] tools/build_sounds.py 가 sound_table_core 의 layer·notes 로 적은 이 표를 audio/<이름>_<번호>.wav 로 만든다. data/weapons.json 의 "sound" 가 이 이름을 부른다.
[근거 문서] 14 §2-2 생존자 전용 무기·§2-7 눈에 띄는 연출, 06 사운드·"AI 티 안 나게"
"""
from __future__ import annotations

from sound_table_core import layer, notes

# 무기 소리는 계속 나서 작게: 기존 무기(권총 −8 · 네일건 −11 · 톱날 −12)와 같은 줄. 쉬지 않고 나는 것(소독약·메스·절단기)은 더 작게.
WEAPON_EFFECTS: dict[str, dict] = {
    # ───────── 경찰 ─────────
    "taser_zap": {"about": "테이저건 '빠직-지지직' — 첫 '빠직' + 빠르게 끊기는 전기 톱니파 + 탁탁 튀는 불꽃 (비트를 줄여 까끌하게)", "variants": 3, "spread": 3.0, "peak_db": -11.0, "crush": 16, "layers": [
        layer("noise", 22050, 0.012, env=(0, 0, 1.0), volume=0.8),
        layer("saw", [180, 140], 0.28, tremolo=(47, 0.9, 4), vibrato=(61, 2.0), env=(0.002, 0.08, 1.4), lowpass=6000, volume=0.6),
        layer("square", [1900, 1200], 0.22, duty=0.125, arpeggio=(90, [0, 7, -5, 12, 3]), env=(0.002, 0.05, 1.6), lowpass=7000, volume=0.25),
        layer("metal", 16000, 0.25, tremolo=(33, 0.95, 6), env=(0.001, 0.06, 1.5), volume=0.4)]},
    "tear_gas_pop": {"about": "최루탄 '퐁-쉬이이' — 발사 '퐁' + 통이 떨어져 '탕' + 길게 새는 가스", "variants": 3, "spread": 2.5, "peak_db": -11.0, "layers": [
        layer("sine", [520, 180], 0.08, curve=2.0, env=(0.001, 0.005, 1.6), volume=0.8),
        layer("noise", 22050, 0.02, env=(0, 0, 1.5), lowpass=6000, volume=0.4),
        layer("metal", 5200, 0.04, start=0.12, env=(0.001, 0, 2.0), lowpass=5000, volume=0.2),
        layer("noise", 22050, 0.75, start=0.14, env=(0.06, 0.25, 1.5), highpass=2200, lowpass=[8000, 4500], tremolo=(17, 0.2, 1), volume=0.5)]},
    "megaphone_blast": {"about": "확성기 충격파 — 하울링 '삐이' + 전화기처럼 좁고 찌그러진 '웅' + 퍼져 나가는 바람", "variants": 3, "spread": 2.0, "peak_db": -10.0, "drive": 1.8, "layers": [
        layer("square", [2200, 2600], 0.12, curve=0.6, vibrato=(25, 0.3), env=(0.03, 0.05, 1.2), lowpass=5000, volume=0.25),
        layer("square", [300, 220], 0.32, start=0.08, vibrato=(70, 1.2), env=(0.003, 0.12, 1.5), lowpass=1800, highpass=250, volume=0.7),
        layer("saw", [450, 330], 0.3, start=0.08, vibrato=(70, 1.2), env=(0.003, 0.1, 1.6), lowpass=2500, highpass=300, volume=0.4),
        layer("noise", 22050, 0.4, start=0.08, env=(0.002, 0.03, 2.0), lowpass=[6000, 800], volume=0.22)]},
    # ───────── 소방관 ─────────
    "fire_hose_spray": {"about": "소방 호스 '쏴아' — 밸브 '퍽' + 굵은 물줄기 노이즈 + 물 튀는 '촤르르'", "variants": 3, "spread": 2.0, "peak_db": -12.0, "layers": [
        layer("sine", [260, 110], 0.06, volume=0.6),
        layer("noise", 22050, 0.55, env=(0.03, 0.25, 1.4), highpass=700, lowpass=5500, tremolo=(29, 0.25, 1), volume=0.8),
        layer("noise", 3000, 0.5, start=0.02, env=(0.04, 0.2, 1.5), lowpass=1200, volume=0.4),
        layer("noise", 22050, 0.3, start=0.25, env=(0.01, 0.05, 1.8), highpass=4000, tremolo=(41, 0.7, 3), volume=0.25)]},
    "rescue_saw_grind": {"about": "구조용 절단기 '위이잉 지직' — 떨리는 모터 톱니파 + 쇠 갈리는 불꽃 노이즈 (빨리 연타해서 짧고 작게)", "variants": 3, "spread": 2.5, "peak_db": -13.0, "crush": 22, "layers": [
        layer("saw", [620, 560], 0.26, tremolo=(38, 0.5, 2), vibrato=(9, 0.3), env=(0.01, 0.12, 1.3), lowpass=4500, volume=0.55),
        layer("square", [1240, 1120], 0.26, duty=0.125, env=(0.01, 0.1, 1.5), lowpass=6000, volume=0.15),
        layer("metal", 13000, 0.24, tremolo=(53, 0.85, 4), env=(0.005, 0.08, 1.4), highpass=2000, volume=0.45)]},
    "flare_burst": {"about": "조명탄 '칙-화악' — 성냥 긋듯 '칙' + 불붙으며 밝아지는 '화악' + 타닥타닥 타는 소리", "variants": 3, "spread": 2.0, "peak_db": -11.0, "layers": [
        layer("noise", 22050, 0.05, env=(0.004, 0, 2.0), highpass=3000, volume=0.6),
        layer("noise", 22050, 0.6, start=0.04, env=(0.08, 0.1, 1.6), lowpass=[700, 6000], highpass=200, volume=0.8),
        layer("sine", [90, 200], 0.3, start=0.04, curve=0.7, env=(0.05, 0.05, 1.5), volume=0.4),
        layer("noise", 3000, 0.6, start=0.2, env=(0.01, 0.2, 1.6), lowpass=2500, tremolo=(17, 0.85, 5), volume=0.35)]},
    # ───────── 택배기사 ─────────
    "box_toss_thud": {"about": "상자 맞음 '퍽' — 골판지 둔한 소리 + 낮은 쿵 + 종이 '바스락'", "variants": 3, "spread": 3.0, "peak_db": -11.0, "layers": [
        layer("noise", [2600, 800], 0.08, env=(0.001, 0.005, 2.0), lowpass=1800, volume=0.8),
        layer("square", [260, 120], 0.07, curve=1.8, duty=0.375, lowpass=1200, volume=0.45),
        layer("sine", [170, 70], 0.09, curve=2.0, volume=0.6),
        layer("noise", 22050, 0.06, start=0.03, env=(0.002, 0, 2.0), highpass=3500, tremolo=(70, 0.8, 3), volume=0.18)]},
    "tape_gun_rip": {"about": "테이프 건 '찌이익-틱' — 뜯기며 점점 높아지는 거친 노이즈(빠르게 떨림) + 끝에 끊는 '틱'", "variants": 3, "spread": 2.5, "peak_db": -12.0, "layers": [
        layer("noise", [4000, 12000], 0.24, curve=0.8, env=(0.01, 0.15, 1.2), highpass=1500, lowpass=9000, tremolo=(85, 0.75, 2), volume=0.75),
        layer("saw", [320, 520], 0.22, curve=0.8, tremolo=(85, 0.6, 2), env=(0.01, 0.13, 1.4), lowpass=3000, volume=0.25),
        layer("square", 3100, 0.015, start=0.23, duty=0.25, env=(0.001, 0, 2.0), volume=0.25)]},
    "parcel_drop_boom": {"about": "소포 폭탄 '휘-쾅' — 짧게 떨어지는 휘파람 + 터지는 폭음 + 종이 조각 흩날림", "variants": 3, "spread": 2.5, "peak_db": -9.0, "drive": 1.7, "layers": [
        layer("square", [1700, 900], 0.22, curve=0.8, duty=0.125, env=(0.03, 0.15, 1.0), lowpass=4000, volume=0.15),
        layer("noise", [8000, 600], 0.6, start=0.2, curve=2.0, env=(0.001, 0.02, 2.2), lowpass=[5000, 500]),
        layer("sine", [120, 38], 0.4, start=0.2, curve=2.0, volume=0.85),
        layer("square", [300, 60], 0.15, start=0.2, curve=2.0, duty=0.375, lowpass=1500, volume=0.35),
        layer("noise", 22050, 0.25, start=0.32, env=(0.01, 0.02, 2.0), highpass=4000, tremolo=(37, 0.7, 3), volume=0.15)]},
    # ───────── 직장인 (15 부록 B) ─────────
    "stapler_click": {"about": "스테이플러 '딸깍' — 짧은 쇠 '찰칵' + 눌리는 플라스틱 '딱' (빨리 연사해서 아주 작게)", "variants": 4, "spread": 3.0, "peak_db": -13.0, "layers": [
        layer("metal", 12000, 0.02, env=(0, 0.002, 2.5), highpass=2500, volume=0.7),
        layer("square", [1500, 900], 0.025, duty=0.25, env=(0.001, 0, 2.0), lowpass=5000, volume=0.35),
        layer("noise", 22050, 0.015, start=0.03, env=(0, 0, 2.0), highpass=4000, volume=0.3)]},
    "paper_swish": {"about": "서류 폭풍 '휙-팔랑' — 종이가 스치는 바람 + 바스락 (자주 나서 아주 작게)", "variants": 3, "spread": 3.0, "peak_db": -15.0, "layers": [
        layer("noise", 22050, 0.09, env=(0.02, 0.01, 1.8), highpass=2500, lowpass=[3000, 9000], volume=0.8),
        layer("noise", 22050, 0.06, start=0.05, env=(0.002, 0, 2.0), highpass=5000, tremolo=(60, 0.8, 3), volume=0.3)]},
    "stamp_slam": {"about": "결재 도장 '쾅' — 묵직한 나무 '쿵' + 책상 울림 + 종이 '탁'", "variants": 3, "spread": 2.0, "peak_db": -9.0, "drive": 1.4, "layers": [
        layer("sine", [150, 45], 0.22, curve=2.0, volume=0.9),
        layer("noise", [3000, 500], 0.12, curve=2.0, env=(0.001, 0.005, 2.0), lowpass=1600, volume=0.6),
        layer("square", [240, 90], 0.08, curve=2.0, duty=0.375, lowpass=1200, volume=0.3),
        layer("noise", 22050, 0.03, start=0.01, env=(0, 0, 2.0), highpass=3500, volume=0.25)]},
    "laptop_crash": {"about": "노트북 '퍽-지직' — 플라스틱 깨짐 + 낮은 폭발 + 전기 지직", "variants": 3, "spread": 2.5, "peak_db": -9.0, "drive": 1.5, "layers": [
        layer("noise", [9000, 1500], 0.12, curve=1.5, env=(0.001, 0.005, 2.0), lowpass=6000, volume=0.6),
        layer("sine", [130, 40], 0.3, curve=2.0, volume=0.8),
        layer("saw", [160, 120], 0.18, start=0.05, tremolo=(57, 0.9, 4), env=(0.001, 0.04, 1.6), lowpass=4000, volume=0.3),
        layer("metal", 9000, 0.06, start=0.02, env=(0.001, 0, 2.0), volume=0.25)]},
    "skill_caffeine": {"about": "카페인 충전 — 컵 뚜껑 '톡' + 후루룩 + 올라가는 '삐융'", "variants": 2, "spread": 1.5, "peak_db": -9.0, "layers": [
        layer("square", 2200, 0.02, duty=0.25, env=(0.001, 0, 2.0), volume=0.3),
        layer("noise", 22050, 0.3, start=0.04, env=(0.05, 0.1, 1.5), lowpass=[900, 2600], highpass=300, tremolo=(23, 0.7, 2), volume=0.6),
        layer("square", [300, 1400], 0.25, start=0.32, curve=0.7, duty=0.125, env=(0.004, 0.08, 1.4), lowpass=5000, volume=0.3)]},
    "clock_out_bell": {"about": "칼퇴근 퇴근 종소리 '딩동댕동' — 학교 종처럼 맑은 네 음 + 길게 울리는 꼬리", "variants": 1, "peak_db": -7.0, "layers": [
        notes("triangle", "E5:3 C5:3 D5:3 G4:6", 0.09, env=(0.002, 0.05, 1.2), volume=0.55),
        notes("sine", "E6:3 C6:3 D6:3 G5:6", 0.09, env=(0.002, 0.03, 1.6), volume=0.18),
        layer("sine", 392, 1.2, start=0.9, env=(0.002, 0.05, 2.0), volume=0.3)]},
    "scalpel_slice": {"about": "메스 '슥-칭' — 아주 짧게 베는 바람 + 가는 쇠 울림 (자주 나서 아주 작게)", "variants": 3, "spread": 3.0, "peak_db": -14.0, "layers": [
        layer("noise", 22050, 0.07, env=(0.025, 0, 1.8), highpass=3000, lowpass=[4000, 10000], volume=0.8),
        layer("sine", 4200, 0.1, start=0.03, env=(0.001, 0, 2.2), volume=0.3),
        layer("sine", 6100, 0.07, start=0.03, env=(0.001, 0, 2.5), volume=0.15)]},
    # ───────── 공용 ─────────
    "molotov_shatter": {"about": "화염병 '쨍그랑-화르륵' — 유리 깨짐(높은 쇠 노이즈 + 조각 '팅' 네 번) + 불붙는 '화륵' + 타닥", "variants": 3, "spread": 2.5, "peak_db": -9.0, "layers": [
        layer("metal", 18000, 0.12, env=(0, 0.005, 2.2), highpass=3000, volume=0.6),
        layer("noise", 22050, 0.2, env=(0.001, 0.01, 2.4), highpass=4000, volume=0.4),
        layer("sine", 3520, 0.09, start=0.02, env=(0.001, 0.005, 1.6), volume=0.5),
        layer("sine", 4980, 0.08, start=0.06, env=(0.001, 0.005, 1.6), volume=0.4),
        layer("sine", 2960, 0.1, start=0.1, env=(0.001, 0.005, 1.6), volume=0.4),
        layer("sine", 4440, 0.07, start=0.15, env=(0.001, 0.005, 1.6), volume=0.3),
        layer("noise", 22050, 0.65, start=0.12, env=(0.15, 0.1, 1.6), lowpass=[600, 4500], highpass=150, volume=0.45),
        layer("noise", 2600, 0.5, start=0.25, env=(0.02, 0.15, 1.6), lowpass=2200, tremolo=(15, 0.85, 5), volume=0.22)]},
}
