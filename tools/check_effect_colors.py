"""
[파일] tools/check_effect_colors.py
[하는 일] 내 무기·스킬 효과 코드에 적의 색(빨강·자홍·주황빨강)이 들어갔는지 찾는다. 파일 안 Color("rrggbb") 를 모두 꺼내 색상 각도로 나누고, 적 색 범위(각도 290°~360°·0°~35°, 채도 0.4 이상, 밝기 0.45 이상)면 파일:줄과 함께 알려 주고 1 로 끝난다.
[쓰는 곳] 사람·검수관이 새 무기를 넣은 뒤 돌린다: py -3 tools/check_effect_colors.py  (보는 파일: scripts/weapons/·scripts/skills/·scripts/world/area_effects.gd)
[근거 문서] 15 §7-1 색 언어 '내 무기에는 적 색을 쓰지 않는다 — 새 무기를 만들 때 검사'
"""
from __future__ import annotations

import colorsys
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
OWN_EFFECT_FILES = sorted(PROJECT.glob("scripts/weapons/*.gd")) + sorted(PROJECT.glob("scripts/skills/*.gd")) + [PROJECT / "scripts/world/area_effects.gd"]
COLOR_PATTERN = re.compile(r'Color\("#?([0-9a-fA-F]{6})"\)')
ENEMY_HUE_DEGREES = (290.0, 35.0)   # 이 각도 사이(360 을 넘어 이어짐)가 적 색
MIN_SATURATION = 0.4
MIN_VALUE = 0.45


def is_enemy_color(hex_code: str) -> tuple[bool, float]:
    red, green, blue = (int(hex_code[index:index + 2], 16) / 255 for index in (0, 2, 4))
    hue, saturation, value = colorsys.rgb_to_hsv(red, green, blue)
    degrees = hue * 360
    in_range = degrees >= ENEMY_HUE_DEGREES[0] or degrees <= ENEMY_HUE_DEGREES[1]
    return in_range and saturation >= MIN_SATURATION and value >= MIN_VALUE, degrees


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    problems = 0
    checked = 0
    for path in OWN_EFFECT_FILES:
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for hex_code in COLOR_PATTERN.findall(line):
                checked += 1
                is_enemy, degrees = is_enemy_color(hex_code)
                if is_enemy:
                    problems += 1
                    print(f"적 색 발견: {path.relative_to(PROJECT)}:{line_number}  #{hex_code} (색상 {degrees:.0f}°)")
    print(f"내 효과 색 {checked}개를 봤어요 — 적 색 {problems}개")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
