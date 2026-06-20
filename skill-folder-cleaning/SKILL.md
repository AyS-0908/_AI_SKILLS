---
name: folder-cleaning
description: >-
  Audit and clean up a messy local folder on Windows. A PowerShell orchestrator
  inventories every file (size, dates, SHA-256, exact duplicates, OneDrive
  availability, broken shortcuts), extracts text from text/code/Office/PDF
  documents, and uses OpenAI models (a cheap tier for bulk classification, a
  stronger tier for version chains and near-duplicates) to classify each file as
  active / reference / outdated / duplicate / unrelated. Produces a human-readable
  cleaning report plus a machine-readable plan. The default `analyze` mode is
  strictly read-only and never touches the source. Use this skill whenever the
  user wants to clean up, audit, declutter, organize, or de-duplicate a folder or
  directory, find outdated or duplicate files under a path, or figure out what in
  a folder can be archived — even if they don't say the word "clean". Trigger for:
  "clean up this folder", "audit/organize/sort out my Downloads", "find duplicate
  or old files in C:\...", "what's in this folder and what can I archive".
  Do NOT trigger for: auditing a single document's internal consistency (use
  audit-it), generating a spec or PRD (use prdgen), comparing external products or
  competitors (use benchmark), or folders that are not a local Windows path.
---

# Folder cleaning

Audit any local Windows folder and propose a safe, reversible cleanup. The work is
done by a PowerShell orchestrator (`scripts/run-folder-cleaning.ps1`) that runs a
fixed pipeline. Deterministic facts (inventory, hashing, duplicate detection,
extraction) are pure PowerShell/.NET. Only **semantic judgement** is sent to
OpenAI, on two tiers — a cheap model for bulk classification and a stronger model
for the genuinely hard cases. This keeps cost low and keeps every irreversible
decision in the user's hands.

Your job is to run the orchestrator, read its artifacts, and walk the user through
the cleaning report. You do **not** classify files yourself — the script does that
via OpenAI so results are reproducible and cheap.

## Gotchas

External calls fail in quiet, specific ways. Handle these explicitly — never let a
failure look like a clean result.

- **OpenAI returns HTTP 200 with an error in the body.** A 200 status does not mean
  success. `Invoke-OpenAI` checks `.error` and the `choices`/`finish_reason` in the
  body, not just the status code. A `finish_reason` of `length` means the answer was
  truncated — treat that file as `unclear`, not as whatever half-answer came back.
- **Missing or invalid API key.** The script reads `OPENAI_API_KEY` from the
  environment. If it is absent, AI phases are *skipped, not faked* — the run
  degrades to inventory + extraction only and says so up front (it does not mark
  good files unreadable). `-SkipAI` forces this same deps-free mode on purpose.
- **Model not available on the account.** If `gpt-5`/`gpt-5-mini` 404s, the script
  falls back to the `fallback` models in `config.json` (default `gpt-4o`/`gpt-4o-mini`)
  and records which model actually answered each file.
- **Rate limits / 5xx.** Retried with backoff up to the config limit, then the file
  is marked `unreadable` with the reason — the run continues.
- **OneDrive cloud-only files.** Files with the `FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS`
  attribute have no local bytes. They are inventoried with `availability:"cloud_only"`,
  **not hashed or extracted**, and surfaced as "needs the user to make available". The
  script never silently triggers a download.
- **Broken / external shortcuts (`.lnk`).** Resolved to their target; if the target is
  missing the entry is `broken_shortcut`. Targets outside the source folder are noted
  but never followed for cleanup.
- **Extraction truncation & unsupported types.** Office files are parsed as zips for
  their text; PDFs need an external extractor (see `reference/openai-setup.md`). Any
  file whose content cannot be extracted is recorded as `extraction_failed` with the
  reason and classified as `unreadable` — never silently dropped.
- **Windows long paths (>260 chars) and odd encodings.** The script uses `\\?\`-style
  long-path access and reads text as UTF-8 with BOM detection; undecodable bytes are
  reported, not guessed.
- **Source safety.** In `analyze` mode the script asserts zero writes to the source
  tree and refuses to place its own artifacts inside the source folder.

## Operating model (read this before running)

- **Default mode is `analyze` — strictly read-only.** It produces a report and a
  plan but changes nothing.
- **`apply` mode is not built yet.** This skill currently ships Phases 1–6 (audit +
  proposal). Phase 7 (executing an approved plan, with `_ARCHIVE` + `rollback.ps1`)
  is intentionally deferred. If the user asks to actually move files, tell them the
  apply step is coming next and that for now they review the plan.
- **The user approves through the report, never by editing `plan.json`.** `plan.json`
  is the machine-readable artifact; the human reads `cleaning-report.md`.
- **Artifacts live in `OutputPath`, never inside the source.** Default OutputPath is
  `<source-parent>\_folder-cleaning\<source-name>-<timestamp>`.

## Invocation

```powershell
.\scripts\run-folder-cleaning.ps1 `
  -SourcePath "C:\Users\me\Downloads\messy-folder" `
  -OutputPath "C:\Users\me\Desktop\cleanup-out" `   # optional; auto if omitted
  -Mode "analyze"                                    # default
```

