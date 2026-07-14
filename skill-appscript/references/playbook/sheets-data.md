# SHEETS, DATA, TENANCY, CONFIG, AND TRIGGERS

Load with `CORE.md` only when the task touches these concerns. CORE owns the rules; this file adds implementation decisions.

## SCHEMA SHAPE

- Declare one schema containing tab names, stable keys, displayed headers, field ownership, lists, and status codes.
- Derive headers, editable fields, dropdowns, coded fields, and date-format columns from it.
- Use safe defaults: visible unless hidden; read-only unless explicitly editable; displayed label falls back to key.
- Keep code-owned vocabularies separate from editorial lists. Validate any sheet-based executable config before use.
- Translate stored labels and logic codes only at Sheet I/O seams.
- Keep IDs, workflow state, and side-effect decisions code-written. A formula consumed by code needs explicit freshness/error checks; `SpreadsheetApp.flush()` applies pending writes but is not a substitute for a tested calculation contract.

## HEADER AND COLUMN POLICY

Build a live `key -> index` map for each operation. By default, use stable protected machine headers and put friendly wording in notes/UI. If headers must be renamed or translated, add a separately validated key row or metadata layer; do not guess keys from labels.

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
- Change visibility/protection only for ranges the tool explicitly owns; do not undo an operator choice on every bootstrap.
- Avoid destructive resets so operator columns, formulas, and conditional formatting survive.
- Install only tool-owned triggers. Track the created trigger ID/topology; handler name alone is not a unique trigger definition, and one account cannot see another account's triggers.

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

This is logical isolation inside the application, not data confidentiality. Anyone who can open or copy the workbook may see protected/hidden content. Use separate workbooks or an access-controlled backend when tenants must not see one another's data.

Client UI may select a tenant; it never defines the eligible row set.

For batch state changes:

- Preflight IDs, tenant, gates, and legal transitions without writes.
- Apply only after batch-fatal checks pass, but do not claim cross-system atomicity: define compensation or recovery for partial Sheet/provider failure.
- Declare whether a bad row aborts the batch or is logged and skipped.
- Never hard-delete history by default; deactivate when retention matters.

## CONFIG, PROPERTY SCOPE, AND CACHE

| Data | Recommended owner |
|---|---|
| Stable schema/status/property names | Code |
| Founder-curated presentation lists | Validated sheet config |
| Global non-secret settings | Global config sheet or properties |
| Per-tenant settings | One row per tenant |
| Low-risk secret values in a trusted-editor tool | Appropriate PropertiesService scope |
| Recomputable expensive reads | CacheService |
| Operational/audit history | Sheet or durable store |

Property scope depends on deployment topology. Script Properties are shared by every user of the script and PropertiesService is not a dedicated secret vault. It can be pragmatic for a small tool with trusted editors; use a dedicated secret manager when access must be independently controlled, audited, or rotated.

Cache only non-secret, recomputable data. Cache is never durable truth.

## LOCKS, TRIGGERS, AND STATE

- Check gates before acquiring the lock where safe; lock the shared document/script resource only around the critical path.
- Design repeated and overlapping executions to produce the same final state.
- Write processed/checkpoint state at a point that cannot hide an ambiguous external side effect.
- Scan existing triggers before installation.
- Record who creates installable triggers: they run as that creator, programmatic edits normally do not fire them, and triggers created by another account are not visible to the current account.
- If a missing authorization scope prevents optional trigger installation, report the gap without corrupting workbook setup.

For a slow external side effect, default to:

1. Lock, re-read, validate, mint the request ID, and mark rows in progress.
2. Release the lock and call the provider.
3. Lock, re-read the claimed state, and finalize the result.
4. Provide a time-bounded recovery/reconciliation path for stale in-progress rows.

The in-progress state must be ineligible to sibling runs. If the provider contract requires a different sequence, document why it stays duplicate-safe.

## LOGS AND USAGE

Use one allowlisted structured event shape containing only needed fields such as time, tenant, object, action, state, request ID, external reference, result, and safe error code.

- At the log seam, remove credential-bearing fields/URLs and known secret values; key-name redaction alone is not sufficient.
- Keep diagnostic logs bounded only when no durable business rule depends on discarded rows.
- Do not enforce quotas or billing from a rolling log. Maintain a durable counter/ledger with sufficient retention.

## SCALE EXIT

Define a move-off-Sheets signal before growth: approaching workbook/cell limits, sustained concurrent writers, high-frequency ingestion, or repeated timeouts after batching/chunking. Move the transactional/high-volume data, not necessarily the operator-facing Sheet.
