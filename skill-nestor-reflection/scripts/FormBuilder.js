/**
 * Nestor Survey helper.
 * Bind this file to the Google Doc template that contains one `Questions` tab.
 * The first table is configuration; the second table is the approved question list.
 */

const NESTOR_FORM = Object.freeze({
  propertyPrefix: 'NESTOR_SURVEY_',
  questionsTab: 'Questions',
  configHeaders: ['Field', 'Value'],
  questionHeaders: ['Question ID', 'Sequence', 'Question', 'Type', 'Required', 'Options', 'Audience segment', 'Macro question ID'],
  types: ['TEXT', 'PARAGRAPH', 'MULTIPLE_CHOICE', 'CHECKBOX', 'DROPDOWN', 'SCALE'],
});

function onOpen() {
  DocumentApp.getUi()
    .createMenu('Nestor')
    .addItem('Record questionnaire approval', 'recordQuestionnaireApproval')
    .addItem('Create approved survey', 'createApprovedSurvey')
    .addToUi();
}

function recordQuestionnaireApproval() {
  const ui = DocumentApp.getUi();
  const answer = ui.alert(
    'Record questionnaire approval?',
    'Confirm only after the questionnaire was validated in chat. Any later content change invalidates this approval.',
    ui.ButtonSet.YES_NO,
  );
  if (answer !== ui.Button.YES) return;

  try {
    withDocumentLock_(function () {
      const data = readSurveyDocument_();
      writeConfigValue_(data.configTable, 'Questionnaire status', 'VALIDATED');
      writeConfigValue_(data.configTable, 'Validated at', new Date().toISOString());
      writeConfigValue_(data.configTable, 'Approved input fingerprint', fingerprintInput_(data.input));
      data.doc.saveAndClose();
    });
    ui.alert('Questionnaire approval recorded.');
  } catch (error) {
    console.error(JSON.stringify({ event: 'nestor_approval_error', message: safeMessage_(error) }));
    ui.alert('Approval not recorded', safeMessage_(error), ui.ButtonSet.OK);
    throw error;
  }
}

function createApprovedSurvey() {
  const ui = DocumentApp.getUi();
  const answer = ui.alert(
    'Create approved survey?',
    'This creates one Google Form and one linked response Sheet from the current Questions tab.',
    ui.ButtonSet.YES_NO,
  );

  if (answer !== ui.Button.YES) return;

  try {
    const result = withDocumentLock_(buildSurveyFromActiveDocument_);
    ui.alert('Survey ready', result.formPublicUrl + '\n\nResponses: ' + result.spreadsheetUrl, ui.ButtonSet.OK);
  } catch (error) {
    console.error(JSON.stringify({ event: 'nestor_survey_error', message: safeMessage_(error) }));
    ui.alert('Survey creation stopped', safeMessage_(error) + '\n\nA Form or Sheet may already exist. Reconcile before retrying.', ui.ButtonSet.OK);
    throw error;
  }
}

function buildSurveyFromActiveDocument_() {
  const data = readSurveyDocument_();
  assertQuestionnaireApproved_(data.config, data.input);
  const result = createSurveyPackage_(data.input);

  writeConfigValue_(data.configTable, 'Form edit URL', result.formEditUrl);
  writeConfigValue_(data.configTable, 'Form public URL', result.formPublicUrl);
  writeConfigValue_(data.configTable, 'Response Sheet URL', result.spreadsheetUrl);
  writeConfigValue_(data.configTable, 'Status', 'READY');
  data.doc.saveAndClose();
  return result;
}

function readSurveyDocument_() {
  const doc = DocumentApp.getActiveDocument();
  if (!doc) throw new Error('Open the bound Google Doc before running the helper.');

  const tab = findUniqueTab_(doc, NESTOR_FORM.questionsTab);
  const tables = tab.asDocumentTab().getBody().getTables();
  if (tables.length < 2) throw new Error('Questions must contain a configuration table and a questions table.');

  const configTable = findTableByHeaders_(tables, NESTOR_FORM.configHeaders);
  const questionsTable = findTableByHeaders_(tables, NESTOR_FORM.questionHeaders);
  const config = readConfig_(configTable);
  const questions = parseQuestionRows_(tableValues_(questionsTable));
  const input = validateInput_(config, questions);
  return { doc: doc, configTable: configTable, config: config, input: input };
}

