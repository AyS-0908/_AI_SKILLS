#!/usr/bin/env python3
"""Small deterministic repo discovery for Audit-IT.

No dependency, no AST, no security scanning. This only tells the auditor what
already exists so the skill can reuse native tools instead of inventing them.
"""

from __future__ import annotations

import json
import os
import shutil
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


DOC_NAMES = {
    "README.md",
    "AGENTS.md",
    "CLAUDE.md",
    "Progress.md",
    "PROGRESS.md",
    "Architecture.md",
    "ARCHITECTURE.md",
}

PRD_HINTS = ("prd", "spec", "requirements", "plan", "architecture", "progress")
RISK_HINTS = ("auth", "login", "permission", "credential", "secret", "env", "deploy", "workflow")
CLI_TOOLS = (
    "git",
    "gh",
    "rg",
    "node",
    "npm",
    "python",
    "clasp",
    "codeql",
    "semgrep",
    "gitleaks",
    "trufflehog",
    "snyk",
    "osv-scanner",
)


def has(path: Path, name: str) -> bool:
    return (path / name).exists()


def read_package_scripts(root: Path) -> dict[str, str]:
    package = root / "package.json"
    if not package.exists():
        return {}
    try:
        data = json.loads(package.read_text(encoding="utf-8"))
    except Exception:
        return {}
    scripts = data.get("scripts", {})
    return scripts if isinstance(scripts, dict) else {}


def iter_files(root: Path, limit: int = 5000):
    skipped = {".git", "node_modules", ".next", "dist", "build", ".venv", "venv", "__pycache__"}
    count = 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skipped]
        for filename in filenames:
            count += 1
            if count > limit:
                return
            yield Path(dirpath) / filename


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    scripts = read_package_scripts(root)
    files = list(iter_files(root))
    names = {p.name for p in files}

    docs = [
        str(p.relative_to(root))
        for p in files
        if p.name in DOC_NAMES or any(h in p.name.lower() for h in PRD_HINTS)
    ][:80]

    risk_files = [
        str(p.relative_to(root))
        for p in files
        if any(h in str(p.relative_to(root)).lower() for h in RISK_HINTS)
    ][:120]

    result = {
        "root": str(root),
        "project_markers": {
            "git": has(root, ".git"),
            "node": has(root, "package.json"),
            "python": has(root, "pyproject.toml") or has(root, "requirements.txt"),
            "apps_script": has(root, ".clasp.json") or any(p.suffix == ".gs" for p in files),
            "n8n": any("n8n" in str(p).lower() or p.suffix == ".json" and "workflow" in p.name.lower() for p in files),
            "supabase": has(root, "supabase") or "supabase" in " ".join(names).lower(),
        },
        "package_scripts": scripts,
        "native_commands": {
            "test": scripts.get("test") is not None,
            "lint": scripts.get("lint") is not None,
            "typecheck": scripts.get("typecheck") is not None,
            "build": scripts.get("build") is not None,
            "audit": scripts.get("audit") is not None,
        },
        "available_cli_tools": {tool: shutil.which(tool) is not None for tool in CLI_TOOLS},
        "docs_candidates": docs,
        "risk_files": risk_files,
        "counts": {
            "files_sampled": len(files),
            "docs_candidates": len(docs),
            "risk_files": len(risk_files),
        },
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
