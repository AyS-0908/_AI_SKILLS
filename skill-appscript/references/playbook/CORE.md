# GOOGLE SHEETS + APPS SCRIPT TOOL PLAYBOOK — CORE

> **Status:** candidate v2. Audited against current official Google guidance on 2026-07-14; project-born rules remain labeled separately from platform facts.
>
> **Purpose:** standing context for an AI coder designing or building a new Google Sheets + Apps Script + external-API tool. Project-specific context still wins on product behavior.

## LOAD CONTRACT

Load this file for relevant SPEC, BUILD, AUDIT, or DEBUG work. Load only the matching detail file:

- Sheet schema, I/O, tenancy, config, triggers, or logs: `sheets-data.md`
- Forms, server trust, or external APIs: `ui-external-apis.md`
- Tests, deployment, reusable assets, or retired designs: `testing-assets.md`
- Rule provenance or official sources: `validation.md` only for maintenance/audit
- Config-driven workflow engine: `experimental-workflow-engine.md` only after rule `A-03` selects it

The original `archive/GSHEET_APPSSCRIPT_PLAYBOOK.md` remains the evidence archive. Do not load it by default.

## RULE SYNTAX

| Field | Values |
|---|---|
| Priority | `MUST` = correctness/security/data risk · `DEFAULT` = preferred v1 design · `WHEN` = conditional |
| Confidence | `EXTERNAL` = directly supported by current official documentation · `PROJECT_REPORTED` = reported shipped in a source project, not independently rerun · `OBSERVED` = workbook/failure evidence · `SYNTHESIZED` = sound project-derived rule, not a platform guarantee · `SPEC` = design-only |

`PROJECT_REPORTED` preserves the source document's maturity claim without calling it proof. `EXTERNAL` does not mean Google mandates the whole design. Nothing tagged `SPEC` is a reusable asset.

## 1. ARCHITECTURE GATES

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| A-01 | MUST | SYNTHESIZED | Always | Let code own the contract and validation for every value it branches on, joins, sends externally, or uses as an ID/status/score. | Trust editable/formula-derived values without validating ownership, freshness, type, and vocabulary. |
| A-02 | DEFAULT | PROJECT_REPORTED + OBSERVED | New stateful tool | Prefer a coded v1 for state, side effects, and integration logic. Keep a formula prototype only when its calculation ownership and limitations are explicit. | Start with an engine because it may be useful later, or silently make a prototype formula part of the production contract. |
| A-03 | WHEN | SPEC | Workflow architecture | Use a config-driven engine only when the owner must create and frequently edit many similar workflows without redeployment. | Ship the unfinished engine for one stable workflow. |
| A-04 | DEFAULT | SYNTHESIZED | External API | Support one provider first. Add one explicit adapter per provider actually supported. | Build hypothetical provider abstractions or expect one wire format to fit unrelated APIs. |
| A-05 | WHEN | PROJECT_REPORTED | Multiple clients share one workbook | Use tenant-aware rows and server-side tenant checks. | Add tenancy machinery to a genuinely single-tenant tool. |

## 2. PRODUCT CONTRACT BEFORE CODE

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| P-01 | DEFAULT | PROJECT_REPORTED | New tool or major workflow | Define the user story, affected tab/form shape, field ownership, and enough examples to remove ambiguity before coding. | Produce speculative screens/tables that do not change implementation decisions. |
| P-02 | MUST | PROJECT_REPORTED | State-driven workflow | Define stable status codes, legal transitions, and the next action for each state. | Scatter status strings and transition rules across handlers. |
| P-03 | MUST | PROJECT_REPORTED | Irreversible action | Identify the action, confirmation information, idempotency risk, and recovery path before build. | Add safety after the first live failure. |
| P-04 | MUST | SYNTHESIZED | Menu, trigger, or web entrypoint | Define target-selection scope, execution identity, timezone/due semantics, and where failures surface. | Leave “which rows, which user, which clock” implicit. |

