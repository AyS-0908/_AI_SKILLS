# Folder-cleaning architecture

## Pipeline

```text
Phase 1 Resolve          -> state.json
Phase 2 Inventory        -> manifest.json
Phase 0 Preflight        -> preflight.json
Host context checkpoint  -> context.json
Phase 3 Extraction       -> extracted/* + extraction-log.json
Phase 4 Queue            -> analysis-queue.json + analysis-batches/*
Host analysis checkpoint -> batch-results/* + analysis-results.json
Phase 5 Ingest           -> organization-plan.json draft
Phase 6 Plan             -> organization-plan.json + plan-validation.json
                            + approval-view.md
Phase 7 Apply            -> transaction.json + rollback.ps1
```

## Ownership

PowerShell:

- Resolve link-aware paths.
- Inventory every file and scan error.
- Hash local files and group exact SHA-256 duplicates.
- Extract supported text.
- Validate context, batches, global analysis, plans, approval, and apply safety.
- Render approval views.
- Apply an approved plan and journal every operation.

Host agent:

- Infer folder context and ask targeted questions.
- Confirm protected items.
- Analyze files globally.
- Identify authoritative documents, version chains, overlap, contradictions, and
  uncertain items.
- Propose folders, filenames, destinations, and actions.
- Translate user corrections into structured revisions.

## State

`state.json` schema 3 records:

- Run ID, real source path, output path, config hash.
- Immutable `skip_ai` and `continue_partial`.
- Phase state: `pending`, `blocked`, `awaiting_context`, `awaiting_host`, `skipped`,
  or `done`.

Resume rejects a different source, changed config, or changed immutable switches.

## Exact duplicates

- Detect by SHA-256 only.
- Choose one representative ID only to avoid repeated semantic reading.
- Preserve every occurrence path.
- Require one host disposition per occurrence.
- Never choose an authoritative copy by age or path.
- Never archive automatically.

## Approval

- `approval-view.md` is rendered from the validated plan.
- Stable registry IDs use `F001`, `D001`, and expanded `I001` forms.
- Structured revisions must bind to the current plan hash.
- `approval.json` must bind to the current plan hash.
- `-SkipAI` plans are always non-approvable.

## Apply

- Re-hash every source file after approval.
- Reject missing approval, hash mismatch, target collision, invalid Windows names,
  excessive paths, and direct-move dependency cycles.
- Write the complete transaction and rollback script before the first move.
- Move each changed file once, directly to its final regular or `_ARCHIVE` path.
- Journal completion after every operation.
- Never hard-delete.

Rollback:

- Reverse completed moves.
- Refuse to overwrite an occupied original path.
- Refuse to restore a moved file that changed after apply.
- Remove only empty folders created by apply.

## Main artifacts

- `manifest.json`: one inventory entry per file, duplicate groups, format census,
  folders, scan completeness.
- `preflight.json`: reader availability, partial/stop status, cloud-only and access
  issues.
- `context.json`: confirmed folder objective, protections, naming, and depth.
- `analysis-queue.json`: semantic IDs, duplicate occurrences, batches, and hashes.
- `organization-plan.json`: exactly one final entry per source file.
- `plan-validation.json`: validation and approvability.
- `approval-view.md`: decision-led user view; no full file audit.
- `transaction.json`: prewritten and incrementally updated apply journal.
