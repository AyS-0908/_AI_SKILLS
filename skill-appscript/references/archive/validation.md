# PLAYBOOK VALIDATION — 2026-07-14

Load only when maintaining or challenging the playbook. `CORE.md` remains the operational context.

## VERDICT

The project-derived playbook contains a strong practical core, but the source projects do not prove universal best practice. This audit kept rules that prevent wrong writes, duplicate side effects, secret leaks, and quota failures; softened rules that confused a safe default with a mandate; and kept the workflow engine quarantined as `SPEC`.

| Decision | Rules affected | Why |
|---|---|---|
| Confirmed by official guidance | batched I/O, bounded/chunked work, cache only for recomputable data, trigger/auth identity, least-privilege scopes, versioned deployments, escaped HTML | Direct platform behavior or Google guidance. |
| Retained as hardened practice | stable IDs, schema contracts, claim/call/finalize, idempotency IDs, response validation, server-side revalidation | Not mandated by Apps Script, but they directly prevent realistic corruption or duplicate effects. |
| Softened | code ownership, coded-v1 preference, pre-code artifacts, formula ban, confirmation payloads, provider reconciliation | The original wording rejected valid designs or prescribed unnecessary artifacts. |
| Corrected as unsafe/misleading | same-workbook tenant “security”, cross-system “all or nothing”, PropertiesService as a vault, key-name-only redaction, overwrite-then-rollback secrets, handler-name-only trigger identity | These claims could create false security or brittle recovery. |
| Still experimental | config-driven workflow engine and named engine assets | Design-only material cannot become proven through documentation review. |

## OFFICIAL PLATFORM ANCHORS