## 3. SCHEMA AND DATA CONTRACT

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| S-01 | DEFAULT | PROJECT_REPORTED | Structured workbook | Keep one schema source for tab names, stable field keys, displayed headers, lists, statuses, and ownership. Derive secondary maps. | Hand-maintain parallel header/list/editability maps. |
| S-02 | MUST | PROJECT_REPORTED | Friendly or translated headers | Give each field a stable machine key separate from its displayed label. | Branch on labels the operator can rename or translate. |
| S-03 | MUST | SYNTHESIZED | Configurable lists | Keep values used by code comparisons in validated code/config. Put only editorial presentation lists under operator control. | Let editable free text silently change executable vocabulary. |
| S-04 | DEFAULT | PROJECT_REPORTED | Stored labels differ from logic codes | Translate once at the read seam and once at the write seam. | Scatter code/label conversion through feature logic. |
| S-05 | DEFAULT | PROJECT_REPORTED + OBSERVED | Formulas exist | Keep IDs, workflow state, timestamps, and side-effect decisions code-written. If code consumes a formula, explicitly own recalculation timing, error/staleness checks, and tests. | Treat a formula cell as fresh, valid durable state by default. |
| S-06 | MUST | SYNTHESIZED | Schema drift | Preserve unknown owner-added columns, but fail on missing/duplicate required headers or ambiguous renames. | Apply “tolerant” or “strict” behavior to every field indiscriminately. |

## 4. SHEETS I/O AND BOOTSTRAP

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

## 5. TRUST, TENANCY, AND CONCURRENCY

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| T-01 | MUST | PROJECT_REPORTED | HTML/client input | Treat the client as an untrusted selector. Re-resolve identities, eligibility, ownership, and actionable rows on the server. | Execute client-supplied row/id lists directly. |
| T-02 | MUST | EXTERNAL + PROJECT_REPORTED | Multi-tenant workbook | Use tenant IDs and server-side filters for logical separation. If tenants must not see one another's data, use separate files or a real access-controlled backend. | Treat hidden/protected rows or app filtering as confidentiality between people who can open the workbook. |
| T-03 | MUST | PROJECT_REPORTED | Privileged action | Enforce authorization at the server entrypoint. A hidden menu is not a security boundary. | Trust UI visibility as authorization. |
| T-04 | MUST | PROJECT_REPORTED | Trigger/shared write | Gate first, then lock the smallest shared resource and keep reruns idempotent. | Assume triggers cannot overlap or rely only on provider deduplication. |
| T-05 | MUST | SYNTHESIZED | Irreversible batch | Preflight before writes, define row-failure policy, and design compensation/recovery; Sheets and external APIs do not provide one cross-system transaction. | Promise “all or nothing” across a sheet and external side effects. |
| T-06 | MUST | SYNTHESIZED | Slow external side effect | Claim eligible rows and persist request/in-progress state under lock; call outside the lock; finalize under lock; define stale-claim recovery. | Hold a shared lock through a slow network call or leave claimed rows unrecoverable. |

## 6. CONFIG, SECRETS, STATE, AND LOGS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| C-01 | DEFAULT | PROJECT_REPORTED | Configuration | Separate global settings, tenant settings, secrets, and recomputable cache. Give each one owner and scope. | Mix them in one sheet or object. |
| C-02 | MUST | EXTERNAL + SYNTHESIZED | Secrets | Keep secrets out of sheets/source/logs/client responses. Treat PropertiesService as scoped storage, not a vault; all script users share Script Properties. Use a dedicated secret manager when editor access, audit, rotation, or stronger isolation requires it. | Assume a property store encrypts away editor/deployment trust or creates tenant isolation. |
| C-03 | MUST | PROJECT_REPORTED | Required config | Fail clearly on missing required values and duplicate keys; allow tolerant getters only for optional/hot-path display data. | Hide broken required config behind empty strings. |
| C-04 | DEFAULT | PROJECT_REPORTED | External capabilities | Separate system capability from the operator’s enable switch; default live side effects off. | Enable a real external path because the platform supports it. |
| C-05 | MUST | SYNTHESIZED | Logs | Log an allowlisted structured event at one seam, then redact known secret values and credential-bearing fields/URLs before serialization. | Dump raw exceptions, responses, arbitrary objects, or rely only on suspicious key names. |
| C-06 | MUST | SYNTHESIZED | Billing/entitlements | Keep enforceable usage in durable, sufficient-retention state. Use a rolling operational log only for diagnostics. | Enforce billing from a capped log without proving retention. |

## 7. UI BOUNDARIES

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| U-01 | MUST | EXTERNAL + PROJECT_REPORTED | HTML Service | Keep business logic server-side and render untrusted/user/AI text with DOM text nodes or contextually escaped template output. | Put secrets/business rules in HTML or force-print/inject external text as HTML. |
| U-02 | DEFAULT | SYNTHESIZED | Several similar forms | Reuse one field-spec renderer only after repeated form shapes exist. | Build a generic form engine for a single simple dialog. |
| U-03 | MUST | SYNTHESIZED | Irreversible external action | Show the exact intended scope, send only stable selectors needed to express the user's choice, then re-authorize and re-validate server-side. Reconfirm if the scope materially changed. | Treat client IDs/counts as authority or silently execute a different set than the user confirmed. |
| U-04 | DEFAULT | PROJECT_REPORTED | Action result | Return one clear outcome, one next action, and navigate only after success. | Emit multiple dialogs or hide a data-caused empty state. |

