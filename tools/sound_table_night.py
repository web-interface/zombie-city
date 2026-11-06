"""
[파일] tools/sound_table_night.py
[하는 일] 효과음 정의 표 ② 끝없는 밤: 새 좀비 6종·정예·새 보스 2종(철거반장·거대 감염체)의 소리, 이벤트(포위 경보·떼 돌진), 밤 생존·다음 밤 시작, 연속 처치 50·100·200 차임.
[쓰는 곳] tools/build_sounds.py 가 sound_table_core 의 layer·notes 로 적은 이 표를 audio/<이름>_<번호>.wav 로 만든다.
[근거 문서] 14 §1 끝없는 밤(1-2 좀비·1-3 보스·1-4 이벤트)·§4 연속 처치, 06 사운드·"AI 티 안 나게"
"""
from __future__ import annotations

from sound_table_core import layer, notes

# peak_db 는 모두 −6 이하 (audio/README.md 크기 기준). 하나뿐인 소리(variants 1)는 경보·축하처럼 한 판에 몇 번 안 나는 것만.
NIGHT_EFFECTS: dict[str, dict] = {
    # ───────── 새 좀비 ─────────
    "spitter_spit": {"about": "침 뱉는 좀비 '크르-퉤' — 목을 긁는 그르륵 + 축축한 '퉤' + 침이 날아가는 짧은 바람", "variants": 3, "spread": 3.0, "peak_db": -12.0, "layers": [
        layer("saw", [150, 230], 0.12, curve=0.7, vibrato=(22, 1.5), env=(0.01, 0.03, 1.2), lowpass=1500, volume=0.45),
        layer("noise", [5000, 2200], 0.07, start=0.11, env=(0.001, 0.01, 2.0), lowpass=3800, highpass=500, volume=0.9),
        layer("square", [700, 1300], 0.05, start=0.11, curve=0.6, duty=0.25, env=(0.001, 0, 1.8), lowpass=3000, volume=0.35),
        layer("noise", 22050, 0.16, start=0.15, env=(0.02, 0, 2.0), highpass=2500, lowpass=7000, volume=0.25)]},
    "acid_sizzle": {"about": "산성 웅덩이 '치이익' — 끓는 노이즈(타닥 끊김) + '보글' 올라오는 거품", "variants": 3, "spread": 2.0, "peak_db": -13.0, "layers": [
        layer("noise", 22050, 0.7, env=(0.01, 0.15, 1.6), highpass=2200, lowpass=8000, tremolo=(27, 0.55, 3), volume=0.7),
        layer("noise", 7000, 0.6, start=0.02, env=(0.03, 0.1, 1.8), highpass=900, lowpass=3000, tremolo=(11, 0.6, 2), volume=0.35),
        notes("triangle", ["G4 . . C5 . . . E4", "A4 . . . D5 . F4", ". F4 . . . B4 . . G4"], 0.07, gate=0.5, glide_to=1.7,
              env=(0.002, 0, 1.8), volume=0.3)]},
    "bloater_swell": {"about": "부푼 좀비 터지기 직전(빨간 고리 0.6초) — 점점 커지며 높아지는 '우우웅' + 꾸르륵 + 끝에 팽팽한 '삐'", "variants": 1, "peak_db": -10.0, "layers": [
        layer("saw", [90, 260], 0.6, curve=0.6, vibrato=(9, 0.8), env=(0.45, 0.1, 1.0), lowpass=[500, 2200], volume=0.7),
        layer("square", [180, 520], 0.6, curve=0.6, duty=0.25, env=(0.45, 0.1, 1.0), lowpass=[600, 2500], tremolo=(14, 0.7, 2), volume=0.35),
        layer("noise", 3000, 0.55, env=(0.3, 0.2, 1.0), lowpass=1200, tremolo=(17, 0.8, 3), volume=0.35),
        layer("sine", [1200, 1700], 0.18, start=0.42, env=(0.1, 0.06, 0.8), volume=0.2)]},
    "bloater_pop": {"about": "부푼 좀비 '펑' — 축축하게 터지는 폭음 + 둔한 쿵 + 사방에 튀는 '철퍽' 세 번", "variants": 3, "spread": 2.5, "peak_db": -8.0, "drive": 1.6, "layers": [
        layer("noise", [7000, 600], 0.55, curve=2.0, env=(0.001, 0.02, 2.2), lowpass=[4500, 500]),
        layer("sine", [140, 40], 0.35, curve=2.0, env=(0.001, 0.01, 1.6), volume=0.9),
        layer("square", [600, 90], 0.12, curve=2.5, duty=0.25, lowpass=2500, volume=0.35),
        layer("noise", 2400, 0.09, start=0.12, env=(0.002, 0, 2.0), lowpass=2200, volume=0.35),
        layer("noise", 1800, 0.08, start=0.2, env=(0.002, 0, 2.0), lowpass=1800, volume=0.25),
        layer("noise", 2800, 0.07, start=0.27, env=(0.002, 0, 2.0), lowpass=2000, volume=0.18)]},
    "shield_block": {"about": "진압복 방패에 막힘 '깡' — 쇠 부딪힘 + 어긋난 두 음 '팅' 울림 (자주 나서 작게)", "variants": 3, "spread": 3.0, "peak_db": -12.0, "layers": [
        layer("metal", 12000, 0.03, env=(0, 0.002, 2.0), volume=0.7),
        layer("square", 1760, 0.18, duty=0.25, env=(0.001, 0.005, 2.2), lowpass=6000, volume=0.35),
        layer("triangle", 2490, 0.22, env=(0.001, 0.01, 2.0), vibrato=(30, 0.1), volume=0.45),
        layer("sine", [400, 250], 0.05, volume=0.3)]},
    "screamer_scream": {"about": "비명 좀비 '꺄아악' — 확 올라갔다 떨며 꺾이는 높은 비명 + 겹친 쉰 목소리 + 숨소리 (찌그러뜨림)", "variants": 3, "spread": 2.0, "peak_db": -8.0, "drive": 1.4, "crush": 24, "layers": [
        layer("square", [650, 1300], 0.14, curve=1.6, duty=0.25, vibrato=(9, 0.6), env=(0.03, 0.11, 0.3), lowpass=5000, volume=0.5),
        layer("square", [1300, 760], 0.85, start=0.12, curve=0.6, duty=0.25, vibrato=(8, 0.9), env=(0.005, 0.35, 1.3), lowpass=5000, volume=0.5),
        layer("saw", [1380, 800], 0.85, start=0.12, curve=0.6, vibrato=(11, 1.2), env=(0.005, 0.3, 1.5), lowpass=3500, volume=0.25),
        layer("noise", 22050, 0.95, env=(0.05, 0.35, 1.5), highpass=2000, lowpass=6500, volume=0.3)]},
    "hound_bark": {"about": "들개 좀비 '컹컹' — 목이 쉰 두 번 짖기(둘째가 조금 낮음) + 거친 숨", "variants": 3, "spread": 3.5, "peak_db": -11.0, "crush": 18, "layers": [
        layer("square", [620, 300], 0.09, curve=1.8, duty=0.25, vibrato=(40, 0.8), env=(0.004, 0.02, 1.5), lowpass=2800, volume=0.6),
        layer("noise", [3500, 1200], 0.08, env=(0.003, 0.01, 1.8), lowpass=2500, highpass=300, volume=0.5),
        layer("square", [560, 260], 0.11, start=0.17, curve=1.8, duty=0.25, vibrato=(40, 0.8), env=(0.004, 0.02, 1.5), lowpass=2600, volume=0.5),
        layer("noise", [3200, 1000], 0.1, start=0.17, env=(0.003, 0.01, 1.8), lowpass=2300, highpass=300, volume=0.45)]},
    "brute_stomp": {"about": "덩치 좀비 '쿵' — 깊게 꺼지는 저음 + 바닥 울림 + 아스팔트 부스러기", "variants": 3, "spread": 2.0, "peak_db": -10.0, "drive": 1.3, "layers": [
        layer("sine", [110, 34], 0.32, curve=2.2, env=(0.001, 0.02, 1.5)),
        layer("square", [200, 70], 0.15, curve=2.0, duty=0.375, lowpass=1000, volume=0.35),
        layer("noise", 1600, 0.25, env=(0.002, 0.02, 2.0), lowpass=900, volume=0.5),
        layer("noise", 9000, 0.06, start=0.03, env=(0.001, 0, 2.0), highpass=2500, lowpass=7000, volume=0.15)]},
    "elite_appear": {"about": "빛나는 정예 등장 — 불길한 감7 펼침음 + 금빛 '샤라랑' 반짝임 + 낮은 쿵", "variants": 3, "spread": 1.5, "peak_db": -8.0, "layers": [
        layer("sine", [120, 45], 0.35, curve=2.0, volume=0.6),
        notes("square", ["E5 G5 Bb5 E6:6", "D5 F5 Ab5 D6:6", "E5 Bb5 G5 E6:6"], 0.07, duty=0.25,
              env=(0.002, 0.03, 1.2), vibrato=(6, 0.2, 0.1), lowpass=5000, volume=0.45),
        layer("square", 2637, 0.6, start=0.25, duty=0.125, arpeggio=(28, [0, 6, 12, 18]), env=(0.01, 0.1, 1.6), volume=0.14),
        layer("noise", 22050, 0.7, start=0.2, env=(0.05, 0.1, 1.8), highpass=5000, lowpass=11000, volume=0.12)]},
    # ───────── 새 보스 ─────────
    "demolisher_warning": {"about": "철거반장 해머 들기(빨간 원 1.2초) — 쇠사슬 '찰그랑' + 힘주는 낮은 '끄으응' + 점점 빨라지는 경고 '삐'", "variants": 3, "spread": 1.5, "peak_db": -8.0, "layers": [
        layer("metal", 7000, 0.05, env=(0, 0, 2.0), lowpass=6000, volume=0.3),
        layer("metal", 5600, 0.05, start=0.07, env=(0, 0, 2.0), lowpass=6000, volume=0.25),
        layer("saw", [70, 95], 1.15, curve=0.8, vibrato=(13, 0.7), env=(0.15, 0.85, 1.0), lowpass=[400, 1200], volume=0.7),
        layer("square", [330, 990], 1.15, curve=0.7, duty=0.25, env=(0.7, 0.4, 0.5), lowpass=[1500, 4500], tremolo=(9, 0.6, 2), volume=0.3),
        notes("square", ["A5 .:5 A5 .:4 A5 .:3 A5 .:2 A5 . A5 . A5 A5", "A5 .:4 A5 .:4 A5 .:3 A5 .:2 A5 .:2 A5 . A5 A5 A5",
                         "A5 .:5 A5 .:3 A5 .:3 A5 .:2 A5 . A5 . A5 A5 A5"], 0.045, gate=0.6, duty=0.25,
              env=(0.001, 0.01, 1.5), volume=0.3)]},
    "demolisher_slam": {"about": "철거반장 해머 내려찍기 '콰앙' — 아주 무거운 폭음 + 땅 꺼지는 저음 + 쇠 울림 + 튀는 콘크리트", "variants": 3, "spread": 2.0, "peak_db": -6.0, "drive": 2.0, "layers": [
        layer("noise", 22050, 0.015, env=(0, 0, 1.0)),
        layer("noise", [8000, 500], 0.9, curve=2.0, env=(0.001, 0.03, 2.3), lowpass=[5000, 400]),
        layer("sine", [95, 28], 0.7, curve=2.0, env=(0.001, 0.03, 1.6)),
        layer("square", [260, 45], 0.3, curve=2.2, duty=0.375, lowpass=1400, volume=0.45),
        layer("metal", 3200, 0.5, start=0.01, env=(0.001, 0.02, 2.2), lowpass=4500, volume=0.25),
        layer("noise", 3500, 0.06, start=0.25, env=(0.002, 0, 2.0), lowpass=3000, volume=0.2),
        layer("noise", 4200, 0.05, start=0.36, env=(0.002, 0, 2.0), lowpass=3500, volume=0.15)]},
    "mother_screech": {"about": "거대 감염체 울음 — 어긋나 맥놀이 치는 낮은 울부짖음 두 겹 + 높은 비명 + 끈적한 그르렁 (찌그러뜨리고 비트를 줄임)", "variants": 3, "spread": 2.0, "peak_db": -6.5, "drive": 1.7, "crush": 26, "layers": [
        layer("saw", [140, 80], 1.4, curve=0.8, vibrato=(6, 1.0), env=(0.12, 0.5, 1.3), lowpass=1600, volume=0.6),
        layer("saw", [151, 84], 1.4, curve=0.8, vibrato=(7, 1.0), env=(0.12, 0.5, 1.3), lowpass=1600, volume=0.5),
        layer("square", [990, 620], 1.2, start=0.08, curve=0.7, duty=0.125, vibrato=(13, 1.6), env=(0.08, 0.4, 1.4), lowpass=4200, volume=0.3),
        layer("noise", 1200, 1.4, env=(0.1, 0.5, 1.4), lowpass=900, tremolo=(23, 0.7, 2), volume=0.55)]},
    "mother_birth": {"about": "거대 감염체가 새끼 낳기 — 꿀렁이는 저음 + 축축하게 '뿌직' 세 번 + 작은 '끼익'", "variants": 3, "spread": 2.5, "peak_db": -9.0, "layers": [
        layer("sine", [70, 120], 0.5, curve=0.7, tremolo=(9, 0.8, 2), env=(0.1, 0.25, 1.2), volume=0.6),
        layer("square", [140, 240], 0.5, curve=0.7, duty=0.25, tremolo=(9, 0.8, 2), env=(0.1, 0.25, 1.2), lowpass=900, volume=0.35),
        layer("noise", [4000, 1500], 0.12, start=0.35, env=(0.001, 0.01, 2.0), lowpass=2800, volume=0.7),
        layer("noise", [3500, 1300], 0.1, start=0.47, env=(0.001, 0.01, 2.0), lowpass=2500, volume=0.5),
        layer("noise", [3800, 1400], 0.1, start=0.58, env=(0.001, 0.01, 2.0), lowpass=2600, volume=0.4),
        layer("square", [1500, 2300], 0.08, start=0.5, duty=0.125, vibrato=(35, 1.0), env=(0.003, 0.01, 1.5), volume=0.15)]},
    # ───────── 이벤트 · 밤 흐름 ─────────
    "encircle_alarm": {"about": "포위 재난 경보 — 재난문자 '삐빅 삐빅' + 길게 올라갔다 내려가는 사이렌 두 겹(단3도로 어긋나 귀에 거슬림)", "variants": 1, "peak_db": -6.5, "layers": [
        notes("square", "B5+F6 B5+F6 . . B5+F6 B5+F6 . .", 0.07, gate=0.75, env=(0.002, 0.04, 1.0), lowpass=6000, volume=0.3),
        layer("square", [260, 780], 1.3, start=0.5, curve=2.2, vibrato=(5, 0.15), env=(0.12, 1.0, 1.0), lowpass=2400, volume=0.4),
        layer("triangle", [310, 928], 1.3, start=0.5, curve=2.2, vibrato=(5, 0.15), env=(0.12, 1.0, 1.0), volume=0.5),
        layer("square", [780, 260], 1.3, start=1.62, curve=0.45, vibrato=(5, 0.15), env=(0.18, 0.4, 1.2), lowpass=2400, volume=0.4),
        layer("triangle", [928, 310], 1.3, start=1.62, curve=0.45, vibrato=(5, 0.15), env=(0.18, 0.4, 1.2), volume=0.5)]},
    "stampede_rumble": {"about": "떼 돌진 예고 — 멀리서 다가오는 우르르 발소리(점점 커지고 밝아짐) + 땅 울림 + 쿵쿵 빨라지는 발 + 끝에 몰려오는 아우성", "variants": 1, "peak_db": -7.0, "drive": 1.3, "layers": [
        layer("noise", 900, 2.2, env=(1.5, 0.3, 1.2), lowpass=[250, 1500], tremolo=(13, 0.55, 2), volume=0.9),
        layer("noise", 2400, 2.2, env=(1.6, 0.2, 1.5), lowpass=[400, 3000], tremolo=(7.3, 0.6, 3), volume=0.5),
        layer("sine", [45, 60], 2.2, env=(1.4, 0.4, 1.2), tremolo=(6.5, 0.8, 4), volume=0.7),
        notes("square", ". . . . A2 . . . A2 . . A2", 0.08, duty=0.375, glide_to=0.5, env=(0.001, 0.01, 2.0), lowpass=700, volume=0.3),
        notes("square", ". A2 . A2 A2 . A2 A2 A2 A2 A2 A2:2", 0.08, start=0.96, duty=0.375, glide_to=0.5, env=(0.001, 0.01, 2.0), lowpass=700, volume=0.75),
        layer("saw", [180, 240], 0.8, start=1.35, vibrato=(9, 1.5), env=(0.2, 0.3, 1.4), lowpass=1500, volume=0.3),
        layer("saw", [205, 270], 0.8, start=1.4, vibrato=(11, 1.5), env=(0.2, 0.3, 1.4), lowpass=1500, volume=0.25)]},
    "night_clear": {"about": "밤 생존 — 동트는 듯 밝게 올라가는 라장조 짧은 곡(약 2.5초) + 북 + 심벌 + 반짝이", "variants": 1, "peak_db": -6.0, "layers": [
        notes("square", "D5 . A4 D5 F#5:2 E5 F#5 A5:3 B5 A5:2 F#5 D6:8", 0.1, duty=0.5, gate=0.92, vibrato=(5.5, 0.2, 0.15),
              env=(0.004, 0.05, 0.9), lowpass=4500, volume=0.45),
        notes("square", "F#4 . F#4 A4 D5:2 C#5 D5 E5:3 G5 F#5:2 D5 A5:8", 0.1, duty=0.25, gate=0.92, env=(0.004, 0.05, 0.9),
              lowpass=3500, volume=0.28),
        notes("triangle", "D3:4 B2:4 G2:4 A2:3 D3:8", 0.1, env=(0.003, 0.1, 1.0), volume=0.7),
        notes("sine", "D2:4 G1:4 A1:7 D2:8", 0.1, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.8),
        layer("triangle", [300, 1200], 0.3, curve=0.7, env=(0.25, 0.02, 1.0), volume=0.15),
        layer("noise", 22050, 1.2, start=1.5, env=(0.001, 0.02, 2.2), highpass=2500, volume=0.28),
        layer("square", 2349, 1.0, start=1.5, duty=0.125, arpeggio=(26, [0, 4, 7, 12]), env=(0.01, 0.3, 1.5), volume=0.12)]},
    "night_start": {"about": "다음 밤 시작 — 멀리 울리는 종 '댕-' + 차오르는 낮은 웅웅 + 반음 부딪히는 높은 떨림 + 심장 '쿵-쿵'", "variants": 1, "peak_db": -7.0, "layers": [
        layer("triangle", 392, 1.8, env=(0.002, 0.05, 2.2), vibrato=(4, 0.05), volume=0.5),
        layer("sine", 1082, 1.2, env=(0.002, 0.02, 2.5), volume=0.25),
        layer("metal", 4000, 0.4, env=(0.001, 0.01, 2.5), lowpass=5000, volume=0.15),
        layer("saw", [49, 58], 2.4, curve=0.8, env=(1.0, 1.0, 1.4), lowpass=[300, 900], volume=0.8),
        layer("square", 1318.5, 1.6, start=0.6, duty=0.25, env=(0.8, 0.5, 1.5), tremolo=(7, 0.5, 1), lowpass=4000, volume=0.12),
        layer("square", 1396.9, 1.6, start=0.6, duty=0.25, env=(0.8, 0.5, 1.5), tremolo=(7, 0.5, 1), lowpass=4000, volume=0.12),
        notes("sine", ". . . . . . . A2:2 A2:6 A2:2 A2:6", 0.1, glide_to=0.55, env=(0.001, 0.02, 2.0), volume=0.8)]},
    # 변형 번호 = 순서: _1 = 연속 50, _2 = 100, _3 = 200. 점점 높고(steps) 길고, 2번부터 반짝이·3번은 심벌과 북까지 (in_variants).
    "combo_milestone": {"about": "연속 처치 50·100·200 차임 — _1→_3 으로 점점 높고 화려해짐(3번은 반짝이·심벌·북까지)", "steps": [0, 3, 7], "peak_db": -8.0, "layers": [
        notes("square", ["C6 E6 G6:6", "G5 C6 E6 G6 C7:6", "C6 E6 G6 C7 G6 C7 E7:7"], 0.045, duty=0.25,
              env=(0.001, 0.02, 1.3), vibrato=(6, 0.15, 0.08), volume=0.5),
        notes("triangle", ["C5:8", "C5:2 G5:8", "C5:2 G5:2 C6:9"], 0.045, env=(0.002, 0.04, 1.2), volume=0.4),
        layer("square", 1568, 0.4, start=0.2, duty=0.125, arpeggio=(28, [0, 7, 12, 19]), env=(0.01, 0.1, 1.6), volume=0.12, in_variants=[2, 3]),
        layer("noise", 22050, 0.6, start=0.27, env=(0.001, 0.02, 2.2), highpass=3000, volume=0.2, in_variants=[3]),
        notes("sine", ". . . . . . C2:6", 0.045, glide_to=0.5, env=(0.001, 0.02, 2.0), volume=0.6, in_variants=[3])]},
}
