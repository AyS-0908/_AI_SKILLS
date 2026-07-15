/**
 * Ui.gs — menu as a data tree + one result contract. Scaffold: add your
 * actions to menuTree_ and implement them as global functions.
 *
 * Result contract (rule U-04): every action shows exactly ONE alert (message
 * + optional "Next:" line), surfaces only err.message on failure (never a
 * stack or secret), and navigates only after success.
 *
 * Deliberately NOT included: a generic HTML form engine. One simple dialog
 * does not earn a framework (rule U-02) — add HtmlService dialogs per action,
 * and factor a shared field-spec renderer only once several forms repeat the
 * same shape.
 */

function onOpen() {
  const ui = SpreadsheetApp.getUi();
  const menu = ui.createMenu('MyTool'); // FILL IN: your tool name
  menuTree_().forEach(function (entry) {
    if (entry.sep) menu.addSeparator();
    else menu.addItem(entry.label, entry.fn);
  });
  menu.addToUi();
}

function menuTree_() {
  return [
    { label: 'Setup / repair workbook', fn: 'menuBootstrap' },
    { sep: true },
    // FILL IN: one entry per operator action, labels task-oriented.
  ];
}

function menuBootstrap() {
  runAction_(function () {
    const result = bootstrapRun();
    const suffix = result.warnings.length
      ? '\nWarnings:\n- ' + result.warnings.join('\n- ')
      : '';
    return { message: 'Workbook ready.' + suffix };
  });
}

// A hidden menu is not a security boundary (rule T-03): globals stay callable
// from the editor. Re-verify identity at the server entrypoint of every
// privileged action, e.g. compare Session.getActiveUser().getEmail() against
// a Setup-stored owner_email — and fail OPEN only for the bootstrap that
// creates that record.

function runAction_(fn) {
  const ui = SpreadsheetApp.getUi();
  try {
    const result = fn() || {};
    const lines = [result.message || 'Done.'];
    if (result.nextStep) lines.push('Next: ' + result.nextStep);
    ui.alert(lines.join('\n'));
    if (result.openTab) {
      const sheet = ss_().getSheetByName(result.openTab);
      if (sheet) ss_().setActiveSheet(sheet); // navigate only on success
    }
  } catch (error) {
    ui.alert(error.message); // message only — never a stack or secret
  }
}