function assertQuestionnaireApproved_(config, input) {
  if (String(config['Questionnaire status'] || '').trim().toUpperCase() !== 'VALIDATED') {
    throw new Error('Questionnaire approval is missing. Run Nestor > Record questionnaire approval first.');
  }
  if (config['Approved input fingerprint'] !== fingerprintInput_(input)) {
    throw new Error('Questionnaire content changed after approval. Record approval again before creation.');
  }
}

function createSurveyPackage_(input) {
  const props = PropertiesService.getDocumentProperties();
  const key = NESTOR_FORM.propertyPrefix + input.reflectionId;
  const existing = readState_(props, key);
  const inputFingerprint = fingerprintInput_(input);

  if (existing) {
    if (existing.status !== 'READY') {
      throw new Error('A previous create stopped at ' + existing.status + '. Reconcile the recorded IDs before retrying.');
    }
    if (existing.inputFingerprint !== inputFingerprint) {
      throw new Error('The approved survey input changed after creation. Use the existing Form or reconcile with a new Reflection ID.');
    }
    return verifyReadyState_(existing);
  }

  const folder = DriveApp.getFolderById(input.folderId);
  const found = findExistingPackage_(folder, input, inputFingerprint);
  if (found) {
    writeState_(props, key, found);
    return found;
  }
  const marker = artifactMarker_(input.reflectionId, inputFingerprint);
  writeState_(props, key, { status: 'CREATING_FORM', inputFingerprint: inputFingerprint });

  const form = FormApp.create(input.formTitle, true);
  const formId = form.getId();
  writeState_(props, key, { status: 'FORM_CREATED', formId: formId, inputFingerprint: inputFingerprint });
  DriveApp.getFileById(formId).setDescription(marker).moveTo(folder);
  writeState_(props, key, { status: 'CONFIGURING_FORM', formId: formId, inputFingerprint: inputFingerprint });
  form.setDescription(input.formDescription)
    .setConfirmationMessage(input.confirmationMessage)
    .setCollectEmail(input.collectEmail);
  input.questions.forEach(function (question) { addQuestion_(form, question); });

  writeState_(props, key, { status: 'CREATING_SHEET', formId: formId, inputFingerprint: inputFingerprint });
  const spreadsheet = SpreadsheetApp.create(input.responseSheetTitle);
  const spreadsheetId = spreadsheet.getId();
  writeState_(props, key, { status: 'SHEET_CREATED', formId: formId, spreadsheetId: spreadsheetId, inputFingerprint: inputFingerprint });
  DriveApp.getFileById(spreadsheetId).setDescription(marker).moveTo(folder);

  writeState_(props, key, { status: 'LINKING', formId: formId, spreadsheetId: spreadsheetId, inputFingerprint: inputFingerprint });
  form.setDestination(FormApp.DestinationType.SPREADSHEET, spreadsheetId);

  const ready = {
    status: 'READY',
    formId: formId,
    spreadsheetId: spreadsheetId,
    formEditUrl: form.getEditUrl(),
    formPublicUrl: form.getPublishedUrl(),
    spreadsheetUrl: spreadsheet.getUrl(),
    inputFingerprint: inputFingerprint,
  };
  writeState_(props, key, ready);
  return ready;
}

