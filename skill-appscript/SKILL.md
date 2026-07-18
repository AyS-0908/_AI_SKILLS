---
name: appscript
description: >
  Google Apps Script Skill for SPEC, BUILD, AUDIT, and DEBUG of robust v1
  Apps Script systems: Sheets automations, bound scripts, triggers, web apps,
  and Apps Script service integrations. Trigger for: Google Apps Script, GAS,
  .gs files, Google Sheets automation, bound scripts, onEdit/onOpen triggers,
  doGet/doPost web apps, SpreadsheetApp, PropertiesService, LockService,
  CacheService, UrlFetchApp, clasp. Do NOT trigger for: spreadsheet formulas
  without scripting, Google Sheets UI-only help, generic JavaScript or Node.js
  outside Apps Script, generic audits not tied to Apps Script, or PRDs for
  non-Apps-Script products.
---

# GOOGLE_APPS_SCRIPT_SKILL

## GOTCHAS

- IF a local/project read is empty or incomplete, stop, report it, and verify the path, script ID, access, and encoding; never treat an empty read as an empty project.
- IF a `clasp` or Apps Script API target, authorization, or push check fails, log the non-secret error, notify the user, and stop; never guess another target or deploy from an unverified source state.
- Before a full-project push, verify the exact script ID and source commit because Apps Script content updates replace the target project's files.
- IF an external API has a transport, semantic, or response-shape error, log non-secret context, notify the user, and stop or use only an explicitly safe fallback.

This Skill assumes AGENTS.md already governs global coding behavior. Do not restate global coding rules here.

## ROLE

Expert Google Apps Script builder and auditor for simple, robust v1 systems used in Google Workspace.

## GAS_PRIORITY_ORDER

0. Official Google Apps Script documentation when runtime, API, quota, authorization, trigger, deployment, or service behavior matters.
1. Apps Script runtime compatibility.
2. Correctness of Sheets, trigger, web app, and service interactions.
3. Minimal Google service calls: read once, process in memory, batch write.
4. v1 simplicity with a clean migration path to v2.
5. Groundedness: no invented APIs, tabs, headers, files, functions, triggers, deployment behavior, scopes, quotas, or limits.

## REQUEST_ROUTER

Classify the request first.

- **SPEC** — specification, architecture, workflow design, planning, data modeling. Goal: an implementation-ready Apps Script specification.
- **BUILD** — code, implementation, feature, refactor, or function creation. Goal: implement one phase, feature, or fix.
- **AUDIT** — review, consistency check, issue finding, risk analysis. Goal: find real GAS-specific issues and propose atomic fixes.
- **DEBUG** — errors, broken behavior, failed triggers/web apps/automations. Goal: isolate the failing step and propose the smallest safe correction.

Mixed request: split into ordered sub-modes; do not code before the needed SPEC or AUDIT decision is resolved.

## REFERENCE_ROUTING

Open **each** row whose concern the task touches — real tasks match two or three. Never open a file you do not need.

| The task involves… | Open |
|---|---|
| Building a NEW tool from scratch (full Sheets+GAS MVP) | `references/starter/` — clasp-ready skeleton (see its README) + `references/build-operate.md` (greenfield kickoff) |
| Writing or changing code | `references/build-patterns.md` — copy-paste recipes + runnable self-checks |
| Reviewing, debugging, or verifying code (AUDIT / DEBUG) | `references/reviewing.md` — audit checklist, debug isolation, test strategy |
| Product/data contract, status model, schema, headers, IDs, sheet I/O, bootstrap, tenancy, config, secrets, locks, triggers, state, or logs | `references/data-sheets.md` |
| Calling an external API, or building HTML / menus / dialogs / forms | `references/apis-ui.md` |
| Architecture choice, long or resumable jobs, deployment / clasp, or an MVP→Editor add-on path | `references/build-operate.md` |

- The four rule files (`data-sheets`, `apis-ui`, `build-operate`, `reviewing`) each hold the rule **and** its implementation together. `build-patterns.md` holds runnable code.
- Precedence: this SKILL.md wins over a reference file; a **rule wins over a code sample**; if the user overrides explicitly, follow the user.
- If a needed file is unavailable, continue with the fallback schema below, do not invent its content, and say what was missing only if it affected the answer.

## GAS_RUNTIME_RULES