Useful switches:
- `-SkipAI` — run Phases 1–3 only (resolve + inventory + extraction). No API key
  needed. Good first smoke test on a real folder.
- `-Resume` — continue an interrupted run using the checkpoint in OutputPath; already
  completed phases are not repeated.
- `-MaxAiFiles <n>` / `-MaxUsd <n>` — hard caps; the AI phases stop early and say so
  if exceeded (defaults in `config.json`).

## The pipeline (Phases 1–6)

Each phase reads the previous phase's artifact and writes its own. Full contracts and
JSON shapes are in `reference/architecture.md`; the plan schema is
`reference/plan-schema.json`.

| # | Phase | Engine | Writes |
|---|-------|--------|--------|
| 1 | Resolve | PowerShell | `state.json` (resolved paths, access checks) |
| 2 | Inventory | PowerShell | `manifest.json` (path, type, size, dates, SHA-256, availability, empty/temp/dup flags) |
| 3 | Extraction | .NET zip / PDF tool | `extracted/<id>.txt` per analyzable file + `extraction-log.json` |
| 4 | Bulk classify | OpenAI cheap tier | adds `classification` to `manifest.json` |
| 5 | Complex analysis | OpenAI strong tier | `analysis.json` (version chains, near-dupes, contradictions) |
| 6 | Proposal | PowerShell | `cleaning-report.md`, `plan.json`, `plan-validation.json` |

Phase 2 detects **exact** duplicates by SHA-256 — that is deterministic and costs
nothing, so it is never sent to a model. AI only ever sees the *semantic* questions:
is this an old version, is this near-duplicate, is this unrelated to the folder's
theme. Files that are obviously classifiable in Phase 4 are not re-examined in Phase 5.

## How to run it (your step-by-step)

1. **Confirm the target with the user.** Echo back the exact `SourcePath` and the
   mode. If they implied "actually clean it", remind them apply mode isn't built yet
   and this run only audits.
2. **Run the orchestrator** with the Bash or PowerShell tool. Stream its progress; it
   prints one line per phase.
3. **If it stops on a missing API key** and the user wanted AI classification, point
   them to `reference/openai-setup.md` (set `OPENAI_API_KEY`), or offer `-SkipAI` for
   an inventory-only pass.
4. **Read `cleaning-report.md`** and summarize it for the user — don't just dump the
   file. Lead with the headline numbers (files, duplicates, archive candidates,
   reclaimable space) and the decisions that need their input.
5. **Surface anything uncertain**: cloud-only files, extraction failures, low-confidence
   classifications, and contradictory documents. These are exactly the items where the
   model is allowed to be unsure — present them as questions, not conclusions.
6. **Stop there.** Do not move, rename, or delete anything. Tell the user the plan is
   ready for review and that applying it is the next step once they approve.

## Presenting the report

The report (`cleaning-report.md`, exact structure in `reference/architecture.md`)
contains: proposed folder structure, proposed renames/moves, archive candidates,
unavailable/unreadable files, decisions needing input, and evidence + confidence per
item. When you summarize:

- Lead with what's safe and obvious (exact duplicates, empty files, temp files).
- Separate "high confidence" from "please confirm". Never present a low-confidence
  guess as a fact.
- Quote the **evidence** the model gave (e.g. "v2 supersedes v1: same title, newer
  date, +3 sections") so the user can trust or overrule it.
- For every "unrelated" or "outdated" call, remind the user nothing is deleted —
  retired files would go to `_ARCHIVE` and be reversible when apply mode lands.

## Safety rules (non-negotiable)

```
default_mode:                analyze        # read-only
source_write_during_analyze: forbidden
hard_delete:                 forbidden      # apply mode will archive, never delete
silent_skip:                 forbidden      # every file is accounted for
classify_on_name_or_date:    forbidden      # evidence required
approval_before_apply:       required
artifacts_inside_source:     forbidden
```

If any of these would be violated, the script aborts with a non-zero exit code and a
reason. Treat a non-zero exit as a hard stop and report it to the user verbatim.

## Model routing & cost

Routing is in `config.json`, not hard-coded — runtimes differ. Defaults:

```
bulk_classification: gpt-5-mini   (fallback gpt-4o-mini)   low effort
complex_analysis:    gpt-5        (fallback gpt-4o)        medium effort
```

Only Phases 4–5 spend money, only on files that need semantic judgement, and only on
extracted text (capped per file in config). The run stops and reports if `-MaxAiFiles`
or `-MaxUsd` is hit. See `reference/openai-setup.md` for key setup, model choice, and
a rough cost estimate.

## When something fails

Every external call follows: **log → tell the user → fall back, don't pretend.**

- Extraction fails → `extraction_failed` + reason → file becomes `unreadable`.
- OpenAI error (any kind) → retry per config → then mark the file `unreadable` with the
  error and continue; the run never dies on one bad file.
- Source changed / access denied → abort the affected phase, write what's done to
  `state.json`, and let the user fix and `-Resume`.
- Partial run → the checkpoint means `-Resume` picks up at the first incomplete phase.
