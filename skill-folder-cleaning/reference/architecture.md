# folder-cleaning — architecture & phase contracts

The orchestrator (`scripts/run-folder-cleaning.ps1`) runs a fixed, resumable
pipeline. Each phase reads the previous artifact and writes its own into
`OutputPath`. State lives in `state.json`; `-Resume` restarts at the first phase
not marked `done`.

```
Phase 1 Resolve     -> state.json
Phase 2 Inventory   -> manifest.json            (PowerShell only)
Phase 3 Extraction  -> extracted/<id>.txt, extraction-log.json
Phase 4 Classify    -> manifest.json (+classification)   OpenAI bulk tier
Phase 5 Analyze     -> analysis.json (+overrides)        OpenAI strong tier
Phase 6 Report      -> plan.json, plan-validation.json, cleaning-report.md
```

## state.json
```
{ schema, source, output, mode, skip_ai, started, updated,
  phases: { resolve, inventory, extraction, classify, analyze, report } }   # each "pending"|"done"
```

## manifest.json — the spine
One record per file. Deterministic fields come from Phase 2; `extraction_*` from
Phase 3; `classification` from Phases 4–5.

```
files[]:
  id                 "f00001"
  rel_path           path relative to source
  ext, type          type in {text,code,word,excel,ppt,pdf,temp,binary_skip,other}
  size_bytes, modified, created
  sha256             null if cloud-only / unreadable / empty
  availability       local | cloud_only | broken_shortcut | unreadable
  is_empty, is_temp
  shortcut_target    resolved .lnk target (or null)
  dup_group          "d001" for exact-hash matches (>1 file), else null
  analyze            bool — sent through extraction + AI?
  extracted_file     "extracted/<id>.txt" | null
  extraction_status  pending | ok | truncated | failed | skipped
  extraction_reason  text when failed/skipped
  classification     { label, confidence, evidence, needs_complex, model }
  notes[]
```

### Classification labels
`active`, `reference`, `outdated_candidate`, `duplicate`, `unrelated_candidate`,
`unclear`, `unreadable`. Exact duplicates, temp, empty, cloud-only, and unreadable
files are labelled **deterministically** (model = `deterministic`) and never sent to
OpenAI. Everything else with extracted text goes to the bulk tier.

## analysis.json — Phase 5
```
{ schema, generated,
  groups[]:    { kind: version_chain|near_duplicate|contradiction, members[id], authoritative, evidence, confidence }
  overrides[]: { id, label, confidence, evidence }     # applied back onto manifest classifications
  calls, est_usd }
```

## plan.json — Phase 6
The machine-readable proposal. Schema: `reference/plan-schema.json`. Key field for
the (future) apply step is `source_hash_index` — Phase 7 will re-hash the source and
abort if anything changed since the plan was generated.

Operations map from classification:
| label / flag | op | destination |
|---|---|---|
| exact duplicate (secondary copy) | archive | `_ARCHIVE/duplicates/` |
| duplicate (semantic) | archive | `_ARCHIVE/duplicates/` |
| outdated_candidate | archive | `_ARCHIVE/outdated/` |
| unrelated_candidate | review | (confirm first) |
| active / reference | keep | — |
| unclear / unreadable | review | (confirm first) |

## Cost control
- Only Phases 4–5 spend money, only on files with extracted content.
- `-MaxAiFiles` and `-MaxUsd` (defaults in `config.json`) are hard caps; when hit,
  remaining files are labelled `unclear` with model `capped` and the run continues.
- Per-call token usage from the API drives the running USD estimate
  (`cost-classify.json`, `analysis.json`).

## Not yet built — Phase 7 (apply)
Executing an approved plan: re-hash source, validate, move retired files to
`_ARCHIVE` (never hard-delete), prevent collisions, and emit `transaction.json` +
`rollback.ps1` + `execution-report.md`. Deferred per the build plan.
