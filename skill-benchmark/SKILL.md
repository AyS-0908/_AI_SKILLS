---
name: benchmark
description: >
  Structured competitive benchmark with a deterministic pipeline. Collects
  web-sourced data into a validated benchmark.json (every entity × criterion
  cell machine-checked for completeness, source URLs, dates), then renders an
  evidence-backed comparison matrix with an auto-computed data-quality section.
  Use this skill WHENEVER the user wants to compare two or more external
  entities — products, tools, companies, vendors, platforms, services, plans —
  on pricing, features, market position, or any criteria, even if they never
  say "benchmark": "compare X vs Y", "how does X stack up against Y", "which
  is cheaper over 2 years", "competitive analysis", "competitive landscape",
  "market comparison", "X vs the market / vs alternatives". Consult this skill
  BEFORE running any web searches for such a comparison — it defines how the
  data must be collected, sourced, and validated.
  Do NOT trigger for: internal audits, consistency checks, document reviews,
  comparing versions of the user's own files or code, performance benchmarking
  of the user's own software, SWOT of a single entity without competitors,
  open-ended market research without entity-vs-entity comparison
  (use deep-research), or single facts like "how much does X cost".
---

# Benchmark Skill

Structured competitive analysis. Five phases: scope → criteria → collect → validate → deliver.

