# BUILD_PATTERNS

meta:
  purpose: "Reusable Apps Script BUILD fragments only; not a framework."
  use_rule: "Load the smallest matching pattern. Do not emit unused patterns."
  skip:
    - "Generic JavaScript style advice"
    - "Generic project architecture"
    - "Rules already stated in SKILL.md"

pattern_index:
  SHEETS_TABLE_ADAPTER: "Header-based table read/write with empty-sheet guard."
  PROPERTIES_STATE: "Small config/state values stored as strings or JSON."
  SCRIPT_LOCK_WRAPPER: "Protect shared sheet/state writes."
  URLFETCH_JSON: "External JSON call with sanitized transport/HTTP/body validation."
  WEBAPP_JSON_ENTRYPOINT: "Authorized doPost JSON boundary with safe response payload."
  INSTALLABLE_TRIGGER_SETUP: "Current-user-idempotent trigger installer/remover."

---

## SHEETS_TABLE_ADAPTER

when:
  - "Sheet data has one header row and body rows."
  - "Code must address columns by header, not fixed indexes."

copy_pattern:
```javascript
const CONFIG = Object.freeze({
  sheets: {
    tasks: 'Tasks',
  },
  headers: {
    tasks: ['ID', 'Status', 'Updated At'],
  },
  props: {
    spreadsheetId: 'SPREADSHEET_ID',
  },
});

function getSpreadsheet_() {
  const id = PropertiesService.getScriptProperties().getProperty(CONFIG.props.spreadsheetId);
  const ss = id ? SpreadsheetApp.openById(id) : SpreadsheetApp.getActiveSpreadsheet();

  if (!ss) {
    throw new Error('No spreadsheet available. Set script property SPREADSHEET_ID for standalone scripts.');
  }

  return ss;
}

function getRequiredSheet_(ss, sheetName) {
  const sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    throw new Error('Missing sheet: ' + sheetName);
  }

  return sheet;
}

function normalizeHeader_(value) {
  return String(value || '').trim().toLowerCase();
}

function buildHeaderMap_(headerRow) {
  return headerRow.reduce(function (map, header, index) {
    const key = normalizeHeader_(header);

    if (key) {
      if (key in map) {
        throw new Error('Duplicate header: ' + header);
      }
      map[key] = index;
    }

    return map;
  }, {});
}

function assertRequiredHeaders_(headerMap, requiredHeaders, context) {
  const missing = requiredHeaders.filter(function (header) {
    return !(normalizeHeader_(header) in headerMap);
  });

  if (missing.length) {
    throw new Error(context + ' missing required headers: ' + missing.join(', '));
  }
}

function readTable_(sheetName, requiredHeaders) {
  const ss = getSpreadsheet_();
  const sheet = getRequiredSheet_(ss, sheetName);
  const lastRow = sheet.getLastRow();
  const lastColumn = sheet.getLastColumn();

  if (lastRow < 1 || lastColumn < 1) {
    throw new Error(sheetName + ' has no header row. Run bootstrap first.');
  }

  const values = sheet.getRange(1, 1, lastRow, lastColumn).getValues();
  const headerMap = buildHeaderMap_(values[0]);

  assertRequiredHeaders_(headerMap, requiredHeaders, sheetName);

  return {
    sheet: sheet,
    headerMap: headerMap,
    rows: values.slice(1),
  };
}

function writeRows_(sheet, startRow, startColumn, rows) {
  if (!rows.length) {
    return;
  }

  const width = rows[0].length;
  const hasBadWidth = rows.some(function (row) {
    return row.length !== width;
  });

  if (hasBadWidth) {
    throw new Error('Cannot write jagged rows.');
  }

  sheet.getRange(startRow, startColumn, rows.length, width).setValues(rows);
}
```

---

## PROPERTIES_STATE

when:
  - "Small durable config/state is needed."
  - "State must survive executions."
  - "Do not use this as a secret vault; Script Properties are shared by all users of the script."

copy_pattern:
```javascript
function getScriptProperty_(key, fallbackValue) {
  const value = PropertiesService.getScriptProperties().getProperty(key);
  return value === null ? fallbackValue : value;
}

function setScriptProperty_(key, value) {
  PropertiesService.getScriptProperties().setProperty(key, String(value));
}

function getJsonProperty_(key, fallbackValue) {
  const raw = PropertiesService.getScriptProperties().getProperty(key);

  if (raw === null) {
    return fallbackValue;
  }

  try {
    return JSON.parse(raw);
  } catch (error) {
    throw new Error('Invalid JSON in script property ' + key + ': ' + error.message);
  }
}

function setJsonProperty_(key, value) {
  PropertiesService.getScriptProperties().setProperty(key, JSON.stringify(value));
}
```

---

## SCRIPT_LOCK_WRAPPER

