#!/usr/bin/env python3
"""Mechanical checks for the Stage 7 Specification (required sections present).

Usage: python check_spec.py <path/to/7-specification.md>
Exit codes: 0 = all pass, 1 = failures listed on stdout.
"""
import re
import sys
from pathlib import Path

# (section, required) - "AI Usage" is only required if relevant, so warn-only.
SECTIONS = [
    ("V1 Scope", True),
    ("SSOT", True),
    ("Main User Flow", True),
    ("Functional Requirements", True),
    ("Business Rules", True),
    ("Edge Cases", True),
    ("User Inputs and Product Outputs", True),
    ("AI Usage", False),
    ("Technical Matters", True),
    ("Privacy and Risk", True),
    ("Do Not Build", True),
    ("Open Questions", True),
]


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check_spec.py <7-specification.md>")
        return 1
    f = Path(sys.argv[1])
    if not f.is_file() or f.stat().st_size == 0:
        print(f"FAIL missing-or-empty: {f}")
        return 1
    text = f.read_text(encoding="utf-8", errors="replace")
    headings = [h.strip() for h in re.findall(r"^#{1,4}\s*(?:\d+\.?\s*)?(.+)$", text, re.M)]
    fails, warns = [], []

    for name, required in SECTIONS:
        if not any(name.lower() in h.lower() for h in headings):
            (fails if required else warns).append(f"section absent: {name}")

    m = re.search(r"^#{1,4}.*Do Not Build.*$", text, re.M | re.I)
    if m:
        block = text[m.end():]
        nxt = re.search(r"^#{1,4}\s", block, re.M)
        items = re.findall(r"^\s*(?:[-*]|\d+\.)\s+\S", block[: nxt.start()] if nxt else block, re.M)
        if not 3 <= len(items) <= 7:
            warns.append(f"Do Not Build items: {len(items)} (contract says 3 to 7)")

    for x in fails:
        print(f"FAIL {x}")
    for x in warns:
        print(f"WARN {x}")
    print("PASS all mechanical checks" if not fails else f"\n{len(fails)} failure(s) - fix and re-run before presenting")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
