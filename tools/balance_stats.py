"""
[파일] tools/balance_stats.py
[하는 일] 밸런스 통계기: 자동 플레이가 남긴 판 기록(*.jsonl, 한 줄 = 한 판)을 모아 생존자·봇 실력별로 탈출률과 재미 지표(레벨 업 간격·아슬아슬 생존·분당 처치·화면 좀비 수·보스 처치 시간·전직 체감·탈출 긴장·지루한 구간)를 내고, 문서 12 목표와 비교한 표를 report.md 로 쓴다.
[쓰는 곳] `py -3 tools/balance_stats.py tools/out/balance` — 난이도 테스터 에이전트가 쓴다. 기록은 scripts/run/run_recorder.gd 가 남긴다.
[근거 문서] 12 §4 목표·§5 재미 지표
"""
from __future__ import annotations

import json
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")   # 윈도 콘솔(cp949)에서 한글·기호가 깨지거나 멈추지 않게

ESCAPE_TARGETS = {"고수": (0.80, 1.00), "보통": (0.45, 0.60), "초보": (0.15, 0.30)}


def main() -> None:
    folder = Path(sys.argv[1] if len(sys.argv) > 1 else "tools/out/balance")
    runs = load_runs(folder)
    if not runs:
        print(f"{folder} 에 기록(*.jsonl)이 없어요")
        return
    lines = ["# 밸런스·재미 통계", f"> 자동 플레이 {len(runs)}판을 모은 결과. 목표는 문서 12 §4·§5.", ""]
    lines += escape_table(runs)
    lines += fun_table(runs)
    lines += card_and_death_table(runs)
    report = folder / "report.md"
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    print(f"\n→ {report}")


def load_runs(folder: Path) -> list[dict]:
    runs = []
    for path in sorted(folder.glob("*.jsonl")):
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                runs.append(json.loads(line))
    return runs


def mean(values: list[float]) -> float:
    return statistics.fmean(values) if values else 0.0


def escape_table(runs: list[dict]) -> list[str]:
    groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for run in runs:
        groups[(run.get("survivor", "?"), run.get("bot", "?"))].append(run)
    lines = ["## 탈출률", "| 생존자 | 봇 | 판 | 탈출률 | 목표 | 평균 버틴 시간 | 평균 처치 | 평균 레벨 |", "|---|---|---|---|---|---|---|---|"]
    for (survivor, bot), group in sorted(groups.items()):
        rate = mean([1.0 if run["is_escaped"] else 0.0 for run in group])
        low, high = ESCAPE_TARGETS.get(bot, (0.0, 1.0))
        verdict = "✅" if low <= rate <= high else ("⬆ 너무 쉬움" if rate > high else "⬇ 너무 어려움")
        lines.append(f"| {survivor} | {bot} | {len(group)} | {rate:.0%} {verdict} | {low:.0%}~{high:.0%} | {mean([r['survived_seconds'] for r in group]):.0f}초 | {mean([r['kills'] for r in group]):.0f} | {mean([r['level'] for r in group]):.1f} |")
    return lines + [""]


def fun_table(runs: list[dict]) -> list[str]:
    early_gaps, late_gaps, level10, level20 = [], [], [], []
    for run in runs:
        times = [0.0] + list(run.get("level_up_times", []))
        gaps = [(later, later - earlier) for earlier, later in zip(times, times[1:])]
        early_gaps += [gap for at, gap in gaps if at <= 60]
        late_gaps += [gap for at, gap in gaps if at > 120]
        if len(times) > 9:
            level10.append(times[9])
        if len(times) > 19:
            level20.append(times[19])
    kill_growth = [run["kills_by_minute"][4] / max(1, run["kills_by_minute"][0]) for run in runs if len(run.get("kills_by_minute", [])) > 4 and run["survived_seconds"] >= 300]
    boss_seconds = [seconds for run in runs for seconds in run.get("boss_kill_seconds", [])]
    speedups = [run["promotion_kill_speedup"] for run in runs if run.get("promotion_kill_speedup", 0) > 0]
    extracting = [run for run in runs if run["survived_seconds"] >= 300]
    rows = [
        ("레벨 업 간격 (처음 1분)", f"{mean(early_gaps):.1f}초", "8~15초"),
        ("레벨 업 간격 (2분 뒤)", f"{mean(late_gaps):.1f}초", "20~35초"),
        ("레벨 10 도달 (1차 전직)", f"{mean(level10):.0f}초 ({len(level10)}판)", "약 90초"),
        ("레벨 20 도달 (2차 전직)", f"{mean(level20):.0f}초 ({len(level20)}판)", "약 210초"),
        ("지루한 구간 (20초+)", f"판당 {mean([r['boring_gaps'] for r in runs]):.1f}번", "0~1번"),
        ("아슬아슬 생존", f"판당 {mean([r['near_death_saves'] for r in runs]):.1f}번", "2~4번"),
        ("가장 낮았던 체력 (탈출한 판)", f"{mean([r.get('lowest_health_ratio', 1.0) for r in runs if r['is_escaped']]):.0%}", "30% 밑으로 한 번은"),
        ("분당 처치 5분째 ÷ 1분째", f"{mean(kill_growth):.1f}배", "4배+"),
        ("4분대 화면 좀비 수 (최대)", f"{mean([r['max_zombies_after_four_minutes'] for r in runs]):.0f}", "120~300"),
        ("보스 처치 시간", f"{mean(boss_seconds):.0f}초 ({len(boss_seconds)}번)", "15~40초"),
        ("전직 체감 (전후 30초 처치 배율)", f"{mean(speedups):.2f}배", "1.3배+"),
        ("탈출 때 맞은 비율", f"{mean([1.0 if r['took_damage_while_extracting'] else 0.0 for r in extracting]):.0%} ({len(extracting)}판)", "60%+"),
    ]
    lines = ["## 재미 지표", "| 지표 | 측정 | 목표 |", "|---|---|---|"]
    lines += [f"| {name} | {measured} | {target} |" for name, measured, target in rows]
    return lines + [""]


def card_and_death_table(runs: list[dict]) -> list[str]:
    picks = Counter(card for run in runs for card in run.get("chosen_cards", []))
    deaths = Counter(run["death_cause"] for run in runs if run.get("death_cause"))
    branches = Counter(run["branch"] for run in runs if run.get("branch"))
    lines = ["## 많이 고른 카드", "| 카드 | 횟수 |", "|---|---|"]
    lines += [f"| {card} | {count} |" for card, count in picks.most_common(12)]
    lines += ["", "## 쓰러진 이유", "| 이유 | 판 |", "|---|---|"]
    lines += [f"| {cause} | {count} |" for cause, count in deaths.most_common()]
    lines += ["", "## 전직 갈래", "| 갈래 | 판 |", "|---|---|"]
    lines += [f"| {branch} | {count} |" for branch, count in branches.most_common()]
    return lines + [""]


if __name__ == "__main__":
    main()