The reliability mechanism: all collected data goes into a **`benchmark.json` file**, and `scripts/benchmark.py` (in this skill's folder) machine-checks it — every entity × criterion cell present, every claim sourced with a URL and access date, units consistent — then renders the matrix and data-quality section deterministically. You never assemble the matrix by hand, so nothing can be silently dropped or unsourced.

**Use web search for every factual claim** (pricing, features, market position). Training knowledge is not a source: it is stale and unverifiable. A benchmark's only value is that the reader can trust and check each cell.

---

## Gotchas

- **Web search returns nothing useful** → cell `status: "gap"` with a note saying what was searched. Never infer or fabricate.
- **Pricing pages that render via JavaScript** → fetch may return an empty or cookie-wall page despite HTTP 200. Check the body actually contains prices; if not, search for the price via a secondary query (press release, review site) and label the source accordingly.
- **Conflicting sources** → record both in the cell (`conflict` field), never silently pick one.
- **Paywalled sources** → try press release / exec summary / public blog. If nothing → `status: "gap"`.
- **Aggregators (G2, Capterra, review blogs) misquote prices** → official pricing page wins for factual claims; aggregators are context.
- **Regional pricing differs** → note the region; don't mix regions across entities (validator warns on mixed currencies).
- **User uploads / internal data** → confirm before incorporating; use source url `user:<description>` so it renders as `[USER-PROVIDED]`.

---

## Phase 1 — SCOPE AND INTAKE

**Input:** User request → **Output:** Locked scope (entities, purpose, depth, criteria, output format)

### Detect Depth Mode

- "quick look", "rough comparison", "directional" → `directional`
- Default / no signal → `standard`
- "thorough", "deep dive", "comprehensive", "board-level" → `deep`

### Extract What's Already in the Request

Parse the user prompt first. Extract any entities, purpose, criteria, and depth signals already provided. Only ask what's genuinely missing.

### Blocking Questions (only if missing — ask together, stop until answered)

1. **Entities** — IF not identifiable from request: "Who/what should we compare?" (minimum 2 for matrix, 1 for deep-dive)
2. **Purpose** — IF not identifiable AND depth is not `directional`: "What's the comparison purpose?" (purchase decision / strategic positioning / feature gap / pricing / other)

- IF depth is `directional` AND purpose not stated → [Assumed: inferred from entities + domain]
- IF all blocking info is already in the request → skip questions, go straight to scope summary

### Single-Entity Mode

- IF only 1 entity + "vs the market" / "vs competitors" / "vs alternatives" → identify 2–3 relevant market reference points and add them as entities. The pipeline is identical; the deliverable defaults to narrative format (see Phase 5).

### Non-Blocking (assume if not answered, state assumption)

- Criteria: [Assumed: inferred from purpose + domain]
- Depth: [Assumed: standard]
- Output format: [Assumed: matrix — except single-entity → narrative]
- Evidence perimeter: [Assumed: open web sources]

→ Present scope summary to user. Proceed on confirmation.

---

## Phase 2 — CRITERIA DEFINITION

**Input:** Locked scope → **Output:** Confirmed criteria list

### Criteria Source Selection (in priority order)

1. IF user already specified criteria → use them directly. Confirm and adjust if needed.
2. ELSE → infer from purpose:

| Purpose | Default Criteria |
|---|---|
| Purchase decision | Price, features, support quality, maturity, lock-in risk |
| Strategic positioning | Market position, differentiation, momentum, reach |
| Feature gap | Feature-by-feature checklist |
| Pricing | Plans, pricing model, unit economics, hidden costs, TCO |
| Strategic inspiration | Market position, disruption nature, revenue impact, strategic response, new revenue streams, AI usage, current trajectory, transferable lesson |

### Criteria Limits

| Depth | Max Criteria |
|---|---|
| directional | 6 |
| standard | 10 |
| deep | 15 |

**Principle:** Fewer focused criteria > many shallow ones. Cut a criterion rather than fill it with non-comparable data. Every criterion you add creates one cell per entity that the validator will force you to fill or explicitly gap.

→ Present criteria list to user before proceeding to data collection.

---

## Phase 3 — DATA COLLECTION

**Input:** Confirmed entities + criteria → **Output:** `benchmark.json`, one cell per entity × criterion

Create `benchmark.json` in the working directory with the scope, then fill cells **as you search** — never batch-write from memory at the end (that is how data gets invented). One entity at a time; official site and pricing page first, then aggregators, analyst reports, press coverage.

### File format

```json
{
  "title": "CRM Pricing Benchmark",
  "date": "2026-07-06",
  "purpose": "purchase decision",
  "depth": "standard",
  "entities": ["HubSpot", "Pipedrive"],
  "criteria": ["Entry price", "Free tier"],
  "cells": [
    {
      "entity": "HubSpot",
      "criterion": "Entry price",
      "status": "ok",
      "value": "$15/user/mo (annual billing)",
      "sources": [
        {"name": "HubSpot pricing page", "url": "https://www.hubspot.com/pricing",
         "accessed": "2026-07-06", "published": null}
      ],
      "note": ""
    },
    {
      "entity": "Pipedrive",
      "criterion": "Free tier",
      "status": "gap",
      "note": "Searched pricing page + 'pipedrive free plan' — no free tier exists as of 2026-07."
    }
  ]
}
```

Cell rules:

- `status`: `"ok"` (value + ≥1 source required) · `"gap"` (nothing found — note what you searched) · `"not_comparable"` (data exists but on a different basis — note why)
- `value`: the datum only, short. Detail goes in `note`.
- `sources[].url`: real URL you actually consulted; `user:<description>` for user-provided data. `accessed` = today. `published` = `"YYYY-MM"` if the source shows a date, else `null`.
- Conflicting sources → keep the better-supported value in `value`, add `"conflict": {"value": "...", "sources": [...]}` with the other.
- `deep` mode only: each `ok` cell also needs `"quality"` (`exact`/`estimated`/`directional`) and `"confidence"` (`high`/`med`/`low`), and money values need two independent sources.

### Normalization (before Phase 4)

- **Units:** same currency, same billing period, same unit across all entities.
- **Vocabulary:** align equivalent tier names ("Enterprise" ≈ "Business Plus") — note the mapping in the cell note.
- **Comparability:** same geography, segment, and tier. IF not achievable → `status: "not_comparable"`.
- `deep` mode: don't mix list vs. negotiated prices; label self-reported vs. independently verified metrics.

---

## Phase 4 — VALIDATE

**Input:** `benchmark.json` → **Output:** validation PASS

```
python <this-skill>/scripts/benchmark.py validate benchmark.json
```

- **ERRORs** (missing cells, unsourced claims, bad dates, duplicates) → fix the JSON, re-run. Loop until 0 errors. Fixing means searching again or honestly marking `gap` — never inventing a value to satisfy the validator.
- **WARNINGs** (stale sources, mixed currencies, high gap rate, single-source money data in deep mode) → resolve when you can; otherwise they auto-appear in the rendered Data Quality section, so the reader sees them either way.

---

## Phase 5 — DELIVER

**Input:** validated `benchmark.json` → **Output:** final deliverable

```
python <this-skill>/scripts/benchmark.py render benchmark.json -o benchmark.md
```

The script renders: matrix, numbered sources, auto-computed Data Quality section, and `<!-- TO WRITE -->` placeholders. You then write the judgment sections in `benchmark.md`:

1. **Key Findings** — decision-relevant differentiators and gaps, each anchored to matrix cells (count scales with depth: 2 directional / 3 standard / 5 deep).
2. **Recommendations** — recommended choice for the stated purpose, plus the condition under which the alternative wins. No recommendation without a finding behind it.
3. **Benchmark Limits** — what this benchmark does NOT cover.

Scoring: only if the user explicitly requested it → 1–5 scale with evidence per score, added as a findings subsection. Otherwise no scores — evidence and labels are the analysis.

**Narrative format** (single-entity mode, or user request): still build and validate `benchmark.json` (main entity + market references as entities), render, then follow `references/output-templates.md` to reshape into narrative. The matrix and sources stay as an appendix.

Deliver `benchmark.md` (and mention `benchmark.json` is available as the raw data).

---

## Core Rules

These apply across all phases. A benchmark is only useful if the reader can trust every cell.

- **Never fabricate.** No value without a source URL you actually consulted. A `gap` is always better than a guess — and the validator makes gaps visible instead of shameful.
- **Never silently resolve conflicts.** When sources disagree, record both in the `conflict` field.
- **Comparability > exhaustiveness.** Cut a criterion rather than fill it with non-comparable data.
- **Official sources win** for factual claims (pricing, features, specs). Analyst framing is context, not ground truth.
- **Say when data is thin.** If the gap rate makes the comparison meaningless, tell the user and propose narrowing scope.
