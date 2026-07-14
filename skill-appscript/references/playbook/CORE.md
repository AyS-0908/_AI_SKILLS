# GOOGLE SHEETS + APPS SCRIPT TOOL PLAYBOOK — CORE

> **Status:** candidate v2. Internal project evidence only; external best-practice validation is still pending.
>
> **Purpose:** standing context for an AI coder designing or building a new Google Sheets + Apps Script + external-API tool. Project-specific context still wins on product behavior.

## LOAD CONTRACT

Load this file for relevant SPEC, BUILD, AUDIT, or DEBUG work. Load only the matching detail file:

- Sheet schema, I/O, tenancy, config, triggers, or logs: `sheets-data.md`
- Forms, server trust, or external APIs: `ui-external-apis.md`
- Tests, deployment, reusable assets, or retired designs: `testing-assets.md`
- Config-driven workflow engine: `experimental-workflow-engine.md` only after rule `A-03` selects it

The original `GSHEET_APPSSCRIPT_PLAYBOOK.md` remains the evidence archive. Do not load it by default.

## RULE SYNTAX

| Field | Values |
|---|---|
| Priority | `MUST` = correctness/security/data risk · `DEFAULT` = preferred v1 design · `WHEN` = conditional |
| Confidence | `PROVEN` = reported shipped in source project · `OBSERVED` = workbook/failure evidence · `SYNTHESIZED` = reconciled decision · `SPEC` = design-only · `EXTERNAL` = reserved for later official-source validation |

`PROVEN` preserves the source document's maturity claim; this rewrite did not re-run the source projects. Nothing tagged `SPEC` is a reusable asset.

## 1. ARCHITECTURE GATES

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| A-01 | MUST | SYNTHESIZED | Always | Let code own every value that code reads, branches on, joins, sends to AI, or uses as an ID/status/score. | Feed logic from formulas or formula errors. |
| A-02 | DEFAULT | PROVEN + OBSERVED | New tool | Build a coded v1 tool first. A formula prototype is disposable and must not feed code. | Start with an engine or formula system because it may be useful later. |
| A-03 | WHEN | SPEC | Workflow architecture | Use a config-driven engine only when the owner must create and frequently edit many similar workflows without redeployment. | Ship the unfinished engine for one stable workflow. |
| A-04 | DEFAULT | SYNTHESIZED | External API | Support one provider first. Add one explicit adapter per provider actually supported. | Build hypothetical provider abstractions or expect one wire format to fit unrelated APIs. |
| A-05 | WHEN | PROVEN | Multiple clients share one workbook | Use tenant-aware rows and server-side tenant checks. | Add tenancy machinery to a genuinely single-tenant tool. |

## 2. PRODUCT CONTRACT BEFORE CODE

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| P-01 | MUST | PROVEN | New tool or major workflow | Define the user story, feature table, tab layouts with two example rows, and form sketches before coding. Mark fields as operator input or code-written. | Discover the product contract while implementing it. |
| P-02 | MUST | PROVEN | State-driven workflow | Define stable status codes, legal transitions, and the next action for each state. | Scatter status strings and transition rules across handlers. |
| P-03 | MUST | PROVEN | Every task | State the problem, exact change, and proof/acceptance check. | Treat code-complete as evidence that behavior is correct. |
| P-04 | MUST | PROVEN | Irreversible action | Identify the action, confirmation information, idempotency risk, and recovery path before build. | Add safety after the first live failure. |
| P-05 | MUST | SYNTHESIZED | Menu, trigger, or web entrypoint | Define target-selection scope, execution identity, timezone/due semantics, and where failures surface. | Leave “which rows, which user, which clock” implicit. |

## 3. SCHEMA AND DATA CONTRACT

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| S-01 | DEFAULT | PROVEN | Structured workbook | Keep one schema source for tab names, stable field keys, displayed headers, lists, statuses, and ownership. Derive secondary maps. | Hand-maintain parallel header/list/editability maps. |
| S-02 | MUST | PROVEN | Friendly or translated headers | Give each field a stable machine key separate from its displayed label. | Branch on labels the operator can rename or translate. |
| S-03 | MUST | SYNTHESIZED | Configurable lists | Keep values used by code comparisons in validated code/config. Put only editorial presentation lists under operator control. | Let editable free text silently change executable vocabulary. |
| S-04 | DEFAULT | PROVEN | Stored labels differ from logic codes | Translate once at the read seam and once at the write seam. | Scatter code/label conversion through feature logic. |
| S-05 | MUST | PROVEN + OBSERVED | Formulas exist | Allow formulas only for display values that no code, API payload, dropdown source, or AI context consumes. | Use formulas for IDs, foreign keys, status, timestamps, joins, or scores. |
| S-06 | MUST | SYNTHESIZED | Schema drift | Preserve unknown owner-added columns, but fail on missing/duplicate required headers or ambiguous renames. | Apply “tolerant” or “strict” behavior to every field indiscriminately. |