function findExistingPackage_(folder, input, inputFingerprint) {
  const marker = artifactMarker_(input.reflectionId, inputFingerprint);
  const formFiles = iteratorValues_(folder.getFilesByName(input.formTitle));
  const sheetFiles = iteratorValues_(folder.getFilesByName(input.responseSheetTitle));
  if (!formFiles.length && !sheetFiles.length) return null;

  const markedForms = formFiles.filter(function (file) { return file.getDescription() === marker; });
  const markedSheets = sheetFiles.filter(function (file) { return file.getDescription() === marker; });
  if (markedForms.length !== 1 || markedSheets.length !== 1) {
    throw new Error('Matching artifacts already exist in the target folder but cannot be reconciled uniquely.');
  }

  const form = FormApp.openById(markedForms[0].getId());
  const spreadsheet = SpreadsheetApp.openById(markedSheets[0].getId());
  if (form.getDestinationId() !== spreadsheet.getId()) {
    throw new Error('Matching Form and Sheet exist but are not linked. Reconcile before continuing.');
  }
  return {
    status: 'READY',
    formId: form.getId(),
    spreadsheetId: spreadsheet.getId(),
    formEditUrl: form.getEditUrl(),
    formPublicUrl: form.getPublishedUrl(),
    spreadsheetUrl: spreadsheet.getUrl(),
    inputFingerprint: inputFingerprint,
  };
}

function artifactMarker_(reflectionId, inputFingerprint) {
  return 'NESTOR_REFLECTION_ID:' + reflectionId + '|INPUT:' + inputFingerprint;
}

function iteratorValues_(iterator) {
  const values = [];
  while (iterator.hasNext()) values.push(iterator.next());
  return values;
}

function verifyReadyState_(state) {
  const form = FormApp.openById(state.formId);
  const spreadsheet = SpreadsheetApp.openById(state.spreadsheetId);
  if (form.getDestinationId() !== state.spreadsheetId) {
    throw new Error('Recorded Form and response Sheet are no longer linked. Reconcile before continuing.');
  }
  return {
    status: 'READY',
    formId: form.getId(),
    spreadsheetId: spreadsheet.getId(),
    formEditUrl: form.getEditUrl(),
    formPublicUrl: form.getPublishedUrl(),
    spreadsheetUrl: spreadsheet.getUrl(),
  };
}

function addQuestion_(form, question) {
  let item;
  if (question.type === 'TEXT') item = form.addTextItem();
  if (question.type === 'PARAGRAPH') item = form.addParagraphTextItem();
  if (question.type === 'MULTIPLE_CHOICE') item = form.addMultipleChoiceItem().setChoiceValues(question.options);
  if (question.type === 'CHECKBOX') item = form.addCheckboxItem().setChoiceValues(question.options);
  if (question.type === 'DROPDOWN') item = form.addListItem().setChoiceValues(question.options);
  if (question.type === 'SCALE') {
    item = form.addScaleItem()
      .setBounds(question.scale.min, question.scale.max)
      .setLabels(question.scale.lowLabel, question.scale.highLabel);
  }
  item.setTitle(question.title).setRequired(question.required);
}

