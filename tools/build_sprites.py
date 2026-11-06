"""
[파일] tools/build_sprites.py
[하는 일] art/source 의 글자 지도와 색 표로 게임 그림을 모두 만든다: 생존자 16벌·좀비 4종 동작 묶음(걷기 4장 × 3방향, 서 있기, 쓰러지기)과 하얀 실루엣, 보스, 소품, 아이콘, 바닥 타일, 빛 그림.
[쓰는 곳] 그림 원본을 고친 뒤 `py -3 tools/build_sprites.py` 로 실행 → art/sprites/*.png. scripts/world/*.gd · scripts/ui/*.gd 가 이 PNG 를 쓴다. tools/pixel_png.py 를 쓴다.
[근거 문서] 06 그림 규칙, 11 §9 픽셀 그림 만드는 길
"""
from __future__ import annotations

import json
import math
import random
from pathlib import Path

from pixel_png import Canvas, PixelMap, read_pixel_maps, save_png

PROJECT = Path(__file__).resolve().parent.parent
SOURCE = PROJECT / "art" / "source"
OUTPUT = PROJECT / "art" / "sprites"
FRAME = 16

# 동작 묶음 한 줄 = 동작 하나. 칸(가로)이 장면 순서다. 게임 코드(scripts/world/sprite_sheet_layout.gd)와 순서가 같아야 한다.
HUMAN_ROWS = ["idle_down", "idle_up", "idle_side", "walk_down", "walk_up", "walk_side", "death"]
ZOMBIE_ROWS = ["walk_down", "walk_up", "walk_side", "death"]
WALK_CONTACT_FRAMES = (0, 2)   # 발을 내딛는 장면: 몸이 1점 내려간다


def main() -> None:
    parts = read_pixel_maps(SOURCE / "parts_people.txt")
    sprites = read_pixel_maps(SOURCE / "sprites.txt")
    colors = json.loads((SOURCE / "outfits.json").read_text(encoding="utf-8"))
    made: list[tuple[str, str]] = []
    for outfit_name, outfit in colors["human_outfits"].items():
        palette = {**colors["human_common"], **outfit}
        sheet = build_sheet(lambda row, index: human_frame(parts, palette, outfit["hat"], row, index), HUMAN_ROWS)
        made += save_with_flash(sheet, f"survivor_{outfit_name}", f"생존자 옷 '{outfit_name}' 동작 묶음 (16×16, 줄: {', '.join(HUMAN_ROWS)})")
    for kind_name, kind in colors["zombie_kinds"].items():
        palette = {**colors["zombie_common"], **kind, "p": kind["q"], "f": kind["z"]}
        if kind_name == "crawler":
            sheet = build_sheet(lambda row, index: crawler_frame(parts, palette, row, index), ZOMBIE_ROWS)
        else:
            sheet = build_sheet(lambda row, index: zombie_frame(parts, palette, kind["hat"], row, index), ZOMBIE_ROWS)
        made += save_with_flash(sheet, f"zombie_{kind_name}", f"좀비 '{kind_name}' 동작 묶음 (16×16, 줄: {', '.join(ZOMBIE_ROWS)})")
    made += build_single_sprites(sprites, colors["global_palette"])
    made += build_ground_tiles()
    made += build_light_textures()
    write_readme(made)
    print(f"그림 {len(made)}장을 만들었어요 → {OUTPUT}")


# ───────── 동작 묶음 ─────────

def frames_in_row(row_name: str) -> int:
    if row_name.startswith("idle"):
        return 2
    if row_name == "death":
        return 3
    return 4


def build_sheet(make_frame, row_names: list[str]) -> Canvas:
    sheet = Canvas(FRAME * 4, FRAME * len(row_names))
    for row_index, row_name in enumerate(row_names):
        for frame_index in range(frames_in_row(row_name)):
            sheet.paste(make_frame(row_name, frame_index), frame_index * FRAME, row_index * FRAME)
    return sheet


def death_frame(standing: Canvas, index: int) -> Canvas:
    """쓰러지기 3장: 무릎 꺾임 → 옆으로 눕기 → 어두워짐."""
    if index == 0:
        return standing.shifted_down(1)
    lying = standing.rotated_clockwise().resting_on_floor()
    return lying if index == 1 else lying.darkened(0.35)


def walk_pose(row_name: str, index: int) -> tuple[str, str, int]:
    """(방향, 동작, 몸 내려감) — 걷기에서 발 내딛는 장면은 몸이 1점 내려간다."""
    action, direction = row_name.split("_")
    is_contact = action == "walk" and index in WALK_CONTACT_FRAMES
    return direction, action, 1 if is_contact else 0


# ───────── 생존자 ─────────

def human_frame(parts: dict[str, PixelMap], palette: dict[str, str], hat: str, row_name: str, index: int) -> Canvas:
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
    stamp_hat(canvas, parts, palette, hat, direction, head_top)
    return canvas


def arm_swing(action: str, index: int) -> tuple[int, int]:
    """걸을 때 팔을 번갈아 흔든다: (왼팔, 오른팔) 이 1점씩 내려감."""
    if action != "walk":
        return 0, 0
    return {0: (1, 0), 2: (0, 1)}.get(index, (0, 0))