| Concern | Official source | What it supports |
|---|---|---|
| Performance | [Apps Script best practices](https://developers.google.com/apps-script/guides/support/best-practices) | Minimize service calls, batch reads/writes, use cache selectively, avoid library overhead in call-heavy HTML UIs, split long work. |
| Limits | [Apps Script quotas](https://developers.google.com/apps-script/guides/services/quotas) | Runtime, simultaneous execution, property, trigger, and UrlFetch limits change; design must not hard-code stale assumptions. |
| Scale exit | [Extend Google Sheets — performance and scaling](https://developers.google.com/apps-script/guides/sheets) | Consider a database near very large workbooks or high-frequency ingestion. |
| Locks | [LockService](https://developers.google.com/apps-script/reference/lock/lock-service) | Document, script, and user locks protect different shared resources; document lock may be unavailable outside a container. |
| Triggers | [Installable triggers](https://developers.google.com/apps-script/guides/triggers/installable) and [simple triggers](https://developers.google.com/apps-script/guides/triggers) | Creator identity, per-account visibility, non-firing programmatic edits, authorization limits, and execution ceilings. |
| Properties/cache | [PropertiesService](https://developers.google.com/apps-script/guides/properties) and [Cache](https://developers.google.com/apps-script/reference/cache/cache) | Property stores have shared/user/document scopes; cache expiration is only a suggestion and cache is not durable state. |
| HTML safety | [Templated HTML](https://developers.google.com/apps-script/guides/html/templates) | Normal print scriptlets escape context; force-printing bypasses escaping. |
| Web identity | [Web apps](https://developers.google.com/apps-script/guides/web) and [Session](https://developers.google.com/apps-script/reference/base/session) | Execute-as/access choices change authority; active user email is unavailable in some contexts. |
| Access boundaries | [Protect, hide and edit sheets](https://support.google.com/docs/answer/1218656) | Protected/hidden sheets are not a confidentiality boundary; trusted sharing remains required. |
| Secrets | [Secret Manager best practices](https://cloud.google.com/secret-manager/docs/best-practices) | Dedicated secrets need IAM, least privilege, audit, and rotation controls beyond a general key-value store. |
| Deployments/scopes | [Deployments](https://developers.google.com/apps-script/concepts/deployments) and [authorization scopes](https://developers.google.com/apps-script/concepts/scopes) | Public use should be versioned; existing deployments must point to new versions; use least-permissive scopes. |
| UI surfaces | [Custom menus and clickable images](https://developers.google.com/apps-script/guides/menus), [UI reference](https://developers.google.com/apps-script/reference/base/ui), and [Editor add-on style guide](https://developers.google.com/workspace/add-ons/guides/editor-style) | Menus/dialogs/sidebars are native surfaces; assigned drawings are browser-only; the add-ons CSS package is guidance for Editor add-ons. |
| Diagnostics | [Apps Script logging](https://developers.google.com/apps-script/guides/logging) | Execution logs are short-lived; Cloud Logging is preferred for multi-user production diagnostics and persists for days, not guaranteed business retention. |
| Local source workflow | [`clasp` guide](https://developers.google.com/apps-script/guides/clasp) | `clasp` supports local development, Git workflows, versions, and deployments; its authentication material must be protected. |
| Add-on choice | [Add-on types](https://developers.google.com/workspace/add-ons/concepts/types), [Editor add-on HTML interfaces](https://developers.google.com/workspace/add-ons/concepts/html-interfaces), and [Workspace add-on restrictions](https://developers.google.com/workspace/add-ons/guides/workspace-restrictions) | Editor add-ons provide Sheets-specific HTML menus/dialogs/sidebars. CardService is more standardized, but Workspace add-ons currently lack active-document context in editors. |
| Library MVP | [Apps Script libraries](https://developers.google.com/apps-script/guides/libraries) and [Editor add-on testing](https://developers.google.com/workspace/add-ons/how-tos/testing-editor-addons) | Libraries provide versioned reuse with some latency; add-on test deployments validate a different installation/auth/UI boundary and do not support installable triggers. |

## EXTERNAL INPUT MERGE — 2026-07-14

Inputs read in full:

- `Google Sheets to SaaS_ UI_UX Transformation Guide.md`
- `External Best Practices & Tricks for Google Sheets + Apps Script.md`

### Merged or corrected

| Input idea | Decision | Playbook location |
|---|---|---|
| Toasts for non-blocking feedback | MERGE, scoped by interaction need | `CORE U-05`; `ui-external-apis.md` |
| Native menus/dialogs/sidebars | MERGE as lightest-surface rule | `CORE U-05`; `ui-external-apis.md` |
| Assigned drawings as buttons | MERGE with official desktop-only caveat and fallback entrypoint | `ui-external-apis.md` |
| Checkbox action | MERGE only with range validation, trigger authorization, and duplicate-safety gates | `ui-external-apis.md` |
| Cloud Logging | MERGE after separating diagnostics from durable business/audit state | `sheets-data.md` |
| `clasp` + Git | MERGE without making CI/CD mandatory | `CORE V-05`; `testing-assets.md` |
| Long-running production jobs | MERGE as bounded chunk + durable checkpoint + idempotent continuation; PropertiesService only for small non-sensitive cursors | `CORE V-07`; `testing-assets.md` |
| Named ranges | MERGE for fixed singleton inputs/outputs; retain header-key adapters for row-oriented tables | `sheets-data.md` |
| Batch I/O, bounded retry, and cache | NO NEW TEXT: already owned by `D-02`, `E-04`, and config/cache guidance | Existing rules |
| Cache “up to 25 minutes” | CORRECT: expiration is a hint; current API allows up to six hours but can evict earlier | Existing cache guidance remains deliberately limit-free |
| Cloud logs as “long-term retention” | CORRECT: useful for production diagnostics, not durable business truth | `sheets-data.md` |
| `gas-local` / `gas-fakes` | DO NOT ENDORSE by name without project need and current package review | `testing-assets.md` |

### Owner decisions — approved 2026-07-14

| Decision | Approved rule |
|---|---|
| MVP appearance | Keep the Sheet lightly styled and workflow-first; do not imitate a full SaaS canvas. |
| Native UI | Target a Sheets Editor add-on using Google's official add-on CSS plus minimal local layout CSS. Do not add third-party UI frameworks by default. |
| Workflow controls | Use validated statuses for state and reversible transitions. Use sidebar/dialog buttons with confirmation for irreversible actions; no checkbox-as-button pattern. |
| MVP distribution | Test about 20 users through a small versioned namespaced library with thin bound-project entrypoints. Test the Editor add-on boundary separately. |
| Namespace | Use one small public namespace for the shared library. Do not wrap every ordinary bound-project function; trigger/menu handlers remain global entrypoints. |

## EVIDENCE POLICY

- Tag `EXTERNAL` only when an official source directly supports the platform fact.
- Tag project techniques `PROJECT_REPORTED`, `OBSERVED`, or `SYNTHESIZED`; do not imply independent proof or Google endorsement.
- Re-check official docs when quotas, authorization, deployment, service behavior, or limits affect a build.
- Promote `SPEC` only after runnable implementation, tests, and real use—not because the design sounds sensible.
