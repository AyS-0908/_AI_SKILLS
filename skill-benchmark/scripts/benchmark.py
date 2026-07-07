#!/usr/bin/env python3
"""Deterministic validator + renderer for benchmark.json files.

Usage:
    python benchmark.py validate <benchmark.json>
    python benchmark.py render <benchmark.json> [-o output.md]

validate: exit 0 = clean (warnings allowed), exit 1 = errors (must fix).
render:   refuses to render if validation errors exist.

Schema (all dates ISO): see SKILL.md Phase 3.
"""
import argparse
import json
import re
import sys
from datetime import date, datetime

DEPTHS = ("directional", "standard", "deep")
STATUSES = ("ok", "gap", "not_comparable")
QUALITIES = ("exact", "estimated", "directional")
CONFIDENCES = ("high", "med", "low")
CURRENCY_RE = re.compile(r"(\$|€|£|USD|EUR|GBP|CHF)")
STALE_MONTHS = 6
GAP_RATE_WARN = 0.4


def parse_date(s, fmt="%Y-%m-%d"):
    return datetime.strptime(s, fmt).date()


def check(data):
    """Return (errors, warnings) — lists of strings."""
    errors, warnings = [], []
    e, w = errors.append, warnings.append

    for field in ("title", "date", "purpose", "depth", "entities", "criteria", "cells"):
        if field not in data:
            e(f"missing top-level field: '{field}'")
    if errors:
        return errors, warnings

    if data["depth"] not in DEPTHS:
        e(f"depth must be one of {DEPTHS}, got '{data['depth']}'")
    try:
        parse_date(data["date"])
    except (ValueError, TypeError):
        e(f"date must be YYYY-MM-DD, got '{data['date']}'")

    entities, criteria = data["entities"], data["criteria"]
    if not entities:
        e("entities is empty")
    if not criteria:
        e("criteria is empty")
    if len(set(entities)) != len(entities):
        e("duplicate entity names")
    if len(set(criteria)) != len(criteria):
        e("duplicate criterion names")

    deep = data["depth"] == "deep"
    today = date.today()
    seen = {}
    for i, c in enumerate(data["cells"]):
        tag = f"cell[{i}] ({c.get('entity','?')} × {c.get('criterion','?')})"
        if c.get("entity") not in entities:
            e(f"{tag}: entity not in entities list")
            continue
        if c.get("criterion") not in criteria:
            e(f"{tag}: criterion not in criteria list")
            continue
        key = (c["entity"], c["criterion"])
        if key in seen:
            e(f"{tag}: duplicate — pair already defined in cell[{seen[key]}]")
        seen[key] = i

        status = c.get("status")
        if status not in STATUSES:
            e(f"{tag}: status must be one of {STATUSES}, got '{status}'")
            continue

        if status in ("gap", "not_comparable") and not c.get("note", "").strip():
            e(f"{tag}: status '{status}' requires a note (what was searched / why not comparable)")

        if status == "ok":
            if not str(c.get("value", "")).strip():
                e(f"{tag}: status 'ok' requires a non-empty value")
            sources = c.get("sources") or []
            if not sources:
                e(f"{tag}: status 'ok' requires at least one source")
            for j, s in enumerate(sources):
                stag = f"{tag} source[{j}]"
                if not s.get("name"):
                    e(f"{stag}: missing name")
                url = s.get("url", "")
                if not (url.startswith("http://") or url.startswith("https://") or url.startswith("user:")):
                    e(f"{stag}: url must start with http(s):// or 'user:' (user-provided data), got '{url}'")
                try:
                    acc = parse_date(s.get("accessed", ""))
                    if acc > today:
                        e(f"{stag}: accessed date {acc} is in the future")
                except (ValueError, TypeError):
                    e(f"{stag}: accessed must be YYYY-MM-DD, got '{s.get('accessed')}'")
                pub = s.get("published")
                if pub:
                    try:
                        pd = parse_date(pub + "-01", "%Y-%m-%d")
                        if (today.year - pd.year) * 12 + (today.month - pd.month) > STALE_MONTHS:
                            w(f"{stag}: published {pub} is >{STALE_MONTHS} months old — verify still current")
                    except ValueError:
                        e(f"{stag}: published must be YYYY-MM or null, got '{pub}'")
            if deep:
                if c.get("quality") not in QUALITIES:
                    e(f"{tag}: deep mode requires quality in {QUALITIES}")
                if c.get("confidence") not in CONFIDENCES:
                    e(f"{tag}: deep mode requires confidence in {CONFIDENCES}")
                if CURRENCY_RE.search(str(c.get("value", ""))) and len(c.get("sources") or []) < 2:
                    w(f"{tag}: deep mode + money value with a single source — add a second independent source")
            if len(str(c.get("value", ""))) > 200:
                w(f"{tag}: value is {len(str(c['value']))} chars — cells hold values, not prose; move detail to note")

    # completeness: every entity × criterion pair must exist
    for ent in entities:
        for crit in criteria:
            if (ent, crit) not in seen:
                e(f"missing cell: {ent} × {crit} — add it with status 'ok' or 'gap'")

    # gap rate
    cells = data["cells"]
    if cells:
        gaps = sum(1 for c in cells if c.get("status") == "gap")
        if gaps / len(cells) > GAP_RATE_WARN:
            w(f"gap rate {gaps}/{len(cells)} ({gaps/len(cells):.0%}) — benchmark may be too thin to be useful; consider narrowing criteria")

    # mixed currencies per criterion
    for crit in criteria:
        symbols = set()
        for c in cells:
            if c.get("criterion") == crit and c.get("status") == "ok":
                symbols.update(CURRENCY_RE.findall(str(c.get("value", ""))))
        if len(symbols) > 1:
            w(f"criterion '{crit}': mixed currencies {sorted(symbols)} — normalize to one currency before delivery")

    return errors, warnings