def stamp_legs(canvas: Canvas, parts: dict[str, PixelMap], palette: dict[str, str], direction: str, action: str, index: int) -> None:
    if action == "walk" and index in WALK_CONTACT_FRAMES:
        if direction == "side":
            name = "legs_side_stride" if index == 0 else "legs_side_cross"
        else:
            name = "legs_contact_a" if index == 0 else "legs_contact_b"
        canvas.stamp(parts[name], 5, 13, palette)
        return
    canvas.stamp(parts["legs_side_stand" if direction == "side" else "legs_stand"], 5, 12, palette)


def stamp_hat(canvas: Canvas, parts: dict[str, PixelMap], palette: dict[str, str], hat: str, direction: str, head_top: int) -> None:
    if hat != "none":
        canvas.stamp(parts[f"hat_{hat}_{direction}"], 4, head_top - 1, palette)


# ───────── 좀비 ─────────

def zombie_frame(parts: dict[str, PixelMap], palette: dict[str, str], hat: str, row_name: str, index: int) -> Canvas:
    """좀비는 팔을 앞으로 뻗고, 머리를 좌우로 흔들며 절뚝거린다 (좌우가 똑같지 않게)."""
    if row_name == "death":
        return death_frame(zombie_frame(parts, palette, hat, "walk_down", 1), index)
    direction, action, body_drop = walk_pose(row_name, index)
    canvas = Canvas(FRAME, FRAME)
    stamp_legs(canvas, parts, palette, direction, action, index)
    canvas.stamp(parts[f"ztorso_{direction}"], 5, 8 + body_drop, palette)
    reach = 1 if index in (1, 3) else 0
    if direction == "down":
        canvas.stamp(parts["zarm_down_left"], 4, 9 + body_drop + reach, palette)
        canvas.stamp(parts["zarm_down_right"], 10, 9 + body_drop + (1 - reach), palette)
    elif direction == "side":
        canvas.stamp(parts["zarm_side"], 9, 9 + body_drop + reach, palette)
    head_sway = {0: -1, 2: 1}.get(index, 0)
    head_top = 1 + body_drop
    canvas.stamp(parts[f"zhead_{direction}"], 4 + head_sway, head_top, palette)
    stamp_hat(canvas, parts, palette, hat, direction, head_top)
    return canvas


def crawler_frame(parts: dict[str, PixelMap], palette: dict[str, str], row_name: str, index: int) -> Canvas:
    """기어다니는 좀비: 아래로 기는 그림 2장을 번갈아 쓰고, 다른 방향은 돌려서 만든다."""
    if row_name == "death":
        base = Canvas(FRAME, FRAME)
        base.stamp(parts["crawler_a"], 0, 0, palette)
        return base.shifted_down(0) if index == 0 else base.darkened(0.2 * index)
    canvas = Canvas(FRAME, FRAME)
    canvas.stamp(parts["crawler_a" if index % 2 == 0 else "crawler_b"], 0, 0, palette)
    direction = row_name.split("_")[1]
    if direction == "up":
        return canvas.rotated_clockwise().rotated_clockwise()
    if direction == "side":
        return canvas.rotated_counter_clockwise()
    return canvas


# ───────── 한 장 그림·보스 ─────────

def build_single_sprites(sprites: dict[str, PixelMap], palette: dict[str, str]) -> list[tuple[str, str]]:
    made: list[tuple[str, str]] = []
    boss = Canvas(24 * 4, 24 * 2)
    for frame_index, name in enumerate(["boss_butcher_a", "boss_butcher_b", "boss_butcher_a", "boss_butcher_b"]):
        boss.stamp(sprites[name], frame_index * 24, 0, palette)
    standing = Canvas(24, 24)
    standing.stamp(sprites["boss_butcher_a"], 0, 0, palette)
    for frame_index in range(3):
        boss.paste(death_frame(standing, frame_index), frame_index * 24, 24)
    made += save_with_flash(boss, "boss_butcher", "보스 도살자 (24×24, 1줄 걷기 4장 · 2줄 쓰러지기 3장)")
    for name, pixel_map in sprites.items():
        if name.startswith("boss_"):
            continue
        canvas = Canvas(pixel_map.width, pixel_map.height)
        canvas.stamp(pixel_map, 0, 0, palette)
        folder = "icons/" if name.startswith("icon_") else ""
        save_png(canvas, OUTPUT / f"{folder}{name}.png")
        made.append((f"{folder}{name}.png", f"한 장 그림 '{name}' ({pixel_map.width}×{pixel_map.height})"))
    return made


def save_with_flash(sheet: Canvas, name: str, description: str) -> list[tuple[str, str]]:
    save_png(sheet, OUTPUT / f"{name}.png")
    save_png(sheet.white_silhouette(), OUTPUT / f"{name}_flash.png")
    return [(f"{name}.png", description), (f"{name}_flash.png", f"{name} 의 하얀 실루엣 (맞았을 때 잠깐)")]


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
        "`tools/build_sprites.py` 가 `art/source/sprites.txt` 의 icon_* 그림으로 만든 10×10 아이콘. 원본을 고치고 도구를 다시 돌린다 (문서 10 §5).",
        "",
        "| 파일 | 무엇 |",
        "|---|---|",
    ]
    icon_lines += [f"| `{name.removeprefix('icons/')}` | {description} |" for name, description in sorted(made) if name.startswith("icons/")]
    (OUTPUT / "icons" / "README.md").write_text("\n".join(icon_lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
