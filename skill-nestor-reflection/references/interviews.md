# Interviews

Use this file only after scope validation. Ask only missing questions. Use the stage, validation, resume, and handoff rules in `SKILL.md`.

Contents: [questions](#method-questions) · [design](#question-design) · [template](#working-doc-template) · [gates](#validation-gates) · [Survey](#survey-execution) · [live](#live-interview-artifacts)

## Method Questions

1. **Mode:** Which interview mode applies?
   1. Survey (Recommended for broad, comparable input)
   2. Live interviews (Recommended for depth)
   3. Mixed - Survey followed by validated live interviews
2. **Question count:** How many questions should each participant receive? Recommend a count that fits the mode, deadline, and audience.
3. **Question mix:** What share should be closed versus open?
   1. Mostly closed - about 70/30
   2. Balanced - about 50/50 (Recommended default)
   3. Mostly open - about 30/70
   4. All open - usually for short live interviews
4. **Consistency:** Should questions be common or tailored?
   1. All common (required for the V1 Survey Form)
   2. Common Survey plus tailored Live questions (Recommended for Mixed)
   3. Common core plus tailored questions (Live interviews only)
   4. Fully tailored (Live interviews only)
5. **Anonymity:** How should identity be handled?
   1. Named responses
   2. Anonymous reporting
   3. Named collection, anonymized report (Recommended when sensitivity matters)
6. **Audience:** Who participates? Require names or stable IDs for individual files; require email addresses only for invitation drafts.
7. **Closing point:** What is the Survey closing date or live-interview completion date?
8. **Live input:** For Live or Mixed mode, what will the user provide?
   1. Notes
   2. Transcript
   3. Both
9. **Mixed follow-up:** For Mixed mode, how many post-Survey live questions may be proposed? Require validation of those questions before use.

Present a compact method brief and end with: `Reply VALIDATE METHOD or correct the numbered field(s).`

## Question Design

1. Draft a short introduction covering purpose, expected completion time, anonymity, and deadline.
2. Map every question to one validated macro question.
3. Use neutral wording; ask one idea per question.
4. For closed questions, define complete, non-overlapping options and add `Other` only when useful.
5. Mark required questions deliberately; do not require sensitive free text by default.
6. Keep tailored questions explicitly assigned to a segment or participant.

## Working Doc Template

Duplicate one template with two tabs. Stop if either tab or required tag is missing.

### `Questions` tab

Required tags:

- `{{REFLECTION_TITLE}}`
- `{{QUESTION_INTRO}}`
- `{{SURVEY_CONFIG_TABLE}}`
- `{{QUESTIONS_TABLE}}`

Populate the pre-created table immediately below `{{SURVEY_CONFIG_TABLE}}`, then delete that anchor. Keep the field labels exact because the bound helper reads them.

| Field | Value |
|---|---|
| Reflection ID | Stable short name |
| Target Folder URL or ID | Validated Drive folder |
| Form Title | Approved title |
| Form Description | Approved introduction |
| Response Sheet Title | Approved title or blank for default |
| Confirmation Message | Approved text or blank for default |
| Collect email | `YES` or `NO` |

The helper appends `Form edit URL`, `Form public URL`, `Response Sheet URL`, and `Status`.
After chat validation, run `Nestor > Record questionnaire approval`; the helper appends `Questionnaire status`, `Validated at`, and an input fingerprint. Any later change invalidates the approval.

Populate the pre-created table immediately below `{{QUESTIONS_TABLE}}`, then delete that anchor:

| Question ID | Sequence | Question | Type | Required | Options | Audience segment | Macro question ID |
|---|---:|---|---|---|---|---|---|

Allowed `Type`: `TEXT`, `PARAGRAPH`, `MULTIPLE_CHOICE`, `CHECKBOX`, `DROPDOWN`, `SCALE`. For choice questions, put one option per line. For `SCALE`, use `min|max|low label|high label`; `min` is 0 or 1 and `max` is 3 to 10. Use `YES` or `NO` for `Required`.

For a Survey, `Question ID`, `Sequence`, and `Macro question ID` are required and unique; `Audience segment` must be blank or `ALL`. Put tailored questions in the Live-interview route.

### `Audience` tab

Required tags:

- `{{INVITATION_SUBJECT}}`
- `{{INVITATION_BODY}}`
- `{{AUDIENCE_TABLE}}`

Populate the pre-created table immediately below `{{AUDIENCE_TABLE}}`, then delete that anchor:

| recipient_id | name | email | segment | status |
|---|---|---|---|---|

Allowed `status`: `draft`, `validated`, `excluded`.

## Validation Gates

- **Questionnaire gate:** Re-read the working Doc, show question and recipient counts, and require `VALIDATE QUESTIONNAIRE` before Form creation or live use.
- **Invitation gate:** Create Gmail drafts only from validated recipients and validated invitation text. Never send.
- **Mixed follow-up gate:** Require `VALIDATE FOLLOW-UP QUESTIONS` before live use.
- **Notes gate:** Require user validation of structured notes before transversal analysis.

## Survey Execution

1. Confirm the copied template contains the bound `scripts/FormBuilder.js` helper, record the validated questionnaire approval, then create one Form through `Nestor > Create approved survey`.
2. Link one response Sheet and record both artifact IDs in the handoff state.
3. On rerun, reuse recorded IDs or stop for reconciliation.
4. Create one invitation draft per validated recipient; include the Form URL; never send.

## Live Interview Artifacts

Recording and transcription are outside V1. The user supplies notes, a transcript, or both.

Create one interview-notes Doc per participant with these tags:

- `{{PARTICIPANT}}`
- `{{INTERVIEW_DATE}}`
- `{{RAW_INPUT}}`
- `{{STRUCTURED_NOTES_TABLE}}`
- `{{VALIDATION_STATUS}}`

Populate the pre-created table immediately below `{{STRUCTURED_NOTES_TABLE}}`, then delete that anchor:

| finding_id | question_id | summary | supporting_extract | interpretation | confidence | follow_up |
|---|---|---|---|---|---|---|

Preserve raw input unchanged. Allowed `confidence`: `high`, `medium`, `low`.

Use one transversal-analysis Sheet with:

- `Findings` tab: `finding_id | participant_id | question_id | finding | supporting_extract | confidence | validated_at`
- `Analysis` tab: use `analysis-report.md`.

Add only validated structured findings to `Findings`.
