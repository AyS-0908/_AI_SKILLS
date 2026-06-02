---
name: appscript
description: >
  Google Apps Script Skill for SPEC, BUILD, AUDIT, and DEBUG of robust v1
  Apps Script systems: Sheets automations, bound scripts, triggers, web apps,
  and Apps Script service integrations.
triggers:
  - "Google Apps Script"
  - "Apps Script"
  - "GAS"
  - ".gs"
  - "Google Sheets automation"
  - "Sheets script"
  - "bound script"
  - "onEdit"
  - "onOpen"
  - "doGet"
  - "doPost"
  - "SpreadsheetApp"
  - "PropertiesService"
  - "LockService"
  - "CacheService"
  - "UrlFetchApp"
  - "clasp"
do_not_trigger_for:
  - "spreadsheet formulas without scripting"
  - "Google Sheets UI-only help"
  - "generic JavaScript outside Apps Script"
  - "Node.js projects outside Apps Script"
  - "generic audits not tied to Apps Script"
  - "PRDs for non-Apps-Script products"
status: active
---

# GOOGLE_APPS_SCRIPT_SKILL

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

SPEC:
- Use for specification, architecture, workflow design, implementation planning, and data modeling.
- Goal: produce an implementation-ready Apps Script specification.

BUILD:
- Use for code, implementation, feature addition, refactor, or Apps Script function creation.
- Goal: implement one phase, feature, or fix.

AUDIT:
- Use for review, consistency check, issue finding, and risk analysis.
- Goal: find real GAS-specific issues and propose atomic fixes.

DEBUG:
- Use for errors, broken behavior, failed triggers, failed web apps, or failed sheet automations.
- Goal: isolate the failing step and propose the smallest safe correction.

Mixed request:
- Split into ordered sub-modes.
- Do not code before the needed SPEC or AUDIT decision is resolved.

## GAS_RUNTIME_RULES

- Do not assume Node.js, npm packages, browser DOM APIs, browser globals, or browser async patterns in .gs files.
- Assume Apps Script V8 unless the project says otherwise.
- Prefer Apps Script-native services and patterns.
- State when an Advanced Google Service must be enabled.
- Verify official Apps Script docs when deployment, authorization, triggers, quotas, service behavior, or runtime behavior affects correctness.
- If official docs are unclear or unavailable, say so.

## GAS_ARCHITECTURE_RULES

Separate when relevant:
- UI: menus, dialogs, sidebars, alerts, HTML service.
- Service adapters: SpreadsheetApp, DriveApp, GmailApp, UrlFetchApp, external APIs.
- Business logic: pure transformation and rules.
- Configuration and state: constants, PropertiesService, sheet configuration, deployment settings.

Use one source of truth for:
- sheet names
- headers
- statuses
- IDs
- trigger names
- property keys
- config constants
- deployment assumptions

## GAS_SERVICE_RULES

- Minimize calls to Google services.
- Prefer: read range once -> transform arrays -> batch write once.
- Avoid per-row calls to SpreadsheetApp, DriveApp, GmailApp, UrlFetchApp, and similar services.
- Use LockService for concurrent triggers or shared writes.
- Use PropertiesService for config or small state, not large datasets.
- Use CacheService only when it clearly reduces repeated expensive work.
- Keep trigger flows idempotent when duplicate or overlapping executions are possible.
- Avoid coupling core logic to UI or active spreadsheet state unless the workflow requires it.

## GAS_EXTERNAL_API_RULES

For UrlFetchApp and external APIs, handle:
- transport failure
- non-2xx HTTP status
- HTTP 200 with semantic error in the response body
- invalid or unexpected JSON
- retry safety
- idempotency risk
- secrets and config outside core code when relevant

## GAS_HIGH_SIGNAL_CHECKS

Sheets:
- Guard empty sheets before getRange calls.
- getLastRow and getLastColumn return last content position, not sheet capacity.
- getValues returns a 2D array.
- Use getDisplayValues when comparing what the user sees.
- Match write dimensions exactly to target range dimensions.
- Normalize headers before relying on column indexes.

Triggers:
- Simple triggers have authorization restrictions.
- Use installable triggers when authorized services are required.
- Trigger executions can overlap.
- Use LockService when shared state or shared sheets can be written concurrently.
- Make duplicate processing safe when trigger re-entry is possible.

Web apps:
- Validate doGet(e) and doPost(e) parameters before processing.
- Do not trust client-provided values.
- Be explicit about execute-as and access settings.
- Updating an existing deployment version is different from creating a new deployment.

Quotas, jobs, and logs:
- Quotas and limits can change; verify official docs when limits affect design.
- Long jobs need chunking, checkpointing, or resumability.
- Trigger errors may not be visible to end users.
- Log actionable context without exposing secrets.

## REFERENCE_LOADING_RULES

Use reference files when available.

references/spec-template.md:
- Load for SPEC.
- Purpose: full Apps Script implementation-ready specification schema.

references/build-patterns.md:
- Load for BUILD or code-pattern questions.
- Purpose: copy-paste-safe v1 Apps Script patterns.

references/audit-checklist.md:
- Load for AUDIT.
- Purpose: GAS-specific audit checklist and issue format.

references/debug-checklist.md:
- Load for DEBUG.
- Purpose: stepwise Apps Script failure isolation.

references/gas-gotchas.md:
- Load when behavior touches Sheets, triggers, web apps, quotas, auth, dates, deployments, or Apps Script runtime edge cases.
- Purpose: high-signal gotchas and examples.

If the relevant reference file is unavailable:
- Continue with the inline fallback schema.
- Do not invent missing reference-file content.
- State the missing reference only if it affects the answer.

If a reference file conflicts with this SKILL.md:
- Prefer this SKILL.md unless the user explicitly says otherwise.

## FALLBACK_OUTPUT_SCHEMAS

SPEC:
- Objective
- Scope_In
- Scope_Out
- Bound_Container
- Sheets_And_Headers
- Data_Model
- Properties_And_Config
- Triggers
- Workflows
- Business_Rules
- Files
- Functions
- Authorization_And_Scopes
- External_APIs
- Error_Handling
- Phase_Plan
- Validation
- Risks
- Assumptions

BUILD:
- Phase
- Files_Impacted
- Create_Or_Modify
- Code
- Insert_Where
- Dependencies
- Apps_Script_Services_Used
- Required_Enablement
- Validation_Checks
- Basic_Tests
- Assumptions

AUDIT:
- Tag: Bug | Spec | Perf | Maintain | Test
- Severity: P0 | P1 | P2
- Where
- Problem
- Why_It_Matters
- Atomic_Fix
- Impact
- Assumptions

DEBUG:
- Symptom
- Confirmed_Facts
- Likely_Cause
- Checks
- Fix
- Regression_Risk
- Validation
- Assumptions

## GAS_FINAL_CHECK

Before answering, verify:
- Mode selected.
- Output matches selected mode.
- Apps Script runtime assumptions are valid.
- No invented sheets, headers, files, functions, triggers, scopes, services, quotas, or deployment behavior.
- Official Apps Script docs checked when behavior could affect correctness.
- Google service calls are minimized where code is involved.
- Trigger, concurrency, auth, and deployment risks considered when relevant.
- User can validate through Apps Script editor, execution logs, spreadsheet UI, web app URL, or controlled trigger.