when:
  - "A trigger or web app writes to shared sheets or shared properties."

copy_pattern:
```javascript
function withScriptLock_(label, callback) {
  const lock = LockService.getScriptLock();

  if (!lock.tryLock(30000)) {
    throw new Error('Could not acquire script lock: ' + label);
  }

  try {
    return callback();
  } finally {
    lock.releaseLock();
  }
}

function runLockedJob_() {
  return withScriptLock_('runLockedJob_', function () {
    // Keep only the shared read/check/write critical section here.
    // Do not hold this lock across UrlFetchApp or other slow services.
  });
}
```

---

## URLFETCH_JSON

when:
  - "Calling an external JSON API with UrlFetchApp."

copy_pattern:
```javascript
function fetchJson_(url, options, context, validateResponse) {
  let response;

  try {
    response = UrlFetchApp.fetch(url, Object.assign({}, options || {}, {
      muteHttpExceptions: true,
    }));
  } catch (error) {
    throw new Error(context + ' transport failed.');
  }

  const status = response.getResponseCode();
  const body = response.getContentText();
  let parsed;

  if (status < 200 || status >= 300) {
    throw new Error(context + ' failed. HTTP ' + status + '.');
  }

  try {
    parsed = body ? JSON.parse(body) : null;
  } catch (error) {
    throw new Error(context + ' returned invalid JSON. HTTP ' + status + '.');
  }

  if (parsed && parsed.error) {
    throw new Error(context + ' returned a semantic error.');
  }

  if (typeof validateResponse !== 'function') {
    throw new Error(context + ' requires a provider response validator.');
  }

  try {
    if (validateResponse(parsed) !== true) {
      throw new Error('invalid');
    }
  } catch (error) {
    throw new Error(context + ' response failed validation.');
  }

  return parsed;
}
```

---

## WEBAPP_JSON_ENTRYPOINT

when:
  - "doPost receives JSON and returns JSON."
  - "Client must receive a structured success/error payload."
  - "Deployment access and execute-as identity are explicitly decided."

copy_pattern:
```javascript
function doPost(e) {
  try {
    const input = parseJsonPostBody_(e);

    if (!input || typeof input !== 'object' || Array.isArray(input)) {
      throw new Error('Expected JSON object input.');
    }

    assertAuthorizedPost_(e, input);
    const result = handlePost_(input);

    return jsonOutput_({
      ok: true,
      data: result,
    });
  } catch (error) {
    console.error(JSON.stringify({
      event: 'webapp_error',
      name: error && error.name ? error.name : 'Error',
    }));

    return jsonOutput_({
      ok: false,
      error: 'Request failed.',
    });
  }
}

function parseJsonPostBody_(e) {
  if (!e || !e.postData || !e.postData.contents) {
    throw new Error('Missing POST body.');
  }

  try {
    return JSON.parse(e.postData.contents);
  } catch (error) {
    throw new Error('Invalid JSON POST body: ' + error.message);
  }
}

function assertAuthorizedPost_(e, input) {
  // Replace with the project's real server-side authorization rule.
  // Safe default: this copy-paste skeleton does not accept public requests.
  throw new Error('POST authorization is not configured.');
}

function jsonOutput_(payload) {
  return ContentService
    .createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}

function handlePost_(input) {
  return {
    received: true,
  };
}
```

---

## INSTALLABLE_TRIGGER_SETUP

when:
  - "A predictable installer is needed for time-based or installable handlers."
  - "One designated account owns trigger installation; other accounts can create invisible duplicates."

copy_pattern:
```javascript
function installDailyTrigger_() {
  const handler = 'runDailyJob';
  const specKey = 'TRIGGER_SPEC_RUN_DAILY_JOB';
  const desiredSpec = 'clock:daily:06:v1';
  const props = PropertiesService.getScriptProperties();
  const matches = ScriptApp.getProjectTriggers().filter(function (trigger) {
    return trigger.getHandlerFunction() === handler;
  });

  if (
    props.getProperty(specKey) === desiredSpec &&
    matches.length === 1 &&
    matches[0].getEventType() === ScriptApp.EventType.CLOCK
  ) {
    return;
  }

  matches.forEach(function (trigger) {
    ScriptApp.deleteTrigger(trigger);
  });

  ScriptApp.newTrigger(handler)
    .timeBased()
    .everyDays(1)
    .atHour(6)
    .create();

  props.setProperty(specKey, desiredSpec);
}

function removeTriggersForHandler_(handler) {
  ScriptApp.getProjectTriggers().forEach(function (trigger) {
    if (trigger.getHandlerFunction() === handler) {
      ScriptApp.deleteTrigger(trigger);
    }
  });
}

function runDailyJob() {
  // Claim shared work under a short lock, call slow services outside it,
  // then finalize under a short lock. Do not lock the whole job by default.
}
```
