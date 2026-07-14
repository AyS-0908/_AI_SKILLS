# SHEETS, DATA, TENANCY, CONFIG, AND TRIGGERS

Load with `CORE.md` only when the task touches these concerns. CORE owns the rules; this file adds implementation decisions.

## SCHEMA SHAPE

- Declare one schema containing tab names, stable keys, displayed headers, field ownership, lists, and status codes.
- Derive headers, editable fields, dropdowns, coded fields, and date-format columns from it.
- Use safe defaults: visible unless hidden; read-only unless explicitly editable; displayed label falls back to key.
- Keep code-owned vocabularies separate from editorial lists. Validate any sheet-based executable config before use.
- Translate stored labels and logic codes only at Sheet I/O seams.

## HEADER AND COLUMN POLICY

Build a live `key -> index` map from the canonical header row for each operation.

Header repair decision:

| State | Action |
|---|---|
| Blank header row | Write the declared headers. |
| Required headers present once | Continue. |
| Missing required headers, no unknown headers | Append only missing headers. |
| Missing and unknown headers together | Stop: likely rename ambiguity. |
| Duplicate required header | Stop. |

Preserve unknown owner-added columns during full-table writes. Tolerance ends at structural identity: required headers, IDs, tenant keys, and required config must be strict.

## BOOTSTRAP

Use one ordered manifest and one rerunnable build path:

`ensure sheet -> ensure headers -> formats -> validations -> notes -> visibility/protection -> seed`

- Create or repair; do not reset.
- Seed only when the target contains no data rows.
- Apply formatting/validation by header key, not column letter.
- Re-show fields whose schema changed from hidden to visible.
- Preserve operator conditional formatting and columns.
- Install triggers idempotently by handler name.

Backfill choice:

| Need | Pattern |
|---|---|
| Fill never-set defaults | Blank-fill only. |
| Replace shipped template/content | Version-gated update. |
| One irreversible legacy correction | One-time migration marker. |

## IDS AND ROW WRITES

- Mint entities with a prefix plus a collision-safe random ID.
- Use a deterministic `{parentId}_{naturalKey}` only when it is the stable identity for an imported/junction row.
- Pair machine IDs with a code-written display-name snapshot for humans; always join by ID.
- Before update/delete/transition, require exactly one ID match.
- For a full rewrite, map objects across all live headers.
- For one row, read once, patch named cells in memory, write once.

## TENANCY AND SIDE EFFECTS

For a multi-tenant workbook:

1. Store the tenant ID on every tenant-owned row.
2. Begin each read by filtering on that ID.
3. Re-read related rows at the side-effect chokepoint.
4. Verify tenant ownership, status, platform, capability, and operator enablement.
5. Mint the request ID only after validation passes.

Client UI may select a tenant; it never defines the eligible row set.

For batch state changes:

- Preflight IDs, tenant, gates, and legal transitions without writes.
- Apply only after batch-fatal checks pass.
- Declare whether a bad row aborts the batch or is logged and skipped.
- Never hard-delete history by default; deactivate when retention matters.

## CONFIG, PROPERTY SCOPE, AND CACHE

| Data | Recommended owner |
|---|---|
| Stable schema/status/property names | Code |
| Founder-curated presentation lists | Validated sheet config |
| Global non-secret settings | Global config sheet or properties |
| Per-tenant settings | One row per tenant |
| Secret values | Appropriate PropertiesService scope |
| Recomputable expensive reads | CacheService |
| Operational/audit history | Sheet or durable store |

Property scope depends on deployment topology. Script Properties are acceptable for a container-bound tool owned as one security domain. Reassess before sharing one library/deployment across workbooks or operators.

Cache only non-secret, recomputable data. Cache is never durable truth.

## LOCKS, TRIGGERS, AND STATE

- Check gates before acquiring the lock where safe; lock the shared document/script resource only around the critical path.
- Design repeated and overlapping executions to produce the same final state.
- Write processed/checkpoint state at a point that cannot hide an ambiguous external side effect.
- Scan existing triggers before installation.
- If a missing authorization scope prevents optional trigger installation, report the gap without corrupting workbook setup.

For a slow external side effect, default to:

1. Lock, re-read, validate, mint the request ID, and mark rows in progress.
2. Release the lock and call the provider.
3. Lock, re-read the claimed state, and finalize the result.
4. Provide a time-bounded recovery/reconciliation path for stale in-progress rows.

The in-progress state must be ineligible to sibling runs. If the provider contract requires a different sequence, document why it stays duplicate-safe.

## LOGS AND USAGE

Use one structured event shape containing time, tenant, object, action, before/after state, request ID, external reference, result, error code, and redacted details.

- Redact recursively at the log seam using secret-like key names.
- Keep diagnostic logs bounded only when no durable business rule depends on discarded rows.
- Do not enforce quotas or billing from a rolling log. Maintain a durable counter/ledger with sufficient retention.
