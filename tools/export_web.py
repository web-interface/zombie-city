"""
[파일] tools/export_web.py
[하는 일] 게임을 웹(브라우저)용으로 내보낸다. Godot 를 화면 없이 띄워 export_presets.cfg 의 'Web' 설정으로 index.html·.wasm·.pck 를 만들고, 링크 미리보기 그림(web/og.png)과 GitHub Pages 용 .nojekyll 을 옆에 둔다. 만들어진 파일이 빠졌거나 Godot 가 오류를 내면 종료 코드 1.
[쓰는 곳] 웹에 새 판을 올릴 때 `py -3 tools/export_web.py` → 나온 폴더(../survivor-web, gh-pages 가지)를 커밋·push (문서 07 내보내기). 기본 출력 폴더는 인자로 바꿀 수 있다.
[근거 문서] 07 내보내기, 08 로드맵 지금 상황
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")   # 윈도 콘솔(cp949)에서 한글이 깨지지 않게

PROJECT = Path(__file__).resolve().parent.parent
GODOT = Path(r"C:\Users\kbs\Godot\Godot_v4.7.2-stable_win64_console.exe")
DEFAULT_OUTPUT = PROJECT.parent / "survivor-web"
PRESET_NAME = "Web"
EXPECTED_FILES = ["index.html", "index.js", "index.wasm", "index.pck"]


def main() -> int:
    output = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else DEFAULT_OUTPUT
    output.mkdir(parents=True, exist_ok=True)
    log = run_godot_export(output / "index.html")
    problems = [line for line in log.splitlines() if "ERROR" in line and not is_known_noise(line)]
    problems += [f"{name} 가 안 만들어짐" for name in EXPECTED_FILES if not (output / name).exists()]
    shutil.copyfile(PROJECT / "web" / "og.png", output / "og.png")
    (output / ".nojekyll").write_text("", encoding="utf-8")   # GitHub Pages 가 _ 로 시작하는 파일을 숨기지 않게
    for name in EXPECTED_FILES:
        path = output / name
        if path.exists():
            print(f"  {name:12} {path.stat().st_size / 1_000_000:6.1f} MB")
    if problems:
        print(f"웹 내보내기: 문제 {len(problems)}건")
        for problem in problems:
            print("  - " + problem)
        return 1
    print(f"웹 내보내기: 끝 → {output}")
    return 0


def run_godot_export(index_path: Path) -> str:
    command = [str(GODOT), "--headless", "--path", str(PROJECT), "--export-release", PRESET_NAME, str(index_path)]
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return result.stdout + result.stderr


def is_known_noise(line: str) -> bool:
    """끌 때 나오는 소리 '아직 쓰는 중' 잡음은 세지 않는다 (문서 12 §3 알려진 잡음)."""
    return "AudioStream" in line or "resources still in use" in line or "ObjectDB instances were leaked" in line


if __name__ == "__main__":
    sys.exit(main())
