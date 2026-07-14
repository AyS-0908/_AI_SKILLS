# TESTING, DEPLOYMENT, ASSETS, AND RETIRED LESSONS

Load with `CORE.md` for implementation or audit. This file is not an asset guarantee; verify source files before copying.

## TEST STRATEGY

- Run real `.gs` code unchanged where possible.
- Fake only the platform/transport seams needed by the behavior.
- Make fakes reproduce failures guarded by production code; a silent no-op mock proves little.
- Mock the innermost HTTP transport so payload building and response mapping remain real.
- Isolate fixture rows with a reserved ID prefix; hide them from operator lists and provide deterministic cleanup.
- Re-derive one critical invariant independently, such as checking every manifest tab/header from the live workbook shape.
- Expose small live smoke suites when a full suite risks the Apps Script execution ceiling.
- Update an assertion only for an explicit contract change; do not loosen it to make a failure green.

Existing `references/build-patterns.md` already owns copy-paste-safe baseline code. Do not duplicate its Sheets adapter, PropertiesService, lock, UrlFetch, web-app, or trigger patterns here.

## DEPLOYMENT

- Keep canonical source in version control and deploy from it.
- Avoid top-level initialization that depends on another file's evaluation order; initialize lazily inside functions when needed.
- Add authorization scopes only for shipped behavior.
- Use versioned deployments for public surfaces; validate the actual trigger creator, execute-as setting, menu, web app URL, and deployed version the operator uses.
- Treat a missing optional scope as a visible setup gap, not permission to leave a half-built workbook.

## CANDIDATE ASSET CATALOG

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

## RETIRED DESIGNS — SURVIVING DECISIONS

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

## EXCLUDED FROM THE PLAYBOOK

- Generic AGENTS/PLAN/PROGRESS workflow belongs to the global/project harness.
- The AyS utility-library catalog is separate inventory, not standing build guidance.
- Provider-specific social-media, SIREN, n8n, and media-host details are project/domain references.
- Exact visual tokens, emoji menu structure, and modal close timing are product decisions.
