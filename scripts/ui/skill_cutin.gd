## [파일] scripts/ui/skill_cutin.gd
## [하는 일] 히든 스킬 컷인: 히든 스킬을 쓰면 화면이 하얗게 번쩍하고, 생존자 그림(3배)과 스킬 이름이 든 비스듬한 띠가 오른쪽에서 들어와 잠깐 멈췄다가 왼쪽으로 빠져나간다. 띠 안엔 빠르게 지나가는 속도선. 실제 시간으로 움직여서 화면이 멈춘 동안에도 보인다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 SkillRunner.hidden_skill_used 를 듣는다. 화면 멈춤 길이는 run.gd 가 같은 숫자(data/run_rules.json build.hidden_skill_cutin_seconds)로 건다.
## [근거 문서] 14 §2-5 (생존자 얼굴 띠가 지나감)·§2-7 (히든 스킬 = 컷인 + 화면 번쩍 + 큰 흔들림)
class_name SkillCutin
extends Control

const BAND_CENTER_Y_RATIO := 0.38       # 띠가 지나가는 높이 (화면 위에서 38%)
const BAND_HEIGHT := 58.0
const BAND_SLANT := 14.0                # 띠 위아래가 어긋난 정도 (비스듬하게)
const SLIDE_RATIO := 0.18               # 전체 시간 중 들어오는·나가는 데 쓰는 비율
const FLASH_SECONDS := 0.18
const PORTRAIT_SCALE := 3.0
const SPEED_LINES := 9
const SPEED_LINE_SPEED := 520.0
const BAND_FILL := Color(0.06, 0.06, 0.1, 0.94)
const BAND_EDGE := Color("ffd166")

var _skill_runner: SkillRunner
var _context: RunContext
var _total_seconds: float = 0.75
var _started_at_msec: int = -1
var _skill_name: String = ""
var _portrait: Texture2D
var _frame_size: Vector2 = Vector2(16, 16)


## Hud 가 한 줄로 만들어 붙이게
static func create(skill_runner: SkillRunner, context: RunContext) -> SkillCutin:
	var cutin := SkillCutin.new()
	cutin.setup(skill_runner, context)
	return cutin


func setup(skill_runner: SkillRunner, context: RunContext) -> void:
	_skill_runner = skill_runner
	_context = context
	_total_seconds = float(GameData.rules("build")["hidden_skill_cutin_seconds"])
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_skill_runner.hidden_skill_used.connect(_play)


func _play(skill_id: String) -> void:
	_skill_name = String(GameData.entry("skills", skill_id)["name"])
	_portrait = _current_outfit_texture()
	_frame_size = _portrait.get_size() / Vector2(SpriteSheetLayout.COLUMNS, SpriteSheetLayout.HUMAN_ROW_COUNT)
	_started_at_msec = Time.get_ticks_msec()
	visible = true


## 지금 입은 옷(전직하면 바뀜) 그림. 맞아서 하얗게 번쩍인 순간이면 보통 그림으로.
func _current_outfit_texture() -> Texture2D:
	var texture := _context.survivor.animator.texture
	var path := texture.resource_path
	if path.ends_with("_flash.png") and ResourceLoader.exists(path.replace("_flash.png", ".png")):
		return load(path.replace("_flash.png", ".png"))
	return texture


func _process(_delta: float) -> void:
	if not visible:
		return
	if _elapsed() > _total_seconds:
		visible = false
		return
	queue_redraw()


func _elapsed() -> float:
	return (Time.get_ticks_msec() - _started_at_msec) / 1000.0


func _draw() -> void:
	var elapsed := _elapsed()
	var screen := size
	if elapsed < FLASH_SECONDS:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(1, 1, 1, 0.85 * (1.0 - elapsed / FLASH_SECONDS)))
	var band_offset := _band_offset(elapsed / _total_seconds) * screen.x
	var top := screen.y * BAND_CENTER_Y_RATIO - BAND_HEIGHT * 0.5
	var band := PackedVector2Array([
		Vector2(band_offset - BAND_SLANT, top), Vector2(band_offset + screen.x + BAND_SLANT, top),
		Vector2(band_offset + screen.x - BAND_SLANT, top + BAND_HEIGHT), Vector2(band_offset - BAND_SLANT * 3.0, top + BAND_HEIGHT)])
	draw_colored_polygon(band, BAND_FILL)
	draw_rect(Rect2(band_offset - BAND_SLANT, top, screen.x + BAND_SLANT * 2.0, 2.0), BAND_EDGE)
	draw_rect(Rect2(band_offset - BAND_SLANT * 3.0, top + BAND_HEIGHT - 2.0, screen.x + BAND_SLANT * 2.0, 2.0), BAND_EDGE)
	_draw_speed_lines(band_offset, top, screen.x, elapsed)
	_draw_portrait(Vector2(band_offset + 8.0, top + BAND_HEIGHT - 2.0))
	var text_left := band_offset + 8.0 + _frame_size.x * PORTRAIT_SCALE + 6.0
	draw_string(PixelUi.FONT_SMALL, Vector2(text_left, top + 18.0), "히든 스킬", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelUi.SIZE_SMALL, BAND_EDGE)
	draw_string_outline(PixelUi.FONT_BOLD, Vector2(text_left, top + 36.0), _skill_name, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelUi.SIZE_REGULAR, 2, Color(0.4, 0.25, 0.0))
	draw_string(PixelUi.FONT_BOLD, Vector2(text_left, top + 36.0), _skill_name, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelUi.SIZE_REGULAR, Color.WHITE)


## 들어오기(오른쪽 → 가운데) · 멈춤 · 나가기(가운데 → 왼쪽). 1 = 화면 오른쪽 밖, 0 = 제자리, -1 = 왼쪽 밖
func _band_offset(progress: float) -> float:
	if progress < SLIDE_RATIO:
		return 1.0 - ease(progress / SLIDE_RATIO, 0.4)
	if progress > 1.0 - SLIDE_RATIO:
		return -ease((progress - (1.0 - SLIDE_RATIO)) / SLIDE_RATIO, 2.5)
	return 0.0


## 띠 안을 왼쪽으로 빠르게 지나가는 하얀 속도선 (줄마다 시작 자리가 달라 박자가 어긋나게)
func _draw_speed_lines(band_offset: float, top: float, width: float, elapsed: float) -> void:
	for index: int in range(SPEED_LINES):
		var line_y := top + 6.0 + float(index) / SPEED_LINES * (BAND_HEIGHT - 12.0)
		var line_x := band_offset + width - fmod(elapsed * SPEED_LINE_SPEED + index * 53.0, width + 40.0)
		draw_rect(Rect2(Vector2(line_x, line_y).round(), Vector2(10.0 + index % 3 * 6.0, 1.0)), Color(1, 1, 1, 0.22))


## 생존자 서 있는 그림(앞모습 첫 장)을 3배로, 발이 띠 아래에 닿게
func _draw_portrait(bottom_left: Vector2) -> void:
	if _portrait == null:
		return
	var draw_size := _frame_size * PORTRAIT_SCALE
	var frame_rect := Rect2(Vector2.ZERO, _frame_size)
	draw_texture_rect_region(_portrait, Rect2((bottom_left - Vector2(0.0, draw_size.y)).round(), draw_size), frame_rect)
