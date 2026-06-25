#!/usr/bin/env python3
"""Merge Audit-IT JSON artifacts into one compact index."""

from __future__ import annotations

import json
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except FileNotFoundError:
        return None, "missing"
    except Exception as exc:
        return None, str(exc)


def main() -> int:
    audit_dir = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    names = [
        "repo_discovery.json",
        "native_checks.json",
        "prd_audit.json",
        "alignment_audit.json",
        "specialist_lanes.json",
    ]
    compiled = {"audit_dir": str(audit_dir), "loaded": {}, "warnings": []}

    for name in names:
        data, err = load_json(audit_dir / name)
        key = name.removesuffix(".json")
        if err:
            compiled["warnings"].append({"file": name, "warning": err})
            continue
        compiled["loaded"][key] = data

    output = audit_dir / "compiled_audit_inputs.json"
    output.write_text(json.dumps(compiled, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"output": str(output), "loaded": list(compiled["loaded"]), "warnings": compiled["warnings"]}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
