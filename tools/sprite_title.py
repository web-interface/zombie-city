"""
[파일] tools/sprite_title.py
[하는 일] 타이틀 화면 뒤에 까는 새벽 밤 도시 실루엣(180×90, 하늘은 투명)을 만든다: 먼 건물 줄, 아파트(동 번호), 상가 세로 간판, 빨간 네온 십자가 교회, 옥상 초록 방수 빌라, 전봇대 전깃줄. 불 켜진 창은 몇 개만.
[쓰는 곳] tools/build_sprites.py 가 부른다 → art/sprites/title_skyline.png. 게임에선 타이틀 화면 연출 뒤 배경으로 쓴다.
[근거 문서] 06 그림 규칙(밤 분위기·한국 동네 디테일·AI 티 안 나게 — 좌우 비대칭, 매끈한 그라데이션 대신 단계 색)
"""
from __future__ import annotations

import random

from pixel_png import Canvas, save_png
from sprite_sheet import OUTPUT, Made

WIDTH = 180
HEIGHT = 90
SEED = 1107   # 같은 그림이 매번 나오게 고정 (11월 7일)
FAR = "#1c2130"          # 먼 건물 (조금 밝음)
FAR_WINDOW = "#252b3b"
NEAR = "#11131a"         # 가까운 건물 (가장 어두움)
NEAR_WINDOW = "#1a1d26"
WARM_LIGHTS = ["#f2c94c", "#e8b04a", "#ffe9a0"]   # 불 켜진 창 (집마다 조금씩 다른 전등 색)
TV_LIGHT = "#7fc8d8"     # 텔레비전 켜 둔 창
PAINT = "#4a5060"        # 아파트 벽 동 번호 페인트
CROSS = "#e0463f"        # 교회 네온 십자가
CROSS_GLOW = "#5a2026"
ROOF_GREEN = "#2f4a3a"   # 한국 빌라 옥상 초록 방수 칠
WARNING_LIGHT = "#d0453c"
SIGN_COLORS = ["#c73a32", "#3fb6a8", "#f2c94c"]
SIGN_PATTERN = [0, 0, 1, 2, 0, 1, 1, 0, 2]   # 세로 간판 글자 칸 색 (위에서 아래로, 일부러 불규칙)

# 3×5 숫자 (아파트 동 번호용)
DIGITS = {
    "0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
    "5": ["###", "#..", "##.", "..#", "##."], "7": ["###", "..#", ".#.", ".#.", ".#."],
}


def build_title_skyline() -> Made:
    canvas = Canvas(WIDTH, HEIGHT)
    rng = random.Random(SEED)
    draw_far_buildings(canvas, rng)
    draw_apartment(canvas, rng, left=3, width=30, height=72, number="103", antenna_x=9)
    draw_apartment(canvas, rng, left=36, width=15, height=56, number="105", antenna_x=-1)
    draw_power_lines(canvas, pole_x=55, pole_height=44)
    draw_shops(canvas, rng, left=58)
    draw_church(canvas, rng, left=84)
    draw_office(canvas, rng, left=108)
    draw_villa(canvas, rng, left=136)
    draw_apartment(canvas, rng, left=158, width=26, height=64, number="107", antenna_x=-1)
    fill_rect(canvas, 0, HEIGHT - 2, WIDTH, 2, NEAR)
    save_png(canvas, OUTPUT / "title_skyline.png")
    return [("title_skyline.png", "타이틀 배경 새벽 밤 도시 실루엣 (180×90, 하늘 투명, 아래 맞춤)")]


def fill_rect(canvas: Canvas, left: int, top: int, width: int, height: int, color: str) -> None:
    for y in range(max(0, top), min(HEIGHT, top + height)):
        for x in range(max(0, left), min(WIDTH, left + width)):
            canvas.pixels[y][x] = color


def draw_windows(canvas: Canvas, rng: random.Random, area: tuple[int, int, int, int], step: tuple[int, int], lit_chance: float, dark: str) -> None:
    """area = (왼쪽, 위, 가로, 세로) 안에 2×1 창을 step 간격으로. 대부분 꺼져 있고 lit_chance 만큼만 켜짐."""
    left, top, width, height = area
    for y in range(top, top + height - 1, step[1]):
        for x in range(left, left + width - 2, step[0]):
            roll = rng.random()
            if roll < lit_chance * 0.15:
                color = TV_LIGHT
            elif roll < lit_chance:
                color = rng.choice(WARM_LIGHTS)
            else:
                color = dark
            fill_rect(canvas, x, y, 2, 1, color)


def draw_far_buildings(canvas: Canvas, rng: random.Random) -> None:
    """뒤쪽 먼 건물 줄: 너비·높이를 들쭉날쭉하게, 창은 거의 꺼져 있음."""
    x = -3
    while x < WIDTH:
        width = rng.randint(7, 17)
        height = rng.randint(22, 50)
        fill_rect(canvas, x, HEIGHT - height, width, height, FAR)
        draw_windows(canvas, rng, (x + 2, HEIGHT - height + 3, width - 3, height - 6), (3, 4), 0.04, FAR_WINDOW)
        x += width + rng.choice([0, 0, 1, 2])


def draw_digits(canvas: Canvas, left: int, top: int, text: str, color: str) -> None:
    for index, digit in enumerate(text):
        for row, line in enumerate(DIGITS[digit]):
            for column, mark in enumerate(line):
                if mark == "#":
                    canvas.pixels[top + row][left + index * 4 + column] = color


