# 좀비 도시 (가제)
좀비가 된 도시 '새벽시'에서 구조 헬기가 올 때까지 5분을 버티는 세로 화면 픽셀 생존 액션. Godot 4.7.2 로 만든다. 지금은 **v0.1 시험판**.

- **해 보기**: https://web-interface.github.io/zombie-city/ (폰·PC 브라우저)
- 조작: 화면을 끌어서 움직임 (PC 는 WASD·방향키도), 공격은 자동, 스킬은 오른쪽 아래 버튼 (PC 는 스페이스)

## 문서
| 문서 | 내용 |
|---|---|
| [docs/README.md](docs/README.md) | 기획 문서 목차 — 여기부터 |
| [docs/08_로드맵.md](docs/08_로드맵.md) | 단계별 계획과 지금 상황 |
| [docs/11_코드구조.md](docs/11_코드구조.md) | 코드 지도 — 코드를 열기 전에 |
| [docs/10_코드규칙.md](docs/10_코드규칙.md) | 사람이 읽을 수 있는 코드 규칙 |

## 웹에 다시 올리기
```
py -3 tools/export_web.py          # ../survivor-web 에 index.html·wasm·pck 생성
cd ../survivor-web                 # gh-pages 가지 (git worktree)
git add -A && git commit -m "웹 시험판 갱신" && git push
```
