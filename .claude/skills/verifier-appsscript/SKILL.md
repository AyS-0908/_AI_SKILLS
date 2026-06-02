---
name: verifier-appsscript
description: Verify the AI-SKILLS Apps Script project is syntactically clean, manifest is intact, and clasp is ready to push. Run after every edit to .js files or appsscript.json, and before any clasp push.
---

# verifier-appsscript

Static verification suite for this project. Three checks, all read-only.
If any check fails, stop and report the failure — do not auto-fix without asking.

## Check 1 — JS syntax on every server file

Sources live in `clasp/` (the clasp `rootDir`). Run `node --check` on each of the 10 server files. All must print `OK <filename>`.

```bash
node --check clasp/skill_config.js && echo "OK skill_config.js"
node --check clasp/skill_sheet_adapter.js && echo "OK skill_sheet_adapter.js"
node --check clasp/skill_drive_adapter.js && echo "OK skill_drive_adapter.js"
node --check clasp/skill_github_adapter.js && echo "OK skill_github_adapter.js"
node --check clasp/skill_validator.js && echo "OK skill_validator.js"
node --check clasp/skill_manifest_service.js && echo "OK skill_manifest_service.js"
node --check clasp/skill_sync_planner.js && echo "OK skill_sync_planner.js"
node --check clasp/skill_sync_executor.js && echo "OK skill_sync_executor.js"
node --check clasp/skill_ui_menu.js && echo "OK skill_ui_menu.js"
node --check clasp/skill_logging.js && echo "OK skill_logging.js"
```

Run these in parallel (one tool call per check, batched in one message) for speed.

Skip `clasp/prompt_as_api.js` — out of scope per project owner's decision.

## Check 2 — `appsscript.json` structural sanity

Required invariants:
- `runtimeVersion === "V8"`
- `webapp` block present (required by `prompt_as_api.js`)
- `oauthScopes` includes all five required scopes
- Manifest is valid JSON

**Do NOT assert `executionApi` is absent.** Project owner has explicitly decided not to modify `appsscript.json`; treat its current shape as the contract.

```bash
node -e "const j=JSON.parse(require('fs').readFileSync('clasp/appsscript.json','utf8'));const fail=(m)=>{console.error('FAIL: '+m);process.exit(1)};if(!j.webapp)fail('webapp block missing (prompt_as_api needs it)');if(!Array.isArray(j.oauthScopes)||j.oauthScopes.length===0)fail('oauthScopes empty');const need=['https://www.googleapis.com/auth/spreadsheets.currentonly','https://www.googleapis.com/auth/drive.readonly','https://www.googleapis.com/auth/script.container.ui','https://www.googleapis.com/auth/script.external_request','https://www.googleapis.com/auth/userinfo.email'];for(const s of need)if(j.oauthScopes.indexOf(s)===-1)fail('missing scope: '+s);if(j.runtimeVersion!=='V8')fail('runtimeVersion must be V8');console.log('manifest_ok=true');console.log('scopes='+j.oauthScopes.length);console.log('webapp=present');"
```

## Check 3 — clasp project status

Confirms the local `.clasp.json` points to the expected script ID and clasp can talk to it.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./clasp.ps1 safe-status
```

Output should be a single-line JSON with `filesToPush` (12 files) and `untrackedFiles`. Any thrown error from `clasp.ps1` (mismatched scriptId, missing tooling) is a hard fail.

## Reporting

After all three checks, output a compact status table:

| Check | Result |
|---|---|
| JS syntax (10 files) | ✅ / ❌ + which file(s) failed |
| appsscript.json | ✅ / ❌ + which assertion failed |
| clasp safe-status | ✅ / ❌ + the error |

Followed by one-line summary: `verifier-appsscript: PASS` or `verifier-appsscript: FAIL — <count> issue(s)`.

## Notes for future regeneration

If this file vanishes again (it has happened twice already in this project's history):
- Memory entry `verifier-appsscript-skill` documents the spec and how to recreate this file.
- Permissions for the bash calls are cached in `.claude/settings.local.json` under the project.