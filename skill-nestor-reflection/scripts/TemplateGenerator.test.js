'use strict';

const generator = require('./TemplateGenerator');
const schema = generator.NESTOR_TEMPLATE_SCHEMA_;
const summary = generator.selfCheckTemplateSchema();

if (summary.templateCount !== 6 || summary.tabCount !== 15 || summary.headerCount !== 17 || summary.tagCount !== 20 || summary.docTableCount !== 4) {
  throw new Error('Wrong template, tab, header, or tag count: ' + JSON.stringify(summary));
}

const expected = [
  ['NESTOR - Interview Working', ['Questions', 'Audience']],
  ['NESTOR - Interview Notes', ['Interview Notes']],
  ['NESTOR - Interview Analysis', ['Findings', 'Analysis']],
  ['NESTOR - Data Research', ['Brief', 'Sources', 'Evidence', 'Analysis']],
  ['NESTOR - Brainstorming', ['Brief', 'Ideas', 'Clusters', 'Evaluation', 'Analysis']],
  ['NESTOR - Pre-report', ['Pre-report']],
];

expected.forEach(function (item, index) {
  if (schema[index].name !== item[0] || JSON.stringify(schema[index].tabs.map(function (tab) { return tab.name; })) !== JSON.stringify(item[1])) {
    throw new Error('Wrong template or tab contract at index ' + index + '.');
  }
});

const analysis = schema[2].tabs[1].blocks;
if (JSON.stringify(analysis.map(function (block) { return block.headers; })) !== JSON.stringify([
  ['finding_id', 'finding', 'evidence_ids', 'method', 'strength', 'limits_or_gaps', 'implication', 'status'],
  ['calculation_id', 'metric', 'formula_or_method', 'inputs', 'result', 'caveat'],
  ['chart_id', 'title', 'source_range', 'message', 'destination', 'status'],
])) throw new Error('Analysis headers changed.');

const spec = schema[0];
if (JSON.stringify(spec.tabs[0].tables) !== JSON.stringify([
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
])) throw new Error('Interview Questions tables changed.');
if (JSON.stringify(spec.tabs[1].tables[0].rows[0]) !== JSON.stringify(['recipient_id', 'name', 'email', 'segment', 'status'])) throw new Error('Audience table changed.');
if (JSON.stringify(schema[1].tabs[0].tables[0].rows[0]) !== JSON.stringify(['finding_id', 'question_id', 'summary', 'supporting_extract', 'interpretation', 'confidence', 'follow_up'])) throw new Error('Interview Notes table changed.');
if (generator.planArtifactAction_([], spec).action !== 'CREATE') throw new Error('No match must CREATE.');
if (generator.planArtifactAction_([{ mimeType: spec.mimeType, description: 'READY:v1' }], spec).action !== 'REUSE') throw new Error('One exact READY:v1 match must REUSE.');

[
  [{ mimeType: spec.mimeType, description: 'BUILDING' }],
  [{ mimeType: 'wrong', description: 'READY:v1' }],
  [
    { mimeType: spec.mimeType, description: 'READY:v1' },
    { mimeType: spec.mimeType, description: 'READY:v1' },
  ],
].forEach(function (matches) {
  if (generator.planArtifactAction_(matches, spec).action !== 'STOP') throw new Error('Ambiguous or incomplete match must STOP.');
});

console.log('template_schema_and_reconciliation ok');
