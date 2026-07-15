/**
 * gas_mock_run.js — offline harness that PROVES the build-patterns recipes.
 *
 * It extracts every ```javascript block from ../build-patterns.md, runs them in a
 * sandbox with fake Google services, then exercises the risky stateful recipes
 * (claim/call/finalize, checkpoint/resume, UrlFetch validation) plus every
 * selfCheck_* function. Any broken recipe fails this run.
 *
 * Usage:  node references/tools/gas_mock_run.js
 * Exit 0 = all green. Non-zero = a recipe is broken (message says which).
 *
 * This is a test double, not a spec of Apps Script behavior. When Apps Script
 * semantics matter, verify against official docs.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');

function assert(cond, msg) {
  if (!cond) throw new Error('ASSERT FAILED: ' + msg);
}

// ---- Fake Sheets ----------------------------------------------------------
function FakeRange(sheet, row, col, numRows, numCols) {
  this.sheet = sheet;
  this.row = row;
  this.col = col;
  this.numRows = numRows;
  this.numCols = numCols;
}
FakeRange.prototype.getValues = function () {
  const out = [];
  for (let r = 0; r < this.numRows; r++) {
    const rowArr = [];
    for (let c = 0; c < this.numCols; c++) {
      const rr = this.sheet.values[this.row - 1 + r] || [];
      rowArr.push(rr[this.col - 1 + c] === undefined ? '' : rr[this.col - 1 + c]);
    }
    out.push(rowArr);
  }
  return out;
};
FakeRange.prototype.getDisplayValues = function () {
  return this.getValues().map(function (r) { return r.map(String); });
};
FakeRange.prototype.setValues = function (vals) {
  assert(vals.length === this.numRows, 'setValues row count mismatch');
  for (let r = 0; r < this.numRows; r++) {
    assert(vals[r].length === this.numCols, 'setValues col count mismatch');
    if (!this.sheet.values[this.row - 1 + r]) this.sheet.values[this.row - 1 + r] = [];
    for (let c = 0; c < this.numCols; c++) {
      this.sheet.values[this.row - 1 + r][this.col - 1 + c] = vals[r][c];
    }
  }
  return this;
};
FakeRange.prototype.getNumRows = function () { return this.numRows; };
FakeRange.prototype.getNumColumns = function () { return this.numCols; };

function FakeSheet(name, values) {
  this.name = name;
  this.values = values; // array of rows; row 0 = header
}
FakeSheet.prototype.getName = function () { return this.name; };
FakeSheet.prototype.getLastRow = function () { return this.values.length; };
FakeSheet.prototype.getLastColumn = function () {
  return this.values.reduce(function (m, r) { return Math.max(m, r.length); }, 0);
};
FakeSheet.prototype.getRange = function (row, col, numRows, numCols) {
  return new FakeRange(this, row, col, numRows, numCols);
};

function FakeSpreadsheet(sheets) {
  this.sheets = sheets;
}
FakeSpreadsheet.prototype.getName = function () { return 'FakeBook'; };
FakeSpreadsheet.prototype.getSheetByName = function (n) { return this.sheets[n] || null; };

// ---- Sandbox with a shared, mutable book ---------------------------------
function makeSandbox(book) {
  let uuidN = 0;
  const props = {};
  const triggers = [];

  function FakeResponse(code, body) { this._c = code; this._b = body; }
  FakeResponse.prototype.getResponseCode = function () { return this._c; };
  FakeResponse.prototype.getContentText = function () { return this._b; };

  function FakeTrigger(handler, eventType) { this._h = handler; this._e = eventType; }
  FakeTrigger.prototype.getHandlerFunction = function () { return this._h; };
  FakeTrigger.prototype.getEventType = function () { return this._e; };

  const sandbox = {
    console: console,
    __triggers: triggers,
    __httpResponder: function () { return { code: 200, body: '{}' }; },
    SpreadsheetApp: {
      getActiveSpreadsheet: function () { return book; },
      getActive: function () { return book; },
      openById: function () { return book; },
      flush: function () {},
    },
    PropertiesService: {
      getScriptProperties: function () {
        return {
          getProperty: function (k) { return k in props ? props[k] : null; },
          setProperty: function (k, v) { props[k] = String(v); },
          deleteProperty: function (k) { delete props[k]; },
        };
      },
    },
    LockService: {
      getScriptLock: function () {
        return { tryLock: function () { return true; }, waitLock: function () {}, releaseLock: function () {} };
      },
    },
    UrlFetchApp: {
      fetch: function (url, options) {
        const r = sandbox.__httpResponder(url, options);
        return new FakeResponse(r.code, r.body);
      },
    },
    ScriptApp: {
      getProjectTriggers: function () { return triggers.slice(); },
      deleteTrigger: function (t) { const i = triggers.indexOf(t); if (i >= 0) triggers.splice(i, 1); },
      newTrigger: function (handler) {
        const b = {
          timeBased: function () { return b; },
          everyDays: function () { return b; },
          atHour: function () { return b; },
          after: function () { return b; },
          create: function () { triggers.push(new FakeTrigger(handler, 'CLOCK')); },
        };
        return b;
      },
      EventType: { CLOCK: 'CLOCK' },
    },
    Utilities: {
      getUuid: function () { uuidN++; return '00000000-0000-0000-0000-' + String(uuidN).padStart(12, '0'); },
      sleep: function () {},
    },
    ContentService: {
      createTextOutput: function (s) { return { setMimeType: function () { return { body: s }; } }; },
      MimeType: { JSON: 'JSON' },
    },
  };
  return sandbox;
}

// ---- Load recipes ---------------------------------------------------------
const patternsPath = path.join(__dirname, '..', 'build-patterns.md');
const md = fs.readFileSync(patternsPath, 'utf8');
const blocks = [];
const re = /```javascript\r?\n([\s\S]*?)```/g;
let m;
while ((m = re.exec(md)) !== null) blocks.push(m[1]);
assert(blocks.length >= 8, 'expected >=8 javascript blocks, found ' + blocks.length);
const source = blocks.join('\n\n');

// ---- Run ------------------------------------------------------------------
function seedCompanies() {
  return new FakeSheet('Companies', [
    ['id', 'status', 'processing at', 'request id', 'company'],
    ['c1', 'pending', '', '', ''],
    ['c2', 'pending', '', '', ''],
    ['c3', 'pending', '', '', ''],
  ]);
}

const book = new FakeSpreadsheet({ Companies: seedCompanies() });
const sandbox = makeSandbox(book);
sandbox.enrichOne_ = function (id) { return { company: 'Co-' + id }; }; // used by CHECKPOINT_RESUME
const ctx = vm.createContext(sandbox);
vm.runInContext(source, ctx, { filename: 'build-patterns.md' });

const results = [];
function run(name, fn) {
  try { fn(); results.push('  ok   ' + name); }
  catch (e) { results.push('  FAIL ' + name + ' -> ' + e.message); throw e; }
}

// 1) Every self-check that ships in the recipes.
run('selfCheck_schema_', () => ctx.selfCheck_schema_());
run('selfCheck_transition_', () => ctx.selfCheck_transition_());
run('selfCheck_findRow_', () => ctx.selfCheck_findRow_());
run('selfCheck_headerRepair_', () => ctx.selfCheck_headerRepair_());
run('selfCheck_redact_', () => ctx.selfCheck_redact_());
run('selfCheck_stale_', () => ctx.selfCheck_stale_());
run('selfCheck_resume_', () => ctx.selfCheck_resume_());
run('selfCheck_retry_', () => ctx.selfCheck_retry_());
run('selfCheck_isDue_', () => ctx.selfCheck_isDue_());

// 2) SHEETS_TABLE_ADAPTER: header-keyed read + missing-header guard.
run('readTable_ header map', () => {
  const t = ctx.readTable_('Companies', ['id', 'status']);
  assert(ctx.getCol_(t.headerMap, 'status') === 1, 'status should be col index 1');
  assert(t.rows.length === 3, 'expected 3 body rows');
});
run('assertRequiredHeaders_ throws on missing', () => {
  let threw = false;
  try { ctx.readTable_('Companies', ['id', 'nope']); } catch (e) { threw = /missing required headers/.test(e.message); }
  assert(threw, 'missing header should throw');
});
run('findRowById_ on real rows requires exactly one match', () => {
  const t = ctx.readTable_('Companies', ['id']);
  const idIx = ctx.getCol_(t.headerMap, 'id');
  assert(ctx.findRowById_(t.rows, idIx, 'c2').rowNumber === 3, 'c2 should resolve to sheet row 3');
  let threw = false;
  try { ctx.findRowById_(t.rows, idIx, 'nope'); } catch (e) { threw = true; }
  assert(threw, 'unmatched id must throw');
});

// 3) CLAIM_CALL_FINALIZE: process, idempotent re-run, stale recovery.
run('processQueue_ finalizes all rows once', () => {
  let calls = 0;
  ctx.processQueue_('Companies', function (id) { calls++; return { company: 'X-' + id }; });
  const t = ctx.readTable_('Companies', ['id', 'status']);
  const sIx = ctx.getCol_(t.headerMap, 'status');
  const cIx = ctx.getCol_(t.headerMap, 'company');
  assert(calls === 3, 'provider called once per row, got ' + calls);
  assert(t.rows.every(r => String(r[sIx]) === 'done'), 'all rows should be done');
  assert(t.rows.every(r => /^X-/.test(String(r[cIx]))), 'company written for each row');
});
run('processQueue_ re-run is idempotent (no re-processing)', () => {
  let calls = 0;
  ctx.processQueue_('Companies', function () { calls++; return { company: 'again' }; });
  assert(calls === 0, 'nothing pending -> provider must not be called, got ' + calls);
});
run('recoverStaleClaims_ routes a stuck row to needs_reconcile', () => {
  const sheet = book.getSheetByName('Companies');
  sheet.values[1][1] = 'processing';
  sheet.values[1][2] = '2020-01-01T00:00:00.000Z'; // long ago
  ctx.recoverStaleClaims_('Companies', 5 * 60 * 1000);
  assert(String(sheet.values[1][1]) === 'needs_reconcile', 'stale processing -> needs_reconcile');
});

// 4) CHECKPOINT_RESUME: early stop schedules exactly one continuation, then drains and retires.
run('runEnrichmentChunk resume cycle', () => {
  book.sheets.Companies = seedCompanies(); // 3 pending
  ctx.shouldStopChunk_ = function (processed) { return processed >= 2; }; // force early stop after 2
  ctx.runEnrichmentChunk();
  assert(ctx.__triggers.filter(t => t.getHandlerFunction() === 'runEnrichmentChunk').length === 1,
    'one continuation trigger after early stop');
  assert(ctx.hasPendingRows_('Companies') === true, 'one row still pending');
  ctx.runEnrichmentChunk(); // drains the last row
  assert(ctx.hasPendingRows_('Companies') === false, 'all drained');
  assert(ctx.__triggers.filter(t => t.getHandlerFunction() === 'runEnrichmentChunk').length === 0,
    'continuation trigger retired when done');
});

// 5) URLFETCH_JSON: the E-02 validation order.
run('fetchJson_ validation order', () => {
  const ok = (d) => typeof d.industry === 'string' && d.industry.length > 0;
  sandbox.__httpResponder = () => ({ code: 200, body: JSON.stringify({ industry: 'Tech' }) });
  assert(ctx.fetchJson_('u', {}, 'ctx', ok).industry === 'Tech', 'valid 200 should pass');
  const cases = [
    [{ code: 500, body: '{}' }, 'non-2xx must throw'],
    [{ code: 200, body: JSON.stringify({ error: 'boom' }) }, '200 with semantic error must throw'],
    [{ code: 200, body: 'not-json' }, 'invalid JSON must throw'],
    [{ code: 200, body: JSON.stringify({ industry: '' }) }, 'failed field validation must throw'],
  ];
  cases.forEach(function (c) {
    sandbox.__httpResponder = () => c[0];
    let threw = false;
    try { ctx.fetchJson_('u', {}, 'ctx', ok); } catch (e) { threw = true; }
    assert(threw, c[1]);
  });
});

console.log(results.join('\n'));
console.log('\nALL RECIPE CHECKS PASSED (' + results.length + ' checks, ' + blocks.length + ' code blocks)');
