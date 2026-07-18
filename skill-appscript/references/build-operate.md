# BUILD & OPERATE

> **Purpose:** co-locate the architecture, deployment, long-job, scale, and lifecycle rules with the implementation "how" for taking an Apps Script tool from MVP through production operation.

## Contents

- [Architecture rung](#architecture-rung)
- [Long-running & resumable jobs](#long-running--resumable-jobs)
- [Deployment & source control](#deployment--source-control)
- [Multi-user distribution gate](#multi-user-distribution-gate)
- [MVP -> Editor add-on](#mvp---editor-add-on)
- [Scale exit](#scale-exit)
- [Config-driven workflow engine — admission gate](#config-driven-workflow-engine--admission-gate)
- [Greenfield kickoff — a NEW tool from scratch](#greenfield-kickoff--a-new-tool-from-scratch)
- [Retired designs — surviving decisions](#retired-designs--surviving-decisions)
- [Out of scope](#out-of-scope)

## Architecture rung

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| A-02 | DEFAULT | PROJECT_REPORTED + OBSERVED | New stateful tool | Prefer a coded v1 for state, side effects, and integration logic. Keep a formula prototype only when its calculation ownership and limitations are explicit. | Start with an engine because it may be useful later, or silently make a prototype formula part of the production contract. |
| A-03 | WHEN | SPEC | Workflow architecture | Use a config-driven engine only when the owner must create and frequently edit many similar workflows without redeployment. | Ship the unfinished engine for one stable workflow. |
| A-06 | WHEN | EXTERNAL + PROJECT_REPORTED | A Sheets tool will serve several operators | First classify the workbook lifecycle, then select a replaceable template, managed bound-project fleet, versioned library, or Editor add-on through the distribution gate below. Keep Git/`clasp` source control separate from this runtime choice. | Choose by code-file count, treat `clasp` and a library as alternatives, or use a library only to obtain automatic updates. |

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
- Add authorization scopes only for shipped behavior. To stay within a narrow scope like `drive.file`, reuse resources by stored ID (properties), never by Drive-wide name search.
- Use versioned deployments for public surfaces; validate the actual trigger creator, execute-as setting, menu, web app URL, and deployed version the operator uses.
- Treat a missing optional scope as a visible setup gap, not permission to leave a half-built workbook.

## Multi-user distribution gate

`clasp` answers **how the owner develops and synchronizes source**. The rows below answer **how operators receive and run the product**. Use both decisions; never collapse them into “`clasp` versus Library.”

### 1. Classify the workbook before choosing

| Signal | Choose | Avoid |
|---|---|---|
| Generated workbook is disposable, contains no durable operator state, and needs no continuing automation | **Replaceable template:** version the master; create future outputs from the new version; leave old outputs alone. | Fleet updates or migration machinery for outputs that can simply be regenerated. |
| Each workbook remains in daily use and holds operator data, config, secrets, or triggers | **Managed bound-project fleet** for a controlled pilot; target an add-on when self-service becomes necessary. | Replacing the workbook and losing or migrating durable state. |
| Two or more consuming script projects share one stable core but retain different container-specific code | **Versioned Library**, with thin coarse calls and deliberate consumer upgrades. | A Library whose only purpose is “automatic updates,” or a chatty Library on latency-sensitive paths. |
| Users must install independently, the owner cannot retain workbook editor access, or Marketplace distribution is now justified | **Editor add-on.** | Extending a trusted-editor fleet beyond its accepted trust/support boundary. |

If a generator's **master workbook** is durable but its generated outputs are disposable, manage only the master with Git/`clasp`; do not enroll the outputs in a fleet.

### 2. Define the update contract in every multi-user SPEC

| Required decision | Minimum contract |
|---|---|
| Source of truth | One Git commit/release owns code. Never maintain competing editor and repository versions. |
| Durable state | State what lives per workbook: operator data, configuration, secrets, IDs, triggers, and generated artifacts. Keep it outside centrally overwritten code. |
| Code-only update | Push one audited commit to canary. IF version, health, or one critical workflow fails, stop and do not promote. Otherwise push the same commit to the fleet; rollback = redeploy the previous known-good commit. |
| Workbook structure/data update | Before live users, prefer a fresh copy. After durable user data exists, use a versioned, idempotent, rerunnable, non-destructive migration with backup, live verification, and restore/rollback steps; a code push alone is insufficient. |
| New authorization scope | Declare the scope delta and reason. Have a canary operator reauthorize and verify the affected workflow before rollout; give every operator the exact reauthorization step. |
| Trigger/config update | Have the designated operator run a versioned setup/repair action; verify the intended trigger count, creator account, timezone, configuration, and last successful run. |
| Trust boundary | State who can edit/read each workbook and code, whether the owner can access workbook data or secrets, and what the operator explicitly accepts. |
| Release control | Name canary target(s), promotion check, fleet group, previous known-good commit, and rollback command/process. Never push an unaudited source state. |
| Observability | Expose a product version and a user-runnable health result; provide a source-vs-target drift/status check for a fleet. Ask for the version before support diagnosis. |
| Trigger ownership | Name one designated account per workbook for installable-trigger setup and health checks; record timezone, expose the last successful run, and surface trigger failure to the operator. |
| Capacity proof | Test the largest expected workload per operator/account, not only the total number of workbooks. |
| Add-on exit signal | Move when self-service install, zero-action centralized updates, reduced owner access, or fleet support cost outweighs add-on conversion/review cost. |

### 3. Managed bound-project fleet invariants

- Keep shipped code byte-identical across targets; exclude test-only files deliberately.
- Keep global catalogs/defaults that are identical for every operator in code. Keep per-workbook data, config, IDs, and secrets in their approved per-workbook stores; never put secrets in shipped source.
- Treat a fleet push as a full-project replacement: prohibit per-workbook code customization and say so during onboarding.
- Keep the target registry private and free of secrets; map each stable script ID to a human label, workbook ID/URL, canary/fleet group, expected version, trigger owner, and timezone.
- Push one audited commit to canary, verify version + health + one critical workflow, then promote the same commit to the fleet.
- Roll back by redeploying the previous known-good Git commit. Do not invent a second release registry when Git already owns history.
- Run drift/status checks before rollout and support work; fix centrally, never patch one operator's code copy.

### 4. Library admission gate

Use a Library only when all are true:

- At least two consuming script projects need one stable core while retaining different container-specific code. IF consumers should ship byte-identical full code, use a fleet instead.
- Consumers can pin a tested version and upgrade deliberately; production does not use HEAD/development mode.
- Public calls are coarse enough that Library latency is acceptable.
- Ownership of properties, cache, locks, triggers, and UI/container calls is explicit and live-tested from a consumer.
- Consumer-specific menus, triggers, authorization, and workbook wiring remain outside the Library.

Otherwise keep the code inside each managed bound project. A future add-on may reuse the same internal service boundaries without preserving the Library as its runtime boundary.

## MVP -> Editor add-on

Rule `A-06` governs this transition and lives in the [Architecture rung](#architecture-rung) section above.

When a bound MVP must be tested by about 20 users before becoming a Sheets Editor add-on:

- Keep `onOpen`, `onEdit`, installable-trigger handlers, menus, and workbook-specific wiring thin. Keep reusable business rules and service adapters decoupled from active-workbook/UI state, whether they ship inside the bound project or through an admitted Library.
- Prefer a managed full-code fleet for a controlled 20–50-user pilot when workbooks are durable, operators accept owner editor access, and rapid canary/rollback matters more than self-service installation.
- If the Library admission gate passes, expose a few coarse methods such as `Tool.getStatus()` or `Tool.runAction(input)`, pin a tested version, and give testers the required Library access.
- Before Marketplace publication, use a standalone add-on project with a standard Google Cloud project; declare and review scopes, test install/authorization states, decide per-user versus per-document storage and secrets, and validate menus/UI plus the release-update path.
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

Otherwise stay with a coded v1. A retired experimental engine design exists in project history (AIssistant, spec-only, never code-verified); it is not a reusable default — if the gate is ever approved, inspect the real engine source, not the old spec.

## Greenfield kickoff — a NEW tool from scratch

Founder-facing artifacts first (they become the code), then scaffold:

1. **User story + features table** — one row per feature: `Feature | Trigger (menu path) | Input | Output | Irreversible?`.
2. **Per-tab layout** — header row + 2 example rows per tab, each column tagged `[auto]` (code-written) or `[input]` (operator). This IS the future `SCHEMA`.
3. **One form mockup per menu action** — first field selects the entity by NAME; the server re-resolves the ID.
4. **Status lifecycle** — codes, legal transitions, one next action per state.
5. **Scaffold from `references/starter/`** (clasp-ready skeleton; its README says what is ready vs to fill). Encode artifacts 2–4 into `00_Constants.gs`. Copy API patterns from `references/build-patterns.md` per provider.
6. **Verify before handover:** `node tools/gas_mock_run.js` green, then bootstrap twice on a fresh workbook — the second run must be a no-op.

**Ground truth, not gospel:** `C:\Users\aymar\AYS_CODING\code-GO_VIRAL\src` (shipped bound tool — mid-refactor, see its `goviral_plan_module_1.md` before trusting content) and `C:\Users\aymar\AYS_CODING\code-HRIS\Code Base\apps-script` (setup/provisioning harness). Mine them for reflection on real problems; they also carry project-specific and superseded choices. The vetted, portable machinery already lives in the starter and `build-patterns.md`.

## Retired designs — surviving decisions

Each row is a design that shipped in a source project and was then removed; keep the surviving decision.

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