## 4. SHEETS I/O AND BOOTSTRAP

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| D-01 | MUST | PROVEN | Table-like sheets | Resolve columns from the live header row by stable key/name. | Hardcode column numbers or assume the ID is column A. |
| D-02 | MUST | PROVEN | Loops or batches | Read ranges once, transform arrays in memory, and batch-write once. | Call Sheets/Drive/API services per cell or per row when batching is possible. |
| D-03 | MUST | PROVEN | Reads/writes | Guard empty and header-only sheets; make written array dimensions match the target range exactly. | Call `getRange` with zero dimensions or write jagged arrays. |
| D-04 | MUST | PROVEN | Full-table rewrite | Map across live headers so owner-added columns survive; patch only named keys for row updates. | Rebuild rows only from the declared schema and erase extra columns. |
| D-05 | MUST | PROVEN | Entity IDs | Mint collision-safe IDs; use deterministic parent/natural-key IDs only when that identity is the idempotency key. | Use row count or `max+1` IDs. |
| D-06 | MUST | PROVEN | Update by ID | Require exactly one ID match before mutation. | Update the first of zero/multiple matches. |
| D-07 | DEFAULT | PROVEN | Workbook setup | Make bootstrap rerunnable and non-destructive; seed only empty targets and repair headers conservatively. | Assume a fresh workbook or overwrite operator data. |
| D-08 | WHEN | PROVEN | Existing workbook backfill | Choose blank-fill, version-gated update, or one-time migration explicitly. | Use one blanket overwrite strategy for every migration. |

## 5. TRUST, TENANCY, AND CONCURRENCY

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| T-01 | MUST | PROVEN | HTML/client input | Treat the client as an untrusted selector. Re-resolve identities, eligibility, ownership, and actionable rows on the server. | Execute client-supplied row/id lists directly. |
| T-02 | MUST | PROVEN | Multi-tenant workbook | Store the stable tenant ID on every tenant row, filter every read by it, and re-check related rows before side effects. | Rely on row grouping, displayed names, or an earlier successful check. |
| T-03 | MUST | PROVEN | Privileged action | Enforce authorization at the server entrypoint. A hidden menu is not a security boundary. | Trust UI visibility as authorization. |
| T-04 | MUST | PROVEN | Trigger/shared write | Gate first, then lock the smallest shared resource and keep reruns idempotent. | Assume triggers cannot overlap or rely only on provider deduplication. |
| T-05 | MUST | PROVEN | Irreversible batch | Preflight all rows before applying all-or-nothing changes; define which row failures may degrade instead of aborting. | Write while validating and leave a half-applied batch. |
| T-06 | MUST | SYNTHESIZED | Slow external side effect | Claim eligible rows and persist request/in-progress state under lock; call outside the lock; finalize under lock; define stale-claim recovery. | Hold a shared lock through a slow network call or leave claimed rows unrecoverable. |

## 6. CONFIG, SECRETS, STATE, AND LOGS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| C-01 | DEFAULT | PROVEN | Configuration | Separate global settings, tenant settings, secrets, and recomputable cache. Give each one owner and scope. | Mix them in one sheet or object. |
| C-02 | MUST | SYNTHESIZED | Secrets | Keep secret values out of sheets, source, logs, caches, and client responses. Select property scope from deployment ownership. | Assume Script Properties remain tenant-safe after moving to a shared library/deployment. |
| C-03 | MUST | PROVEN | Required config | Fail clearly on missing required values and duplicate keys; allow tolerant getters only for optional/hot-path display data. | Hide broken required config behind empty strings. |
| C-04 | DEFAULT | PROVEN | External capabilities | Separate system capability from the operator’s enable switch; default live side effects off. | Enable a real external path because the platform supports it. |
| C-05 | MUST | PROVEN | Logs | Write structured events at one seam and recursively redact secret-like fields before serialization. | Depend on every caller to scrub its own log payload. |
| C-06 | MUST | SYNTHESIZED | Billing/entitlements | Keep enforceable usage in durable, sufficient-retention state. Use a rolling operational log only for diagnostics. | Enforce billing from a capped log without proving retention. |