def draw_apartment(canvas: Canvas, rng: random.Random, left: int, width: int, height: int, number: str, antenna_x: int) -> None:
    """복도식 아파트: 꼭대기 벽에 동 번호, 옥상 물탱크, 창은 층마다 줄지어 있고 몇 집만 불이 켜짐."""
    top = HEIGHT - height
    fill_rect(canvas, left, top, width, height, NEAR)
    fill_rect(canvas, left + 3, top - 3, 6, 3, NEAR)                 # 옥상 물탱크·계단실
    if antenna_x >= 0:
        fill_rect(canvas, left + antenna_x, top - 8, 1, 5, NEAR)     # 안테나
    draw_digits(canvas, min(left + width, WIDTH) - 13, top + 2, number, PAINT)   # 화면 밖으로 잘린 동도 번호는 보이게
    draw_windows(canvas, rng, (left + 2, top + 9, width - 3, height - 12), (3, 4), 0.09, NEAR_WINDOW)


def draw_power_lines(canvas: Canvas, pole_x: int, pole_height: int) -> None:
    """전봇대와 처진 전깃줄 (한국 골목의 엉킨 전선)."""
    top = HEIGHT - pole_height
    fill_rect(canvas, pole_x, top, 1, pole_height, NEAR)
    fill_rect(canvas, pole_x - 3, top + 2, 7, 1, NEAR)
    for start_x, end_x, sag in [(0, pole_x, 6), (pole_x, WIDTH, 9), (pole_x, 120, 4)]:
        for x in range(start_x, end_x):
            ratio = (x - start_x) / max(1, end_x - start_x)
            y = top + 2 + round(sag * 4 * ratio * (1 - ratio))
            if 0 <= y < HEIGHT and canvas.pixels[y][x] is None:
                canvas.pixels[y][x] = NEAR


def draw_shops(canvas: Canvas, rng: random.Random, left: int) -> None:
    """2층 상가 둘: 세로 간판 하나(색 점이 위아래로), 가로 간판 띠, 1층 셔터는 내려가 있음."""
    fill_rect(canvas, left, HEIGHT - 22, 12, 22, NEAR)
    fill_rect(canvas, left + 12, HEIGHT - 17, 11, 17, NEAR)
    for step, color_index in enumerate(SIGN_PATTERN):
        fill_rect(canvas, left + 9, HEIGHT - 31 + step * 2, 2, 1, SIGN_COLORS[color_index])
    fill_rect(canvas, left + 13, HEIGHT - 15, 9, 2, SIGN_COLORS[1])
    draw_windows(canvas, rng, (left + 2, HEIGHT - 19, 6, 6), (3, 3), 0.3, NEAR_WINDOW)


def draw_church(canvas: Canvas, rng: random.Random, left: int) -> None:
    """작은 교회: 몸체 + 뾰족한 종탑 + 빨간 네온 십자가(한국 밤 풍경). 종탑은 가운데가 아니라 오른쪽으로 치우침."""
    fill_rect(canvas, left, HEIGHT - 28, 20, 28, NEAR)
    tower_left = left + 11
    fill_rect(canvas, tower_left, HEIGHT - 40, 7, 12, NEAR)
    for step in range(5):
        fill_rect(canvas, tower_left + step, HEIGHT - 41 - step, 7 - step * 2, 1, NEAR)
    cross_x = tower_left + 3
    cross_top = HEIGHT - 53
    fill_rect(canvas, cross_x, cross_top + 7, 1, 2, NEAR)            # 십자가를 받치는 쇠대
    draw_neon_cross(canvas, cross_x, cross_top)
    fill_rect(canvas, left + 3, HEIGHT - 20, 2, 4, rng.choice(WARM_LIGHTS))   # 새벽 기도 불빛 한 창


def draw_neon_cross(canvas: Canvas, center_x: int, top: int) -> None:
    """네온 십자가(세로 7 · 가로 3)와, 그 모양을 따라 한 점 번진 어두운 빨간 빛 (네모 상자가 아니라 십자가 둘레만)."""
    lit = [(center_x, top + row) for row in range(7)] + [(center_x - 1, top + 2), (center_x + 1, top + 2)]
    for x, y in lit:
        for near_x, near_y in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]:
            if canvas.pixels[near_y][near_x] is None:
                canvas.pixels[near_y][near_x] = CROSS_GLOW
    for x, y in lit:
        canvas.pixels[y][x] = CROSS


def draw_office(canvas: Canvas, rng: random.Random, left: int) -> None:
    """사무 건물: 촘촘한 창은 거의 꺼짐, 옥상 한쪽에 빨간 항공 경고등."""
    fill_rect(canvas, left, HEIGHT - 50, 24, 50, NEAR)
    fill_rect(canvas, left + 16, HEIGHT - 54, 5, 4, NEAR)
    canvas.pixels[HEIGHT - 55][left + 18] = WARNING_LIGHT
    draw_windows(canvas, rng, (left + 2, HEIGHT - 46, 21, 42), (3, 3), 0.05, NEAR_WINDOW)


def draw_villa(canvas: Canvas, rng: random.Random, left: int) -> None:
    """4층 빌라: 옥상 초록 방수 칠 테두리와 둥근 물탱크."""
    fill_rect(canvas, left, HEIGHT - 30, 20, 30, NEAR)
    fill_rect(canvas, left, HEIGHT - 31, 20, 1, ROOF_GREEN)
    fill_rect(canvas, left + 13, HEIGHT - 35, 4, 4, NEAR)
    draw_windows(canvas, rng, (left + 2, HEIGHT - 27, 17, 24), (4, 6), 0.18, NEAR_WINDOW)
