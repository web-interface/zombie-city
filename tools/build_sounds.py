"""
[파일] tools/build_sounds.py
[하는 일] 8비트풍 효과음(이름마다 변형 1~4개, 줍기·연속 처치는 높이 순서)과 음악을 만들어 audio/*.wav 로 저장하고 audio/README.md 를 새로 쓴다. 효과음 최고점이 한도(−6dBFS)를 넘게 적혀 있으면 멈춘다.
[쓰는 곳] `py -3 tools/build_sounds.py` 로 실행. 효과음 정의 표 tools/sound_table_*.py, 음악 tools/sound_music.py(+ audio/source/music_scores.txt), 소리 조각 tools/chiptune.py 를 쓴다 → scripts/autoload/sound_player.gd 가 audio/*.wav 를 튼다.
[근거 문서] 06 사운드·"AI 티 안 나게", 02 §12 위험할수록 악기가 더해지는 음악, 08 v0.2 손맛·소리, 14 전부 넣기(새 좀비·무기·보상 소리)
"""
from __future__ import annotations

import random
from pathlib import Path

from chiptune import SAMPLE_RATE, finish_sound, render_effect, write_wav
from sound_music import build_music
from sound_table_core import CORE_EFFECTS
from sound_table_night import NIGHT_EFFECTS
from sound_table_rewards import REWARD_EFFECTS
from sound_table_weapons import WEAPON_EFFECTS

PROJECT = Path(__file__).resolve().parent.parent
AUDIO = PROJECT / "audio"
SCORE_FILE = AUDIO / "source" / "music_scores.txt"
EFFECT_PEAK_LIMIT_DB = -6.0     # 효과음 하나의 최고점 한도(0.5). 웹판에서 여러 개가 겹쳐도 합이 1.0 을 덜 넘게 — audio/README.md '크기'
EFFECT_TABLES: dict[str, dict[str, dict]] = {    # README 의 묶음 제목 → 표
    "기본 — 무기·좀비·보스·스킬·흐름·UI": CORE_EFFECTS,
    "끝없는 밤 — 새 좀비·보스·이벤트·연속 처치": NIGHT_EFFECTS,
    "새 무기 13종": WEAPON_EFFECTS,
    "진화·히든·보물 상자·줍기·해금": REWARD_EFFECTS,
}
MUSIC_SECTION = "음악 (반복)"


def main() -> None:
    made = build_effects(merged_effects()) + build_music(AUDIO, SCORE_FILE)
    remove_stale_files({file_name for file_name, _, _, _ in made})
    write_readme(made)
    total_bytes = sum((AUDIO / file_name).stat().st_size for file_name, _, _, _ in made)
    print(f"소리 {len(made)}개를 만들었어요 → {AUDIO}  (합계 {total_bytes / 1_000_000:.2f}MB)")


# ───────── 효과음 ─────────

def merged_effects() -> dict[str, dict]:
    """표 네 개를 하나로 합친다. 적은 값에 문제가 있으면 어느 소리인지 알려 주고 멈춘다."""
    effects: dict[str, dict] = {}
    for table in EFFECT_TABLES.values():
        for name, effect in table.items():
            problem = effect_problem(name, effect, effects)
            if problem:
                raise ValueError(f"효과음 '{name}': {problem}")
            effects[name] = effect
    return effects


def effect_problem(name: str, effect: dict, earlier: dict[str, dict]) -> str:
    """문제가 없으면 빈 문자열."""
    if name in earlier:
        return "다른 표에 같은 이름이 있음"
    if name.rpartition("_")[2].isdigit():
        return "이름이 '_숫자'로 끝나면 SoundPlayer 가 변형 번호로 착각함"
    if effect["peak_db"] > EFFECT_PEAK_LIMIT_DB:
        return f"peak_db {effect['peak_db']} 가 한도 {EFFECT_PEAK_LIMIT_DB} 보다 큼 (audio/README.md '크기')"
    if "steps" not in effect and "variants" not in effect:
        return "variants(변형 수)나 steps(높이 순서)가 없음"
    return ""


