/**
 * SheetIO.gs — the ONLY module that touches the grid. Ready to run.
 *
 * Addresses columns by header NAME through a live {key -> index} map rebuilt
 * from row 1 on each operation (rules D-01/S-06): user-reordered or
 * owner-added columns survive. Read once / transform in memory / write once
 * (rule D-02). Every by-id mutation requires exactly one match (rule D-06).
 */

function ss_() {
  const id = PropertiesService.getScriptProperties().getProperty(C.PROPS.SPREADSHEET_ID);
  const ss = id ? SpreadsheetApp.openById(id) : SpreadsheetApp.getActiveSpreadsheet();
  if (!ss) {
    throw new Error('No spreadsheet available. Set script property ' + C.PROPS.SPREADSHEET_ID + ' for standalone scripts.');
  }
  return ss;
}

function getSheet_(tabId) {
  const sheet = ss_().getSheetByName(C.sheetName(tabId));
  if (!sheet) throw new Error('Missing sheet "' + C.sheetName(tabId) + '". Run bootstrap first.');
  return sheet;
}

function nowIso_() {
  return new Date().toISOString();
}

function nextId_(prefix) {
  return prefix + Utilities.getUuid().replace(/-/g, '').slice(0, 12);
}

// Live header row -> {fieldKey: 0-based column index}. Unknown headers are
// skipped (preserved); a duplicate mapped header throws (S-06 strictness).
function headerMap_(tabId, sheet) {
  const lastColumn = sheet.getLastColumn();
  if (sheet.getLastRow() < 1 || lastColumn < 1) {
    throw new Error(C.sheetName(tabId) + ' has no header row. Run bootstrap first.');
  }
  const headers = sheet.getRange(1, 1, 1, lastColumn).getDisplayValues()[0];
  const map = {};
  headers.forEach(function (header, ix) {
    const key = C.keyForHeader(tabId, header);
    if (key === null) return; // owner-added column: preserve, do not map
    if (key in map) throw new Error(C.sheetName(tabId) + ' duplicate header for key: ' + key);
    map[key] = ix;
  });
  C.fieldsFor(tabId).forEach(function (f) {
    if (!(f.key in map)) throw new Error(C.sheetName(tabId) + ' missing required header: ' + f.header);
  });
  return map;
}

// Whole tab -> array of objects keyed by field key, plus __row (1-based sheet
// row). Blank rows (no id) are skipped.
function readObjects_(tabId) {
  const sheet = getSheet_(tabId);
  const map = headerMap_(tabId, sheet);
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return [];
  const values = sheet.getRange(2, 1, lastRow - 1, sheet.getLastColumn()).getValues();
  const out = [];
  values.forEach(function (row, i) {
    const obj = { __row: i + 2 };
    let hasContent = false;
    Object.keys(map).forEach(function (key) {
      obj[key] = row[map[key]];
      if (String(obj[key]) !== '') hasContent = true;
    });
    if (hasContent) out.push(obj);
  });
  return out;
}

// Append one object; mints an id and stamps updated_at when absent.
// Writes only mapped keys across the live header width, so owner-added
// columns stay untouched (rule D-04).
function appendObject_(tabId, obj) {
  const sheet = getSheet_(tabId);
  const map = headerMap_(tabId, sheet);
  const idPrefix = C.ID_PREFIX[tabId] || 'row_';
  const record = Object.assign({}, obj);
  if (!record.id && 'id' in map) record.id = nextId_(idPrefix);
  if ('updated_at' in map && !record.updated_at) record.updated_at = nowIso_();
  const width = sheet.getLastColumn();
  const row = new Array(width).fill('');
  Object.keys(map).forEach(function (key) {
    if (key in record) row[map[key]] = record[key];
  });
  sheet.getRange(sheet.getLastRow() + 1, 1, 1, width).setValues([row]);
  return record;
}

// Exactly-one-match lookup (rule D-06): zero or multiple matches throw.
function findRowById_(tabId, id) {
  const hits = readObjects_(tabId).filter(function (o) {
    return String(o.id) === String(id);
  });
  if (hits.length === 0) throw new Error(C.sheetName(tabId) + ': no row matches id ' + id);
  if (hits.length > 1) throw new Error(C.sheetName(tabId) + ': ' + hits.length + ' rows match id ' + id);
  return hits[0];
}

// Patch named fields on ONE row: read the row once, set mapped cells, write
// once. Unknown owner columns round-trip unchanged.
function updateRowById_(tabId, id, patch) {
  const sheet = getSheet_(tabId);
  const map = headerMap_(tabId, sheet);
  const target = findRowById_(tabId, id);
  const width = sheet.getLastColumn();
  const range = sheet.getRange(target.__row, 1, 1, width);
  const values = range.getValues();
  Object.keys(patch).forEach(function (key) {
    if (!(key in map)) throw new Error(C.sheetName(tabId) + ': unknown field key ' + key);
    values[0][map[key]] = patch[key];
  });
  if ('updated_at' in map && !('updated_at' in patch)) values[0][map.updated_at] = nowIso_();
  range.setValues(values);
  return findRowById_(tabId, id);
}

// Status write chokepoint: every status change passes the transition contract
// (rule P-02) so an illegal or stale move throws instead of being written.
function transitionById_(tabId, id, toStatus) {
  const current = findRowById_(tabId, id);
  C.assertTransition(String(current.status), toStatus);
  return updateRowById_(tabId, id, { status: toStatus });
}
