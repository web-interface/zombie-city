# scenes — 장면 파일과 화면 모양 리소스
장면(.tscn)은 맨 위 노드의 editor_description 에 머리말을 적고, 주석을 넣을 수 없는 리소스(.tres)는 여기에 적는다 (문서 10 §5).

| 파일 | 무엇 | 쓰는 곳 |
|---|---|---|
| `pixel_theme.tres` | 기본 UI 모양: 기본 글꼴 Galmuri11, 글자 크기 12 | project.godot 의 gui/theme/custom — 모든 화면 기본값 |
| `title.tscn` · `survivor_select.tscn` · `run.tscn` · `result.tscn` | 화면 장면 (각 파일 editor_description 참고) | SceneRouter (문서 11 §3) |