def md_escape(s):
    return str(s).replace("|", "\\|").replace("\n", " ")


def render(data):
    """Return markdown string. Assumes validation passed."""
    src_index = {}  # (url, name) -> number
    src_list = []

    def ref(sources):
        nums = []
        for s in sources or []:
            key = (s.get("url"), s.get("name"))
            if key not in src_index:
                src_index[key] = len(src_list) + 1
                src_list.append(s)
            nums.append(src_index[key])
        return "".join(f"[{n}]" for n in nums)

    cellmap = {(c["entity"], c["criterion"]): c for c in data["cells"]}
    ents = data["entities"]

    lines = [f"# {data['title']}", "",
             f"Scope: {', '.join(ents)} · {data['purpose']} · {data['depth']} · {data['date']}", "",
             "## Comparison Matrix", "",
             "| Criterion | " + " | ".join(md_escape(x) for x in ents) + " |",
             "|---" * (len(ents) + 1) + "|"]

    conflicts, gaps, ncs = [], [], []
    for crit in data["criteria"]:
        row = [md_escape(crit)]
        for ent in ents:
            c = cellmap[(ent, crit)]
            if c["status"] == "gap":
                row.append("[DATA GAP]")
                gaps.append(f"{ent} × {crit}: {c.get('note', '')}")
            elif c["status"] == "not_comparable":
                row.append("[NOT COMPARABLE]")
                ncs.append(f"{ent} × {crit}: {c.get('note', '')}")
            else:
                txt = f"{md_escape(c['value'])} {ref(c.get('sources'))}"
                if data["depth"] == "deep":
                    txt += f" `{c['quality']}/{c['confidence']}`"
                conf = c.get("conflict")
                if conf:
                    txt += f" ⚠ conflicting: {md_escape(conf['value'])} {ref(conf.get('sources'))}"
                    conflicts.append(f"{ent} × {crit}: '{c['value']}' vs '{conf['value']}'")
                row.append(txt)
        lines.append("| " + " | ".join(row) + " |")

    lines += ["", "## Sources", ""]
    for n, s in enumerate(src_list, 1):
        url = s.get("url", "")
        label = "[USER-PROVIDED] " if url.startswith("user:") else ""
        pub = f", published {s['published']}" if s.get("published") else ""
        lines.append(f"{n}. {label}{s.get('name')} — {url} (accessed {s.get('accessed')}{pub})")

    # auto-generated data quality — computed, never remembered
    lines += ["", "## Data Quality (auto-generated)", ""]
    total = len(data["cells"])
    lines.append(f"- {total - len(gaps) - len(ncs)}/{total} cells filled · {len(gaps)} data gap(s) · {len(ncs)} not comparable · {len(conflicts)} conflicting source(s)")
    for g in gaps:
        lines.append(f"- [DATA GAP] {g}")
    for n_ in ncs:
        lines.append(f"- [NOT COMPARABLE] {n_}")
    for cf in conflicts:
        lines.append(f"- [CONFLICT] {cf}")
    _, warnings = check(data)
    for wmsg in warnings:
        lines.append(f"- [WARNING] {wmsg}")

    n_findings = {"directional": 2, "standard": 3, "deep": 5}[data["depth"]]
    lines += ["", "## Key Findings", "",
              f"<!-- TO WRITE by the model: {n_findings} decision-relevant findings, each anchored to matrix cells. -->", "",
              "## Recommendations", "",
              "<!-- TO WRITE by the model: recommended choice for the stated purpose + condition for the alternative. Anchor in findings. -->", "",
              "## Benchmark Limits", "",
              "<!-- TO WRITE by the model: what this benchmark does NOT cover (adjacent scope the reader might expect). -->", ""]
    return "\n".join(lines)


def main():
    # Windows consoles default to cp1252, which chokes on ×/⚠/—
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("command", choices=["validate", "render"])
    p.add_argument("file")
    p.add_argument("-o", "--output", help="render: write markdown here instead of stdout")
    a = p.parse_args()

    try:
        with open(a.file, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as ex:
        print(f"ERROR: cannot read {a.file}: {ex}")
        sys.exit(1)

    errors, warnings = check(data)
    if a.command == "validate":
        for x in errors:
            print(f"ERROR: {x}")
        for x in warnings:
            print(f"WARNING: {x}")
        if errors:
            print(f"\nFAIL — {len(errors)} error(s). Fix and re-run.")
            sys.exit(1)
        print(f"PASS — 0 errors, {len(warnings)} warning(s). "
              + ("Address warnings or acknowledge them in the output." if warnings else "Ready to render."))
        sys.exit(0)

    if errors:
        print("Cannot render — validation errors:")
        for x in errors:
            print(f"ERROR: {x}")
        sys.exit(1)
    md = render(data)
    if a.output:
        with open(a.output, "w", encoding="utf-8") as f:
            f.write(md)
        print(f"Wrote {a.output}")
    else:
        print(md)


if __name__ == "__main__":
    main()
