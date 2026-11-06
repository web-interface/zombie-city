"""
[파일] tools/build_sprites.py
[하는 일] art/source 의 글자 지도와 색 표로 게임 그림을 모두 만든다: 생존자 16벌 동작 묶음(서 있기·걷기 4장 × 3방향·쓰러지기)과 하얀 실루엣, 좀비·보스(sprite_zombies.py), 아이콘(sprite_icons.py), 소품·상자·드론, 바닥 타일, 빛 그림, 폴더 README.
[쓰는 곳] 그림 원본을 고친 뒤 `py -3 tools/build_sprites.py` 로 실행 → art/sprites/*.png. scripts/world/*.gd · scripts/ui/*.gd 가 이 PNG 를 쓴다. tools/pixel_png.py · sprite_sheet.py · sprite_zombies.py · sprite_icons.py 를 쓴다.
[근거 문서] 06 그림 규칙, 11 §11 픽셀 그림 만드는 길, 14 §1-2·§1-3·§2 (새 좀비·보스·아이콘)
"""
from __future__ import annotations

import json
import sys
import math
import random

from pixel_png import Canvas, PixelMap, read_pixel_maps, save_png
from sprite_icons import build_icons
from sprite_sheet import FRAME, HUMAN_ROWS, OUTPUT, SOURCE, Made, Palette, Parts, build_sheet, death_frame, save_with_flash, stamp_hat, stamp_legs, walk_pose
from sprite_zombies import build_boss_sheets, build_zombie_sheets

sys.stdout.reconfigure(encoding="utf-8")   # 윈도 콘솔(cp949)에서 한글이 깨지지 않게


def main() -> None:
    parts = {**read_pixel_maps(SOURCE / "parts_people.txt"), **read_pixel_maps(SOURCE / "parts_zombies.txt")}
    sprites = read_pixel_maps(SOURCE / "sprites.txt")
    colors = json.loads((SOURCE / "outfits.json").read_text(encoding="utf-8"))
    made: Made = []
    for outfit_name, outfit in colors["human_outfits"].items():
        palette = {**colors["human_common"], **outfit}
        sheet = build_sheet(lambda row, index: human_frame(parts, palette, outfit["hat"], row, index), HUMAN_ROWS)
        made += save_with_flash(sheet, f"survivor_{outfit_name}", f"생존자 옷 '{outfit_name}' 동작 묶음 (16×16, 줄: {', '.join(HUMAN_ROWS)})")
    made += build_zombie_sheets(parts, colors)
    made += build_boss_sheets(read_pixel_maps(SOURCE / "bosses.txt"), colors["global_palette"])
    made += build_icons(read_pixel_maps(SOURCE / "icons.txt"), colors["global_palette"], colors["evolved_icons"])
    made += build_single_sprites(sprites, colors["global_palette"])
    made += build_ground_tiles()
    made += build_light_textures()
    write_readme(made)
    print(f"그림 {len(made)}장을 만들었어요 → {OUTPUT}")


# ───────── 생존자 ─────────

def human_frame(parts: Parts, palette: Palette, hat: str, row_name: str, index: int) -> Canvas:
    if row_name == "death":
        return death_frame(human_frame(parts, palette, hat, "idle_down", 0), index)
    direction, action, body_drop = walk_pose(row_name, index)
    canvas = Canvas(FRAME, FRAME)
    stamp_legs(canvas, parts, palette, direction, action, index)
    canvas.stamp(parts[f"torso_{direction}"], 5, 8 + body_drop, palette)
    left_swing, right_swing = arm_swing(action, index)
    if direction == "side":
        canvas.stamp(parts["arm_side"], 7 + left_swing - right_swing, 8 + body_drop, palette)
    else:
        canvas.stamp(parts["arm_left"], 3, 8 + body_drop + left_swing, palette)
        canvas.stamp(parts["arm_right"], 11, 8 + body_drop + right_swing, palette)
    breathing = 1 if action == "idle" and index == 1 else 0
    head_top = 1 + body_drop + breathing
    canvas.stamp(parts[f"head_{direction}"], 4, head_top, palette)
    stamp_hat(canvas, parts, palette, hat, direction, 4, head_top)
    return canvas


def arm_swing(action: str, index: int) -> tuple[int, int]:
    """걸을 때 팔을 번갈아 흔든다: (왼팔, 오른팔) 이 1점씩 내려감."""
    if action != "walk":
        return 0, 0
    return {0: (1, 0), 2: (0, 1)}.get(index, (0, 0))


# ───────── 한 장 그림 (소품·헬기·백신 조각·드론·상자) ─────────

# 칸 나눔처럼 게임 코드가 알아야 하는 것은 README 설명에 따로 적는다
SINGLE_SPRITE_NOTES = {
    "chest": "보물 상자 — 16×16 두 칸 가로 (왼쪽 닫힘 · 오른쪽 열림)",
    "drone_parcel": "배달 드론 — 소포를 매단 드론 (9×10, 한 장)",
}


def build_single_sprites(sprites: dict[str, PixelMap], palette: Palette) -> Made:
    made: Made = []
    for name, pixel_map in sprites.items():
        canvas = Canvas(pixel_map.width, pixel_map.height)
        canvas.stamp(pixel_map, 0, 0, palette)
        save_png(canvas, OUTPUT / f"{name}.png")
        made.append((f"{name}.png", SINGLE_SPRITE_NOTES.get(name, f"한 장 그림 '{name}' ({pixel_map.width}×{pixel_map.height})")))
    return made


