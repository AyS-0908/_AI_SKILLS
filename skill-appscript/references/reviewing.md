# REVIEWING — AUDIT, DEBUG, TESTING

One-line purpose: the same Apps Script review skill in three directions — AUDIT (find issues), DEBUG (isolate a failure), and TESTING (verify the work).

Mini-TOC:
- [AUDIT](#audit) — evidence-gated GAS risk scan
- [DEBUG](#debug) — GAS-specific failure isolation with probes
- [TESTING](#testing) — verification rules and test strategy

## AUDIT

# AUDIT_CHECKLIST

usage_contract:
  purpose: "GAS-only AUDIT risk scanner; use after normal code/spec review."
  use_rule: "Raise only evidence-backed issues found in the provided spec/code. Do not paste this checklist verbatim."
  depends_on: "Use SKILL.md for AUDIT output schema and global GAS priorities."
  exclude:
    - "Generic clean-code review"
    - "Generic JavaScript review"
    - "Copy-paste BUILD snippets"
    - "DEBUG probes or symptom diagnosis"
    - "Restating SKILL.md rules without project-specific evidence"

evidence_gate:
  issue_is_valid_only_if:
    - "The exact code/spec location, contract, or missing decision is identifiable."
    - "The failure mode is plausible for the declared Apps Script entrypoint."
    - "The fix is atomic and smaller than a rewrite."
  suppress_if:
    - "The risk is already handled by code, spec, deployment notes, or tests."
    - "The issue requires guessing sheet names, headers, scopes, quotas, users, or deployment settings."

scan:

  execution_context:
    ask:
      - "Is the entrypoint context explicit enough to validate active-file, event-object, and user-identity assumptions?"
      - "Does any standalone, trigger, or web-app path depend on active spreadsheet/sheet state that may not exist?"

  data_contract:
    ask:
      - "Are tab names, headers, statuses, IDs, property keys, and trigger names centralized and consistently consumed?"
      - "Can duplicate, blank, renamed, or user-reordered headers route data into the wrong column?"
      - "Are update targets based on stable IDs rather than mutable row position, unless row-position behavior is intentional?"

  sheets_io:
    ask:
      - "Can the computed read/write rectangle ever diverge from the array shape being read or written?"
      - "Can filters, sorting, manual row edits, or deleted rows make stored row indexes unsafe?"
      - "When output shrinks, is stale previous output intentionally cleared or preserved?"

  trigger_side_effects:
    ask:
      - "Can overlapping or repeated trigger runs duplicate irreversible effects: emails, API writes, appended rows, or status changes?"
      - "Is the chosen lock/state scope aligned with the shared resource being protected?"
      - "Is the processed/checkpoint marker written at a safe point relative to external side effects?"

  auth_identity_deployment:
    ask:
      - "Does the execution identity have access to every file, service, and external credential used by the flow?"
      - "Would a new service call require re-authorization, manifest scope review, or Advanced Service enablement?"
      - "For deployed surfaces, is the user-facing deployment/version the one being audited?"

  external_interfaces:
    ask:
      - "Can retry or re-run duplicate an external action?"
      - "Are secrets/config excluded from source, logs, sheet outputs, and client responses?"
      - "Is the external response contract validated before business logic trusts it?"

  scale_limits:
    ask:
      - "Which loop dominates Google-service or external-service calls as row/file/message volume grows?"
      - "Can a long run resume from a stored cursor/checkpoint without replaying completed side effects?"
      - "Is any cache used only for recomputable data, never as durable truth?"

  test_surface:
    ask:
      - "Is there a safe manual validation path for each real entrypoint: editor, trigger, menu, web app, or API call?"
      - "Can high-risk side effects run in dry-run/sample mode before touching production data?"

triage:
  P0:
    - "Likely data corruption, credential/secret exposure, unauthorized access, or unrecoverable duplicate external action."
  P1:
    - "Likely normal-path runtime failure, wrong-user failure, quota failure, deployment mismatch, or recurring duplicate processing."
  P2:
    - "Edge-case fragility, weak validation surface, maintainability blocker, or missing low-risk test coverage."

output_constraint:
  - "Use SKILL.md AUDIT schema."
  - "One issue = one atomic fix."
  - "Do not report checklist items that are not evidenced by the provided project."

## DEBUG

# DEBUG_CHECKLIST

meta:
  purpose: "GAS-specific failure isolation for DEBUG answers."
  use_rule: "Use as a routing checklist; do not paste verbatim unless requested."
  skip:
    - "Generic debugging advice"
    - "Generic JavaScript explanations"
    - "Output schema already defined in SKILL.md"

required_facts:
  - entrypoint: "editor_run | simple_trigger | installable_trigger | menu | sidebar | web_app | time_trigger"
  - container: "bound | standalone | unknown"
  - exact_error: "message + function + timestamp when available"
  - changed_recently: "code | sheet headers | deployment | trigger | permissions | external API"
  - data_surface: "spreadsheet id, sheet name, header row, relevant range when relevant"

route_by_surface:

  editor_run_fails:
    check:
      - "Function selected in editor is the real entrypoint."
      - "Manual run is not calling an event-handler that requires e.range, e.postData, or e.parameter."
      - "Required script properties exist."
    useful_probe:
      - "Run a dedicated debug_* function that builds the same inputs explicitly."

  editor_run_works_trigger_fails:
    check:
      - "Handler receives event object shape expected by the code."
      - "Trigger is simple vs installable as required by the services used."
      - "Effective user has access to target files."
      - "Concurrent trigger executions cannot corrupt shared sheet/state."
    first_probe:
      - "Log only event shape and target identifiers, not full user data."

  web_app_fails:
    check:
      - "Current deployment URL is the one being called."
      - "execute-as and access settings match the workflow."
      - "doGet/doPost validates missing parameters/body before business logic."
      - "Client expects JSON only if ContentService JSON is actually returned."
    first_probe:
      - "Return {ok:false,error:'...'} instead of throwing raw errors to the client."

  sheets_flow_fails:
    check:
      - "Bound vs standalone spreadsheet resolution."
      - "Sheet name exact match."
      - "Header row exists and normalized headers match constants."
      - "Range dimensions match values dimensions."
      - "Code needs raw values or display values."
    first_probe:
      - "Log lastRow, lastColumn, headers, and target write dimensions."

  urlfetch_fails:
    check:
      - "HTTP status code."
      - "Response body shape."
      - "JSON parse safety."
      - "Secret/config source."
      - "Retry would be safe before adding it."
    first_probe:
      - "Use muteHttpExceptions:true and log status + first 500 body chars."

symptom_map:

  "Cannot read properties of null":
    likely:
      - "getSheetByName returned null."
      - "getActiveSpreadsheet returned null in standalone context."
    isolate:
      - "Log spreadsheet name/id resolution and sheet names."

  "Cannot read properties of undefined":
    likely:
      - "Manual run of handler expecting event object."
      - "Missing nested field in e, row object, or parsed JSON."
    isolate:
      - "Log event/input shape before field access."

  "The number of columns in the data does not match":
    likely:
      - "setValues row width differs from target range width."
      - "Rows are jagged."
    isolate:
      - "Log rows.length, rows[0].length, target numRows, target numColumns."

  "Authorization is required":
    likely:
      - "Simple trigger using service requiring authorization."
      - "New scope added but script not re-authorized."
    isolate:
      - "Run once manually from editor and confirm trigger type."

  "Service invoked too many times":
    likely:
      - "Per-row calls to a Google service or external API."
      - "Unbounded trigger/web app loop."
    isolate:
      - "Count service calls in the smallest failing execution."

  "Works for owner, fails for others":
    likely:
      - "File permissions, deployment execute-as/access setting, or user-scoped property."
    isolate:
      - "Test with one non-owner account and log only role/context, not private data."

probes:

  event_shape:
```javascript
function debugEventShape_(e) {
  console.log(JSON.stringify({
    hasEvent: !!e,
    authMode: e && e.authMode ? String(e.authMode) : null,
    hasRange: !!(e && e.range),
    rangeA1: e && e.range ? e.range.getA1Notation() : null,
    hasPostData: !!(e && e.postData),
    parameterKeys: e && e.parameter ? Object.keys(e.parameter) : [],
  }));
}
```

  sheet_shape:
```javascript
function debugSheetShape_(sheetName) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  if (!ss) {
    throw new Error('No active spreadsheet.');
  }

  const sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    throw new Error('Missing sheet: ' + sheetName);
  }

  const lastRow = sheet.getLastRow();
  const lastColumn = sheet.getLastColumn();
  const headers = lastColumn
    ? sheet.getRange(1, 1, 1, lastColumn).getDisplayValues()[0]
    : [];

  console.log(JSON.stringify({
    spreadsheetName: ss.getName(),
    sheetName: sheet.getName(),
    lastRow: lastRow,
    lastColumn: lastColumn,
    headers: headers,
  }));
}
```

  write_dimensions:
```javascript
function debugWriteShape_(rows, targetRange) {
  console.log(JSON.stringify({
    rowCount: rows.length,
    firstRowWidth: rows[0] ? rows[0].length : 0,
    targetRows: targetRange.getNumRows(),
    targetColumns: targetRange.getNumColumns(),
  }));
}
```

minimal_fix_order:
  - "Fix missing/wrong entrypoint inputs before changing business logic."
  - "Fix spreadsheet/sheet/header resolution before changing row processing."
  - "Fix range dimensions before changing data transformation."
  - "Fix authorization/trigger type before changing service calls."
  - "Fix external API response handling before adding retries."

## TESTING

### CORE rules (section 9, testing rows)

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| V-01 | MUST | PROJECT_REPORTED | Every behavior change | Leave the smallest runnable check that fails when the rule breaks; exercise the real entrypoint where practical. | Count a silent mock/no-op as coverage. |
| V-02 | DEFAULT | PROJECT_REPORTED | External APIs | Mock the innermost transport so production payload building, validation, and status mapping still run. | Mock the public workflow and bypass the logic being tested. |
| V-03 | WHEN | EXTERNAL + PROJECT_REPORTED | Suite approaches Apps Script runtime | Chunk/resume long work; run larger deterministic checks offline when practical and keep small live smoke suites. | Depend on one cloud run that cannot finish within current quotas. |
| V-04 | MUST | PROJECT_REPORTED | Test data touches live schema | Reserve fixture IDs, exclude them from operator views, and provide deterministic cleanup. | Leave test rows indistinguishable from real rows. |

### TEST STRATEGY

- Run real `.gs` code unchanged where possible.
- Fake only the platform/transport seams needed by the behavior.
- Make fakes reproduce failures guarded by production code; a silent no-op mock proves little.
- Mock the innermost HTTP transport so payload building and response mapping remain real.
- Isolate fixture rows with a reserved ID prefix; hide them from operator lists and provide deterministic cleanup.
- Re-derive one critical invariant independently, such as checking every manifest tab/header from the live workbook shape.
- Expose small live smoke suites when a full suite risks the Apps Script execution ceiling.
- Update an assertion only for an explicit contract change; do not loosen it to make a failure green.

Existing `references/build-patterns.md` already owns copy-paste-safe baseline code. Do not duplicate its Sheets adapter, PropertiesService, lock, UrlFetch, web-app, or trigger patterns here.
