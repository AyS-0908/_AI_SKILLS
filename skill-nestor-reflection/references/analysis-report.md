# Analysis and Report

Use this file after collection for any method. Use the stage, validation, resume, and handoff rules in `SKILL.md`.

## Analysis Preconditions

Do not analyse until:

- the scope and method are validated;
- the collection artifact exists;
- the questionnaire, source plan, or brainstorming brief passed its branch gate;
- required interview notes are validated, research evidence passed the reliability gate, or brainstorming clusters and criteria are validated.

## `Analysis` Tab Schema

Create these three blocks in the selected method Sheet's `Analysis` tab.

### Findings

| finding_id | finding | evidence_ids | method | strength | limits_or_gaps | implication | status |
|---|---|---|---|---|---|---|---|

Allowed `strength`: `strong`, `moderate`, `weak`. Allowed `status`: `draft`, `challenged`, `validated`, `rejected`.

### Calculations

| calculation_id | metric | formula_or_method | inputs | result | caveat |
|---|---|---|---|---|---|

Use native Sheet formulas where practical. Never hide a manual adjustment.

### Charts Index

| chart_id | title | source_range | message | destination | status |
|---|---|---|---|---|---|

Keep charts in Sheets. Link or insert them into narrative artifacts only when they improve understanding.

## Method Checks

- **Survey:** show response count, missingness, common answers, differences by approved segment, notable open-text themes, and limits. Do not imply causation from opinion data.
- **Live interviews:** trace findings to validated participant notes; distinguish repeated patterns from isolated views; protect the approved anonymity choice.
- **Data research:** trace each finding to accepted evidence IDs; preserve source conflicts and gaps; exclude claims that fail the reliability gate.
- **Brainstorming:** distinguish ideas from verified facts; show criteria, weights, scores, assumptions, sensitivity to close scores, and unscored strategic judgment.

## Independent Challenge

Give a fresh AI reviewer only the validated scope, method brief, source artifacts, and draft analysis. Ask it to return:

| challenge_id | target_finding_id | issue | evidence | severity | correction |
|---|---|---|---|---|---|

Require checks for unsupported claims, weak logic, missing alternatives, contradictory evidence, false precision, overconfidence, and scope drift. Use a fresh agent when available; otherwise use a fresh conversation. Apply only confirmed corrections and preserve a short record of rejected challenges.

## Narrative Pre-report Template

Create one Google Doc and require these tags:

- `{{REFLECTION_TITLE}}`
- `{{EXECUTIVE_SUMMARY}}`
- `{{KEY_CONCLUSIONS}}`
- `{{PATTERNS_AND_DIFFERENCES}}`
- `{{KEY_FIGURES}}`
- `{{LIMITS_AND_GAPS}}`
- `{{FURTHER_STUDY}}`
- `{{APPENDIX_INDEX}}`

Keep the main narrative concise and decision-ready. Put method detail, source lists, detailed calculations, and question-level results in appendices or linked artifacts.

End with: `Reply VALIDATE PRE-REPORT or list corrections.` Do not create the final report before validation.

## Final Report

The generator does not create this company-specific asset. Use the user-supplied branded Google Doc, Sheet, or Slides template. Require these stable tags or equivalent named placeholders:

- `{{TITLE}}`
- `{{CORE_MESSAGES}}`
- `{{RECOMMENDATIONS}}`
- `{{LIMITS}}`
- `{{EVIDENCE_APPENDIX}}`

Core pages lead with messages and decisions; appendices hold evidence and detail. Preserve brand formatting instead of rebuilding it. Re-read the created artifact and report its URL only after required sections are present.
