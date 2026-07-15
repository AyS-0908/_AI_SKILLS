/**
 * Config.gs — global settings on the Setup tab + secret-by-name resolution.
 * Ready to run.
 *
 * Secrets NEVER live in a cell (rule C-02): a config cell stores only the
 * PROPERTY NAME (e.g. "OPENAI_API_KEY"); the value lives in PropertiesService
 * and is resolved at call time. Scope decision: document properties for a
 * container-bound tool (survives a later shared-library split without leaking
 * across workbooks); script properties as the standalone fallback.
 * PropertiesService is scoped storage, not a vault — use a real secret
 * manager when editor access, audit, or rotation must be controlled.
 */

function configAll_() {
  const out = {};
  readObjects_('setup').forEach(function (row) {
    const key = String(row.key || '').trim();
    if (!key) return;
    if (key in out) throw new Error('Duplicate Setup key: ' + key);
    out[key] = row.value;
  });
  return out;
}

function getConfig_(key, fallbackValue) {
  const all = configAll_();
  return key in all && String(all[key]) !== '' ? all[key] : fallbackValue;
}

// Required config fails clearly (rule C-03) — never proceed on an empty string.
function getRequiredConfig_(key) {
  const value = getConfig_(key, '');
  if (String(value) === '') throw new Error('Missing required Setup value: ' + key);
  return value;
}

// Upsert: update-in-place or append; never a duplicate key row.
function setConfig_(key, value) {
  const hit = readObjects_('setup').filter(function (r) { return String(r.key) === String(key); })[0];
  if (hit) {
    const sheet = getSheet_('setup');
    const map = headerMap_('setup', sheet);
    sheet.getRange(hit.__row, map.value + 1).setValue(value);
  } else {
    appendObject_('setup', { key: key, value: value });
  }
}

function secretStore_() {
  const doc = PropertiesService.getDocumentProperties();
  return doc || PropertiesService.getScriptProperties();
}

// refKey is a Setup key whose VALUE is the property name holding the secret.
// The thrown message names the missing property, never a value.
function secret_(refKey) {
  const propertyName = getRequiredConfig_(refKey);
  const value = secretStore_().getProperty(propertyName);
  if (value === null || value === '') {
    throw new Error('Secret not set: property "' + propertyName + '" (referenced by Setup key "' + refKey + '").');
  }
  return value;
}
