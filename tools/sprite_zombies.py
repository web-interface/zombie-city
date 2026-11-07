"""
[파일] tools/sprite_zombies.py
[하는 일] 좀비 동작 묶음(16×16)과 보스 동작 묶음(24×24), 생존자 곁 동물(사냥개)을 만든다. 서서 걷는 좀비는 '몸 설계'(머리·몸통·팔·다리 부품과 자리)만 바꿔 같은 방법으로 찍고, 기어다니는 좀비·들개 좀비는 따로 그린 장면으로, 보스는 걷기 2장(a·b)을 a·b·a·b 로 쓴다.
[쓰는 곳] tools/build_sprites.py 가 부른다 → art/sprites/zombie_*.png, boss_*.png (+ _flash), hunting_dog.png. 원본: art/source/parts_zombies.txt · bosses.txt, 색: outfits.json 의 zombie_kinds · companions.
[근거 문서] 06 그림 규칙(16×16·걷기 4장·비대칭), 14 §1-2 새 좀비 6종 · §1-3 보스 3종 · §3-1 사냥개, 11 §11
"""
from __future__ import annotations

from dataclasses import dataclass

from pixel_png import Canvas, save_png
from sprite_sheet import FRAME, OUTPUT, ZOMBIE_ROWS, Made, Palette, Parts, build_sheet, death_frame, save_with_flash, stamp_hat, stamp_legs, walk_pose

HEAD_SWAY = {0: -1, 2: 1}            # 좀비는 걸을 때 머리를 좌우로 흔든다 (장면 번호 → 옆으로 몇 점)
DROOL_LENGTHS = (1, 2, 3, 1)         # 침 좀비: 턱에서 흐르는 침 길이가 장면마다 늘었다 줄어든다
SHIELD_GLASS_COLOR = "#a9d6f0"       # 진압 방패 유리 색 (뒤 몸이 비쳐 보이게 섞는다)
SHIELD_GLASS_STRENGTH = 0.45
BOSS_TITLES = {"butcher": "도살자", "demolisher": "철거반장", "mother": "거대 감염체"}
ZOMBIE_TITLES = {"walker": "걷는 좀비", "runner": "달리는 좀비", "hazmat": "방호복 좀비", "crawler": "기어다니는 좀비",
                 "spitter": "침 뱉는 좀비", "bloater": "부푼 좀비", "riot": "진압복 좀비", "screamer": "비명 좀비", "hound": "들개 좀비", "brute": "덩치 좀비"}


# ───────── 덧그림: 침·방패 (몸을 다 찍은 뒤 그 위에) ─────────

def draw_drool(canvas: Canvas, parts: Parts, palette: Palette, direction: str, index: int, head_left: int, head_top: int) -> None:
    """초록 침이 턱 한쪽(왼쪽으로 치우침)에서 흘러내린다. 뒷모습에선 안 보인다."""
    if direction == "up":
        return
    drool_x = head_left + (8 if direction == "side" else 4)
    drool_top = head_top + 8
    length = DROOL_LENGTHS[index]
    for step in range(length):
        letter = "J" if step == length - 1 else "j"
        if drool_top + step < FRAME:
            canvas.pixels[drool_top + step][drool_x] = palette[letter]


def draw_riot_shield(canvas: Canvas, parts: Parts, palette: Palette, direction: str, index: int, head_left: int, head_top: int) -> None:
    """앞에 든 투명 방패: 테두리는 칠하고 가운데는 뒤 몸 색에 유리 색을 섞는다. 걸음에 따라 1점 흔들린다."""
    shield = parts[f"riot_shield_{direction}"]
    bob = 1 if index in (1, 3) else 0
    left = {"down": 2, "up": 11, "side": 11}[direction]
    top = 6 + bob
    canvas.glaze(shield, left, top, SHIELD_GLASS_COLOR, SHIELD_GLASS_STRENGTH)
    canvas.stamp(shield, left, top, palette)


# ───────── 서서 걷는 좀비 ─────────

