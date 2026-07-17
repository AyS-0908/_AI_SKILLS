/**
 * Standalone Apps Script V8 generator for the six Nestor Google templates.
 * Enable the Advanced Google Docs service (`Docs`) before running.
 * After generation, bind FormBuilder.js manually to the Interview Working Doc.
 */

const NESTOR_TEMPLATE_PARENT_FOLDER = 'PASTE_PARENT_FOLDER_URL_OR_ID_HERE';

const NESTOR_TEMPLATE_FOLDER_NAME_ = 'NESTOR - Templates';
const NESTOR_DOC_MIME_ = 'application/vnd.google-apps.document';
const NESTOR_SHEET_MIME_ = 'application/vnd.google-apps.spreadsheet';

const NESTOR_ANALYSIS_BLOCKS_ = [
  { title: 'Findings', headers: ['finding_id', 'finding', 'evidence_ids', 'method', 'strength', 'limits_or_gaps', 'implication', 'status'] },
  { title: 'Calculations', headers: ['calculation_id', 'metric', 'formula_or_method', 'inputs', 'result', 'caveat'] },
  { title: 'Charts Index', headers: ['chart_id', 'title', 'source_range', 'message', 'destination', 'status'] },
];

const NESTOR_TEMPLATE_SCHEMA_ = [
  {
    key: 'INTERVIEW_WORKING',
    name: 'NESTOR - Interview Working',
    kind: 'DOC',
    mimeType: NESTOR_DOC_MIME_,
    tabs: [
      {
        name: 'Questions',
        title: 'Interview Working - Questions',
        tags: ['{{REFLECTION_TITLE}}', '{{QUESTION_INTRO}}', '{{SURVEY_CONFIG_TABLE}}', '{{QUESTIONS_TABLE}}'],
        tables: [
          {
            anchor: '{{SURVEY_CONFIG_TABLE}}',
            rows: [
              ['Field', 'Value'],
              ['Reflection ID', ''],
              ['Target Folder URL or ID', ''],
              ['Form Title', ''],
              ['Form Description', ''],
              ['Response Sheet Title', ''],
              ['Confirmation Message', ''],
              ['Collect email', ''],
            ],
          },
          { anchor: '{{QUESTIONS_TABLE}}', rows: [['Question ID', 'Sequence', 'Question', 'Type', 'Required', 'Options', 'Audience segment', 'Macro question ID']] },
        ],
      },
      {
        name: 'Audience',
        title: 'Interview Working - Audience',
        tags: ['{{INVITATION_SUBJECT}}', '{{INVITATION_BODY}}', '{{AUDIENCE_TABLE}}'],
        tables: [
          { anchor: '{{AUDIENCE_TABLE}}', rows: [['recipient_id', 'name', 'email', 'segment', 'status']] },
        ],
      },
    ],
  },
  {
    key: 'INTERVIEW_NOTES',
    name: 'NESTOR - Interview Notes',
    kind: 'DOC',
    mimeType: NESTOR_DOC_MIME_,
    tabs: [
      {
        name: 'Interview Notes',
        title: 'Interview Notes',
        tags: ['{{PARTICIPANT}}', '{{INTERVIEW_DATE}}', '{{RAW_INPUT}}', '{{STRUCTURED_NOTES_TABLE}}', '{{VALIDATION_STATUS}}'],
        tables: [
          { anchor: '{{STRUCTURED_NOTES_TABLE}}', rows: [['finding_id', 'question_id', 'summary', 'supporting_extract', 'interpretation', 'confidence', 'follow_up']] },
        ],
      },
    ],
  },
  {
    key: 'INTERVIEW_ANALYSIS',
    name: 'NESTOR - Interview Analysis',
    kind: 'SHEET',
    mimeType: NESTOR_SHEET_MIME_,
    tabs: [
      { name: 'Findings', headers: ['finding_id', 'participant_id', 'question_id', 'finding', 'supporting_extract', 'confidence', 'validated_at'] },
      { name: 'Analysis', blocks: NESTOR_ANALYSIS_BLOCKS_ },
    ],
  },
  {
    key: 'DATA_RESEARCH',
    name: 'NESTOR - Data Research',
    kind: 'SHEET',
    mimeType: NESTOR_SHEET_MIME_,
    tabs: [
      { name: 'Brief', headers: ['field', 'value', 'validation_status'] },
      { name: 'Sources', headers: ['source_id', 'title', 'author_or_publisher', 'url', 'source_type', 'publication_date', 'access_date', 'geography', 'reliability_class', 'reliability_rationale', 'status'] },
      { name: 'Evidence', headers: ['evidence_id', 'claim_id', 'claim', 'source_id', 'source_type', 'publication_date', 'geography', 'evidence', 'reliability_rationale', 'conflicts', 'gaps'] },
      { name: 'Analysis', blocks: NESTOR_ANALYSIS_BLOCKS_ },
    ],
  },
  {
    key: 'BRAINSTORMING',
    name: 'NESTOR - Brainstorming',
    kind: 'SHEET',
    mimeType: NESTOR_SHEET_MIME_,
    tabs: [
      { name: 'Brief', headers: ['field', 'value', 'validation_status'] },
      { name: 'Ideas', headers: ['idea_id', 'idea', 'short_description', 'angle', 'contributor', 'assumptions', 'status'] },
      { name: 'Clusters', headers: ['cluster_id', 'cluster_name', 'idea_ids', 'consolidated_idea', 'distinction', 'validation_status'] },
      { name: 'Evaluation', headers: ['cluster_id', 'criterion', 'weight', 'score', 'weighted_score', 'rationale', 'evidence_or_assumption', 'rank'] },
      { name: 'Analysis', blocks: NESTOR_ANALYSIS_BLOCKS_ },
    ],
  },
  {
    key: 'PRE_REPORT',
    name: 'NESTOR - Pre-report',
    kind: 'DOC',
    mimeType: NESTOR_DOC_MIME_,
    tabs: [
      { name: 'Pre-report', title: 'Narrative Pre-report', tags: ['{{REFLECTION_TITLE}}', '{{EXECUTIVE_SUMMARY}}', '{{KEY_CONCLUSIONS}}', '{{PATTERNS_AND_DIFFERENCES}}', '{{KEY_FIGURES}}', '{{LIMITS_AND_GAPS}}', '{{FURTHER_STUDY}}', '{{APPENDIX_INDEX}}'] },
    ],
  },
];

