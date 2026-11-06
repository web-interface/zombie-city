## [파일] scripts/shared/spatial_grid.gd
## [하는 일] 칸 나누기: 화면을 일정한 크기의 칸으로 나눠 물체 번호를 칸에 담아 두고, "이 근처에 뭐가 있나"를 가까운 칸만 보고 빠르게 찾는다. 매 프레임 다시 담으므로, 칸 배열은 지우지 않고 비워서 재사용한다 (새로 만드는 비용을 줄이려고).
## [쓰는 곳] scripts/world/zombie_horde.gd 가 매 프레임 좀비를 다시 담고, 무기·스킬·투사체가 근처 좀비를 찾을 때 쓴다.
## [근거 문서] 07·11 — 좀비 300마리 성능: 가까운 것끼리만 계산, 12 §6 (중급 폰 60fps)
class_name SpatialGrid
extends RefCounted

var cell_size: float
var _cells: Dictionary = {}          # Vector2i → Array[int] (참조라 넣을 때 복사가 일어나지 않음)
var _used_cells: Array[Vector2i] = []


func _init(new_cell_size: float) -> void:
	cell_size = new_cell_size


## 칸은 남겨 두고 내용만 비운다 (다음 프레임에 그대로 다시 씀)
func clear() -> void:
	for cell: Vector2i in _used_cells:
		(_cells[cell] as Array).clear()
	_used_cells.clear()


func insert(item_index: int, position: Vector2) -> void:
	var cell := _cell_of(position)
	if not _cells.has(cell):
		_cells[cell] = []
	var items: Array = _cells[cell]
	if items.is_empty():
		_used_cells.append(cell)
	items.append(item_index)


## 중심에서 radius 안에 '있을 수도 있는' 물체 번호들을 result 에 담는다 (result 는 부르는 쪽이 재사용).
## 정확한 거리는 부르는 쪽이 다시 확인한다.
func collect_nearby(center: Vector2, radius: float, result: Array[int]) -> void:
	result.clear()
	var low := _cell_of(center - Vector2(radius, radius))
	var high := _cell_of(center + Vector2(radius, radius))
	for cell_y: int in range(low.y, high.y + 1):
		for cell_x: int in range(low.x, high.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			if _cells.has(cell):
				result.append_array(_cells[cell])


func _cell_of(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.y / cell_size))
