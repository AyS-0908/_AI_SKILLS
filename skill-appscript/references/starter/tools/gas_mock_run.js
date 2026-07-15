/**
 * gas_mock_run.js — offline harness for the starter. Loads the REAL src/*.gs
 * unchanged into a sandbox with fake Google services, runs bootstrapRun()
 * twice (idempotence) and the full Test suite.
 *
 * Usage:  node tools/gas_mock_run.js        (from the project root)
 * Exit 0 = all green. Non-zero = a check failed (message says which).
 *
 * This is a test double, not a spec of Apps Script behavior. When Apps Script
 * semantics matter, verify against official docs. Extend the fakes so they
 * reproduce the failures your guards defend — a silent no-op mock proves
 * little (rule V-01).
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
FakeRange.prototype.setValue = function (v) { return this.setValues([[v]]); };
FakeRange.prototype.setDataValidation = function () { return this; };

function FakeSheet(name, values) {
  this.name = name;
  this.values = values; // array of rows; row 0 = header
  this.frozenRows = 0;
}
FakeSheet.prototype.getName = function () { return this.name; };
FakeSheet.prototype.getLastRow = function () { return this.values.length; };
FakeSheet.prototype.getLastColumn = function () {
  return this.values.reduce(function (m, r) { return Math.max(m, r.length); }, 0);
};
FakeSheet.prototype.getMaxRows = function () { return 1000; };
FakeSheet.prototype.getRange = function (row, col, numRows, numCols) {
  return new FakeRange(this, row, col, numRows || 1, numCols || 1);
};
FakeSheet.prototype.setFrozenRows = function (n) { this.frozenRows = n; };
FakeSheet.prototype.deleteRows = function (start, howMany) {
  this.values.splice(start - 1, howMany);
};

function FakeSpreadsheet() {
  this.sheets = [];
}
FakeSpreadsheet.prototype.getName = function () { return 'FakeBook'; };
FakeSpreadsheet.prototype.getSheetByName = function (n) {
  return this.sheets.filter(function (s) { return s.name === n; })[0] || null;
};
FakeSpreadsheet.prototype.insertSheet = function (n) {
  const sheet = new FakeSheet(n, []);
  this.sheets.push(sheet);
  return sheet;
};
FakeSpreadsheet.prototype.getSheets = function () { return this.sheets.slice(); };
FakeSpreadsheet.prototype.deleteSheet = function (sheet) {
  const i = this.sheets.indexOf(sheet);
  if (i >= 0) this.sheets.splice(i, 1);
};
FakeSpreadsheet.prototype.setActiveSheet = function () {};

// ---- Sandbox --------------------------------------------------------------
function makeProps() {
  const store = {};
  return {
    getProperty: function (k) { return k in store ? store[k] : null; },
    setProperty: function (k, v) { store[k] = String(v); },
    deleteProperty: function (k) { delete store[k]; },
  };
}

function makeSandbox(book) {
  let uuidN = 0;
  const scriptProps = makeProps();
  const docProps = makeProps();
  return {
    console: console,
    SpreadsheetApp: {
      getActiveSpreadsheet: function () { return book; },
      openById: function () { return book; },
      flush: function () {},
      newDataValidation: function () {
        const b = {
          requireValueInList: function () { return b; },
          setAllowInvalid: function () { return b; },
          build: function () { return {}; },
        };
        return b;
      },
    },
    PropertiesService: {
      getScriptProperties: function () { return scriptProps; },
      getDocumentProperties: function () { return docProps; },
    },
    LockService: {
      getScriptLock: function () {
        return { tryLock: function () { return true; }, waitLock: function () {}, releaseLock: function () {} };
      },
      getDocumentLock: function () {
        return { tryLock: function () { return true; }, waitLock: function () {}, releaseLock: function () {} };
      },
    },
    Utilities: {
      getUuid: function () {
        uuidN++; // counter at the FRONT: nextId_ keeps the first 12 hex chars
        return String(uuidN).padStart(8, '0') + '-0000-4000-8000-000000000000';
      },
      sleep: function () {},
    },
  };
}

// ---- Load real src/*.gs unchanged -----------------------------------------
const srcDir = path.join(__dirname, '..', 'src');
const files = fs.readdirSync(srcDir).filter(function (f) { return f.endsWith('.gs'); }).sort();
assert(files[0] === '00_Constants.gs', 'expected 00_Constants.gs to load first');
const source = files.map(function (f) { return fs.readFileSync(path.join(srcDir, f), 'utf8'); }).join('\n\n');

const book = new FakeSpreadsheet();
book.insertSheet('Feuille 1'); // exercise locale-aware default-sheet removal
const ctx = vm.createContext(makeSandbox(book));
vm.runInContext(source, ctx, { filename: 'src/*.gs' });

// ---- Run ------------------------------------------------------------------
const first = ctx.bootstrapRun();
assert(first.warnings.length === 0, 'first bootstrap warnings: ' + first.warnings.join('; '));
assert(book.getSheetByName('Items') && book.getSheetByName('Setup') && book.getSheetByName('logs'),
  'manifest tabs missing after bootstrap');
assert(book.getSheetByName('Feuille 1') === null, 'empty locale default sheet should be removed');

const second = ctx.bootstrapRun();
assert(second.warnings.length === 0, 'second bootstrap warnings: ' + second.warnings.join('; '));

const summary = ctx.testRunAll();
assert(summary.failed === 0, summary.failed + ' test(s) failed');

console.log('\nSTARTER GREEN — bootstrap idempotent, ' + summary.passed + '/' + summary.total + ' checks passed (' + files.length + ' .gs files)');
