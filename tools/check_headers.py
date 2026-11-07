"""
[파일] tools/check_headers.py
[하는 일] 머리말 검사기: 프로젝트의 모든 파일이 맨 위에 머리말 4칸(파일·하는 일·쓰는 곳·근거 문서)을 갖췄는지, 주석을 못 넣는 그림·소리·글꼴·리소스 폴더에 README.md 가 있는지, 코드·장면·도구 파일이 코드 지도(docs/11_코드구조.md)에 적혀 있는지 검사한다. 문제가 있으면 목록을 보여 주고 종료 코드 1.
[쓰는 곳] 코드를 넣을 때마다 `py -3 tools/check_headers.py` (문서 10 §9). 검수관 에이전트도 돌린다.
[근거 문서] 10 §5 파일 머리말, 10 §9 확인, 10 §10 코드 지도
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")   # 윈도 콘솔(cp949)에서 한글·기호가 깨지거나 멈추지 않게

PROJECT = Path(__file__).resolve().parent.parent
CODE_MAP = PROJECT / "docs" / "11_코드구조.md"
SKIP_FOLDERS = {".godot", ".git", "out", "__pycache__", "worktrees"}   # worktrees = 에이전트가 따로 일하는 작업 공간 (.claude/worktrees)
HEADER_TAGS = ["[파일]", "[하는 일]", "[쓰는 곳]", "[근거 문서]"]
BINARY_SUFFIXES = {".png", ".wav", ".ttf", ".otf", ".tres", ".ogg"}
MAPPED_SUFFIXES = {".gd", ".tscn", ".py"}       # 코드 지도에 반드시 적혀야 하는 종류


def main() -> int:
    problems: list[str] = []
    code_map_text = CODE_MAP.read_text(encoding="utf-8") if CODE_MAP.exists() else ""
    for path in sorted(project_files()):
        relative = path.relative_to(PROJECT).as_posix()
        problem = check_file(path)
        if problem:
            problems.append(f"{relative} — {problem}")
        if path.suffix in MAPPED_SUFFIXES and path.name not in code_map_text:
            problems.append(f"{relative} — 코드 지도(docs/11_코드구조.md)에 이 파일이 없음")
    for folder in folders_with_binaries():
        if not (folder / "README.md").exists():
            problems.append(f"{folder.relative_to(PROJECT).as_posix()}/ — 그림·소리·글꼴이 있는데 README.md 가 없음")
    if problems:
        print(f"머리말 검사: 문제 {len(problems)}건")
        for problem in problems:
            print("  - " + problem)
        return 1
    print("머리말 검사: 통과 (문제 0건)")
    return 0


def project_files() -> list[Path]:
    files = []
    for path in PROJECT.rglob("*"):
        if path.is_dir() or any(part in SKIP_FOLDERS for part in path.relative_to(PROJECT).parts):
            continue
        if path.suffix in {".import", ".uid", ".pyc"} or path.name in {".gitignore", ".gdignore", "project.godot", "export_presets.cfg"}:
            continue   # Godot 이 저장할 때 주석을 지우는 설정 파일 → 설명은 문서 07
        if "LICENSE" in path.name:
            continue   # 남이 만든 사용 조건 원문은 고치지 않는다 — 폴더 README 에 설명
        files.append(path)
    return files


def folders_with_binaries() -> set[Path]:
    return {path.parent for path in project_files() if path.suffix in BINARY_SUFFIXES}


def check_file(path: Path) -> str:
    """문제가 없으면 빈 문자열."""
    suffix = path.suffix
    if suffix in BINARY_SUFFIXES:
        return ""   # 폴더 README 로 따로 검사
    text = path.read_text(encoding="utf-8", errors="replace")
    if suffix == ".gd":
        return missing_tags(text.splitlines()[:6], "맨 위 ## 머리말")
    if suffix == ".tscn":
        match = re.search(r'editor_description = "(.*?)"', text, re.S)
        return "맨 위 노드에 editor_description 머리말이 없음" if not match else missing_tags([match.group(1)], "editor_description")
    if suffix == ".json":
        return check_json(text)
    if suffix in {".py", ".txt", ".html", ".js", ".css"}:
        return missing_tags(text.splitlines()[:12], "맨 위 머리말")
    if suffix == ".md" and text.startswith("---"):
        return missing_tags(text.splitlines()[:16], "머리말(앞부분 설정 뒤 주석)")   # 에이전트 정의 파일
    if suffix == ".md":
        return check_markdown(text)
    return f"모르는 파일 종류({suffix}) — 문서 10 §5 표에 쓰는 법을 더해야 함"


def missing_tags(lines: list[str], where: str) -> str:
    joined = "\n".join(lines)
    missing = [tag for tag in HEADER_TAGS if tag not in joined]
    return f"{where}에 {', '.join(missing)} 없음" if missing else ""


def check_json(text: str) -> str:
    try:
        data = json.loads(text)
    except json.JSONDecodeError as error:
        return f"JSON 읽기 실패: {error}"
    about = data.get("_설명") if isinstance(data, dict) else None
    if not isinstance(about, dict):
        return '맨 앞 "_설명" 칸이 없음'
    missing = [key for key in ["파일", "하는 일", "쓰는 곳", "근거 문서"] if key not in about]
    return f'"_설명" 에 {", ".join(missing)} 없음' if missing else ""


def check_markdown(text: str) -> str:
    lines = [line for line in text.splitlines() if line.strip()]
    if not lines or not lines[0].startswith("#"):
        return "맨 위에 # 제목이 없음"
    if len(lines) < 2 or lines[1].startswith("#") or lines[1].startswith("|"):
        return "제목 바로 아래 한 줄 설명이 없음"
    return ""


if __name__ == "__main__":
    sys.exit(main())