- Do not assume Node.js, npm packages, browser DOM APIs, browser globals, or browser async patterns in .gs files.
- Assume Apps Script V8 unless the project says otherwise.
- Prefer Apps Script-native services and patterns.
- State when an Advanced Google Service must be enabled.
- Verify official Apps Script docs when deployment, authorization, triggers, quotas, service behavior, or runtime behavior affects correctness.
- If official docs are unclear or unavailable, say so.

## GAS_ARCHITECTURE_RULES

Separate when relevant: **UI** (menus, dialogs, sidebars, alerts, HTML service) · **Service adapters** (SpreadsheetApp, DriveApp, GmailApp, UrlFetchApp, external APIs) · **Business logic** (pure transformation and rules) · **Configuration and state** (constants, PropertiesService, sheet configuration, deployment settings).

Keep one source of truth for: sheet names, headers, statuses, IDs, trigger names, property keys, config constants, deployment assumptions.

## GAS_HIGH_SIGNAL_CHECKS

Standing checks for any Apps Script work; each fact appears once. The rule files add depth when opened.

Sheets I/O:
- Guard empty/header-only sheets before getRange. getLastRow/getLastColumn return the last row/column with content, not sheet capacity.
- Read a range once, transform arrays in memory, write once. Avoid per-row calls to SpreadsheetApp, DriveApp, GmailApp, UrlFetchApp, and similar services.
- getValues returns a 2D array; use getDisplayValues when comparing what the user sees.
- Match written array dimensions to the target range exactly; resolve/normalize headers before using column indexes.

Triggers and concurrency:
- Simple triggers have authorization restrictions; use installable triggers for services that require authorization.
- Trigger executions can overlap. Use LockService around shared writes and keep flows idempotent so duplicate or re-entrant runs are safe.

External APIs (UrlFetchApp):
- Before trusting a response, handle transport failure, non-2xx status, HTTP 200 with a semantic error in the body, and invalid or unexpected JSON.
- Consider retry safety and idempotency risk. Keep secrets and config out of core code.

Web apps:
- Validate doGet(e)/doPost(e) parameters and never trust client-provided values.
- Be explicit about execute-as and access settings. Updating an existing deployment version differs from creating a new deployment.

Config, state, quotas, jobs, and logs:
- Use PropertiesService for config or small state, not large datasets. Use CacheService only when it clearly reduces repeated expensive work.
- Keep core logic decoupled from UI or active-spreadsheet state unless the workflow requires it.
- Quotas and limits can change; verify official docs when they affect design. Long jobs need chunking, checkpointing, or resumability.
- Trigger errors may not be visible to end users. Log actionable context without exposing secrets.

## FALLBACK_OUTPUT_SCHEMAS

Use the matching rule file for depth; if it is unavailable, at minimum cover these fields.

SPEC: Objective · Scope_In · Scope_Out · Bound_Container · Sheets_And_Headers · Data_Model · Properties_And_Config · Triggers · Workflows · Business_Rules · Files · Functions · Authorization_And_Scopes · External_APIs · Distribution_And_Update_Model · Error_Handling · Phase_Plan · Validation · Risks · Assumptions

BUILD: Phase · Files_Impacted · Create_Or_Modify · Code · Insert_Where · Dependencies · Apps_Script_Services_Used · Required_Enablement · Validation_Checks · Basic_Tests · Assumptions

AUDIT: Tag (Bug | Spec | Perf | Maintain | Test) · Severity (P0 | P1 | P2) · Where · Problem · Why_It_Matters · Atomic_Fix · Impact · Assumptions

DEBUG: Symptom · Confirmed_Facts · Likely_Cause · Checks · Fix · Regression_Risk · Validation · Assumptions

## GAS_FINAL_CHECK

Before answering, verify:
- Mode selected; output matches the selected mode.
- Apps Script runtime assumptions are valid.
- No invented sheets, headers, files, functions, triggers, scopes, services, quotas, or deployment behavior.
- Official Apps Script docs checked when behavior could affect correctness.
- Google service calls are minimized where code is involved.
- Machinery matches need: no lock, claim/finalize, library split, or extra files beyond what the task's scale and side effects require — prefer the lightest safe pattern.
- Trigger, concurrency, auth, and deployment risks considered when relevant.
- For a multi-user tool, the SPEC selects a distribution/update model and defines source of truth, update classes, rollout, rollback, visible version/health, trust boundary, trigger owner, and add-on exit signal.
- User can validate through Apps Script editor, execution logs, spreadsheet UI, web app URL, or controlled trigger.
