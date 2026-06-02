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
