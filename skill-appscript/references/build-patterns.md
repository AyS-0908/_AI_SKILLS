# BUILD_PATTERNS

meta:
  purpose: "Reusable Apps Script BUILD fragments only; not a framework."
  use_rule: "Load the smallest matching pattern. Do not emit unused patterns."
  self_check: "Risky stateful patterns ship a selfCheck_* function. Run it once in the editor or your offline mock; it fails loudly if the logic breaks. Model V-01 the same way in your own project."
  harness: "tools/gas_mock_run.js runs every code block here against fake Google services (Sheets/Properties/Lock/UrlFetch/ScriptApp) and asserts the claim/finalize, resume, and UrlFetch-validation behavior. Run: node references/tools/gas_mock_run.js — green means the recipes still work."
  starter: "SCHEMA_CONSTANTS + STATUS_MACHINE + CONFIG_REQUIRED + REDACTED_LOG + SHEETS_TABLE_ADAPTER + SCRIPT_LOCK_WRAPPER + URLFETCH_JSON + CLAIM_CALL_FINALIZE + CHECKPOINT_RESUME + INSTALLABLE_TRIGGER_SETUP compose a minimal bound-Sheet MVP starter. Copy only what the task needs; replace every placeholder."
  skip:
    - "Generic JavaScript style advice"
    - "Generic project architecture"
    - "Rules already stated in SKILL.md"

pattern_index:
  SCHEMA_CONSTANTS: "One schema source of truth: stable key vs display header; derive maps."
  STATUS_MACHINE: "Server-owned status codes, legal transitions, and next action; reject illegal/stale moves."
  SHEETS_TABLE_ADAPTER: "Header-based table read/write with empty-sheet guard; single-row patch by key; exactly-one-match lookup; header-repair decision."
  PROPERTIES_STATE: "Small config/state as strings or JSON; fail-fast getter for required values."
  SCRIPT_LOCK_WRAPPER: "Protect shared sheet/state writes."
  URLFETCH_JSON: "External JSON call with sanitized transport/HTTP/body validation."
  REDACTED_LOG: "One structured event with secret redaction at the log seam."
  CLAIM_CALL_FINALIZE: "Claim under a short lock, call the slow service OUTSIDE the lock, finalize; recover stale claims."
  CHECKPOINT_RESUME: "Bounded chunk + durable Status checkpoint + idempotent self-rescheduling continuation."
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

// Look up a column index by header name. buildHeaderMap_ stores normalized keys,
// so always resolve through this helper, never headerMap['Status'] directly.
function getCol_(headerMap, header) {
  const ix = headerMap[normalizeHeader_(header)];

  if (ix === undefined) {
    throw new Error('Unknown column: ' + header);
  }

  return ix;
}

// Patch named cells in ONE row: read the row once, set only the named cells, write once.
// Unknown owner-added columns are preserved (the whole row is round-tripped).
function setCells_(sheet, headerMap, rowNumber, patchByHeader) {
  const width = sheet.getLastColumn();
  const range = sheet.getRange(rowNumber, 1, 1, width);
  const values = range.getValues();

  Object.keys(patchByHeader).forEach(function (header) {
    values[0][getCol_(headerMap, header)] = patchByHeader[header];
  });

  range.setValues(values);
}

// D-06 — before any update/delete/transition, require EXACTLY ONE match.
// `rows` is table.rows from readTable_; returns the 1-based sheet rowNumber (+2 = header + 1-based).
// Zero or multiple matches is a bug (wrong-row corruption), never a silent pick-first.
function findRowById_(rows, idIx, id) {
  const hits = [];

  for (let i = 0; i < rows.length; i++) {
    if (String(rows[i][idIx]) === String(id)) {
      hits.push(i);
    }
  }

  if (hits.length === 0) {
    throw new Error('No row matches id: ' + id);
  }

  if (hits.length > 1) {
    throw new Error('Ambiguous: ' + hits.length + ' rows match id: ' + id);
  }

  return { index: hits[0], rowNumber: hits[0] + 2, row: rows[hits[0]] };
}

