## [파일] scripts/world/shadows.gd
## [하는 일] 발밑 그림자: 생존자와 좀비 발밑에 납작한 픽셀 그림자를 한 번에 그린다. 바닥에 서 있는 느낌(입체감)을 주고, 어두운 밤에도 캐릭터 자리가 보이게 한다. 보스는 크게, 기어다니는 좀비는 작게.
## [쓰는 곳] scenes/run.tscn 의 World/Shadows (바닥 바로 위, 캐릭터 아래). run.gd 가 setup() 을 부르고, 스스로 매 프레임 다시 그린다.
## [근거 문서] 02 §12 고급 게임 품질 기준(모든 것이 움직임·손맛), 06 그림 규칙
class_name Shadows
extends Node2D

const SHADOW_COLOR := Color(0.0, 0.0, 0.02, 0.38)

var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context
	z_index = -3   # 바닥(-10)·장판(-1) 사이, 조각(-2)보다 아래


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _context == null:
		return
	_draw_shadow(_context.survivor.position, 5.0)
	for zombie: Zombie in _context.horde.zombies:
		if zombie.sprite != null and zombie.sprite.modulate.a > 0.05:
			_draw_shadow(zombie.position, zombie.radius + (3.0 if zombie.is_boss else 1.0))


## 가로로 납작한 타원을 점 줄로 (매끈한 원 대신 픽셀 느낌)
func _draw_shadow(feet: Vector2, half_width: float) -> void:
	var center := feet.round() + Vector2(0, 1)
	draw_rect(Rect2(center.x - half_width, center.y, half_width * 2.0, 1.0), SHADOW_COLOR)
	draw_rect(Rect2(center.x - half_width + 1.0, center.y - 1.0, half_width * 2.0 - 2.0, 1.0), SHADOW_COLOR)
	draw_rect(Rect2(center.x - half_width + 1.0, center.y + 1.0, half_width * 2.0 - 2.0, 1.0), SHADOW_COLOR)
