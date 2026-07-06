#!/usr/bin/env python3
"""Mechanical checks for the Stage 6 mockup HTML file (contract rules only).

Usage: python check_mockup.py <path/to/6-mockup.html>
Exit codes: 0 = all pass, 1 = failures listed on stdout.
"""
import re
import sys
from pathlib import Path

BRIEF_FIELDS = ["Device priority", "State list", "Design anchor", "Data plan", "Interaction scope"]


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check_mockup.py <6-mockup.html>")
        return 1
    f = Path(sys.argv[1])
    if not f.is_file() or f.stat().st_size == 0:
        print(f"FAIL missing-or-empty: {f}")
        return 1
    html = f.read_text(encoding="utf-8", errors="replace")
    fails, warns = [], []

    n_style = len(re.findall(r"<style[\s>]", html, re.I))
    n_script = len(re.findall(r"<script[\s>]", html, re.I))
    if n_style != 1:
        fails.append(f"style tags: {n_style} (need exactly 1)")
    if n_script != 1:
        fails.append(f"script tags: {n_script} (need exactly 1)")

    for field in BRIEF_FIELDS:
        if field.lower() not in html.lower():
            fails.append(f"Mockup Brief field absent: {field}")
    if "mockup brief" not in html.lower():
        fails.append("Mockup Brief comment block absent")

    ext = re.findall(r'(?:src|href)\s*=\s*["\']https?://[^"\']+', html, re.I)
    ext += re.findall(r'url\(\s*["\']?https?://', html, re.I)
    ext += re.findall(r'@import\s+["\']?https?://', html, re.I)
    if ext:
        fails.append(f"external dependencies ({len(ext)}): {ext[0][:80]}...")

    for api in ("localStorage", "sessionStorage", "document.cookie", "fetch(", "XMLHttpRequest", "WebSocket("):
        if api in html:
            fails.append(f"forbidden persistence/network API: {api}")

    n_open = html.count("DEMO ONLY")
    n_close = html.count("/DEMO ONLY")
    if n_close * 2 != n_open:  # each pair contributes one plain + one closing marker
        fails.append(f"DEMO ONLY markers unbalanced: {n_open - n_close} open vs {n_close} close")
    if n_open == 0:
        warns.append("no DEMO ONLY block found (ok only if the mockup has no demo controls)")

    for x in fails:
        print(f"FAIL {x}")
    for x in warns:
        print(f"WARN {x}")
    print("PASS all mechanical checks" if not fails else f"\n{len(fails)} failure(s) - fix and re-run before presenting")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