## 7. UI BOUNDARIES

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| U-01 | MUST | PROVEN | HTML Service | Keep business logic server-side and render untrusted/user/AI text with DOM text nodes. | Put secrets/business rules in HTML or inject external text with `innerHTML`. |
| U-02 | DEFAULT | SYNTHESIZED | Several similar forms | Reuse one field-spec renderer only after repeated form shapes exist. | Build a generic form engine for a single simple dialog. |
| U-03 | MUST | PROVEN | Irreversible external action | Show a plain-language count, send only the tenant/action identifier, and re-derive the final set server-side. | Put the actionable ID list in the confirmation payload. |
| U-04 | DEFAULT | PROVEN | Action result | Return one clear outcome, one next action, and navigate only after success. | Emit multiple dialogs or hide a data-caused empty state. |

## 8. EXTERNAL APIS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| E-01 | DEFAULT | SYNTHESIZED | Provider integration | Keep one thin adapter per real provider/boundary. Let a registry select validated adapters and safe parameters only when users truly switch providers. | Build dynamic arbitrary endpoint/auth/response execution or hypothetical strategy layers. |
| E-02 | MUST | PROVEN | Every call | Validate transport errors, HTTP status, semantic error bodies, JSON shape, and load-bearing fields before state changes. | Treat HTTP 200 or parseable JSON as success. |
| E-03 | MUST | PROVEN | External side effect | Mint a trace/idempotency ID before the call and thread it through the row, log, and provider header when supported. | Make an ambiguous side effect untraceable. |
| E-04 | MUST | SYNTHESIZED | Retry | Base retry on operation idempotency and failure type. Each adapter defines safe failures, attempt cap, delay, and reconciliation contract. | Use one universal retry policy, blind-retry ambiguous writes, or retry forever. |
| E-05 | MUST | PROVEN | Ambiguous write | Mark for reconciliation and resolve by a provider read requiring exactly one match. | Guess whether the write succeeded or issue another create. |
| E-06 | MUST | PROVEN | Credentials/config write | Snapshot, validate cheaply, write, and roll back on validation failure without echoing the value. | Overwrite a working secret before validating its replacement. |
| E-07 | MUST | PROVEN | AI/provider output | Be strict on fields that drive behavior; tolerate optional metadata; clamp/drop invalid optional values with counts. | Reject a usable result for optional metadata or write off-vocabulary values. |
| E-08 | MUST | PROVEN | Error reporting | Sanitize URLs, headers, bodies, and debug dumps before showing or logging them. | Surface raw provider exceptions that may embed credentials. |

## 9. TESTING, DEPLOYMENT, AND OPERATIONS

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| V-01 | MUST | PROVEN | Every behavior change | Leave the smallest runnable check that fails when the rule breaks; exercise the real entrypoint where practical. | Count a silent mock/no-op as coverage. |
| V-02 | DEFAULT | PROVEN | External APIs | Mock the innermost transport so production payload building, validation, and status mapping still run. | Mock the public workflow and bypass the logic being tested. |
| V-03 | WHEN | PROVEN | Suite exceeds Apps Script runtime | Run the full suite offline and expose small live smoke suites. | Guarantee a cloud timeout with one “run all” action. |
| V-04 | MUST | PROVEN | Test data touches live schema | Reserve fixture IDs, exclude them from operator views, and provide deterministic cleanup. | Leave test rows indistinguishable from real rows. |
| V-05 | MUST | PROVEN | Deployment/scopes | Keep source in version control, add only scopes required by shipped behavior, and validate the deployed surface the user actually runs. | Treat the cloud editor or an old deployment as source of truth. |

## 10. CONDITIONAL PATTERN INDEX

| Need | Load | Gate |
|---|---|---|
| Schema/bootstrap/tenancy/config details | `sheets-data.md` | The project touches that concern. |
| Forms/client trust/external API details | `ui-external-apis.md` | The project exposes HTML or external calls. |
| Test harness/assets/retired lessons | `testing-assets.md` | Implementation or audit needs them. |
| Config-driven workflow engine | `experimental-workflow-engine.md` | `A-03` is satisfied and the user explicitly accepts the engine tax. |