function createNestorTemplates() {
  selfCheckTemplateSchema();
  assertDocsAdvancedService_();
  const parentId = extractDriveId_(NESTOR_TEMPLATE_PARENT_FOLDER);
  const parent = DriveApp.getFolderById(parentId); // Validate access before any write.
  const lock = LockService.getScriptLock();

  if (!lock.tryLock(30000)) throw new Error('Another Nestor template generation is running. Try again later.');

  try {
    const folder = getOrCreateTemplateFolder_(parent);
    const planned = NESTOR_TEMPLATE_SCHEMA_.map(function (spec) {
      const matches = listNamedFiles_(folder, spec.name);
      const decision = planArtifactAction_(matches, spec);
      if (decision.action === 'STOP') throw new Error(spec.name + ': ' + decision.reason);
      return { spec: spec, matches: matches, decision: decision };
    });

    const artifacts = planned.map(function (item) {
      if (item.decision.action === 'REUSE') {
        verifyExistingTemplate_(item.matches[0].id, item.spec);
        return { name: item.spec.name, action: 'REUSED', url: item.matches[0].url };
      }
      const created = item.spec.kind === 'DOC'
        ? createDocumentTemplate_(folder, item.spec)
        : createSheetTemplate_(folder, item.spec);
      return { name: item.spec.name, action: 'CREATED', url: created.url };
    });

    const result = { folderUrl: folder.getUrl(), artifacts: artifacts };
    Logger.log(JSON.stringify(result, null, 2));
    return result;
  } finally {
    lock.releaseLock();
  }
}

function planArtifactAction_(matches, spec) {
  if (!Array.isArray(matches) || !spec) return { action: 'STOP', reason: 'Invalid reconciliation input.' };
  if (matches.length === 0) return { action: 'CREATE' };
  if (matches.length !== 1) return { action: 'STOP', reason: 'Found ' + matches.length + ' exact-name files; reconcile them first.' };

  const match = matches[0];
  if (match.mimeType !== spec.mimeType) return { action: 'STOP', reason: 'The exact-name file has the wrong Google file type.' };
  if (match.description === 'READY:v1') return { action: 'REUSE' };
  return { action: 'STOP', reason: 'The exact-name file is incomplete or not a Nestor READY:v1 template.' };
}