def build_effects(effects: dict[str, dict]) -> list[tuple[str, str, str, float]]:
    """소리마다 변형을 만들어 '<이름>_<번호>.wav' 로 저장 (변형이 하나여도 _1). 돌려주는 값: (파일, 묶음 이름, 설명, 초)."""
    made: list[tuple[str, str, str, float]] = []
    for name, effect in effects.items():
        rng = random.Random(name)      # 이름이 씨앗 → 다시 돌려도 같은 소리 (원본을 안 고치면 파일도 안 바뀜)
        loop_seconds = effect.get("loop_seconds", 0.0)
        for number, (pitch_ratio, time_ratio) in enumerate(variant_settings(effect, rng), start=1):
            layers = [layer for layer in effect["layers"] if number in layer.get("in_variants", [number])]
            samples = render_effect(layers, rng, pitch_ratio, time_ratio, number - 1, loop_seconds)
            samples = finish_sound(samples, effect["peak_db"], effect.get("drive", 0.0), effect.get("crush", 0), loop_seconds > 0)
            file_name = f"{name}_{number}.wav"
            write_wav(AUDIO / file_name, samples, is_loop=loop_seconds > 0)
            made.append((file_name, name, effect["about"], len(samples) / SAMPLE_RATE))
    return made


def variant_settings(effect: dict, rng: random.Random) -> list[tuple[float, float]]:
    """변형마다 (높이 비율, 길이 비율). 높이는 고르게 퍼뜨린 뒤 섞어서 '1번이 늘 제일 낮음' 같은 규칙이 안 보이게 한다.
    줍기·연속 처치처럼 'steps'(반음 단계)가 있으면 그 순서가 곧 높이다. 변형이 하나뿐이면 적은 그대로."""
    if "steps" in effect:
        return [(2.0 ** (semitones / 12), 1.0) for semitones in effect["steps"]]
    count = effect["variants"]
    if count == 1:
        return [(1.0, 1.0)]
    offsets = [effect["spread"] * (index / (count - 1) - 0.5) for index in range(count)]
    rng.shuffle(offsets)
    settings: list[tuple[float, float]] = []
    for offset in offsets:
        pitch_ratio = 2.0 ** ((offset + rng.uniform(-0.15, 0.15)) / 12)
        time_ratio = 1.0 if "loop_seconds" in effect else rng.uniform(0.94, 1.06)   # 반복 소리는 길이가 정확해야 이음매가 맞는다
        settings.append((pitch_ratio, time_ratio))
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
`tools/build_sounds.py` 가 만든 소리다. 바꾸려면 효과음 정의 표(`tools/sound_table_core.py`·`sound_table_night.py`·`sound_table_weapons.py`·`sound_table_rewards.py`)나 악보 `source/music_scores.txt` 를 고치고 `py -3 tools/build_sounds.py` 로 다시 만든다. (문서 10 §5 — 소리 파일엔 주석을 못 넣어서 여기 적음)

**출처: 이 프로젝트에서 도구로 직접 만듦 (외부 자료·AI 음성/음악 생성 없음).** 파이썬 기본 라이브러리로 파형을 한 샘플씩 계산했다. 사용 조건: 제한 없음(우리 것).

- 형식: 16비트 모노 WAV, 22050Hz (8비트풍이라 이걸로 충분하고 용량이 절반)
- 크기 (2026-11-07 바꿈): **효과음은 모두 최고점 −6dBFS(0.5) 이하.** 큰 소리(폭발·포효·전직·탈출·진화·상자 대박·해머 내려찍기·폭탄·컷인) −6, 경보·예고 −6.5 ~ −11, 무기 −8 ~ −14, 좀비 맞음 −12, 줍기 −17, UI −17 ~ −19.5 — 자주 나는 소리일수록 작게 (폰 스피커로 들리는 크기 기준)
  - 왜: 웹판에서 효과음 여러 개가 한꺼번에 나면 합친 크기가 1.0 을 넘어 소리가 찢어졌다(측정 최고 1.2~1.4). 그래서 원래 있던 효과음 26종을 **모두 똑같이 3dB 낮췄고**(예전 −3 → −6, −14 → −17 … 서로의 크기 비율은 그대로), 새 효과음도 −6 이하로 만들었다. 표의 `peak_db` 가 −6 을 넘으면 도구가 멈춘다
  - 음악은 그대로: 한 판 음악은 세 층을 다 켰을 때 −3dBFS, 조용한 타이틀·결과·은신처는 −5dBFS (1층만 켠 평온할 때는 약 5dB 작음 — 위험해질수록 커지게). 효과음이 3dB 작아진 만큼 음악이 상대적으로 조금 크게 들릴 수 있다 → 필요하면 SoundPlayer 의 음악 볼륨으로 맞춘다
  - 파일 하나로는 클리핑 없음
