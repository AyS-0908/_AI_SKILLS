# Google Workspace Operations

Use this file before any Google Drive, Docs, Sheets, Slides, Forms, or Gmail action. Use available platform capabilities without assuming an exact connector or tool name. Use the stage, validation, resume, and handoff rules in `SKILL.md`.

## Capability Check

1. Confirm the requested Google action is available in the current chatbot session.
2. Confirm the user is authorized and the target folder or artifact is accessible.
3. Confirm the required validation gate is recorded.
4. IF an action is unavailable -> do not simulate success; explain the gap and give the smallest fallback: another available capability, the minimal Apps Script helper, or a short manual step.

Use current Google capabilities first. Apps Script is also allowed for the one-time creation of the neutral Nestor template set.

## One-time Template Setup

Run `scripts/TemplateGenerator.js` once from a standalone Apps Script project. It creates or safely reuses exactly these six neutral templates in one Drive folder:

| Template | Type | Purpose |
|---|---|---|
| `NESTOR - Interview Working` | Doc | Approved questions, Survey settings, audience, and invitation text |
| `NESTOR - Interview Notes` | Doc | One copy per live-interview participant |
| `NESTOR - Interview Analysis` | Sheet | Validated interview findings and analysis |
| `NESTOR - Data Research` | Sheet | Research brief, sources, evidence, and analysis |
| `NESTOR - Brainstorming` | Sheet | Brief, ideas, clusters, evaluation, and analysis |
| `NESTOR - Pre-report` | Doc | Method-neutral narrative before final-report approval |

Setup:

1. Choose the parent Drive folder where the script may create its `NESTOR - Templates` subfolder.
2. Create a standalone project at `script.google.com`, paste `TemplateGenerator.js`, and set `NESTOR_TEMPLATE_PARENT_FOLDER` to that parent folder's URL or ID.
3. In Apps Script, open **Services**, select **Google Docs API**, and add it.
4. Run `createNestorTemplates`, authorize it, and keep the six logged URLs.
5. Open `NESTOR - Interview Working`, choose **Extensions > Apps Script**, paste `scripts/FormBuilder.js`, save, and reload the Doc. This is the only manual binding step.

Do not add a registry Sheet or automate the bound-script setup. Stable folder, file names, and Drive IDs are sufficient. The generator intentionally does not create the final branded report template: the user supplies the company's approved Doc, Sheet, or Slides template.

## Safe Write Protocol

Before a create or copy:

- validate the target Drive folder URL;
- choose a stable artifact name containing the reflection title and artifact type;
- check the handoff state for an existing artifact ID;
- if an ID exists, open and reuse it;
- if creation status is uncertain, search the target folder by stable name and template marker; reuse only one exact match, otherwise stop for reconciliation.

After a write:

- inspect the returned content, not only the success status;
- re-read the created or changed artifact;
- verify required tabs, tags, tables, URLs, and IDs;
- record the artifact ID and URL in the handoff state.

Never create a second artifact to bypass an ambiguous result. Stop for reconciliation.

## External-call Error Pattern

For every external call:

1. **Log:** record `timestamp`, `stage`, `action`, `target`, `result`, `artifact_id`, and `error_summary` in the run handoff.
2. **Notify:** tell the user plainly what failed and whether any artifact may have been created or changed. Never expose tokens or private raw error data.
3. **Fallback:** take only a safe fallback:
   - read failure -> verify URL and permission, then ask for access or an export;
   - edit failure -> preserve the approved content in chat and provide the exact target location for manual paste;
   - create timeout or ambiguous result -> search and reconcile before retrying;
   - unavailable capability -> use an approved minimal Apps Script action or a manual step;
   - authorization or quota failure -> stop and ask the user to restore access or wait.

Treat an error embedded in a nominally successful response as a failure.

## Template Contract

- Duplicate the user-approved template; never edit the source template.
- For Survey, use the generated Interview Working Doc after binding `scripts/FormBuilder.js`. A copied container includes a copy of its bound script; the new owner authorizes it on first use.
- Verify required tabs and literal `{{TAG_NAME}}` markers before population.
- Replace each text tag once. A table tag is an anchor immediately above its pre-created table: verify one anchor, populate the table without changing its headers, then delete the anchor. Stop if a required tag is missing or duplicated in a fresh copy.
- Preserve template styling and unrelated content.
- Re-read after population and fail validation if a required text tag or table anchor remains.
- Use method table schemas exactly; do not silently rename columns or add tabs.
- Keep user-specific folder and template IDs in the run handoff or configuration, never in Skill instructions.

## Action Rules

- **Docs/Sheets/Slides:** make only validated, range- or placeholder-specific edits.
- **Forms:** create only from the validated Survey question table; link one response Sheet; persist both IDs before reporting success.
- **Gmail:** create one draft per validated recipient from validated text; include the Form URL; never send.
- **Reruns:** reuse stored IDs. If stored state and Drive contents disagree, stop and ask the user which artifact is authoritative.
