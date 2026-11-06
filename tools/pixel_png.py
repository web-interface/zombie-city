"""
[파일] tools/pixel_png.py
[하는 일] 픽셀 그림 기본 도구: 글자 지도 파일 읽기(@part / @sprite), 점 단위 캔버스(겹쳐 찍기·돌리기·어둡게·하얀 실루엣), PNG 저장. 파이썬 기본 라이브러리만 쓴다.
[쓰는 곳] tools/build_sprites.py 가 불러 쓴다.
[근거 문서] 06 그림 규칙, 11 §9 픽셀 그림 만드는 길
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

EMPTY = "."


class PixelMap:
    """글자 지도 하나 (부품 또는 한 장 그림). rows 의 글자 하나가 점 하나다."""

    def __init__(self, name: str, width: int, height: int, rows: list[str]) -> None:
        self.name = name
        self.width = width
        self.height = height
        self.rows = rows


def read_pixel_maps(path: Path) -> dict[str, PixelMap]:
    """'@part 이름 가로x세로' 또는 '@sprite 이름 가로x세로' 다음 줄들을 지도로 읽는다. '#' 줄과 빈 줄은 건너뛴다."""
    maps: dict[str, PixelMap] = {}
    current: PixelMap | None = None
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.rstrip()
        if line.startswith("#") or not line.strip():
            continue
        if line.startswith("@"):
            _check_complete(current, path)
            current = _start_map(line, path, line_number)
            maps[current.name] = current
            continue
        if current is None:
            raise ValueError(f"{path.name}:{line_number} — '@part' 또는 '@sprite' 줄보다 그림이 먼저 나옴")
        if len(line) != current.width:
            raise ValueError(f"{path.name}:{line_number} — '{current.name}' 의 줄 길이 {len(line)}, 가로 {current.width} 여야 함")
        current.rows.append(line)
    _check_complete(current, path)
    return maps


def _start_map(header: str, path: Path, line_number: int) -> PixelMap:
    parts = header.split()
    if len(parts) != 3 or "x" not in parts[2]:
        raise ValueError(f"{path.name}:{line_number} — 머리줄 모양은 '@part 이름 16x16' 이어야 함")
    width_text, height_text = parts[2].split("x")
    return PixelMap(parts[1], int(width_text), int(height_text), [])


def _check_complete(pixel_map: PixelMap | None, path: Path) -> None:
    if pixel_map is not None and len(pixel_map.rows) != pixel_map.height:
        raise ValueError(f"{path.name} — '{pixel_map.name}' 줄 수 {len(pixel_map.rows)}, 세로 {pixel_map.height} 여야 함")


class Canvas:
    """색(#rrggbb) 또는 None(투명)을 담는 점 격자."""

    def __init__(self, width: int, height: int) -> None:
        self.width = width
        self.height = height
        self.pixels: list[list[str | None]] = [[None] * width for _ in range(height)]

    def stamp(self, pixel_map: PixelMap, left: int, top: int, palette: dict[str, str]) -> None:
        """지도를 (left, top) 에 겹쳐 찍는다. '.' 은 아래 그림을 그대로 둔다. 캔버스 밖은 버린다."""
        for row_index, row in enumerate(pixel_map.rows):
            for column_index, letter in enumerate(row):
                if letter == EMPTY:
                    continue
                x = left + column_index
                y = top + row_index
                if 0 <= x < self.width and 0 <= y < self.height:
                    if letter not in palette:
                        raise KeyError(f"'{pixel_map.name}' 의 글자 '{letter}' 에 해당하는 색이 팔레트에 없음")
                    self.pixels[y][x] = palette[letter]

    def paste(self, other: Canvas, left: int, top: int) -> None:
        for y in range(other.height):
            for x in range(other.width):
                color = other.pixels[y][x]
                if color is not None:
                    self.pixels[top + y][left + x] = color

    def shifted_down(self, amount: int) -> Canvas:
        result = Canvas(self.width, self.height)
        for y in range(self.height - amount):
            result.pixels[y + amount] = list(self.pixels[y])
        return result

    def rotated_clockwise(self) -> Canvas:
        """정사각형 그림을 시계 방향으로 90도 돌린다 (쓰러지는 동작)."""
        result = Canvas(self.height, self.width)
        for y in range(result.height):
            for x in range(result.width):
                result.pixels[y][x] = self.pixels[self.height - 1 - x][y]
        return result

    def rotated_counter_clockwise(self) -> Canvas:
        return self.rotated_clockwise().rotated_clockwise().rotated_clockwise()

    def resting_on_floor(self) -> Canvas:
        """그림의 맨 아래 칠한 줄이 캔버스 바닥에 닿게 내린다."""
        lowest_row = max((y for y in range(self.height) if any(self.pixels[y])), default=self.height - 1)
        return self.shifted_down(self.height - 1 - lowest_row)

    def darkened(self, ratio: float) -> Canvas:
        result = Canvas(self.width, self.height)
        for y in range(self.height):
            result.pixels[y] = [_darken(color, ratio) if color else None for color in self.pixels[y]]
        return result

    def white_silhouette(self) -> Canvas:
        """맞았을 때 잠깐 보여 줄 하얀 그림: 칠한 점은 모두 흰색."""
        result = Canvas(self.width, self.height)
        for y in range(self.height):
            result.pixels[y] = ["#ffffff" if color else None for color in self.pixels[y]]
        return result


def _darken(color: str, ratio: float) -> str:
    red, green, blue = (int(color[index:index + 2], 16) for index in (1, 3, 5))
    keep = 1.0 - ratio
    return "#%02x%02x%02x" % (int(red * keep), int(green * keep), int(blue * keep))


def save_png(canvas: Canvas, path: Path, alpha_rows: list[list[int]] | None = None) -> None:
    """캔버스를 RGBA PNG 로 저장한다. alpha_rows 를 주면 색 대신 흰색 + 그 투명도로 저장한다 (빛 그림용)."""
    raw = bytearray()
    for y in range(canvas.height):
        raw.append(0)
        for x in range(canvas.width):
            if alpha_rows is not None:
                raw += bytes((255, 255, 255, alpha_rows[y][x]))
                continue
            color = canvas.pixels[y][x]
            if color is None:
                raw += b"\x00\x00\x00\x00"
            else:
                raw += bytes((int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16), 255))
    path.parent.mkdir(parents=True, exist_ok=True)
    header = struct.pack(">IIBBBBB", canvas.width, canvas.height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", header) + _chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + _chunk(b"IEND", b"")
    path.write_bytes(png)


def _chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
