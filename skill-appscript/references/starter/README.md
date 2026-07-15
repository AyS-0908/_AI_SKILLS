# Starter — bound-Sheet MVP skeleton

Clasp-ready skeleton for a NEW Google Sheets + Apps Script tool. The Sheet is
NOT a template file: `bootstrapRun()` **generates** the workbook from the
schema, idempotently. Copy this folder, fill in the placeholders, run.

**Provenance & trust:** extracted from shipped projects and vetted against
this skill's rule files. Source projects evolve and contain project-specific
choices — the *machinery* here is the asset; every VALUE (tabs, fields,
statuses, labels) is a placeholder to replace, never a recommendation.

## Ready to run (change values, keep machinery)

| File | Gives you |
|---|---|
| `src/00_Constants.gs` | One frozen `SCHEMA` (keys ≠ labels), derived headers, status machine + `assertTransition` |
| `src/SheetIO.gs` | Header-name I/O, exactly-one-match by-id updates, ID minting, transition chokepoint |
| `src/Config.gs` | Setup-tab key/value config, fail-fast required getters, secret-by-property-NAME |
| `src/Log.gs` | One redacted structured event per state change; ring-buffered — diagnostics only |
| `src/Bootstrap.gs` | Rerunnable non-destructive build: ensure → repair headers (pure `planHeaderRepair_`) → freeze → strict dropdowns → seed-if-empty; collects warnings, never aborts setup on cosmetics |
| `src/Test.gs` + `tools/gas_mock_run.js` | Offline harness running the real `.gs` unchanged against fakes |

## Scaffolded — fill in

- `00_Constants.gs` SCHEMA: replace the placeholder `items` tab with your real tabs/fields/statuses.
- `Ui.gs` `menuTree_`: one entry per operator action; keep the one-alert result contract.
- `Test.gs`: one suite per behavior you add; never loosen an assert to pass.
- External APIs: copy the matching pattern from `references/build-patterns.md`
  (URLFETCH_JSON, RETRY_POLICY, CLAIM_CALL_FINALIZE, CHECKPOINT_RESUME) — one
  thin adapter per real provider, no generic layer.

## Verify

```
node tools/gas_mock_run.js   # exit 0 = green; run before every handoff
```

Then in the editor: run `bootstrapRun` twice on a fresh workbook (second run
must be a no-op), then `testRunAll`.

## Setup with clasp

`npm i -g @google/clasp`, `clasp login`, `clasp create --type sheets --rootDir src`
(or `clasp clone <scriptId> --rootDir src`). Keep `.clasprc.json` out of git —
its token is a credential. Source of truth is this repo, never the cloud editor.