## 8. EXTERNAL APIS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| E-01 | DEFAULT | SYNTHESIZED | Provider integration | Keep one thin adapter per real provider/boundary. Let a registry select validated adapters and safe parameters only when users truly switch providers. | Build dynamic arbitrary endpoint/auth/response execution or hypothetical strategy layers. |
| E-02 | MUST | PROJECT_REPORTED | Every call | Validate transport errors, HTTP status, semantic error bodies, JSON shape, and load-bearing fields before state changes. | Treat HTTP 200 or parseable JSON as success. |
| E-03 | MUST | PROJECT_REPORTED | External side effect | Mint a trace/idempotency ID before the call and thread it through the row, log, and provider header when supported. | Make an ambiguous side effect untraceable. |
| E-04 | MUST | SYNTHESIZED | Retry | Base retry on operation idempotency and failure type. Each adapter defines safe failures, attempt cap, delay, and reconciliation contract. | Use one universal retry policy, blind-retry ambiguous writes, or retry forever. |
| E-05 | MUST | SYNTHESIZED | Ambiguous write | Mark for reconciliation. Use a provider lookup only when it has a stable key and unambiguous match contract; otherwise require manual resolution. | Guess whether the write succeeded or issue another create. |
| E-06 | MUST | SYNTHESIZED | Credentials/config write | Keep the old value until the candidate passes a safe validation, then swap once under the appropriate lock; retain a recovery path without echoing either value. | Overwrite first and attempt a racy rollback after failure. |
| E-07 | MUST | PROJECT_REPORTED | AI/provider output | Be strict on fields that drive behavior; tolerate optional metadata; clamp/drop invalid optional values with counts. | Reject a usable result for optional metadata or write off-vocabulary values. |
| E-08 | MUST | PROJECT_REPORTED | Error reporting | Sanitize URLs, headers, bodies, and debug dumps before showing or logging them. | Surface raw provider exceptions that may embed credentials. |

## 9. TESTING, DEPLOYMENT, AND OPERATIONS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| V-01 | MUST | PROJECT_REPORTED | Every behavior change | Leave the smallest runnable check that fails when the rule breaks; exercise the real entrypoint where practical. | Count a silent mock/no-op as coverage. |
| V-02 | DEFAULT | PROJECT_REPORTED | External APIs | Mock the innermost transport so production payload building, validation, and status mapping still run. | Mock the public workflow and bypass the logic being tested. |
| V-03 | WHEN | EXTERNAL + PROJECT_REPORTED | Suite approaches Apps Script runtime | Chunk/resume long work; run larger deterministic checks offline when practical and keep small live smoke suites. | Depend on one cloud run that cannot finish within current quotas. |
| V-04 | MUST | PROJECT_REPORTED | Test data touches live schema | Reserve fixture IDs, exclude them from operator views, and provide deterministic cleanup. | Leave test rows indistinguishable from real rows. |
| V-05 | MUST | EXTERNAL + PROJECT_REPORTED | Deployment/scopes | Keep source in version control, use least-privilege scopes, deploy public surfaces as versions, and validate the exact deployment/trigger identity users run. | Treat saved editor code, a `/dev` URL, or an old deployment as production truth. |
| V-06 | WHEN | EXTERNAL | Data volume or write frequency grows | Define an exit signal from Sheets; consider a database before workbook size, formula load, concurrent writes, or high-frequency ingestion becomes the bottleneck. | Treat Sheets as an indefinitely scalable transactional database. |

## 10. CONDITIONAL PATTERN INDEX

| Need | Load | Gate |
|---|---|---|
| Schema/bootstrap/tenancy/config details | `sheets-data.md` | The project touches that concern. |
| Forms/client trust/external API details | `ui-external-apis.md` | The project exposes HTML or external calls. |
| Test harness/assets/retired lessons | `testing-assets.md` | Implementation or audit needs them. |
| Config-driven workflow engine | `experimental-workflow-engine.md` | `A-03` is satisfied and the user explicitly accepts the engine tax. |
| Rule provenance / platform caveats | `validation.md` | Maintaining or challenging the playbook itself. |
