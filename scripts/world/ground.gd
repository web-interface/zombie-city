## [파일] scripts/world/ground.gd
## [하는 일] 도심 도로 바닥을 그린다: 아스팔트 타일(금·기름 얼룩·맨홀 섞임), 블록마다 인도, 노란 점선 차선, 교차로 횡단보도. 끝없이 이어지는 바둑판 도시를 카메라가 보는 곳만 그린다.
## [쓰는 곳] scenes/run.tscn 의 World/Ground. run.gd 가 update() 로 카메라 위치를 넘긴다.
## [근거 문서] 04 §6 지역(도심 도로), 06 밤 분위기, data/run_rules.json city_layout
class_name Ground
extends Node2D

const TILE_SIZE := 16
const TILES_TEXTURE: Texture2D = preload("res://art/sprites/tiles_downtown.png")
const PLAIN_ASPHALT_TILES := 4
const CRACK_TILE := 4
const OIL_TILE := 5
const MANHOLE_TILE := 6
const SIDEWALK_TILE := 7
const LANE_COLOR := Color("8c7a32")
const CROSSWALK_COLOR := Color(0.75, 0.77, 0.8, 0.55)
const CURB_COLOR := Color("555b66")

var _block_spacing: float
var _road_half_width: float
var _view_center: Vector2 = Vector2.ZERO
var _view_size: Vector2 = Vector2(180, 320)


func setup(city_layout: Dictionary) -> void:
	_block_spacing = float(city_layout["block_spacing"])
	_road_half_width = float(city_layout["road_half_width"])
	z_index = -10


func update(view_center: Vector2, view_size: Vector2) -> void:
	_view_center = view_center.round()
	_view_size = view_size
	queue_redraw()


## 이 자리가 인도(블록 안)인가 — 소품·착륙 지점 고를 때도 씀
func is_sidewalk(at_position: Vector2) -> bool:
	var inside_x := fposmod(at_position.x, _block_spacing)
	var inside_y := fposmod(at_position.y, _block_spacing)
	var low := _road_half_width
	var high := _block_spacing - _road_half_width
	return inside_x > low and inside_x < high and inside_y > low and inside_y < high


func _draw() -> void:
	var top_left := _view_center - _view_size * 0.5 - Vector2.ONE * TILE_SIZE
	var bottom_right := _view_center + _view_size * 0.5 + Vector2.ONE * TILE_SIZE
	_draw_tiles(top_left, bottom_right)
	_draw_lanes(top_left, bottom_right)
	_draw_crosswalks_and_curbs(top_left, bottom_right)


func _draw_tiles(top_left: Vector2, bottom_right: Vector2) -> void:
	for tile_y: int in range(floori(top_left.y / TILE_SIZE), ceili(bottom_right.y / TILE_SIZE)):
		for tile_x: int in range(floori(top_left.x / TILE_SIZE), ceili(bottom_right.x / TILE_SIZE)):
			var world_position := Vector2(tile_x, tile_y) * TILE_SIZE
			var tile_index := _tile_kind(tile_x, tile_y, world_position)
			var source := Rect2(tile_index * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
			draw_texture_rect_region(TILES_TEXTURE, Rect2(world_position, Vector2.ONE * TILE_SIZE), source)


func _tile_kind(tile_x: int, tile_y: int, world_position: Vector2) -> int:
	if is_sidewalk(world_position + Vector2.ONE * TILE_SIZE * 0.5):
		return SIDEWALK_TILE
	var roll := absi(hash(Vector2i(tile_x, tile_y))) % 100
	if roll < 2:
		return MANHOLE_TILE
	if roll < 7:
		return CRACK_TILE
	if roll < 10:
		return OIL_TILE
	return roll % PLAIN_ASPHALT_TILES


func _draw_lanes(top_left: Vector2, bottom_right: Vector2) -> void:
	for column: int in range(floori(top_left.x / _block_spacing), ceili(bottom_right.x / _block_spacing) + 1):
		var x := column * _block_spacing
		for y: int in range(floori(top_left.y / 12.0) * 12, int(bottom_right.y), 12):
			if absf(fposmod(y + _block_spacing * 0.5, _block_spacing) - _block_spacing * 0.5) > _road_half_width + 12.0:
				draw_rect(Rect2(x - 1, y, 2, 6), LANE_COLOR)
	for row: int in range(floori(top_left.y / _block_spacing), ceili(bottom_right.y / _block_spacing) + 1):
		var y := row * _block_spacing
		for x: int in range(floori(top_left.x / 12.0) * 12, int(bottom_right.x), 12):
			if absf(fposmod(x + _block_spacing * 0.5, _block_spacing) - _block_spacing * 0.5) > _road_half_width + 12.0:
				draw_rect(Rect2(x, y - 1, 6, 2), LANE_COLOR)


func _draw_crosswalks_and_curbs(top_left: Vector2, bottom_right: Vector2) -> void:
	var size := _block_spacing - _road_half_width * 2.0
	for row: int in range(floori(top_left.y / _block_spacing) - 1, ceili(bottom_right.y / _block_spacing) + 1):
		for column: int in range(floori(top_left.x / _block_spacing) - 1, ceili(bottom_right.x / _block_spacing) + 1):
			var corner := Vector2(column, row) * _block_spacing
			draw_rect(Rect2(corner + Vector2.ONE * _road_half_width, Vector2.ONE * size), CURB_COLOR, false, 2.0)
			for offset: int in range(int(-_road_half_width) + 4, int(_road_half_width) - 2, 6):
				draw_rect(Rect2(corner + Vector2(offset, -_road_half_width - 9), Vector2(3, 8)), CROSSWALK_COLOR)
				draw_rect(Rect2(corner + Vector2(-_road_half_width - 9, offset), Vector2(8, 3)), CROSSWALK_COLOR)
