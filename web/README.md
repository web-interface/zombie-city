# web — 웹 공개용 파일
웹(GitHub Pages)에 올릴 때 게임 옆에 같이 두는 파일. Godot 가 이 폴더를 게임에 넣지 않도록 `.gdignore` 를 둔다. `tools/export_web.py` 가 내보낸 폴더로 복사한다 (문서 07 내보내기).

| 파일 | 무엇 | 쓰는 곳 | 출처 |
|---|---|---|---|
| `og.png` | 링크 미리보기 그림 (카톡·메신저에 링크를 보내면 뜨는 그림), 540×960 | `export_presets.cfg` 의 `og:image` | 자동 플레이 화면 캡처(간호사, 둘째 밤 철거반장 보스전) 를 3배로 키움 — 직접 만든 게임 화면 |
| `sound_unlock.js` | 폰 브라우저 소리 켜기 — 아이폰 무음 모드에서도 소리, 손 뗄 때 소리 장치 다시 켜기, 다른 앱 갔다 오면 멈췄다 다시 켜기 | `export_presets.cfg` 의 head_include 가 Godot 보다 먼저 불러옴 | 직접 작성 |
| `kakao_open.js` | 카톡 링크로 열면(카톡 안 브라우저는 소리가 안 남) 폰의 기본 브라우저로 다시 열기. 카톡 안에서는 게임을 받지 않고 안내 + '브라우저로 열기'·'여기서 소리 없이 하기' 버튼 | `export_presets.cfg` head_include, `shell.html` 이 시작 전에 물어봄 | 직접 작성 |
| `account.js` | 게임 로그인(웹판은 로그인해야 시작 — 야구 게임과 같은 저장 키 `bb9.session`·`bb.user`, 같은 PBKDF2): 자동 로그인, 로그인·가입·복구 코드 창(HTML, 폰 한글 자판 때문에), 판 결과 올리기·순위 받기. 게임은 `scripts/meta/online.gd` 가 `window.ZombieCityAccount` 로 부름 | `export_presets.cfg` head_include | 직접 작성 |
| `account.css` | 로그인 창 모양 (어두운 밤 바탕·Galmuri 2.40.3 웹 글꼴(jsdelivr, 창을 열 때만)·각진 테두리·빨강/하늘색) | `export_presets.cfg` head_include | 직접 작성 |
| `shell.html` | 웹 첫 화면 틀 — Godot 기본 틀에 한국어 lang·카톡 확인만 더함 (그대로 복사하지 않고 Godot 가 index.html 로 채워 냄) | `export_presets.cfg` 의 custom_html_shell | Godot 4.7.2 godot.html (MIT) 고침 |
| `.gdignore` | 빈 파일. Godot 가 이 폴더를 가져오지 않게 하는 표시 | Godot 편집기·내보내기 | — |