@dataclass(frozen=True)
class ZombieBody:
    """서서 걷는 좀비의 몸 설계. 부품 이름은 '<앞부분>_<방향>' (방향 = down 앞모습 / up 뒷모습 / side 옆모습)."""
    head: str = "zhead"
    torso: str = "ztorso"
    arms: str = "zarm"
    legs: str = "legs"
    head_top: int = 1          # 구부정하거나 어깨에 파묻히면 머리가 내려온다
    torso_top: int = 8
    head_forward: int = 0      # 옆모습에서 머리가 몸보다 앞으로 나온 정도 (구부정)
    pulse: str = ""            # 'vV' 처럼 두 글자: 1·3번째 장면에서 앞 글자 색을 뒷 글자 색으로 (핏줄이 꿈틀)
    extras: tuple = ()         # 몸을 다 찍은 뒤 그 위에 그리는 덧그림 함수들


BODIES: dict[str, ZombieBody] = {
    "spitter": ZombieBody(head="spitter_head", torso="spitter_torso", arms="spitter_arm", head_top=2, torso_top=7, head_forward=1, extras=(draw_drool,)),
    "bloater": ZombieBody(torso="bloater_torso", torso_top=6, pulse="vV"),
    "riot": ZombieBody(extras=(draw_riot_shield,)),
    "screamer": ZombieBody(head="screamer_head", torso="screamer_torso", arms="screamer_arm", legs="thin_legs", head_top=0),
    "brute": ZombieBody(head="brute_head", torso="brute_torso", arms="brute_arm", head_top=2, torso_top=6),
}


def upright_zombie_frame(parts: Parts, palette: Palette, body: ZombieBody, hat: str, row_name: str, index: int) -> Canvas:
    """좀비는 팔을 앞으로 뻗고, 머리를 좌우로 흔들며 절뚝거린다 (좌우가 똑같지 않게)."""
    if row_name == "death":
        return death_frame(upright_zombie_frame(parts, palette, body, hat, "walk_down", 1), index)
    direction, action, body_drop = walk_pose(row_name, index)
    if body.pulse and index in (1, 3):
        palette = {**palette, body.pulse[0]: palette[body.pulse[1]]}
    canvas = Canvas(FRAME, FRAME)
    stamp_legs(canvas, parts, palette, direction, action, index, body.legs)
    torso = parts[f"{body.torso}_{direction}"]
    torso_left = (FRAME - torso.width) // 2
    torso_top = body.torso_top + body_drop
    canvas.stamp(torso, torso_left, torso_top, palette)
    stamp_zombie_arms(canvas, parts, palette, body.arms, direction, torso_left, torso.width, torso_top, index)
    head = parts[f"{body.head}_{direction}"]
    head_left = (FRAME - head.width) // 2 + HEAD_SWAY.get(index, 0) + (body.head_forward if direction == "side" else 0)
    head_top = body.head_top + body_drop
    canvas.stamp(head, head_left, head_top, palette)
    stamp_hat(canvas, parts, palette, hat, direction, head_left, head_top)
    for draw_extra in body.extras:
        draw_extra(canvas, parts, palette, direction, index, head_left, head_top)
    return canvas


def stamp_zombie_arms(canvas: Canvas, parts: Parts, palette: Palette, arms: str, direction: str, torso_left: int, torso_width: int, torso_top: int, index: int) -> None:
    """팔은 몸통 양 끝에 붙인다. 뒷모습 팔 부품이 없으면 (팔이 몸 앞이라) 안 그린다. 걸음마다 두 팔이 번갈아 1점 처진다."""
    reach = 1 if index in (1, 3) else 0
    if direction == "side":
        canvas.stamp(parts[f"{arms}_side"], torso_left + torso_width - 2, torso_top + 1 + reach, palette)
        return
    if f"{arms}_{direction}_left" not in parts:
        return
    left_arm = parts[f"{arms}_{direction}_left"]
    right_arm = parts[f"{arms}_{direction}_right"]
    canvas.stamp(left_arm, torso_left - 1, torso_top + 1 + reach, palette)
    canvas.stamp(right_arm, torso_left + torso_width - right_arm.width + 1, torso_top + 1 + (1 - reach), palette)


# ───────── 기어다니는 좀비·들개 좀비 (따로 그린 장면) ─────────

def crawler_frame(parts: Parts, palette: Palette, row_name: str, index: int) -> Canvas:
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


