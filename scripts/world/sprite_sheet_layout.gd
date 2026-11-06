## [파일] scripts/world/sprite_sheet_layout.gd
## [하는 일] 동작 묶음 그림(art/sprites/survivor_*.png, zombie_*.png)에서 어느 줄이 어떤 동작이고 몇 장인지 정한 표. 그림 도구(tools/build_sprites.py 의 HUMAN_ROWS·ZOMBIE_ROWS)와 순서가 같아야 한다.
## [쓰는 곳] scripts/world/survivor_animator.gd, scripts/world/zombie_horde.gd
## [근거 문서] 06 그림 규칙(걷기 4장·3방향·쓰러지기 3장), 11 §9
class_name SpriteSheetLayout
extends RefCounted

const COLUMNS := 4

## 생존자 묶음: 줄 번호와 장 수
const HUMAN_ROW_COUNT := 7
const HUMAN_ROWS := {
	"idle_down": [0, 2], "idle_up": [1, 2], "idle_side": [2, 2],
	"walk_down": [3, 4], "walk_up": [4, 4], "walk_side": [5, 4],
	"death": [6, 3],
}

## 좀비 묶음
const ZOMBIE_ROW_COUNT := 4
const ZOMBIE_ROWS := {
	"walk_down": [0, 4], "walk_up": [1, 4], "walk_side": [2, 4], "death": [3, 3],
}

## 보스 묶음 (24×24): 1줄 걷기 4장, 2줄 쓰러지기 3장
const BOSS_ROW_COUNT := 2
const BOSS_ROWS := {
	"walk_down": [0, 4], "walk_up": [0, 4], "walk_side": [0, 4], "death": [1, 3],
}


## 방향 → 걷기 동작 이름 (매 프레임 글자를 이어 붙이지 않게 미리 만들어 둠)
const WALK_ACTIONS := {"down": "walk_down", "up": "walk_up", "side": "walk_side"}


## 움직이는 방향으로 그림 방향을 고른다. 옆모습은 오른쪽 그림을 좌우로 뒤집어 왼쪽에 쓴다.
static func direction_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "side"
	return "up" if direction.y < 0.0 else "down"


## 동작 이름과 장 번호 → 그림 묶음에서의 칸 번호 (Sprite2D.frame)
static func frame_index(rows: Dictionary, action_name: String, frame_number: int) -> int:
	var row_info: Array = rows[action_name]
	var row_index: int = row_info[0]
	var frames_in_row: int = row_info[1]
	return row_index * COLUMNS + (frame_number % frames_in_row)
