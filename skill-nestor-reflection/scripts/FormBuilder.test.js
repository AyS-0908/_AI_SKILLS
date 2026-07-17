'use strict';

const helper = require('./FormBuilder');

if (helper.selfCheckNestorFormBuilder() !== true) {
  throw new Error('Nestor FormBuilder self-check did not pass.');
}

const state = {};
let formCreates = 0;
let sheetCreates = 0;
let destinationId = null;
const files = {};
const folderFiles = [];

function driveFile(id, name) {
  const file = {
    id,
    name,
    description: '',
    getId() { return this.id; },
    getDescription() { return this.description; },
    setDescription(value) { this.description = value; return this; },
    moveTo() { if (folderFiles.indexOf(this) < 0) folderFiles.push(this); return this; },
  };
  files[id] = file;
  return file;
}

const folder = {
  getFilesByName(name) {
    const matches = folderFiles.filter(file => file.name === name);
    let index = 0;
    return { hasNext() { return index < matches.length; }, next() { return matches[index++]; } };
  },
};

const item = { setTitle() { return this; }, setRequired() { return this; } };
const form = {
  id: 'form-123456',
  setDescription() { return this; },
  setConfirmationMessage() { return this; },
  setCollectEmail() { return this; },
  addTextItem() { return item; },
  getId() { return this.id; },
  getEditUrl() { return 'https://docs.google.com/forms/d/' + this.id + '/edit'; },
  getPublishedUrl() { return 'https://docs.google.com/forms/d/' + this.id + '/viewform'; },
  setDestination(type, id) { destinationId = id; return this; },
  getDestinationId() { return destinationId; },
};
const spreadsheet = {
  id: 'sheet-123456',
  getId() { return this.id; },
  getUrl() { return 'https://docs.google.com/spreadsheets/d/' + this.id; },
};

global.PropertiesService = {
  getDocumentProperties() {
    return {
      getProperty(key) { return Object.prototype.hasOwnProperty.call(state, key) ? state[key] : null; },
      setProperty(key, value) { state[key] = value; },
    };
  },
};
global.DriveApp = {
  getFolderById() { return folder; },
  getFileById(id) { return files[id]; },
};
global.FormApp = {
  DestinationType: { SPREADSHEET: 'SPREADSHEET' },
  create(title) { formCreates++; driveFile(form.id, title); return form; },
  openById() { return form; },
};
global.SpreadsheetApp = {
  create(title) { sheetCreates++; driveFile(spreadsheet.id, title); return spreadsheet; },
  openById() { return spreadsheet; },
};

const input = {
  reflectionId: 'demo',
  folderId: 'folder-123456',
  formTitle: 'Demo',
  formDescription: '',
  confirmationMessage: 'Thanks',
  collectEmail: false,
  responseSheetTitle: 'Demo responses',
  questions: [{ id: 'q1', sequence: 1, type: 'TEXT', title: 'Why?', required: true, audienceSegment: 'ALL', macroQuestionId: 'm1' }],
};

helper.assertQuestionnaireApproved_({
  'Questionnaire status': 'VALIDATED',
  'Approved input fingerprint': helper.fingerprintInput_(input),
}, input);

const first = helper.createSurveyPackage_(input);
const second = helper.createSurveyPackage_(input);
if (formCreates !== 1 || sheetCreates !== 1) throw new Error('Rerun created duplicate artifacts.');
if (destinationId !== spreadsheet.id || first.spreadsheetId !== second.spreadsheetId) throw new Error('Form linking or READY reuse failed.');

let changedInputStopped = false;
try { helper.createSurveyPackage_(Object.assign({}, input, { formTitle: 'Changed' })); } catch (error) { changedInputStopped = /input changed/.test(error.message); }
if (!changedInputStopped || formCreates !== 1) throw new Error('Changed input did not stop before duplicate creation.');

Object.keys(state).forEach(key => delete state[key]);
const copiedDocumentResult = helper.createSurveyPackage_(input);
if (formCreates !== 1 || sheetCreates !== 1 || copiedDocumentResult.formId !== form.id) throw new Error('Copied-document reconciliation created duplicates.');

state.NESTOR_SURVEY_blocked = JSON.stringify({ status: 'CREATING_FORM' });
let stopped = false;
try { helper.createSurveyPackage_(Object.assign({}, input, { reflectionId: 'blocked' })); } catch (error) { stopped = /Reconcile/.test(error.message); }
if (!stopped || formCreates !== 1) throw new Error('Ambiguous create state did not stop safely.');

console.log('duplicate_prevention_and_linking ok');

function verifyFaultBoundary(failAt, expectedStatus, expectSheetId) {
  const scenarioState = {};
  let creates = 0;
  const scenarioInput = Object.assign({}, input, {
    reflectionId: 'fault-' + failAt,
    formTitle: 'Form ' + failAt,
    responseSheetTitle: 'Sheet ' + failAt,
  });
  const scenarioForm = {
    getId() { return 'form-' + failAt; },
    setDescription() { if (failAt === 'form_config') throw new Error('injected'); return this; },
    setConfirmationMessage() { return this; },
    setCollectEmail() { return this; },
    addTextItem() { return item; },
    setDestination() { if (failAt === 'link') throw new Error('injected'); return this; },
  };
  const scenarioSheet = { getId() { return 'sheet-' + failAt; } };
  const emptyFolder = {
    getFilesByName() { return { hasNext() { return false; }, next() { return null; } }; },
  };

  global.PropertiesService = {
    getDocumentProperties() {
      return {
        getProperty(key) { return Object.prototype.hasOwnProperty.call(scenarioState, key) ? scenarioState[key] : null; },
        setProperty(key, value) { scenarioState[key] = value; },
      };
    },
  };
  global.DriveApp = {
    getFolderById() { return emptyFolder; },
    getFileById(id) {
      return {
        setDescription() { return this; },
        moveTo() {
          if ((failAt === 'form_move' && id.indexOf('form-') === 0) || (failAt === 'sheet_move' && id.indexOf('sheet-') === 0)) throw new Error('injected');
          return this;
        },
      };
    },
  };
  global.FormApp = {
    DestinationType: { SPREADSHEET: 'SPREADSHEET' },
    create() { creates++; return scenarioForm; },
  };
  global.SpreadsheetApp = {
    create() { if (failAt === 'sheet_create') throw new Error('injected'); return scenarioSheet; },
  };

  try { helper.createSurveyPackage_(scenarioInput); } catch (error) { /* expected */ }
  const saved = JSON.parse(scenarioState['NESTOR_SURVEY_' + scenarioInput.reflectionId]);
  if (saved.status !== expectedStatus || !saved.formId || (!!saved.spreadsheetId !== expectSheetId)) {
    throw new Error('Wrong recovery state after ' + failAt + ': ' + JSON.stringify(saved));
  }
  try { helper.createSurveyPackage_(scenarioInput); } catch (error) { /* expected stop */ }
  if (creates !== 1) throw new Error('Rerun duplicated Form after ' + failAt + '.');
}

verifyFaultBoundary('form_move', 'FORM_CREATED', false);
verifyFaultBoundary('form_config', 'CONFIGURING_FORM', false);
verifyFaultBoundary('sheet_create', 'CREATING_SHEET', false);
verifyFaultBoundary('sheet_move', 'SHEET_CREATED', true);
verifyFaultBoundary('link', 'LINKING', true);
console.log('fault_boundary_recovery ok');
