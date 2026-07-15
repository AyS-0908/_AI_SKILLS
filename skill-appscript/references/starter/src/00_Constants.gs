/**
 * 00_Constants.gs — the contract layer. ONE schema is the source of truth for
 * tab names, field keys, displayed headers, lists, and statuses (rules S-01/S-02).
 * Everything else derives from it. Deep-frozen: no runtime mutation.
 *
 * FILL IN: replace the placeholder `items` tab with your real tabs/fields.
 * Keys are stable machine names code branches on; headers are labels the
 * operator may read (and you may relabel freely — never rename a key).
 * Statuses are stored as codes in cells for v1 simplicity; add a code<->label
 * translation seam (rule S-04) only when friendly labels are actually needed.
 */

function normalizeHeader_(value) {
  return String(value || '').trim().toLowerCase();
}

function deepFreeze_(obj) {
  Object.getOwnPropertyNames(obj).forEach(function (name) {
    const v = obj[name];
    if (v && typeof v === 'object') deepFreeze_(v);
  });
  return Object.freeze(obj);
}

const C = (function () {
  const SCHEMA = {
    tabs: {
      // PLACEHOLDER domain tab — replace with your real entity.
      items: {
        sheet: 'Items',
        fields: [
          { key: 'id', header: 'ID' },
          { key: 'title', header: 'Title', editable: true },
          { key: 'status', header: 'Status', list: 'status' },
          { key: 'updated_at', header: 'Updated At' },
        ],
      },
      // Key/value config tab, read via Config.gs. Keep global settings here;
      // per-tenant settings get one row per tenant on their own tab (rule C-01).
      setup: {
        sheet: 'Setup',
        fields: [
          { key: 'key', header: 'Key' },
          { key: 'value', header: 'Value', editable: true },
        ],
      },
      // Structured diagnostics (rule C-05). NOT durable business truth: if
      // billing/caps must read counts, give them their own durable tab (C-06).
      logs: {
        sheet: 'logs',
        fields: [
          { key: 'log_id', header: 'Log ID' },
          { key: 'timestamp', header: 'Timestamp' },
          { key: 'object_id', header: 'Object' },
          { key: 'action', header: 'Action' },
          { key: 'status_before', header: 'Status Before' },
          { key: 'status_after', header: 'Status After' },
          { key: 'request_id', header: 'Request ID' },
          { key: 'result', header: 'Result' },
          { key: 'error_code', header: 'Error Code' },
          { key: 'details', header: 'Details' },
        ],
      },
    },
    lists: {
      status: ['pending', 'processing', 'done', 'error', 'needs_reconcile'],
    },
  };

  // Server-owned status contract (rule P-02). Terminal states map to [].
  const STATUS = {
    PENDING: 'pending',
    PROCESSING: 'processing',
    DONE: 'done',
    ERROR: 'error',
    NEEDS_RECONCILE: 'needs_reconcile',
  };
  const TRANSITIONS = {
    [STATUS.PENDING]: [STATUS.PROCESSING],
    [STATUS.PROCESSING]: [STATUS.DONE, STATUS.ERROR, STATUS.NEEDS_RECONCILE],
    [STATUS.NEEDS_RECONCILE]: [STATUS.PENDING, STATUS.DONE],
    [STATUS.ERROR]: [STATUS.PENDING],
    [STATUS.DONE]: [],
  };
  const NEXT_ACTION = {
    [STATUS.PENDING]: 'claim and process',
    [STATUS.PROCESSING]: 'wait; recover if the claim is stale',
    [STATUS.NEEDS_RECONCILE]: 'reconcile against the provider',
    [STATUS.ERROR]: 'inspect, then requeue to pending',
    [STATUS.DONE]: 'none',
  };

  // Script/Document property KEYS only — values never live in code or cells.
  const PROPS = {
    SPREADSHEET_ID: 'SPREADSHEET_ID', // only needed for standalone scripts
  };
  const ID_PREFIX = { items: 'itm_', logs: 'log_', request: 'req_' };

  function tab_(tabId) {
    const t = SCHEMA.tabs[tabId];
    if (!t) throw new Error('Unknown tab id: ' + tabId);
    return t;
  }

  return deepFreeze_({
    SCHEMA: SCHEMA,
    STATUS: STATUS,
    TRANSITIONS: TRANSITIONS,
    NEXT_ACTION: NEXT_ACTION,
    PROPS: PROPS,
    ID_PREFIX: ID_PREFIX,

    sheetName: function (tabId) { return tab_(tabId).sheet; },
    fieldsFor: function (tabId) { return tab_(tabId).fields; },
    headersFor: function (tabId) {
      return tab_(tabId).fields.map(function (f) { return f.header; });
    },
    // Displayed header -> stable key. Unknown owner-added column -> null
    // (preserve, do not map — rule S-06).
    keyForHeader: function (tabId, header) {
      const norm = normalizeHeader_(header);
      const hit = tab_(tabId).fields.filter(function (f) {
        return normalizeHeader_(f.header) === norm;
      })[0];
      return hit ? hit.key : null;
    },
    listFor: function (listId) { return SCHEMA.lists[listId] || null; },

    canTransition: function (from, to) {
      const allowed = TRANSITIONS[from];
      return Array.isArray(allowed) && allowed.indexOf(to) !== -1;
    },
    assertTransition: function (from, to) {
      if (!this.canTransition(from, to)) {
        throw new Error('Illegal status transition: ' + from + ' -> ' + to);
      }
    },
  });
})();