function parseQuestionRows_(rows) {
  const headers = rows[0].map(normalize_);
  const index = {};
  NESTOR_FORM.questionHeaders.forEach(function (header) {
    const position = headers.indexOf(normalize_(header));
    if (position < 0) throw new Error('Questions table is missing header: ' + header);
    index[header] = position;
  });

  const parsed = rows.slice(1).filter(function (row) {
    return row.some(function (value) { return String(value || '').trim(); });
  }).map(function (row, offset) {
    const id = String(row[index['Question ID']] || '').trim();
    const sequence = Number(row[index.Sequence]);
    const type = String(row[index.Type] || '').trim().toUpperCase().replace(/[ -]+/g, '_');
    const title = String(row[index.Question] || '').trim();
    const optionsText = String(row[index.Options] || '').trim();
    const audienceSegment = String(row[index['Audience segment']] || '').trim();
    const macroQuestionId = String(row[index['Macro question ID']] || '').trim();
    if (!id) throw new Error('Question ' + (offset + 1) + ' has no Question ID.');
    if (!Number.isInteger(sequence) || sequence < 1) throw new Error('Question ' + id + ' has an invalid Sequence.');
    if (NESTOR_FORM.types.indexOf(type) < 0) throw new Error('Question ' + (offset + 1) + ' has unsupported type: ' + type);
    if (!title) throw new Error('Question ' + (offset + 1) + ' has no text.');
    if (audienceSegment && audienceSegment.toUpperCase() !== 'ALL') throw new Error('Tailored Survey questions are not supported in V1. Use Live interviews for segment-specific questions.');
    if (!macroQuestionId) throw new Error('Question ' + id + ' has no Macro question ID.');

    const question = { id: id, sequence: sequence, type: type, title: title, required: parseYesNo_(row[index.Required], 'Question ' + id + ' Required'), audienceSegment: audienceSegment || 'ALL', macroQuestionId: macroQuestionId };
    if (['MULTIPLE_CHOICE', 'CHECKBOX', 'DROPDOWN'].indexOf(type) >= 0) {
      question.options = optionsText.split(/\r?\n/).map(function (value) { return value.trim(); }).filter(Boolean);
      if (question.options.length < 2) throw new Error('Question ' + (offset + 1) + ' needs at least two options on separate lines.');
    }
    if (type === 'SCALE') question.scale = parseScale_(optionsText, offset + 1);
    return question;
  });
  assertUnique_(parsed.map(function (question) { return question.id; }), 'Question ID');
  assertUnique_(parsed.map(function (question) { return question.sequence; }), 'Sequence');
  return parsed.sort(function (a, b) { return a.sequence - b.sequence; });
}

function assertUnique_(values, label) {
  const seen = Object.create(null);
  values.forEach(function (value) {
    const key = String(value);
    if (seen[key]) throw new Error('Duplicate ' + label + ': ' + value);
    seen[key] = true;
  });
}

function parseScale_(text, number) {
  const parts = text.split('|').map(function (value) { return value.trim(); });
  const min = Number(parts[0]);
  const max = Number(parts[1]);
  if (!Number.isInteger(min) || !Number.isInteger(max) || [0, 1].indexOf(min) < 0 || max < 3 || max > 10) {
    throw new Error('Question ' + number + ' scale must be min|max|low label|high label, with min 0 or 1 and max 3 to 10.');
  }
  return { min: min, max: max, lowLabel: parts[2] || '', highLabel: parts[3] || '' };
}

function validateInput_(config, questions) {
  const required = ['Reflection ID', 'Target Folder URL or ID', 'Form Title'];
  required.forEach(function (field) { if (!config[field]) throw new Error('Missing configuration value: ' + field); });
  if (!questions.length) throw new Error('The approved questions table is empty.');

  const reflectionId = String(config['Reflection ID']).trim().replace(/[^A-Za-z0-9_-]/g, '-').slice(0, 80);
  if (!reflectionId) throw new Error('Reflection ID has no usable characters.');
  const responseSheetTitle = String(config['Response Sheet Title'] || config['Form Title'] + ' - Responses').trim();
  if (responseSheetTitle === String(config['Form Title']).trim()) {
    throw new Error('Response Sheet Title must differ from Form Title.');
  }
  return {
    reflectionId: reflectionId,
    folderId: extractDriveId_(config['Target Folder URL or ID']),
    formTitle: String(config['Form Title']).trim(),
    formDescription: String(config['Form Description'] || '').trim(),
    responseSheetTitle: responseSheetTitle,
    confirmationMessage: String(config['Confirmation Message'] || 'Thank you for your response.').trim(),
    collectEmail: parseYesNo_(config['Collect email'] || 'NO', 'Collect email'),
    questions: questions,
  };
}

function findUniqueTab_(doc, title) {
  const hits = flattenTabs_(doc.getTabs()).filter(function (tab) { return tab.getTitle() === title; });
  if (hits.length !== 1) throw new Error('Expected exactly one ' + title + ' tab; found ' + hits.length + '.');
  return hits[0];
}

function flattenTabs_(tabs) {
  return tabs.reduce(function (all, tab) {
    return all.concat([tab], flattenTabs_(tab.getChildTabs()));
  }, []);
}

