/**
 * Log.gs — one structured, redacted event per state change or external call
 * (rule C-05). Ready to run.
 *
 * DIAGNOSTICS ONLY. The tab is capped as a ring buffer, so it silently drops
 * old rows: never derive billing, quotas, or any durable business rule from
 * it (rule C-06 — give durable counters their own uncapped tab). Lesson paid
 * for in a source project: billing read from a capped log undercounts.
 */

const LOG_MAX_ROWS = 1000; // header excluded; size ABOVE what any consumer scans

const REDACT_KEY_RE = /key|token|secret|authorization|password|apikey|credential|bearer/i;

// Key-name redaction is defense in depth, NOT sufficient alone: also keep
// secrets and credential-bearing URLs out of the event you pass in.
function redact_(value) {
  if (value === null || typeof value !== 'object') return value;
  if (Array.isArray(value)) return value.map(redact_);
  return Object.keys(value).reduce(function (out, key) {
    out[key] = REDACT_KEY_RE.test(key) ? '[redacted]' : redact_(value[key]);
    return out;
  }, {});
}

function logEvent_(event) {
  const safe = redact_(event || {});
  const record = {
    log_id: nextId_(C.ID_PREFIX.logs),
    timestamp: nowIso_(),
    object_id: safe.object_id || '',
    action: safe.action || '',
    status_before: safe.status_before || '',
    status_after: safe.status_after || '',
    request_id: safe.request_id || '',
    result: safe.result || 'ok',
    error_code: safe.error_code || '',
    details: safe.details ? JSON.stringify(redact_(safe.details)) : '',
  };
  console.log(JSON.stringify(record));
  try {
    appendObject_('logs', record);
    trimLog_();
  } catch (error) {
    // Logging must never take down the action being logged.
    console.error('logEvent_ failed: ' + error.message);
  }
  return record;
}

function trimLog_() {
  const sheet = getSheet_('logs');
  const overflow = sheet.getLastRow() - 1 - LOG_MAX_ROWS;
  if (overflow > 0) sheet.deleteRows(2, overflow);
}