- 반복: `music_*.wav`·`helicopter_loop_*.wav` 는 WAV 안 'smpl' 칸에 처음~끝 반복 구간이 적혀 있어 Godot 가져오기 Loop Mode 기본값(Detect From WAV)으로 끊김 없이 반복된다

## 게임에서 쓸 때
- 같은 이름의 `_1`~`_4` 중 무작위 + 높이(pitch_scale) 조금씩 → 같은 소리 반복이 안 들림 (문서 06 AI 티)
- 변형이 하나뿐인 소리도 `_1` 이 붙는다(`encircle_alarm_1.wav`) — SoundPlayer 가 '이름_번호' 파일만 모으기 때문. 부를 때는 그대로 `play("encircle_alarm")`
- `shard_pickup_1`~`_5` 는 무작위가 아니라 **높이 순서**(도·레·미·솔·라). 잠깐(약 0.4초) 안에 또 주우면 다음 번호, 쉬면 1로, 5 다음은 5 유지. 높이를 따로 흔들지 말고 그대로 튼다
- `combo_milestone_1`~`_3` 도 **순서**: 연속 50 = `_1`, 100 = `_2`, 200 = `_3` (점점 높고 화려함) → `play_exact("combo_milestone_2")` 처럼 정확히 고른다
- `music_run_layer1~3` 은 길이가 샘플 하나까지 같고 템포도 같다 → **같은 순간에 셋 다 틀고 볼륨만** 바꾼다(1층 늘 켬, 위험 2단계에 2층, 3단계에 3층). 한 층만 멈췄다 다시 틀면 박자가 어긋난다
- `music_shelter` 는 은신처 화면: `play_single_music("music_shelter")`
- `helicopter_loop_*` 는 끝없이 반복되므로 전용 플레이어에서 틀고 헬기가 떠날 때 멈춘다
- 예고 → 본소리 짝: `boss_warning`(약 2초) → `boss_roar` · `bloater_swell`(0.6초, 빨간 고리) → `bloater_pop` · `demolisher_warning`(약 1.1초, 빨간 원이 차는 동안) → `demolisher_slam` · `airstrike_whistle`(약 1초) → `airstrike_boom` · `hidden_card_appear`(금색 카드) → 쓸 때 `hidden_skill_cutin` → 생존자별 히든 소리(`airstrike_*`·`backdraft_roar`·`express_dash`·`miracle_chime`)
- 보물 상자: `chest_drop`(떨어질 때) → 열면 `chest_roll`(슬롯 1.5초, 점점 느려짐) → 멈출 때 `chest_open_small`(강화 1~3개) 또는 `chest_jackpot`(5개)
- 2초 안팎의 길고 중요한 소리(전용 칸에서 끊기지 않게 트는 것이 좋음): `evolution`·`chest_jackpot`·`night_clear`·`night_start`·`encircle_alarm`·`stampede_rumble`·`hidden_skill_cutin`

## 파일
| 파일 | 길이 | 무엇 |
|---|---|---|
"""


def write_readme(made: list[tuple[str, str, str, float]]) -> None:
    """만든 파일을 소리 이름별로 묶어 한 줄씩 적는다. 표가 바뀌는 곳에 묶음 제목 줄을 넣는다."""
    section_of = {name: title for title, table in EFFECT_TABLES.items() for name in table}
    groups: dict[str, list[tuple[str, str, float]]] = {}
    for file_name, group, about, seconds in made:
        groups.setdefault(group, []).append((file_name, about, seconds))
    rows: list[str] = []
    current_section = ""
    for group, files in groups.items():
        section = section_of.get(group, MUSIC_SECTION)
        if section != current_section:
            rows.append(f"| **{section}** | | |")
            current_section = section
        longest = max(seconds for _, _, seconds in files)
        shown = f"`{files[0][0]}`" if len(files) == 1 else f"`{group}_1.wav` ~ `_{len(files)}.wav`"
        length_text = f"{longest:.2f}초" if longest < 0.1 else f"{longest:.1f}초"
        rows.append(f"| {shown} | {length_text} | {files[0][1]} |")
    rows.append("| `source/music_scores.txt` | — | 음악 악보 원본(악기 설정 + 마디별 음표). 사람이 읽고 고칠 수 있음 |")
    (AUDIO / "README.md").write_text(README_INTRO + "\n".join(rows) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
