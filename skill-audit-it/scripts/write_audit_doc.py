#!/usr/bin/env python3
"""Write a numbered Audit-IT markdown handoff into <project>/_Audit-IT."""

from __future__ import annotations

import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def slugify(text: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9]+", "_", text.strip().lower()).strip("_")
    return slug or "audit"


def next_number(out_dir: Path) -> int:
    pattern = re.compile(r"^audit_it__(\d+)_")
    numbers = []
    for path in out_dir.glob("audit_it__*.md"):
        match = pattern.match(path.name)
        if match:
            numbers.append(int(match.group(1)))
    return max(numbers, default=0) + 1


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: write_audit_doc.py <project_root> <title> [draft_markdown_file]", file=sys.stderr)
        return 2

    project_root = Path(sys.argv[1]).resolve()
    title = sys.argv[2]
    if not project_root.exists():
        print(f"project root does not exist: {project_root}", file=sys.stderr)
        return 2

    if len(sys.argv) >= 4:
        content = Path(sys.argv[3]).read_text(encoding="utf-8")
    else:
        content = sys.stdin.read()

    out_dir = project_root / "_Audit-IT"
    out_dir.mkdir(exist_ok=True)
    number = next_number(out_dir)
    out_path = out_dir / f"audit_it__{number:03d}_{slugify(title)}.md"
    out_path.write_text(content.rstrip() + "\n", encoding="utf-8")

    prompt = (
        f"Give this to the AI coder:\n"
        f"Use the Audit-IT handoff file at {out_path}. Implement the AI Coder Tasks only. "
        f"Keep the diff minimal and run the checks listed in the file."
    )
    print(prompt)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