def hound_frame(parts: Parts, palette: Palette, row_name: str, index: int) -> Canvas:
    """들개 좀비: 네 발 짐승이라 방향마다 따로 그린 장면을 쓴다. 옆모습은 달리기 4장, 앞·뒤는 2장 번갈아. 바닥에 발을 붙인다."""
    if row_name == "death":
        if index == 0:
            return hound_frame(parts, palette, "walk_side", 1).shifted_down(1)
        lying = Canvas(FRAME, FRAME)
        lying.stamp(parts["hound_lying"], 0, FRAME - parts["hound_lying"].height, palette)
        return lying if index == 1 else lying.darkened(0.35)
    direction = row_name.split("_")[1]
    letter = "abcd"[index] if direction == "side" else "ab"[index % 2]
    scene = parts[f"hound_{direction}_{letter}"]
    canvas = Canvas(FRAME, FRAME)
    canvas.stamp(scene, (FRAME - scene.width) // 2, FRAME - scene.height, palette)
    return canvas


# ───────── 묶음 만들기 ─────────

def zombie_palette(colors: dict, kind: dict) -> Palette:
    """다리 부품의 p(바지)·f(발)는 좀비 바지·맨발로 칠한다. 종류에 f 가 있으면(장화) 그것을 쓴다."""
    return {**colors["zombie_common"], "p": kind["q"], "f": kind["z"], **{key: value for key, value in kind.items() if len(key) == 1}}


def build_zombie_sheets(parts: Parts, colors: dict) -> Made:
    made: Made = []
    for kind_name, kind in colors["zombie_kinds"].items():
        palette = zombie_palette(colors, kind)
        if kind_name == "crawler":
            make_frame = lambda row, index, palette=palette: crawler_frame(parts, palette, row, index)
        elif kind_name == "hound":
            make_frame = lambda row, index, palette=palette: hound_frame(parts, palette, row, index)
        else:
            body = BODIES.get(kind_name, ZombieBody())
            make_frame = lambda row, index, palette=palette, body=body, hat=kind["hat"]: upright_zombie_frame(parts, palette, body, hat, row, index)
        sheet = build_sheet(make_frame, ZOMBIE_ROWS)
        title = ZOMBIE_TITLES.get(kind_name, kind_name)
        made += save_with_flash(sheet, f"zombie_{kind_name}", f"{title} '{kind_name}' 동작 묶음 (16×16, 줄: {', '.join(ZOMBIE_ROWS)})")
    return made


def build_boss_sheets(bosses: Parts, palette: Palette) -> Made:
    """bosses.txt 의 boss_<이름>_a · _b 마다 묶음 하나: 1줄 걷기 a·b·a·b, 2줄 쓰러지기 3장 (a 를 눕힘)."""
    made: Made = []
    boss_ids = [name.removeprefix("boss_").removesuffix("_a") for name in bosses if name.endswith("_a")]
    for boss_id in boss_ids:
        standing_map = bosses[f"boss_{boss_id}_a"]
        size = standing_map.width
        sheet = Canvas(size * 4, size * 2)
        for frame_index, letter in enumerate("abab"):
            sheet.stamp(bosses[f"boss_{boss_id}_{letter}"], frame_index * size, 0, palette)
        standing = Canvas(size, size)
        standing.stamp(standing_map, 0, 0, palette)
        for frame_index in range(3):
            sheet.paste(death_frame(standing, frame_index), frame_index * size, size)
        title = BOSS_TITLES.get(boss_id, boss_id)
        made += save_with_flash(sheet, f"boss_{boss_id}", f"보스 {title} ({size}×{size}, 1줄 걷기 4장 · 2줄 쓰러지기 3장)")
    return made


def build_companion_sheets(parts: Parts, colors: dict) -> Made:
    """생존자 곁 동물(outfits.json companions): 좀비 장면 함수를 색만 바꿔 쓴다. 좀비와 같은 4줄 배치, 맞을 일이 없어 하얀 실루엣은 안 만든다."""
    made: Made = []
    scene_makers = {"hound": hound_frame}
    for name, companion in colors["companions"].items():
        palette = {key: value for key, value in companion.items() if len(key) == 1}
        make_scene = scene_makers[companion["scene"]]
        sheet = build_sheet(lambda row, index, palette=palette, make_scene=make_scene: make_scene(parts, palette, row, index), ZOMBIE_ROWS)
        save_png(sheet, OUTPUT / f"{name}.png")
        made.append((f"{name}.png", f"곁 동물 '{name}' 동작 묶음 (16×16, 좀비와 같은 줄: {', '.join(ZOMBIE_ROWS)})"))
    return made
