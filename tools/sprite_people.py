"""
[파일] tools/sprite_people.py
[하는 일] 생존자 동작 묶음(16×16: 서 있기 2장·걷기 4장 × 3방향·쓰러지기 3장)을 만든다. 옷마다 머리·몸통·다리 부품(예: 줄무늬 유니폼, 사냥 조끼, 흙 묻은 바지)과 모자를 바꾸고,
           멘 배트·글러브·털 망토·개 목줄 같은 덧그림을 몸 뒤나 앞에 얹는다.
[쓰는 곳] tools/build_sprites.py 가 부른다 → art/sprites/survivor_<옷>.png (+ _flash). 원본: art/source/parts_people.txt, 옷 표: outfits.json 의 human_outfits.
[근거 문서] 04 §2 생존자 모습·전직 옷차림, 06 그림 규칙, 14 §3-1 새 생존자(야구선수·사냥꾼)
"""
from __future__ import annotations

from dataclasses import dataclass

from pixel_png import Canvas
from sprite_sheet import FRAME, HUMAN_ROWS, Made, Palette, Parts, build_sheet, death_frame, save_with_flash, stamp_hat, stamp_legs, walk_pose


@dataclass(frozen=True)
class Overlay:
    """덧그림 한 장: 어느 방향에서, 어느 부품을, 무엇을 기준으로 (x, y) 만큼 옮겨, 몸 뒤(behind)·앞에 찍는지."""
    direction: str
    part: str
    anchor: str            # body(몸 — 걸음 따라 1점 내려감) · head(머리) · left_arm / right_arm(보는 사람 기준 왼팔·오른팔) · side_arm(옆모습 팔)
    x: int
    y: int
    behind: bool = False


# 옷 표(outfits.json)의 "extras" 이름 → 덧그림들. 앞모습에서 보는 사람 왼쪽 = 생존자의 오른손.
OVERLAYS: dict[str, list[Overlay]] = {
    "bat": [Overlay("down", "bat_down", "body", 11, 2, behind=True), Overlay("up", "bat_up", "body", 2, 2),
            Overlay("side", "bat_side", "body", 2, 2, behind=True)],
    "glove": [Overlay("down", "glove", "right_arm", -1, 2), Overlay("up", "glove", "left_arm", -1, 2)],
    "apron_skirt": [Overlay("down", "apron_skirt_down", "body", 6, 12), Overlay("side", "apron_skirt_side", "body", 6, 12)],
    "fur_cape": [Overlay("down", "fur_cape_down_back", "body", 2, 8, behind=True), Overlay("down", "fur_cape_down", "body", 3, 7),
                 Overlay("up", "fur_cape_up", "body", 3, 7), Overlay("side", "fur_cape_side_back", "body", 3, 7, behind=True),
                 Overlay("side", "fur_cape_side", "body", 5, 7)],
    "leash": [Overlay("down", "leash_down", "left_arm", -1, 3), Overlay("up", "leash_up", "right_arm", 0, 3),
              Overlay("side", "leash_side", "side_arm", 1, 3)],
    "scoped_crossbow": [Overlay("down", "crossbow_down_back", "body", 1, 6, behind=True), Overlay("up", "crossbow_up", "body", 3, 5),
                        Overlay("side", "crossbow_side_back", "body", 1, 4, behind=True)],
}


def build_survivor_sheets(parts: Parts, colors: dict) -> Made:
    made: Made = []
    for outfit_name, outfit in colors["human_outfits"].items():
        palette = {**colors["human_common"], **{key: value for key, value in outfit.items() if len(key) == 1}}
        make_frame = lambda row, index, palette=palette, outfit=outfit: human_frame(parts, palette, outfit, row, index)
        sheet = build_sheet(make_frame, HUMAN_ROWS)
        made += save_with_flash(sheet, f"survivor_{outfit_name}", f"생존자 옷 '{outfit_name}' 동작 묶음 (16×16, 줄: {', '.join(HUMAN_ROWS)})")
    return made


def human_frame(parts: Parts, palette: Palette, outfit: dict, row_name: str, index: int) -> Canvas:
    if row_name == "death":
        return death_frame(human_frame(parts, palette, outfit, "idle_down", 0), index)
    direction, action, body_drop = walk_pose(row_name, index)
    left_swing, right_swing = arm_swing(action, index)
    breathing = 1 if action == "idle" and index == 1 else 0
    head_top = 1 + body_drop + breathing
    anchors = {
        "body": (0, body_drop), "head": (4, head_top),
        "left_arm": (3, 8 + body_drop + left_swing), "right_arm": (11, 8 + body_drop + right_swing),
        "side_arm": (7 + left_swing - right_swing, 8 + body_drop),
    }
    overlays = [overlay for name in outfit.get("extras", []) for overlay in OVERLAYS[name] if overlay.direction == direction]
    canvas = Canvas(FRAME, FRAME)
    stamp_overlays(canvas, parts, palette, [overlay for overlay in overlays if overlay.behind], anchors)
    stamp_legs(canvas, parts, palette, direction, action, index, outfit.get("legs", "legs"))
    canvas.stamp(parts[f"{outfit.get('torso', 'torso')}_{direction}"], 5, 8 + body_drop, palette)
    if direction == "side":
        canvas.stamp(parts["arm_side"], *anchors["side_arm"], palette)
    else:
        canvas.stamp(parts["arm_left"], *anchors["left_arm"], palette)
        canvas.stamp(parts["arm_right"], *anchors["right_arm"], palette)
    canvas.stamp(parts[f"{outfit.get('head', 'head')}_{direction}"], 4, head_top, palette)
    stamp_hat(canvas, parts, palette, outfit["hat"], direction, 4, head_top)
    stamp_overlays(canvas, parts, palette, [overlay for overlay in overlays if not overlay.behind], anchors)
    return canvas


def stamp_overlays(canvas: Canvas, parts: Parts, palette: Palette, overlays: list[Overlay], anchors: dict[str, tuple[int, int]]) -> None:
    for overlay in overlays:
        anchor_x, anchor_y = anchors[overlay.anchor]
        canvas.stamp(parts[overlay.part], anchor_x + overlay.x, anchor_y + overlay.y, palette)


def arm_swing(action: str, index: int) -> tuple[int, int]:
    """걸을 때 팔을 번갈아 흔든다: (왼팔, 오른팔) 이 1점씩 내려감."""
    if action != "walk":
        return 0, 0
    return {0: (1, 0), 2: (0, 1)}.get(index, (0, 0))
