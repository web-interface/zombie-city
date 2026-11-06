"""
[파일] tools/sprite_icons.py
[하는 일] 카드·스킬 아이콘(10×10)을 만든다. art/source/icons.txt 의 그림을 그대로 찍고, 무기 아이콘마다 진화 아이콘(icon_<무기>_evolved)을 금색 색바꿈 + 금빛 테두리 + 반짝이로 자동으로 만든다.
[쓰는 곳] tools/build_sprites.py 가 부른다 → art/sprites/icons/*.png. 무기 목록·금색 단계는 art/source/outfits.json 의 "evolved_icons".
[근거 문서] 06 그림 규칙(아이콘 10×10), 14 §2-2 무기 · §2-3 장비 · §2-4 진화(금색 무기) · §2-5 히든 스킬 · §2-6 줍기
"""
from __future__ import annotations

from pixel_png import Canvas, brightness, save_png
from sprite_sheet import OUTPUT, Made, Palette, Parts

OUTLINE = "#16171f"


def build_icons(icons: Parts, palette: Palette, evolved_rules: dict) -> Made:
    made: Made = []
    finished: dict[str, Canvas] = {}
    for name, pixel_map in icons.items():
        canvas = Canvas(pixel_map.width, pixel_map.height)
        canvas.stamp(pixel_map, 0, 0, palette)
        finished[name] = canvas
        made += save_icon(canvas, name, f"아이콘 '{name.removeprefix('icon_')}' ({pixel_map.width}×{pixel_map.height})")
    for weapon_id in evolved_rules["weapons"]:
        base = finished.get(f"icon_{weapon_id}")
        if base is None:
            raise KeyError(f"outfits.json evolved_icons 의 무기 '{weapon_id}' 에 맞는 icon_{weapon_id} 그림이 icons.txt 에 없음")
        made += save_icon(evolved_icon(base, evolved_rules), f"icon_{weapon_id}_evolved", f"진화 아이콘 '{weapon_id}' — 금색 색바꿈 + 금빛 테두리 (자동)")
    return made


def save_icon(canvas: Canvas, name: str, description: str) -> Made:
    save_png(canvas, OUTPUT / "icons" / f"{name}.png")
    return [(f"icons/{name}.png", description)]


def evolved_icon(base: Canvas, rules: dict) -> Canvas:
    """진화 무기 아이콘: 밝기를 그대로 살려 금색 단계로 바꾸고(모양이 읽히게), 테두리는 짙은 갈색,
    바깥 빈칸 한 겹은 금빛 테두리, 오른쪽 위 한 점은 하얀 반짝이 (좌우 똑같지 않게 한 점만)."""
    result = Canvas(base.width, base.height)
    for y in range(base.height):
        for x in range(base.width):
            color = base.pixels[y][x]
            if color is None:
                continue
            result.pixels[y][x] = rules["outline"] if color == OUTLINE else gold_for(color, rules["gold_steps"])
    add_glow_border(result, base, rules["glow"])
    add_sparkle(result, rules["sparkle"])
    return result


def gold_for(color: str, gold_steps: list[list]) -> str:
    """gold_steps = [[이 밝기 이상이면, 이 금색], …] 밝은 것부터. 마지막은 가장 어두운 금색."""
    light = brightness(color)
    for minimum, gold in gold_steps:
        if light >= minimum:
            return gold
    return gold_steps[-1][1]


def add_glow_border(result: Canvas, base: Canvas, glow: str) -> None:
    """그림 바로 바깥(상하좌우로 닿은 빈칸)을 금빛으로 칠한다."""
    for y in range(base.height):
        for x in range(base.width):
            if base.pixels[y][x] is not None:
                continue
            neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            if any(0 <= nx < base.width and 0 <= ny < base.height and base.pixels[ny][nx] for nx, ny in neighbors):
                result.pixels[y][x] = glow


def add_sparkle(result: Canvas, sparkle: str) -> None:
    """오른쪽 위에서 가장 가까운 빈칸 한 점에 반짝이."""
    for distance in range(result.width + result.height):
        for x in range(result.width - 1, -1, -1):
            y = distance - (result.width - 1 - x)
            if 0 <= y < result.height and result.pixels[y][x] is None:
                result.pixels[y][x] = sparkle
                return
