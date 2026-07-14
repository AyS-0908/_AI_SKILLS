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

## EVIDENCE POLICY

- Tag `EXTERNAL` only when an official source directly supports the platform fact.
- Tag project techniques `PROJECT_REPORTED`, `OBSERVED`, or `SYNTHESIZED`; do not imply independent proof or Google endorsement.
- Re-check official docs when quotas, authorization, deployment, service behavior, or limits affect a build.
- Promote `SPEC` only after runnable implementation, tests, and real use—not because the design sounds sensible.
