---
name: nestor-reflection
description: >
  Run a validated reflection pipeline from scope through evidence collection,
  challenge, and final report using Interviews, Data research, or Brainstorming
  with Google Workspace artifacts. Trigger for: "nestor reflection", "run a
  reflection", "structure this strategic reflection", "research and challenge
  this question", or requests to resume a Nestor reflection. Do NOT trigger for:
  a narrow external-entity comparison (use benchmark), generic one-off
  brainstorming with no reflection/report workflow, simple survey creation,
  document cleanup, or ordinary Google Workspace editing.
status: active
---

# Nestor Reflection

## Gotchas

- IF a Google tool is unavailable, unauthenticated, rate-limited, or returns an empty result: log the failed action without secrets, tell the user what remains undone, and provide the smallest manual fallback. Never claim success.
- IF an external create may have succeeded but no stable file ID was captured: stop for reconciliation. Never retry a create blindly.
- IF an attachment or Google artifact is empty, truncated, missing a required tab/table, or inconsistent with the approved input: stop and ask for the corrected source.
- Google Docs tab titles are not guaranteed unique. Require exactly one expected tab before reading or writing it.
- The Survey helper is a bound Apps Script copied with the Google Doc template. Its owner must authorize it on first use; only document editors can run it.
- Create Gmail invitations as drafts only. Never send them.

## Contract

Run one ordered `PIPELINE`. A later stage must consume approved artifacts from earlier stages; do not silently regenerate them.

| Stage | Required output | Gate and legal next action |
|---|---|---|
| `SCOPE` | Scope summary, initial opinion, answered scope fields | User approves -> `METHOD` |
| `METHOD` | Selected branch and method settings | User approves -> `PREPARE` |
| `PREPARE` | Method-specific Google working artifact | User approves exact content -> `COLLECT` |
| `COLLECT` | Responses, interview notes, research evidence, or ideas | Completeness check passes -> `ANALYZE` |
| `ANALYZE` | Structured analysis plus narrative pre-report | Fresh challenge completed -> `REVIEW` |
| `REVIEW` | Corrected pre-report | User approves -> `FINALIZE` |
| `FINALIZE` | Final report from the selected template | Report URL returned -> `DONE` |

At every stop, return this handoff block:

```text
Reflection: <short stable name>
Stage: <stage>
Method: <Interviews | Data research | Brainstorming>
Approved artifacts: <label + URL, or none>
Pending: <one user or AI action>
```

On resume, read the listed artifacts, verify the gate evidence, and continue from the recorded stage. IF evidence is missing or conflicts with the handoff, stop and reconcile; do not infer approval.

## Reference Routing

1. Always read `references/guidelines.md` for scope, method selection, question rules, and completeness checks.
2. Read only the selected branch:
   - Interviews -> `references/interviews.md`
   - Data research -> `references/data-research.md`
   - Brainstorming -> `references/brainstorming.md`
3. Read `references/google-workspace.md` before creating or editing Google artifacts.
4. Read `references/analysis-report.md` only from `ANALYZE` onward.
5. For Survey Form creation, use the approved working Doc and its bound `scripts/FormBuilder.js` helper.
6. For one-time neutral template setup, use `scripts/TemplateGenerator.js`; do not run it during a reflection.

## Execution

### 1. Scope

1. Ingest the topic, constraints, attachments, and any existing artifact URLs.
2. Summarize the understanding in plain language.
3. State an initial opinion on the macro questions and recommended method; label judgment as judgment.
4. Ask only missing scope questions from `references/guidelines.md`, numbered with numbered options when useful.
5. Stop for explicit scope approval.

### 2. Method

1. Load only the selected method reference.
2. Ask only missing method questions, including the target Drive folder URL.
3. Recommend one setup and explain the decisive trade-off briefly.
4. Stop for explicit method approval.

### 3. Prepare

1. Verify the target folder and required template IDs before copying anything.
2. Create only the branch artifacts defined in the selected reference.
3. Populate their fixed tabs, tables, tags, and headers.
4. Return the working URLs and ask the user to edit and validate them.
5. After approval, re-read the artifact and treat its current content as exact execution input.

### 4. Collect

- Interviews: follow the selected Survey, Live, or Mixed route exactly.
- Data research: enforce the source and claim-evidence gates before analysis.
- Brainstorming: separate divergence, clustering, and evaluation.
- IF collection is incomplete, remain in `COLLECT` and state the missing items.

### 5. Analyze and challenge

1. Build structured findings in the method Sheet and the narrative pre-report in a Doc.
2. Start a fresh reviewer context to attack unsupported claims, weak logic, missing alternatives, and overconfidence. IF unavailable, instruct the user to open a fresh conversation with the supplied review prompt.
3. Apply only confirmed corrections; keep unresolved disagreements visible.
4. Stop for user review of the corrected pre-report.

### 6. Finalize

1. Re-read the user-approved pre-report.
2. Copy the selected branded final-report template.
3. Put core messages first and supporting detail in appendices.
4. Verify title, audience, date, sources, links, and final format.
5. Return the final URL and a `DONE` handoff.

## Completion Check

Do not mark `DONE` unless all are true:

- scope, method, working artifact, and pre-report approvals are explicit;
- every required artifact exists at a stable URL;
- key conclusions trace to collected material or are labelled judgment;
- the fresh challenge was completed and confirmed fixes were applied;
- no invitation email was sent;
- the final report opens and matches the approved type.
