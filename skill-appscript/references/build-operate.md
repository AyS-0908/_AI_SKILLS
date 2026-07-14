# BUILD & OPERATE

> **Purpose:** co-locate the architecture, deployment, long-job, scale, and lifecycle rules with the implementation "how" for taking an Apps Script tool from MVP through production operation.

## Contents

- [Architecture rung](#architecture-rung)
- [Long-running & resumable jobs](#long-running--resumable-jobs)
- [Deployment & source control](#deployment--source-control)
- [MVP -> Editor add-on](#mvp---editor-add-on)
- [Scale exit](#scale-exit)
- [Config-driven workflow engine — admission gate](#config-driven-workflow-engine--admission-gate)
- [Reusable assets — do not blindly copy](#reusable-assets--do-not-blindly-copy)
- [Retired designs — surviving decisions](#retired-designs--surviving-decisions)
- [Out of scope](#out-of-scope)

## Architecture rung

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| A-02 | DEFAULT | PROJECT_REPORTED + OBSERVED | New stateful tool | Prefer a coded v1 for state, side effects, and integration logic. Keep a formula prototype only when its calculation ownership and limitations are explicit. | Start with an engine because it may be useful later, or silently make a prototype formula part of the production contract. |
| A-03 | WHEN | SPEC | Workflow architecture | Use a config-driven engine only when the owner must create and frequently edit many similar workflows without redeployment. | Ship the unfinished engine for one stable workflow. |
| A-06 | DEFAULT | SYNTHESIZED | Sheet-led MVP targets a future add-on | Keep bound-project menus/triggers thin and put reusable business logic behind a small versioned library API during multi-user MVP testing. Target a Sheets Editor add-on when the product needs active-document context. | Treat library use by MVP users as proof of add-on installation, authorization, UI, or final runtime performance. |

> Irreversible-action planning lives in the product contract (`data-sheets.md`, rule P-03); the confirmation-flow how-to is in `apis-ui.md` (IRREVERSIBLE ACTIONS).

## Long-running & resumable jobs

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| V-07 | WHEN | SYNTHESIZED | A production job can exceed one execution | Process bounded chunks, persist a durable checkpoint, and continue through an idempotent scheduled run with explicit completion/failure state. | Depend on cache as the cursor, restart blindly, or create unbounded continuation triggers. |

- Stop each run before the execution ceiling, after a bounded record/time budget.
- Persist a job version, cursor, status, and safe error state in an appropriately durable store; do not use CacheService as the checkpoint.
- Make the continuation re-read and revalidate state so a repeated trigger reaches the same result.
- Keep at most one known continuation schedule per job/owner, and remove or retire it on completion.
- Use PropertiesService only for small, non-sensitive cursors; use a sheet or backend when the checkpoint needs larger, inspectable, or independently controlled state.

## Deployment & source control

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| V-05 | MUST | EXTERNAL + PROJECT_REPORTED | Deployment/scopes | Keep source in version control; use `clasp` when local development, Git review, or repeatable deployment is part of the workflow. Use least-privilege scopes, deploy public surfaces as versions, and validate the exact deployment/trigger identity users run. | Maintain competing editor/repository sources, or treat saved editor code, a `/dev` URL, or an old deployment as production truth. |

- Keep canonical source in version control and deploy from it.
- Pick one source of truth; do not alternate unsafely between Apps Script editor changes and repository pushes.
- Keep `.clasprc.json` out of version control. Treat its refresh token as a credential. Decide deliberately whether `.clasp.json` is private project mapping or shared non-secret configuration for the team's workflow.
- Avoid top-level initialization that depends on another file's evaluation order; initialize lazily inside functions when needed.
- Add authorization scopes only for shipped behavior.
- Use versioned deployments for public surfaces; validate the actual trigger creator, execute-as setting, menu, web app URL, and deployed version the operator uses.
- Treat a missing optional scope as a visible setup gap, not permission to leave a half-built workbook.

## MVP -> Editor add-on

Rule `A-06` governs this transition and lives in the [Architecture rung](#architecture-rung) section above.

When a bound MVP must be tested by about 20 users before becoming a Sheets Editor add-on:

- Put reusable business rules and service adapters behind one small versioned library identifier/namespace.
- Keep `onOpen`, `onEdit`, installable-trigger handlers, menus, and workbook-specific wiring in the consuming project; they call the library's public API.
- Expose a few coarse methods such as `Tool.getStatus()` or `Tool.runAction(input)`. End private library functions with `_`; avoid chatty per-field library calls because libraries add execution latency.
- Pin consumers to a tested library version and upgrade deliberately. Give every tester the access required to load the library.
- Test the future Editor add-on separately through an Editor add-on test deployment. Library usage does not exercise installation, authorization lifecycle, menu/sidebar behavior, or Marketplace packaging.
- Do not assume the library must remain the final add-on runtime boundary. Keep it only if measured latency and deployment ergonomics remain acceptable.
- Editor add-on test deployments do not support installable triggers; validate trigger-dependent behavior through a separate controlled path.

## Scale exit

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| V-06 | WHEN | EXTERNAL | Data volume or write frequency grows | Define an exit signal from Sheets; consider a database before workbook size, formula load, concurrent writes, or high-frequency ingestion becomes the bottleneck. | Treat Sheets as an indefinitely scalable transactional database. |

Define a move-off-Sheets signal before growth: approaching workbook/cell limits, sustained concurrent writers, high-frequency ingestion, or repeated timeouts after batching/chunking. Move the transactional/high-volume data, not necessarily the operator-facing Sheet.

## Config-driven workflow engine — admission gate

Use an engine only when all are true:

- The owner must create and edit many similar workflows without redeployment.
- Workflow count and change frequency make coded v1 changes materially costly.
- The owner accepts a second executable source of truth in a sheet.
- The project will build validation, guided authoring, versioning/backup, and engine tests.

Otherwise stay with a coded v1. The full experimental engine design is archived and is not a reusable default.

## Reusable assets — do not blindly copy

These names are leads from the source playbook, not a reusable library. **Do not copy until the real source exists, its license/ownership is clear, and its behavior passes current checks.**

| Candidate | Intended value | Default action |
|---|---|---|
| `00_Constants.gs` schema pattern | One schema source and derived maps | Recreate the small pattern; do not assume the named file transfers. |
| `SheetIO.gs` | Header-name I/O, IDs, tenant filtering | Prefer existing `references/build-patterns.md`; inspect source before any larger lift. |
| `Bootstrap.gs` | Rerunnable workbook construction | Lift only after rerun and data-preservation checks. |
| `Config.gs` | Global/tenant config and secret-name resolution | Adapt property scope to deployment. |
| `Log.gs` | Structured/redacted audit events | Do not inherit a fixed retention cap blindly. |
| `ux_form.html` / `ux_confirm.html` | Repeated form and confirmation surfaces | Use only when the project has enough repeated UI to justify them. |
| `ux_style.html` | Shared dialog styles | Skip until repeated dialogs justify a shared asset. |
| `tools/gas_mock_run.js` | Offline execution of real `.gs` files | Verify mocks and file load behavior. |
| Provider adapter files | Boundary-specific HTTP mapping | Copy only the relevant provider, not a generic layer. |

Real runnable recipes now live in `references/build-patterns.md`.

## Retired designs — surviving decisions

Keep only the decision; consult the original playbook for project history.

| Prefer | Avoid |
|---|---|
| Select human-readable entities, resolve stable IDs server-side. | Ask operators to type internal IDs. |
| Server-computed actionable sets. | Duplicate row-selection logic in HTML. |
| Sheet status for human approval. | Broad-scope email approval machinery without a proven need. |
| Fresh-workbook-only delivery before users exist. | Migration infrastructure for users who do not exist. |
| One writer per generated surface. | Bootstrap and updater both owning the same block. |
| Business-state changes only through explicit workflow actions. | State changes as side effects of technical actions. |
| Status queues for batches. | Per-row pickers that stop scaling quickly. |
| Fixed anchors plus protection for system blocks. | Searching operator-editable text as the idempotency marker. |
| Small live suites plus full offline verification. | A guaranteed-timeout “run all” cloud button. |

## Out of scope

- Generic AGENTS/PLAN/PROGRESS workflow belongs to the global/project harness.
- The AyS utility-library catalog is separate inventory, not standing build guidance.
- Provider-specific social-media, SIREN, n8n, and media-host details are project/domain references.
- Exact visual tokens, emoji menu structure, and modal close timing are product decisions.
- Third-party UI frameworks, icon packs, and local GAS test packages are dependencies, not standing best practices. Add one only when a project-specific need outweighs its maintenance and supply-chain cost.
