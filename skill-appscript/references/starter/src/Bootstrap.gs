/**
 * Bootstrap.gs — rerunnable, non-destructive workbook construction (rule D-07).
 * Ready to run: `bootstrapRun` builds or repairs every manifest tab; a second
 * run is a no-op. Create or repair — never reset.
 *
 * Error model (lesson from a shipped setup harness): COLLECT warnings and
 * continue — one failed cosmetic step must not abort workspace setup. Only
 * broken inputs/contracts throw (missing+unknown headers, duplicates).
 */

function bootstrapManifest_() {
  // Ordered: config first, then domain tabs, diagnostics last.
  return [
    { tab: 'setup' },
    { tab: 'items', seed: function () { return [{ title: 'Example item', status: C.STATUS.PENDING }]; } },
    { tab: 'logs' },
  ];
}

function bootstrapRun() {
  const warnings = [];
  bootstrapManifest_().forEach(function (spec) {
    const sheet = ensureSheet_(spec.tab);
    repairHeaders_(spec.tab, sheet);
    applyTry_(warnings, spec.tab + ': freeze header', function () { sheet.setFrozenRows(1); });
    applyTry_(warnings, spec.tab + ': dropdowns', function () { applyDropdowns_(spec.tab, sheet); });
    if (spec.seed && sheet.getLastRow() < 2) {
      spec.seed().forEach(function (obj) { appendObject_(spec.tab, obj); });
    }
  });
  applyTry_(warnings, 'remove default sheet', removeDefaultSheets_);
  warnings.forEach(function (w) { console.warn('bootstrap: ' + w); });
  return { warnings: warnings };
}

function applyTry_(warnings, label, fn) {
  try { fn(); } catch (error) { warnings.push(label + ' — ' + error.message); }
}

function ensureSheet_(tabId) {
  const book = ss_();
  const name = C.sheetName(tabId);
  return book.getSheetByName(name) || book.insertSheet(name);
}

// S-06 — the header decision is a pure function, not judgment. Same contract
// as planHeaderRepair_ in references/build-patterns.md (SHEETS_TABLE_ADAPTER).
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

function repairHeaders_(tabId, sheet) {
  const required = C.headersFor(tabId);
  const lastColumn = sheet.getLastColumn();
  const actual = lastColumn ? sheet.getRange(1, 1, 1, lastColumn).getDisplayValues()[0] : [];
  const plan = planHeaderRepair_(actual, required);

  if (plan.action === 'stop') {
    throw new Error(C.sheetName(tabId) + ' headers need a human: ' + plan.reason + ' (' + JSON.stringify(plan) + ')');
  }
  if (plan.action === 'write_headers') {
    sheet.getRange(1, 1, 1, required.length).setValues([required]);
    return;
  }
  if (plan.action === 'append_missing') {
    // Append at the END only — repositioning existing columns would split data.
    const requiredByNorm = {};
    required.forEach(function (h) { requiredByNorm[normalizeHeader_(h)] = h; });
    const labels = plan.headers.map(function (h) { return requiredByNorm[h]; });
    sheet.getRange(1, lastColumn + 1, 1, labels.length).setValues([labels]);
  }
}

// Strict dropdown on every list-bound field: the accepted set is the set code
// compares against (rule S-03). setAllowInvalid(false) for code-owned values.
function applyDropdowns_(tabId, sheet) {
  const map = headerMap_(tabId, sheet);
  C.fieldsFor(tabId).forEach(function (field) {
    if (!field.list) return;
    const values = C.listFor(field.list);
    if (!values) throw new Error('Unknown list: ' + field.list);
    const rule = SpreadsheetApp.newDataValidation()
      .requireValueInList(values, true)
      .setAllowInvalid(false)
      .build();
    sheet.getRange(2, map[field.key] + 1, sheet.getMaxRows() - 1, 1).setDataValidation(rule);
  });
}

// Delete Google's auto-created leftover sheet, locale-aware, ONLY when it is
// empty and not the last sheet (a spreadsheet must keep one).
const DEFAULT_SHEET_RE = /^(Sheet|Feuille|Hoja|Foglio|Tabelle|Folha)\s*1$/i;

function removeDefaultSheets_() {
  const book = ss_();
  book.getSheets().forEach(function (sheet) {
    if (
      DEFAULT_SHEET_RE.test(sheet.getName()) &&
      sheet.getLastRow() === 0 &&
      book.getSheets().length > 1
    ) {
      book.deleteSheet(sheet);
    }
  });
}