function selfCheckTemplateSchema() {
  const names = NESTOR_TEMPLATE_SCHEMA_.map(function (spec) { return spec.name; });
  const keys = NESTOR_TEMPLATE_SCHEMA_.map(function (spec) { return spec.key; });
  const tabCount = NESTOR_TEMPLATE_SCHEMA_.reduce(function (sum, spec) { return sum + spec.tabs.length; }, 0);
  const headerCount = NESTOR_TEMPLATE_SCHEMA_.reduce(function (sum, spec) {
    return sum + spec.tabs.reduce(function (tabSum, tab) {
      return tabSum + (tab.headers ? 1 : 0) + (tab.blocks ? tab.blocks.length : 0);
    }, 0);
  }, 0);
  const tagCount = NESTOR_TEMPLATE_SCHEMA_.reduce(function (sum, spec) {
    return sum + spec.tabs.reduce(function (tabSum, tab) { return tabSum + (tab.tags ? tab.tags.length : 0); }, 0);
  }, 0);
  const docTableCount = NESTOR_TEMPLATE_SCHEMA_.reduce(function (sum, spec) {
    return sum + spec.tabs.reduce(function (tabSum, tab) { return tabSum + (tab.tables ? tab.tables.length : 0); }, 0);
  }, 0);

  assertUnique_(names, 'template name');
  assertUnique_(keys, 'template key');
  NESTOR_TEMPLATE_SCHEMA_.forEach(function (spec) {
    assertUnique_(spec.tabs.map(function (tab) { return tab.name; }), spec.name + ' tab name');
    spec.tabs.forEach(function (tab) {
      const tables = tab.tables || [];
      assertUnique_(tables.map(function (table) { return table.anchor; }), spec.name + ' table anchor');
      tables.forEach(function (table) {
        if ((tab.tags || []).filter(function (tag) { return tag === table.anchor; }).length !== 1) throw new Error(spec.name + ' table anchor must match one tag: ' + table.anchor);
        if (!table.rows.length || !table.rows[0].length) throw new Error(spec.name + ' has an empty table: ' + table.anchor);
        const width = table.rows[0].length;
        if (table.rows.some(function (row) { return row.length !== width; })) throw new Error(spec.name + ' has a non-rectangular table: ' + table.anchor);
      });
    });
  });
  if (NESTOR_TEMPLATE_SCHEMA_.length !== 6 || tabCount !== 15 || headerCount !== 17 || tagCount !== 20 || docTableCount !== 4) {
    throw new Error('Nestor template schema count mismatch.');
  }
  return { templateCount: 6, tabCount: tabCount, headerCount: headerCount, tagCount: tagCount, docTableCount: docTableCount };
}

function assertDocsAdvancedService_() {
  if (typeof Docs === 'undefined' || !Docs.Documents || typeof Docs.Documents.create !== 'function' || typeof Docs.Documents.get !== 'function' || typeof Docs.Documents.batchUpdate !== 'function') {
    throw new Error('Enable the Advanced Google Docs service (Docs API) before running. No files were created.');
  }
}

function getOrCreateTemplateFolder_(parent) {
  const folders = iteratorValues_(parent.getFoldersByName(NESTOR_TEMPLATE_FOLDER_NAME_));
  if (folders.length > 1) throw new Error('Found multiple NESTOR - Templates folders. Reconcile them before running.');
  return folders.length === 1 ? folders[0] : parent.createFolder(NESTOR_TEMPLATE_FOLDER_NAME_);
}

function listNamedFiles_(folder, name) {
  return iteratorValues_(folder.getFilesByName(name)).map(function (file) {
    return {
      id: file.getId(),
      mimeType: file.getMimeType(),
      description: file.getDescription(),
      url: file.getUrl(),
      file: file,
    };
  });
}