# ───────── 바닥 타일·빛 ─────────

TILE_NAMES = ["아스팔트1", "아스팔트2", "아스팔트3", "아스팔트4", "금 간 아스팔트", "기름 얼룩", "맨홀", "인도 블록"]


def build_ground_tiles() -> list[tuple[str, str]]:
    """도심 도로 바닥 타일 8칸 (16×16, 가로 한 줄). 순서는 TILE_NAMES."""
    sheet = Canvas(FRAME * len(TILE_NAMES), FRAME)
    for tile_index in range(len(TILE_NAMES)):
        sheet.paste(make_tile(tile_index, random.Random(tile_index * 97 + 11)), tile_index * FRAME, 0)
    save_png(sheet, OUTPUT / "tiles_downtown.png")
    return [("tiles_downtown.png", "도심 도로 바닥 타일 8칸: " + ", ".join(TILE_NAMES))]


def make_tile(tile_index: int, rng: random.Random) -> Canvas:
    is_sidewalk = tile_index == 7
    tile = Canvas(FRAME, FRAME)
    base, light, dark = ("#30343c", "#363a43", "#2a2d34") if is_sidewalk else ("#262a33", "#2d313b", "#20232b")
    tile.pixels = [[base] * FRAME for _ in range(FRAME)]
    for _ in range(16):
        tile.pixels[rng.randrange(FRAME)][rng.randrange(FRAME)] = light if rng.random() < 0.5 else dark
    if is_sidewalk:
        for edge in range(FRAME):
            tile.pixels[0][edge] = dark
            tile.pixels[edge][0] = dark
    elif tile_index == 4:
        draw_crack(tile, rng)
    elif tile_index == 5:
        draw_oil_stain(tile, rng)
    elif tile_index == 6:
        draw_manhole(tile)
    return tile


def draw_crack(tile: Canvas, rng: random.Random) -> None:
    x = rng.randrange(FRAME)
    for y in range(FRAME):
        tile.pixels[y][x] = "#191b21"
        x = max(0, min(FRAME - 1, x + rng.choice((-1, 0, 1))))


def draw_oil_stain(tile: Canvas, rng: random.Random) -> None:
    for y in range(FRAME):
        for x in range(FRAME):
            if ((x - 8) / 6) ** 2 + ((y - 9) / 4) ** 2 < 1 and rng.random() > 0.15:
                tile.pixels[y][x] = "#1d2027"


def draw_manhole(tile: Canvas) -> None:
    for y in range(FRAME):
        for x in range(FRAME):
            distance = math.hypot(x - 7.5, y - 7.5)
            if distance < 5.6:
                tile.pixels[y][x] = "#454b57" if distance > 4.6 else ("#30343d" if y % 3 == 0 else "#1c1f26")


def build_light_textures() -> list[tuple[str, str]]:
    """계단식 둥근 빛 (64×64, 흰색 + 투명도 4단계). 매끈한 그라데이션 대신 픽셀 느낌으로 (06 AI 티 안 나게)."""
    size = 64
    steps = [(0.45, 255), (0.70, 170), (0.88, 95), (1.0, 40)]
    alpha_rows = []
    for y in range(size):
        row = []
        for x in range(size):
            distance = math.hypot(x - size / 2 + 0.5, y - size / 2 + 0.5) / (size / 2)
            row.append(next((alpha for limit, alpha in steps if distance <= limit), 0))
        alpha_rows.append(row)
    save_png(Canvas(size, size), OUTPUT / "light_stepped.png", alpha_rows)
    return [("light_stepped.png", "계단식 둥근 빛 (가로등·손전등·조명탄 빛에 씀)")]


def write_readme(made: list[tuple[str, str]]) -> None:
    lines = [
        "# art/sprites — 만들어진 그림 (직접 고치지 않음)",
        "`tools/build_sprites.py` 가 `art/source/` 의 글자 지도로 만든 그림이다. 그림을 바꾸려면 원본을 고치고 도구를 다시 돌린다. (문서 10 §5 — 그림 파일엔 주석을 못 넣어서 여기 적음)",
        "출처: 이 프로젝트에서 직접 그림. AI 이미지 생성 안 씀.",
        "",
        "| 파일 | 무엇 |",
        "|---|---|",
    ]
    lines += [f"| `{name}` | {description} |" for name, description in sorted(made)]
    (OUTPUT / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    icon_lines = [
        "# art/sprites/icons — 카드·스킬 아이콘 (직접 고치지 않음)",
        "`tools/build_sprites.py`(+ `sprite_icons.py`) 가 `art/source/icons.txt` 의 그림으로 만든 10×10 아이콘. 무기마다 `_evolved`(금색 진화 아이콘)는 자동 생성. 원본을 고치고 도구를 다시 돌린다 (문서 10 §5).",
        "",
        "| 파일 | 무엇 |",
        "|---|---|",
    ]
    icon_lines += [f"| `{name.removeprefix('icons/')}` | {description} |" for name, description in sorted(made) if name.startswith("icons/")]
    (OUTPUT / "icons" / "README.md").write_text("\n".join(icon_lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
