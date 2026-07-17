# Scope and Routing

Use this file for the common scope only. Use the selected method file for method setup. Use the stage, validation, resume, and handoff rules in `SKILL.md`.

## Question Rules

1. Extract every answer already present in the request, attachments, or validated handoff.
2. Summarize the topic and give a short opinion on the likely macro questions and best method.
3. Ask only fields that are missing, ambiguous, or contradictory.
4. Keep the stable question numbers below. For each asked question, show numbered options and mark one `Recommended` when a recommendation is possible.
5. Accept an answer by option number or free text. Restate any inferred answer for confirmation.
6. Do not proceed until the user explicitly validates the scope.

## Scope Questions

1. **Trigger:** Why is this reflection needed now?
   1. Decision to make
   2. Problem to understand
   3. Opportunity to explore
   4. Alignment or preparation
2. **Audience:** Who will use the result?
   1. User only
   2. Project team
   3. Executive or client audience
   4. Wider internal audience
3. **Macro questions:** Which decisions or questions must the reflection answer? Propose a draft list from the input.
4. **Geography:** Which geographic perimeter applies?
   1. One named market
   2. Several named markets
   3. Global
   4. Not relevant
5. **Method:** Which method should be used?
   1. Interviews - collect views or experience from people
   2. Data research - answer with external or internal evidence
   3. Brainstorming - generate and prioritize ideas
6. **Detail level:** How deep should the work go?
   1. Quick directional view
   2. Standard decision-ready reflection (Recommended)
   3. Deep study
7. **Final report type:** Which final artifact is required?
   1. Google Doc (Recommended for narrative)
   2. Google Slides (Recommended for executive presentation)
   3. Google Sheet (Recommended for analysis-led delivery)
8. **Deadline:** When must the final report be ready? Require a date or an explicit no-deadline answer.
9. **Budget:** What spending limit applies to sources, participants, or tools?
   1. No spend
   2. Fixed amount supplied by the user
   3. Approval required before each spend
10. **Drive location:** In which Google Drive folder should working and final artifacts be stored? Require a folder URL before creating artifacts.

## Required and Skippable Fields

| Field | Required | Skip only when |
|---|---:|---|
| Trigger | Yes | The purpose and decision are explicit |
| Audience | Yes | Users of the result are explicit |
| Macro questions | Yes | A bounded list is explicit |
| Geography | Yes | Explicitly supplied or confirmed not relevant |
| Method | Yes | Explicitly supplied and suitable, or user accepts the recommendation |
| Detail level | Yes | Explicitly supplied |
| Final report type | Yes | Explicitly supplied |
| Deadline | Yes | A date or no-deadline answer is explicit |
| Budget | Yes | A limit or no-spend answer is explicit |
| Drive location | Before artifact creation | A validated folder URL is already in the handoff |

## Scope Validation Output

Present one compact scope brief with:

`topic`, `trigger`, `audience`, `macro_questions`, `geography`, `method`, `detail_level`, `report_type`, `deadline`, `budget`, `drive_folder_url`, `assumptions`, `exclusions`.

End with: `Reply VALIDATE SCOPE or correct the numbered field(s).` Treat edits as a new candidate scope, not as validation.

## Routing

- IF method is Interviews -> load `interviews.md`.
- IF method is Data research -> load `data-research.md`.
- IF method is Brainstorming -> load `brainstorming.md`.
- For analysis, challenge, pre-report, or final report -> load `analysis-report.md`.
- Before any Google read or write -> load `google-workspace.md`.

## Collection Completion Checks

Pass only the selected route. Otherwise remain in `COLLECT` and list each missing item.

- **Survey:** questionnaire approval is recorded; Form and linked response Sheet IDs exist; collection is closed or the user accepts the current response count; response count and missingness are reported.
- **Live interviews:** every in-scope participant is completed or explicitly excluded; raw input is preserved; each structured note is user-validated; validated findings are present in the transversal Sheet.
- **Data research:** every material claim has accepted evidence or is labelled a gap/provisional; the reliability gate passed; conflicts and unavailable evidence are recorded.
- **Brainstorming:** approved idea volume is reached or the shortfall is accepted; raw ideas remain traceable; clusters and criteria are validated; every shortlisted cluster is scored or explicitly left to judgment.