function selfCheck_findRow_() {
  const rows = [['c1', 'a'], ['c2', 'b'], ['c2', 'c']]; // c2 intentionally duplicated
  if (findRowById_(rows, 0, 'c1').rowNumber !== 2) throw new Error('exact match rowNumber wrong');
  let threw = 0;
  try { findRowById_(rows, 0, 'zz'); } catch (e) { threw++; } // zero matches
  try { findRowById_(rows, 0, 'c2'); } catch (e) { threw++; } // duplicate
  if (threw !== 2) throw new Error('must throw on zero AND on duplicate');
  console.log('selfCheck_findRow_ ok');
}

// S-06 — decide the bootstrap header action deterministically instead of by judgment.
// `actual` = the live header row; `required` = declared headers. Returns exactly one action.
function planHeaderRepair_(actualHeaders, requiredHeaders) {
  const actual = actualHeaders.map(normalizeHeader_).filter(function (h) { return h; });
  const required = requiredHeaders.map(normalizeHeader_);

  const duplicated = required.filter(function (h) {
    return actual.filter(function (a) { return a === h; }).length > 1;
  });
  if (duplicated.length) {
    return { action: 'stop', reason: 'duplicate required header', headers: duplicated };
  }

  if (actual.length === 0) {
    return { action: 'write_headers', headers: requiredHeaders };
  }

  const missing = required.filter(function (h) { return actual.indexOf(h) === -1; });
  if (missing.length === 0) {
    return { action: 'continue' }; // unknown owner-added columns are preserved
  }

  const unknown = actual.filter(function (h) { return required.indexOf(h) === -1; });
  if (unknown.length) {
    return { action: 'stop', reason: 'rename ambiguity', missing: missing, unknown: unknown };
  }

  return { action: 'append_missing', headers: missing };
}