function createDocumentTemplate_(folder, spec) {
  const created = Docs.Documents.create({ title: spec.name });
  const id = created.documentId;
  const file = DriveApp.getFileById(id);
  file.setDescription('BUILDING').moveTo(folder);

  const initial = getDocsDocument_(id);
  const initialTabs = flattenApiTabs_(initial.tabs || []);
  if (initialTabs.length !== 1) throw new Error(spec.name + ' started with an unexpected tab count.');

  const tabRequests = [{
    updateDocumentTabProperties: {
      tabProperties: { tabId: initialTabs[0].tabProperties.tabId, title: spec.tabs[0].name },
      fields: 'title',
    },
  }];
  spec.tabs.slice(1).forEach(function (tab, index) {
    tabRequests.push({ addDocumentTab: { tabProperties: { title: tab.name, index: index + 1 } } });
  });
  Docs.Documents.batchUpdate({ requests: tabRequests }, id);

  const doc = DocumentApp.openById(id);
  const documentTabs = flattenDocumentTabs_(doc.getTabs());
  spec.tabs.forEach(function (tabSpec) {
    const matches = documentTabs.filter(function (tab) { return tab.getTitle() === tabSpec.name; });
    if (matches.length !== 1) throw new Error(spec.name + ' expected exactly one ' + tabSpec.name + ' tab.');
    const body = matches[0].asDocumentTab().getBody();
    body.clear();
    body.appendParagraph(tabSpec.title).setHeading(DocumentApp.ParagraphHeading.TITLE);
    tabSpec.tags.forEach(function (tag) {
      body.appendParagraph(tag);
      const tableSpec = (tabSpec.tables || []).filter(function (table) { return table.anchor === tag; })[0];
      if (tableSpec) {
        const table = body.appendTable(tableSpec.rows);
        for (let column = 0; column < table.getRow(0).getNumCells(); column++) {
          table.getCell(0, column).editAsText().setBold(true);
        }
      }
    });
  });
  doc.saveAndClose();
  verifyDocumentTemplate_(id, spec);
  file.setDescription('READY:v1');
  return { id: id, url: file.getUrl() };
}

function createSheetTemplate_(folder, spec) {
  const spreadsheet = SpreadsheetApp.create(spec.name);
  const id = spreadsheet.getId();
  const file = DriveApp.getFileById(id);
  file.setDescription('BUILDING').moveTo(folder);

  const firstSheet = spreadsheet.getSheets()[0];
  firstSheet.setName(spec.tabs[0].name);
  spec.tabs.forEach(function (tabSpec, index) {
    const sheet = index === 0 ? firstSheet : spreadsheet.insertSheet(tabSpec.name);
    writeSheetTab_(sheet, tabSpec);
  });
  verifySheetTemplate_(spreadsheet, spec);
  file.setDescription('READY:v1');
  return { id: id, url: spreadsheet.getUrl() };
}

function verifyExistingTemplate_(id, spec) {
  if (spec.kind === 'DOC') verifyDocumentTemplate_(id, spec);
  else verifySheetTemplate_(SpreadsheetApp.openById(id), spec);
}

function writeSheetTab_(sheet, tabSpec) {
  const layout = sheetLayout_(tabSpec);
  sheet.getRange(1, 1, layout.rows.length, layout.width).setValues(layout.rows);
  layout.headerRows.forEach(function (row) {
    sheet.getRange(row, 1, 1, layout.width).setFontWeight('bold').setBackground('#D9EAF7');
  });
  layout.titleRows.forEach(function (row) {
    sheet.getRange(row, 1, 1, layout.width).setFontWeight('bold').setBackground('#1F4E78').setFontColor('#FFFFFF');
  });
  sheet.setFrozenRows(layout.frozenRows);
  sheet.autoResizeColumns(1, layout.width);
}

function sheetLayout_(tabSpec) {
  if (tabSpec.headers) {
    return { rows: [tabSpec.headers.slice()], width: tabSpec.headers.length, headerRows: [1], titleRows: [], frozenRows: 1 };
  }

  const width = tabSpec.blocks.reduce(function (max, block) { return Math.max(max, block.headers.length); }, 1);
  const rows = [];
  const titleRows = [];
  const headerRows = [];
  tabSpec.blocks.forEach(function (block, index) {
    if (index) rows.push([]);
    titleRows.push(rows.length + 1);
    rows.push([block.title]);
    headerRows.push(rows.length + 1);
    rows.push(block.headers.slice());
  });
  return {
    rows: rows.map(function (row) { return padRow_(row, width); }),
    width: width,
    headerRows: headerRows,
    titleRows: titleRows,
    frozenRows: 2,
  };
}

