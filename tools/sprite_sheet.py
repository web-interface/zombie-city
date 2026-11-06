"""
[파일] tools/sprite_sheet.py
[하는 일] 동작 묶음(걷기 4장 × 3방향 + 쓰러지기 3장) 공통 도구: 줄 배치, 걷는 자세(몸 1점 내려감), 다리·모자 찍기, 쓰러지기 3장, 하얀 실루엣과 함께 저장.
[쓰는 곳] tools/build_sprites.py(생존자) · tools/sprite_zombies.py(좀비·보스)가 불러 쓴다. tools/pixel_png.py 를 쓴다.
[근거 문서] 06 그림 규칙(걷기 4장·3방향·쓰러지기 3장), 11 §11 그림 만드는 길
"""
from __future__ import annotations

from pathlib import Path

from pixel_png import Canvas, PixelMap, save_png

PROJECT = Path(__file__).resolve().parent.parent
SOURCE = PROJECT / "art" / "source"
OUTPUT = PROJECT / "art" / "sprites"
FRAME = 16

# 동작 묶음 한 줄 = 동작 하나. 칸(가로)이 장면 순서다. 게임 코드(scripts/world/sprite_sheet_layout.gd)와 순서가 같아야 한다.
HUMAN_ROWS = ["idle_down", "idle_up", "idle_side", "walk_down", "walk_up", "walk_side", "death"]
ZOMBIE_ROWS = ["walk_down", "walk_up", "walk_side", "death"]
WALK_CONTACT_FRAMES = (0, 2)   # 발을 내딛는 장면: 몸이 1점 내려간다

Parts = dict[str, PixelMap]
Palette = dict[str, str]
Made = list[tuple[str, str]]


def frames_in_row(row_name: str) -> int:
    if row_name.startswith("idle"):
        return 2
    if row_name == "death":
        return 3
    return 4


def build_sheet(make_frame, row_names: list[str], frame_size: int = FRAME) -> Canvas:
    sheet = Canvas(frame_size * 4, frame_size * len(row_names))
    for row_index, row_name in enumerate(row_names):
        for frame_index in range(frames_in_row(row_name)):
            sheet.paste(make_frame(row_name, frame_index), frame_index * frame_size, row_index * frame_size)
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


def stamp_legs(canvas: Canvas, parts: Parts, palette: Palette, direction: str, action: str, index: int, prefix: str = "legs") -> None:
    """다리를 가운데에 찍는다. prefix 로 다른 다리 묶음(예: 마른 다리)을 고를 수 있다."""
    if action == "walk" and index in WALK_CONTACT_FRAMES:
        if direction == "side":
            name = "side_stride" if index == 0 else "side_cross"
        else:
            name = "contact_a" if index == 0 else "contact_b"
        leg_map = parts[f"{prefix}_{name}"]
        canvas.stamp(leg_map, (FRAME - leg_map.width) // 2, 13, palette)
        return
    leg_map = parts[f"{prefix}_side_stand" if direction == "side" else f"{prefix}_stand"]
    canvas.stamp(leg_map, (FRAME - leg_map.width) // 2, 12, palette)


def stamp_hat(canvas: Canvas, parts: Parts, palette: Palette, hat: str, direction: str, head_left: int, head_top: int) -> None:
    if hat != "none":
        canvas.stamp(parts[f"hat_{hat}_{direction}"], head_left, head_top - 1, palette)


def save_with_flash(sheet: Canvas, name: str, description: str) -> Made:
    save_png(sheet, OUTPUT / f"{name}.png")
    save_png(sheet.white_silhouette(), OUTPUT / f"{name}_flash.png")
    return [(f"{name}.png", description), (f"{name}_flash.png", f"{name} 의 하얀 실루엣 (맞았을 때 잠깐)")]
