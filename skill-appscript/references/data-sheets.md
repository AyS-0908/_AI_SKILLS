# DATA & SHEETS — SCHEMA, I/O, TENANCY, CONFIG, TRIGGERS, LOGS

> **Purpose:** co-located rules + implementation "how" for everything that touches the workbook as a data store — schema, headers, sheet I/O, IDs, bootstrap, tenancy, config, secrets, locks, triggers, state, and logs.

## CONTENTS

1. [Rule syntax legend](#rule-syntax-legend)
2. [Architecture & ownership](#architecture--ownership)
3. [Product contract before code](#product-contract-before-code)
4. [Schema & data contract](#schema--data-contract)
5. [Sheet I/O & IDs](#sheet-io--ids)
6. [Trust, tenancy & concurrency](#trust-tenancy--concurrency)
7. [Config, secrets, state & logs](#config-secrets-state--logs)

## RULE SYNTAX LEGEND

Tags on each rule row mean:

| Field | Values |
|---|---|
| Priority | `MUST` = correctness/security/data risk · `DEFAULT` = preferred v1 design · `WHEN` = conditional |
| Confidence | `EXTERNAL` = directly supported by current official documentation · `PROJECT_REPORTED` = reported shipped in a source project, not independently rerun · `OBSERVED` = workbook/failure evidence · `SYNTHESIZED` = sound project-derived rule, not a platform guarantee · `SPEC` = design-only |

`PROJECT_REPORTED` preserves the source document's maturity claim without calling it proof. `EXTERNAL` does not mean Google mandates the whole design. Nothing tagged `SPEC` is a reusable asset.

## ARCHITECTURE & OWNERSHIP

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| A-01 | MUST | SYNTHESIZED | Always | Let code own the contract and validation for every value it branches on, joins, sends externally, or uses as an ID/status/score. | Trust editable/formula-derived values without validating ownership, freshness, type, and vocabulary. |
| A-05 | WHEN | PROJECT_REPORTED | Multiple clients share one workbook | Use tenant-aware rows and server-side tenant checks. | Add tenancy machinery to a genuinely single-tenant tool. |

## PRODUCT CONTRACT BEFORE CODE

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| P-01 | DEFAULT | PROJECT_REPORTED | New tool or major workflow | Define the user story, affected tab/form shape, field ownership, and enough examples to remove ambiguity before coding. | Produce speculative screens/tables that do not change implementation decisions. |
| P-02 | MUST | PROJECT_REPORTED | State-driven workflow | Define stable status codes, legal transitions, and the next action for each state. | Scatter status strings and transition rules across handlers. |
| P-03 | MUST | PROJECT_REPORTED | Irreversible action | Identify the action, confirmation information, idempotency risk, and recovery path before build. | Add safety after the first live failure. |
| P-04 | MUST | SYNTHESIZED | Menu, trigger, or web entrypoint | Define target-selection scope, execution identity, timezone/due semantics, and where failures surface. | Leave “which rows, which user, which clock” implicit. |

> P-02 has a runnable guard: `STATUS` / `TRANSITIONS` / `assertTransition_` in `build-patterns.md` (STATUS_MACHINE). Validate every status write through it so an illegal or stale transition throws instead of being written.

## SCHEMA & DATA CONTRACT

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| S-01 | DEFAULT | PROJECT_REPORTED | Structured workbook | Keep one schema source for tab names, stable field keys, displayed headers, lists, statuses, and ownership. Derive secondary maps. | Hand-maintain parallel header/list/editability maps. |
| S-02 | MUST | PROJECT_REPORTED | Friendly or translated headers | Give each field a stable machine key separate from its displayed label. | Branch on labels the operator can rename or translate. |
| S-03 | MUST | SYNTHESIZED | Configurable lists | Keep values used by code comparisons in validated code/config. Put only editorial presentation lists under operator control. | Let editable free text silently change executable vocabulary. |
| S-04 | DEFAULT | PROJECT_REPORTED | Stored labels differ from logic codes | Translate once at the read seam and once at the write seam. | Scatter code/label conversion through feature logic. |
| S-05 | DEFAULT | PROJECT_REPORTED + OBSERVED | Formulas exist | Keep IDs, workflow state, timestamps, and side-effect decisions code-written. If code consumes a formula, explicitly own recalculation timing, error/staleness checks, and tests. | Treat a formula cell as fresh, valid durable state by default. |
| S-06 | MUST | SYNTHESIZED | Schema drift | Preserve unknown owner-added columns, but fail on missing/duplicate required headers or ambiguous renames. | Apply “tolerant” or “strict” behavior to every field indiscriminately. |

### SCHEMA SHAPE

- Declare one schema containing tab names, stable keys, displayed headers, field ownership, lists, and status codes.
- Derive headers, editable fields, dropdowns, coded fields, and date-format columns from it.
- Use safe defaults: visible unless hidden; read-only unless explicitly editable; displayed label falls back to key.
- Keep code-owned vocabularies separate from editorial lists. Validate any sheet-based executable config before use.
- Use named ranges for stable singleton inputs/outputs when they improve readability; validate that each required name exists. Use header-key adapters for row-oriented tables.
- Translate stored labels and logic codes only at Sheet I/O seams.
- Keep IDs, workflow state, and side-effect decisions code-written. A formula consumed by code needs explicit freshness/error checks; `SpreadsheetApp.flush()` applies pending writes but is not a substitute for a tested calculation contract.

### HEADER AND COLUMN POLICY

Build a live `key -> index` map for each operation. By default, use stable protected machine headers and put friendly wording in notes/UI. If headers must be renamed or translated, add a separately validated key row or metadata layer; do not guess keys from labels.

Header repair decision:

| State | Action |
|---|---|
| Blank header row | Write the declared headers. |
| Required headers present once | Continue. |
| Missing required headers, no unknown headers | Append only missing headers. |
| Missing and unknown headers together | Stop: likely rename ambiguity. |
| Duplicate required header | Stop. |

> This decision is a pure function: `planHeaderRepair_(actual, required)` in `build-patterns.md` (SHEETS_TABLE_ADAPTER) returns `write_headers` / `continue` / `append_missing` / `stop`. Branch on its result instead of re-judging the table by hand.

Preserve unknown owner-added columns during full-table writes. Tolerance ends at structural identity: required headers, IDs, tenant keys, and required config must be strict.

### BOOTSTRAP

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

## SHEET I/O & IDS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| D-01 | MUST | PROJECT_REPORTED | Table-like sheets | Resolve columns from the live header row by stable key/name. | Hardcode column numbers or assume the ID is column A. |
| D-02 | MUST | EXTERNAL + PROJECT_REPORTED | Loops or batches | Read ranges once, transform arrays in memory, and batch-write once. | Call Sheets/Drive/API services per cell or per row when batching is possible. |
| D-03 | MUST | PROJECT_REPORTED | Reads/writes | Guard empty and header-only sheets; make written array dimensions match the target range exactly. | Call `getRange` with zero dimensions or write jagged arrays. |
| D-04 | MUST | SYNTHESIZED | Mixed-ownership sheet | Prefer targeted writes. If a full-table rewrite is unavoidable, preserve unknown columns and formulas explicitly. | Round-trip `getValues()` across operator/formula columns and silently replace formulas or owner data. |
| D-05 | MUST | PROJECT_REPORTED | Entity IDs | Mint collision-safe IDs; use deterministic parent/natural-key IDs only when that identity is the idempotency key. | Use row count or `max+1` IDs. |
| D-06 | MUST | PROJECT_REPORTED | Update by ID | Require exactly one ID match before mutation. | Update the first of zero/multiple matches. |
| D-07 | DEFAULT | PROJECT_REPORTED | Workbook setup | Make bootstrap rerunnable and non-destructive; seed only empty targets and repair headers conservatively. | Assume a fresh workbook or overwrite operator data. |
| D-08 | WHEN | PROJECT_REPORTED | Existing workbook backfill | Choose blank-fill, version-gated update, or one-time migration explicitly. | Use one blanket overwrite strategy for every migration. |

### IDS AND ROW WRITES

- Mint entities with a prefix plus a collision-safe random ID.
- Use a deterministic `{parentId}_{naturalKey}` only when it is the stable identity for an imported/junction row.
- Pair machine IDs with a code-written display-name snapshot for humans; always join by ID.
- Before update/delete/transition, require exactly one ID match. Use `findRowById_` in `build-patterns.md` (SHEETS_TABLE_ADAPTER); it throws on zero or multiple matches (D-06) rather than mutating the first hit.
- For a full rewrite, map objects across all live headers.
- For one row, read once, patch named cells in memory, write once.

## TRUST, TENANCY & CONCURRENCY

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| T-01 | MUST | PROJECT_REPORTED | HTML/client input | Treat the client as an untrusted selector. Re-resolve identities, eligibility, ownership, and actionable rows on the server. | Execute client-supplied row/id lists directly. |
| T-02 | MUST | EXTERNAL + PROJECT_REPORTED | Multi-tenant workbook | Use tenant IDs and server-side filters for logical separation. If tenants must not see one another's data, use separate files or a real access-controlled backend. | Treat hidden/protected rows or app filtering as confidentiality between people who can open the workbook. |
| T-03 | MUST | PROJECT_REPORTED | Privileged action | Enforce authorization at the server entrypoint. A hidden menu is not a security boundary. | Trust UI visibility as authorization. |
| T-04 | MUST | PROJECT_REPORTED | Trigger/shared write | Gate first, then lock the smallest shared resource and keep reruns idempotent. | Assume triggers cannot overlap or rely only on provider deduplication. |
| T-05 | MUST | SYNTHESIZED | Irreversible batch | Preflight before writes, define row-failure policy, and design compensation/recovery; Sheets and external APIs do not provide one cross-system transaction. | Promise “all or nothing” across a sheet and external side effects. |
| T-06 | MUST | SYNTHESIZED | Slow external side effect | Claim eligible rows and persist request/in-progress state under lock; call outside the lock; finalize under lock; define stale-claim recovery. | Hold a shared lock through a slow network call or leave claimed rows unrecoverable. |

### TENANCY AND SIDE EFFECTS

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

### LOCKS, TRIGGERS, AND STATE

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

## CONFIG, SECRETS, STATE & LOGS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| C-01 | DEFAULT | PROJECT_REPORTED | Configuration | Separate global settings, tenant settings, secrets, and recomputable cache. Give each one owner and scope. | Mix them in one sheet or object. |
| C-02 | MUST | EXTERNAL + SYNTHESIZED | Secrets | Keep secrets out of sheets/source/logs/client responses. Treat PropertiesService as scoped storage, not a vault; all script users share Script Properties. Use a dedicated secret manager when editor access, audit, rotation, or stronger isolation requires it. | Assume a property store encrypts away editor/deployment trust or creates tenant isolation. |
| C-03 | MUST | PROJECT_REPORTED | Required config | Fail clearly on missing required values and duplicate keys; allow tolerant getters only for optional/hot-path display data. | Hide broken required config behind empty strings. |
| C-04 | DEFAULT | PROJECT_REPORTED | External capabilities | Separate system capability from the operator’s enable switch; default live side effects off. | Enable a real external path because the platform supports it. |
| C-05 | MUST | SYNTHESIZED | Logs | Log an allowlisted structured event at one seam, then redact known secret values and credential-bearing fields/URLs before serialization. | Dump raw exceptions, responses, arbitrary objects, or rely only on suspicious key names. |
| C-06 | MUST | SYNTHESIZED | Billing/entitlements | Keep enforceable usage in durable, sufficient-retention state. Use a rolling operational log only for diagnostics. | Enforce billing from a capped log without proving retention. |

### CONFIG, PROPERTY SCOPE, AND CACHE

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

### LOGS AND USAGE

Use one allowlisted structured event shape containing only needed fields such as time, tenant, object, action, state, request ID, external reference, result, and safe error code.

- Use the execution log for short development checks. Use Cloud Logging/Error Reporting for production diagnostics when the project setup and retention fit the need. Keep business/audit truth in a durable application-owned store.
- Prefer `console`/Cloud Logging over a custom diagnostic sheet unless operators genuinely need to inspect those diagnostics in Sheets.
- Do not log personal data merely to identify a user; use the platform's temporary active-user key where applicable.
- At the log seam, remove credential-bearing fields/URLs and known secret values; key-name redaction alone is not sufficient.
- Keep diagnostic logs bounded only when no durable business rule depends on discarded rows.
- Do not enforce quotas or billing from a rolling log. Maintain a durable counter/ledger with sufficient retention.