function verifyDocumentTemplate_(id, spec) {
  const doc = DocumentApp.openById(id);
  const tabs = flattenDocumentTabs_(doc.getTabs());
  if (tabs.length !== spec.tabs.length) throw new Error(spec.name + ' tab verification failed.');
  spec.tabs.forEach(function (tabSpec) {
    const matches = tabs.filter(function (tab) { return tab.getTitle() === tabSpec.name; });
    if (matches.length !== 1) throw new Error(spec.name + ' tab verification failed for ' + tabSpec.name + '.');
    const body = matches[0].asDocumentTab().getBody();
    const text = body.getText();
    tabSpec.tags.forEach(function (tag) {
      if (countOccurrences_(text, tag) !== 1) throw new Error(spec.name + ' tag verification failed for ' + tag + '.');
    });
    const tables = body.getTables();
    if (tables.length !== (tabSpec.tables || []).length) throw new Error(spec.name + ' table count verification failed for ' + tabSpec.name + '.');
    (tabSpec.tables || []).forEach(function (tableSpec, index) {
      const table = tables[index];
      if (table.getNumRows() !== tableSpec.rows.length || JSON.stringify(tableRowValues_(table, 0)) !== JSON.stringify(tableSpec.rows[0])) {
        throw new Error(spec.name + ' table header verification failed for ' + tableSpec.anchor + '.');
      }
      const tableIndex = body.getChildIndex(table);
      if (tableIndex < 1 || body.getChild(tableIndex - 1).asParagraph().getText() !== tableSpec.anchor) {
        throw new Error(spec.name + ' table anchor verification failed for ' + tableSpec.anchor + '.');
      }
    });
  });
  doc.saveAndClose();
}

function verifySheetTemplate_(spreadsheet, spec) {
  const sheets = spreadsheet.getSheets();
  if (sheets.length !== spec.tabs.length) throw new Error(spec.name + ' tab verification failed.');
  spec.tabs.forEach(function (tabSpec) {
    const sheet = spreadsheet.getSheetByName(tabSpec.name);
    if (!sheet) throw new Error(spec.name + ' is missing tab ' + tabSpec.name + '.');
    const expected = sheetLayout_(tabSpec).rows;
    const actual = sheet.getRange(1, 1, expected.length, expected[0].length).getValues();
    if (JSON.stringify(actual) !== JSON.stringify(expected)) throw new Error(spec.name + ' schema verification failed for ' + tabSpec.name + '.');
  });
}

function getDocsDocument_(id) {
  return Docs.Documents.get(id, { includeTabsContent: true });
}

function flattenApiTabs_(tabs) {
  return tabs.reduce(function (all, tab) {
    return all.concat([tab], flattenApiTabs_(tab.childTabs || []));
  }, []);
}

function flattenDocumentTabs_(tabs) {
  return tabs.reduce(function (all, tab) {
    return all.concat([tab], flattenDocumentTabs_(tab.getChildTabs()));
  }, []);
}

function tableRowValues_(table, rowIndex) {
  const row = table.getRow(rowIndex);
  const values = [];
  for (let column = 0; column < row.getNumCells(); column++) values.push(row.getCell(column).getText());
  return values;
}

function extractDriveId_(value) {
  const match = String(value || '').trim().match(/[-\w]{10,}/);
  if (!match || match[0] === 'PASTE_PARENT_FOLDER_URL_OR_ID_HERE') throw new Error('Set NESTOR_TEMPLATE_PARENT_FOLDER to a valid Google Drive folder URL or ID.');
  return match[0];
}

function iteratorValues_(iterator) {
  const values = [];
  while (iterator.hasNext()) values.push(iterator.next());
  return values;
}

function padRow_(row, width) {
  const padded = row.slice();
  while (padded.length < width) padded.push('');
  return padded;
}

function assertUnique_(values, label) {
  const seen = Object.create(null);
  values.forEach(function (value) {
    if (seen[value]) throw new Error('Duplicate ' + label + ': ' + value);
    seen[value] = true;
  });
}

function countOccurrences_(text, value) {
  return String(text).split(value).length - 1;
}

if (typeof module !== 'undefined') {
  module.exports = { NESTOR_TEMPLATE_SCHEMA_: NESTOR_TEMPLATE_SCHEMA_, planArtifactAction_: planArtifactAction_, selfCheckTemplateSchema: selfCheckTemplateSchema };
}