function selfCheck_headerRepair_() {
  const req = ['ID', 'Status'];
  if (planHeaderRepair_([], req).action !== 'write_headers') throw new Error('blank -> write_headers');
  if (planHeaderRepair_(['ID', 'Status'], req).action !== 'continue') throw new Error('present -> continue');
  if (planHeaderRepair_(['ID', 'Status', 'Notes'], req).action !== 'continue') throw new Error('unknown extra -> continue');
  if (planHeaderRepair_(['ID'], req).action !== 'append_missing') throw new Error('missing-only -> append_missing');
  if (planHeaderRepair_(['ID', 'Sttus'], req).action !== 'stop') throw new Error('missing+unknown -> stop');
  if (planHeaderRepair_(['ID', 'ID', 'Status'], req).action !== 'stop') throw new Error('duplicate -> stop');
  console.log('selfCheck_headerRepair_ ok');
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

// Required config: fail clearly instead of proceeding on an empty string.
function getRequiredProperty_(key) {
  const value = PropertiesService.getScriptProperties().getProperty(key);

  if (value === null || value === '') {
    throw new Error('Missing required script property: ' + key);
  }

  return value;
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

---

## SCHEMA_CONSTANTS

when:
  - "Code branches on statuses, IDs, or field values, or resolves columns by header."
  - "Owners may rename displayed headers or add columns."

copy_pattern:
```javascript
// One schema is the single source of truth: a stable machine KEY plus a displayed
// HEADER for each field. Branch code on keys; never on the label an owner can rename.
const SCHEMA = Object.freeze({
  companies: {
    sheet: 'Companies',
    fields: Object.freeze([
      Object.freeze({ key: 'id', header: 'Company ID' }),
      Object.freeze({ key: 'name', header: 'Company', editable: true }),
      Object.freeze({ key: 'status', header: 'Status' }),
      Object.freeze({ key: 'company', header: 'Enriched Company' }),
    ]),
  },
});

function headersFor_(entity) {
  return SCHEMA[entity].fields.map(function (field) {
    return field.header;
  });
}

function keyForHeader_(entity, header) {
  const norm = normalizeHeader_(header);
  const hit = SCHEMA[entity].fields.filter(function (field) {
    return normalizeHeader_(field.header) === norm;
  })[0];

  return hit ? hit.key : null; // unknown owner-added column -> null (preserve, do not map)
}

function selfCheck_schema_() {
  if (headersFor_('companies')[0] !== 'Company ID') throw new Error('header derivation broke');
  if (keyForHeader_('companies', 'Status') !== 'status') throw new Error('key resolution broke');
  if (keyForHeader_('companies', 'Owner Notes') !== null) throw new Error('unknown column must be null');
  console.log('selfCheck_schema_ ok');
}
```

---

## STATUS_MACHINE

when:
  - "A workflow row moves through statuses (P-02: state-driven workflow)."
  - "Illegal or stale status jumps must be rejected, not written."

Status codes, the legal transitions between them, and the next action for each state are ONE
server-owned contract. Validate every transition through `assertTransition_` before writing status
(e.g. inside `finalizeRow_`), so a stale client edit or a bad code path cannot force `done -> processing`.

copy_pattern:
```javascript
const STATUS = Object.freeze({
  PENDING: 'pending',
  PROCESSING: 'processing',
  DONE: 'done',
  ERROR: 'error',
  NEEDS_RECONCILE: 'needs_reconcile',
});

// from -> the states it may legally become. Terminal states map to [].
const TRANSITIONS = Object.freeze({
  [STATUS.PENDING]: [STATUS.PROCESSING],
  [STATUS.PROCESSING]: [STATUS.DONE, STATUS.ERROR, STATUS.NEEDS_RECONCILE],
  [STATUS.NEEDS_RECONCILE]: [STATUS.PENDING, STATUS.DONE],
  [STATUS.ERROR]: [STATUS.PENDING],
  [STATUS.DONE]: [],
});

// The one next action each state implies — the P-02 "next action for each state".
const NEXT_ACTION = Object.freeze({
  [STATUS.PENDING]: 'claim and process',
  [STATUS.PROCESSING]: 'wait; recover if the claim is stale',
  [STATUS.NEEDS_RECONCILE]: 'reconcile against the provider',
  [STATUS.ERROR]: 'inspect, then requeue to pending',
  [STATUS.DONE]: 'none',
});

function canTransition_(from, to) {
  const allowed = TRANSITIONS[from];
  return Array.isArray(allowed) && allowed.indexOf(to) !== -1;
}

function assertTransition_(from, to) {
  if (!canTransition_(from, to)) {
    throw new Error('Illegal status transition: ' + from + ' -> ' + to);
  }
}

function selfCheck_transition_() {
  if (!canTransition_(STATUS.PENDING, STATUS.PROCESSING)) throw new Error('legal transition rejected');
  if (canTransition_(STATUS.DONE, STATUS.PROCESSING)) throw new Error('terminal state must not transition');
  if (canTransition_(STATUS.PENDING, 'banana')) throw new Error('unknown target must be illegal');
  let threw = false;
  try { assertTransition_(STATUS.DONE, STATUS.PENDING); } catch (e) { threw = true; }
  if (!threw) throw new Error('assertTransition_ must throw on an illegal move');
  if (NEXT_ACTION[STATUS.PENDING] !== 'claim and process') throw new Error('next action missing');
  console.log('selfCheck_transition_ ok');
}
```

---

## REDACTED_LOG

when:
  - "One structured event per state change or external call."

copy_pattern:
```javascript
// Key-name redaction is defense in depth, NOT sufficient alone: also keep secrets and
// credential-bearing URLs out of the event you pass in (see data-sheets.md rule C-05 / logs).
const REDACT_KEY_RE = /key|token|secret|authorization|password|apikey|credential|bearer/i;

function redact_(value) {
  if (value === null || typeof value !== 'object') {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map(redact_);
  }

  return Object.keys(value).reduce(function (out, key) {
    out[key] = REDACT_KEY_RE.test(key) ? '[redacted]' : redact_(value[key]);
    return out;
  }, {});
}

function logEvent_(event) {
  console.log(JSON.stringify(redact_(event)));
}

function selfCheck_redact_() {
  const out = redact_({ action: 'call', apiKey: 'sk-123', nested: { authorization: 'Bearer x', ok: 1 } });
  if (out.apiKey !== '[redacted]') throw new Error('top-level secret leaked');
  if (out.nested.authorization !== '[redacted]') throw new Error('nested secret leaked');
  if (out.action !== 'call' || out.nested.ok !== 1) throw new Error('non-secret value dropped');
  console.log('selfCheck_redact_ ok');
}
```

---

## CLAIM_CALL_FINALIZE

when:
  - "A trigger or batch performs a slow external side effect per row."
  - "Overlapping runs must not double-process, and a died-mid-run row must recover."

Builds on SHEETS_TABLE_ADAPTER (`getCol_`, `setCells_`, `readTable_`) and SCRIPT_LOCK_WRAPPER
(`withScriptLock_`). Requires columns `id`, `status`, `processing at`, `request id`.
Never hold a lock across the slow call: claim under a short lock, release, call, finalize under a short lock.

copy_pattern:
```javascript
function newRequestId_() {
  return 'req_' + Utilities.getUuid().replace(/-/g, '').slice(0, 12);
}

// STEP 1 — claim one eligible row under a short lock, then RELEASE the lock.
function claimNextRow_(sheetName) {
  return withScriptLock_('claim:' + sheetName, function () {
    const table = readTable_(sheetName, ['id', 'status']);
    const statusIx = getCol_(table.headerMap, 'status');
    const idIx = getCol_(table.headerMap, 'id');

    for (let i = 0; i < table.rows.length; i++) {
      if (String(table.rows[i][statusIx]) === 'pending') {
        const rowNumber = i + 2; // +1 header row, +1 for 1-based rows
        const requestId = newRequestId_();

        setCells_(table.sheet, table.headerMap, rowNumber, {
          'status': 'processing',
          'processing at': new Date().toISOString(),
          'request id': requestId,
        });

        return { rowNumber: rowNumber, id: table.rows[i][idIx], requestId: requestId };
      }
    }

    return null; // nothing eligible
  });
}

// STEP 3 — finalize under a short lock (STEP 2, the slow call, happens between, with NO lock held).
function finalizeRow_(sheetName, rowNumber, patch) {
  withScriptLock_('finalize:' + sheetName, function () {
    const table = readTable_(sheetName, ['status']);
    setCells_(table.sheet, table.headerMap, rowNumber, patch);
  });
}

function processQueue_(sheetName, callProvider) {
  let claim;

  while ((claim = claimNextRow_(sheetName)) !== null) {
    try {
      const result = callProvider(claim.id, claim.requestId); // STEP 2: slow call, NO lock held
      finalizeRow_(sheetName, claim.rowNumber, { 'status': 'done', 'company': result.company });
    } catch (error) {
      // Ambiguous non-idempotent write? route to reconciliation instead of blind retry.
      finalizeRow_(sheetName, claim.rowNumber, { 'status': 'error' });
    }
  }
}

// STEP 4 — recover rows stuck in 'processing' past a timeout (a run that died mid-flight).
function isStaleClaim_(startedIso, nowMs, maxAgeMs) {
  const started = Date.parse(startedIso);
  return !!started && (nowMs - started) > maxAgeMs;
}

function recoverStaleClaims_(sheetName, maxAgeMs) {
  withScriptLock_('recover:' + sheetName, function () {
    const table = readTable_(sheetName, ['status', 'processing at']);
    const statusIx = getCol_(table.headerMap, 'status');
    const atIx = getCol_(table.headerMap, 'processing at');
    const now = Date.now();

    table.rows.forEach(function (row, i) {
      if (String(row[statusIx]) !== 'processing') return;
      if (isStaleClaim_(row[atIx], now, maxAgeMs)) {
        // Idempotent read: safe to reset to 'pending'. Non-idempotent write with an
        // ambiguous outcome: route to 'needs_reconcile' rather than retrying.
        setCells_(table.sheet, table.headerMap, i + 2, { 'status': 'needs_reconcile' });
      }
    });
  });
}

function selfCheck_stale_() {
  const t0 = '2026-01-01T00:00:00.000Z';
  const base = Date.parse(t0);
  if (isStaleClaim_(t0, base + 10 * 60000, 5 * 60000) !== true) throw new Error('stale not detected');
  if (isStaleClaim_(t0, base + 1 * 60000, 5 * 60000) !== false) throw new Error('false stale');
  if (isStaleClaim_('', base, 5 * 60000) !== false) throw new Error('blank must not be stale');
  console.log('selfCheck_stale_ ok');
}
```

---

## CHECKPOINT_RESUME

when:
  - "A job can exceed the ~6-minute execution limit and must resume."

The durable checkpoint is the Status column itself (re-derived each run), NOT CacheService.
Builds on CLAIM_CALL_FINALIZE and INSTALLABLE_TRIGGER_SETUP (`removeTriggersForHandler_`).

copy_pattern:
```javascript
const RESUME = Object.freeze({
  handler: 'runEnrichmentChunk',
  timeBudgetMs: 5 * 60 * 1000, // stop before the ~6-minute limit
  maxRowsPerRun: 500,
});

// PURE stop decision — self-checkable without touching a sheet.
function shouldStopChunk_(processedCount, startedMs, nowMs, budgetMs, maxRows) {
  return processedCount >= maxRows || (nowMs - startedMs) >= budgetMs;
}

function runEnrichmentChunk() {
  const startedMs = Date.now();
  let processed = 0;
  let claim;

  while ((claim = claimNextRow_('Companies')) !== null) {
    try {
      const result = enrichOne_(claim.id, claim.requestId); // your adapter; NO lock held
      finalizeRow_('Companies', claim.rowNumber, { 'status': 'done', 'company': result.company });
    } catch (error) {
      finalizeRow_('Companies', claim.rowNumber, { 'status': 'error' });
    }

    processed++;
    if (shouldStopChunk_(processed, startedMs, Date.now(), RESUME.timeBudgetMs, RESUME.maxRowsPerRun)) {
      break;
    }
  }

  if (hasPendingRows_('Companies')) {
    ensureContinuation_(); // more work remains -> schedule one continuation
  } else {
    removeTriggersForHandler_(RESUME.handler); // done -> retire the trigger
  }
}

function hasPendingRows_(sheetName) {
  const table = readTable_(sheetName, ['status']);
  const statusIx = getCol_(table.headerMap, 'status');
  return table.rows.some(function (row) {
    return String(row[statusIx]) === 'pending';
  });
}

// Idempotent: at most one continuation trigger for this handler.
function ensureContinuation_() {
  const exists = ScriptApp.getProjectTriggers().some(function (trigger) {
    return trigger.getHandlerFunction() === RESUME.handler;
  });

  if (!exists) {
    ScriptApp.newTrigger(RESUME.handler).timeBased().after(60 * 1000).create();
  }
}

function selfCheck_resume_() {
  if (shouldStopChunk_(500, 0, 1000, 300000, 500) !== true) throw new Error('row-cap stop failed');
  if (shouldStopChunk_(1, 0, 300000, 300000, 500) !== true) throw new Error('time-budget stop failed');
  if (shouldStopChunk_(1, 0, 1000, 300000, 500) !== false) throw new Error('should have continued');
  console.log('selfCheck_resume_ ok');
}
```