function findTableByHeaders_(tables, expected) {
  const hits = tables.filter(function (table) {
    const rows = tableValues_(table);
    if (!rows.length) return false;
    const headers = rows[0].map(normalize_);
    return expected.every(function (header) { return headers.indexOf(normalize_(header)) >= 0; });
  });
  if (hits.length !== 1) throw new Error('Expected exactly one table with headers: ' + expected.join(', ') + '.');
  return hits[0];
}

function tableValues_(table) {
  const rows = [];
  for (let r = 0; r < table.getNumRows(); r++) {
    const row = [];
    for (let c = 0; c < table.getRow(r).getNumCells(); c++) row.push(table.getCell(r, c).getText());
    rows.push(row);
  }
  return rows;
}

function readConfig_(table) {
  const rows = tableValues_(table);
  const result = {};
  rows.slice(1).forEach(function (row) {
    const field = String(row[0] || '').trim();
    if (field) result[field] = String(row[1] || '').trim();
  });
  return result;
}

function writeConfigValue_(table, field, value) {
  for (let r = 1; r < table.getNumRows(); r++) {
    if (table.getCell(r, 0).getText().trim() === field) {
      table.getCell(r, 1).setText(String(value));
      return;
    }
  }
  const row = table.appendTableRow();
  row.appendTableCell(field);
  row.appendTableCell(String(value));
}

function extractDriveId_(value) {
  const text = String(value || '').trim();
  const match = text.match(/[-\w]{10,}/);
  if (!match) throw new Error('Target Folder URL or ID is invalid.');
  return match[0];
}

function parseYesNo_(value, label) {
  const normalized = normalize_(value);
  if (['yes', 'true', '1', 'x'].indexOf(normalized) >= 0) return true;
  if (['no', 'false', '0', ''].indexOf(normalized) >= 0) return false;
  throw new Error(label + ' must be YES or NO.');
}

function normalize_(value) {
  return String(value || '').trim().toLowerCase();
}

function fingerprintInput_(input) {
  const text = JSON.stringify(input);
  let hash = 2166136261;
  for (let i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16);
}

function withDocumentLock_(callback) {
  const lock = LockService.getDocumentLock();
  if (!lock || !lock.tryLock(30000)) throw new Error('Another survey creation is running. Try again later.');
  try { return callback(); } finally { lock.releaseLock(); }
}

function readState_(props, key) {
  const raw = props.getProperty(key);
  if (!raw) return null;
  try { return JSON.parse(raw); } catch (error) { throw new Error('Survey registry is invalid. Reconcile before continuing.'); }
}

function writeState_(props, key, state) {
  props.setProperty(key, JSON.stringify(state));
}

function safeMessage_(error) {
  return error && error.message ? String(error.message).slice(0, 500) : 'Unknown error.';
}

function selfCheckNestorFormBuilder() {
  if (extractDriveId_('https://drive.google.com/drive/folders/abcDEF12345') !== 'abcDEF12345') throw new Error('Drive ID parser failed.');
  if (!parseYesNo_('YES', 'test') || parseYesNo_('NO', 'test')) throw new Error('YES/NO parser failed.');
  const rows = [
    ['Question ID', 'Sequence', 'Question', 'Type', 'Required', 'Options', 'Audience segment', 'Macro question ID'],
    ['q2', '2', 'Pick one', 'multiple choice', 'YES', 'A\nB', 'ALL', 'm1'],
    ['q1', '1', 'Score', 'scale', 'NO', '1|5|Low|High', '', 'm1'],
  ];
  const parsed = parseQuestionRows_(rows);
  if (parsed.length !== 2 || parsed[0].scale.max !== 5 || parsed[1].options.length !== 2) throw new Error('Question parser failed.');
  console.log('selfCheckNestorFormBuilder ok');
  return true;
}

if (typeof module !== 'undefined') {
  module.exports = { assertQuestionnaireApproved_, createSurveyPackage_, extractDriveId_, fingerprintInput_, parseYesNo_, parseQuestionRows_, selfCheckNestorFormBuilder };
}
