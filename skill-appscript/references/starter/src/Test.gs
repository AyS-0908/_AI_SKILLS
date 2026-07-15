/**
 * Test.gs — minimal in-project harness (rule V-01: every behavior leaves the
 * smallest runnable check). Runs live from the editor (testRunAll) AND
 * offline under tools/gas_mock_run.js — same code, transport faked only.
 *
 * FILL IN: one suite per behavior you add. Never loosen an assert to pass;
 * a deliberate contract change updates the assert (rule from source projects).
 * Live fixtures: reserve a test id prefix, exclude it from operator views,
 * clean up deterministically (rule V-04).
 */

const Test = {
  _results: [],

  assert: function (name, condition, detail) {
    this._results.push({ name: name, ok: !!condition, detail: detail || '' });
    if (!condition) console.error('FAIL ' + name + (detail ? ' — ' + detail : ''));
  },

  assertThrows: function (name, fn, messagePart) {
    try {
      fn();
      this.assert(name, false, 'expected a throw');
    } catch (error) {
      const ok = !messagePart || String(error.message).indexOf(messagePart) !== -1;
      this.assert(name, ok, ok ? '' : 'threw wrong message: ' + error.message);
    }
  },

  runAll: function () {
    this._results = [];
    suiteSchema_();
    suiteHeaderRepair_();
    suiteBootstrap_();
    suiteSheetIO_();
    suiteConfig_();
    suiteLog_();
    const failed = this._results.filter(function (r) { return !r.ok; });
    const summary = { passed: this._results.length - failed.length, failed: failed.length, total: this._results.length };
    console.log(JSON.stringify(summary));
    return summary;
  },
};

function testRunAll() {
  return Test.runAll();
}

function suiteSchema_() {
  Test.assert('schema: frozen', Object.isFrozen(C) && Object.isFrozen(C.SCHEMA));
  Test.assert('schema: headers derive', C.headersFor('items')[0] === 'ID');
  Test.assert('schema: header->key', C.keyForHeader('items', 'status') === 'status');
  Test.assert('schema: unknown column -> null', C.keyForHeader('items', 'Owner Notes') === null);
  Test.assert('transitions: legal', C.canTransition(C.STATUS.PENDING, C.STATUS.PROCESSING));
  Test.assert('transitions: terminal blocked', !C.canTransition(C.STATUS.DONE, C.STATUS.PROCESSING));
  Test.assertThrows('transitions: assert throws', function () {
    C.assertTransition(C.STATUS.DONE, C.STATUS.PENDING);
  }, 'Illegal status transition');
}

function suiteHeaderRepair_() {
  const req = ['ID', 'Status'];
  Test.assert('repair: blank -> write', planHeaderRepair_([], req).action === 'write_headers');
  Test.assert('repair: present -> continue', planHeaderRepair_(['ID', 'Status'], req).action === 'continue');
  Test.assert('repair: extra unknown -> continue', planHeaderRepair_(['ID', 'Status', 'Notes'], req).action === 'continue');
  Test.assert('repair: missing only -> append', planHeaderRepair_(['ID'], req).action === 'append_missing');
  Test.assert('repair: missing+unknown -> stop', planHeaderRepair_(['ID', 'Sttus'], req).action === 'stop');
  Test.assert('repair: duplicate -> stop', planHeaderRepair_(['ID', 'ID', 'Status'], req).action === 'stop');
}

function suiteBootstrap_() {
  const first = bootstrapRun();
  Test.assert('bootstrap: first run clean', first.warnings.length === 0, first.warnings.join('; '));
  const seeded = readObjects_('items').length;
  Test.assert('bootstrap: seeded once', seeded >= 1);
  const second = bootstrapRun();
  Test.assert('bootstrap: rerun is no-op', second.warnings.length === 0 && readObjects_('items').length === seeded);
}

function suiteSheetIO_() {
  const created = appendObject_('items', { title: 'Test row', status: C.STATUS.PENDING });
  Test.assert('sheetio: id minted', /^itm_/.test(created.id));
  const read = findRowById_('items', created.id);
  Test.assert('sheetio: roundtrip', read.title === 'Test row');
  const patched = updateRowById_('items', created.id, { title: 'Patched' });
  Test.assert('sheetio: patch by key', patched.title === 'Patched' && String(patched.status) === C.STATUS.PENDING);
  const moved = transitionById_('items', created.id, C.STATUS.PROCESSING);
  Test.assert('sheetio: legal transition written', String(moved.status) === C.STATUS.PROCESSING);
  Test.assertThrows('sheetio: illegal transition throws', function () {
    transitionById_('items', created.id, C.STATUS.PENDING);
  }, 'Illegal status transition');
  Test.assertThrows('sheetio: unknown id throws', function () {
    findRowById_('items', 'itm_nope');
  }, 'no row matches');
}

function suiteConfig_() {
  setConfig_('greeting', 'hello');
  Test.assert('config: set/get', getConfig_('greeting') === 'hello');
  setConfig_('greeting', 'bonjour');
  Test.assert('config: upsert not duplicate', getConfig_('greeting') === 'bonjour' &&
    readObjects_('setup').filter(function (r) { return r.key === 'greeting'; }).length === 1);
  Test.assertThrows('config: required missing throws', function () {
    getRequiredConfig_('absent_key');
  }, 'Missing required');
  setConfig_('ai_key_ref', 'TEST_SECRET_PROP');
  secretStore_().setProperty('TEST_SECRET_PROP', 'sk-test');
  Test.assert('config: secret by name', secret_('ai_key_ref') === 'sk-test');
  secretStore_().deleteProperty('TEST_SECRET_PROP');
  Test.assertThrows('config: missing secret names property, not value', function () {
    secret_('ai_key_ref');
  }, 'TEST_SECRET_PROP');
}

function suiteLog_() {
  const record = logEvent_({
    object_id: 'itm_x',
    action: 'test',
    details: { note: 'fine', apiKey: 'sk-live-123' },
  });
  Test.assert('log: row shape', /^log_/.test(record.log_id) && record.result === 'ok');
  Test.assert('log: secret redacted', record.details.indexOf('sk-live-123') === -1 &&
    record.details.indexOf('[redacted]') !== -1);
  const rows = readObjects_('logs');
  Test.assert('log: appended', rows.some(function (r) { return r.log_id === record.log_id; }));
}
