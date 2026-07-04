# Progress.md - AI Skills

Last updated: 2026-06-25

## Current Objective

Publish `skill-audit-it` and remove obsolete Audit-IT WIP source files.

## Done

- Confirmed active published skills are consumed from `AyS-0908/SKILLS`.
- Confirmed `code-AI_SKILLS` is the local skills workbench.
- Confirmed `code-SKILLS_COCKPIT` is the old Google Drive -> Apps Script -> GitHub cockpit.
- Rewrote `README.md` to describe this folder correctly.
- Added project harness docs.
- Created `skill-hostinger/` (SKILL.md + reference/: stack, diagnostics, backup-restore, status-template, weekly-review).
- Reverse-engineered the n8n orchestrator email contract (POST /webhook/orchestrator, subflow_id=message,
  service=email_send, payload.confirm=true required to actually send) and documented it in `reference/weekly-review.md`.
- Created a least-privilege n8n project `vps-review` (capability `message:send` only) in the `projects` data table.
- Verified the orchestrator email path end-to-end via direct webhook (curl) AND via the n8n MCP connector
  (execute_workflow with webhook input) — both return ok:true with a Gmail message_id.
- Created the weekly cloud routine `VPS Weekly Review` (trigger_id trig_01QPTysp4mBbYa9yb4yjjvtN),
  cron `0 10 * * 1` = Mondays 12:00 Europe/Paris. Connectors: Gmail (read report) + n8n (send).
- Discovered the Claude cloud sandbox blocks outbound HTTP (curl to n8n fails), so the routine sends via the
  n8n MCP connector instead of curl. The orchestrator itself is unaffected — only the sandbox lacks egress.

- Pivoted the weekly automation OUT of the Claude cloud routine (sandbox has no internet egress and its n8n
  connector exposes no send/execute tool) and INTO a native n8n workflow. Disabled the cloud routine.
- Built + verified n8n workflow "VPS Weekly Review" (id 0WyF42knSiTROPzv): Gmail Trigger (polls for the
  Brevo report) -> Code (deterministic parser, no LLM) -> Gmail send. Parser test on the real report:
  disk 11%, 18 updates incl. Docker stack, 14 containers healthy -> correct HTML review.
- User ACTIVATED the workflow on 2026-06-18. No historical report email was available for a manual send
  test, so the first live run will be the next real report (expected Mon 2026-06-22).
- Published `skill-audit-it/` as the active Audit-IT skill. It audits startup-sized projects, includes
  Tier 1/2/3 findings, and writes `_Audit-IT/audit_it__NNN_title.md` handoff files for AI coders.
- Removed obsolete Audit-IT draft material from `x_.WIP/_audit-it/` and `x_.WIP/_audit-general.zip`.

## In Progress

- Publishing workflow from local workbench to `AyS-0908/SKILLS` still needs a dedicated command/script if desired.

## Watch items

- Gmail OAuth (`Gmail_Perso`) token durability: if the GCP OAuth consent screen is in "Testing", the token
  expires ~every 7 days and the weekly send breaks. Observe over the next ~10 days; if it breaks, publish the consent screen.
- Do not delete the weekly report email before Monday's run, or the routine sends a "report not received" alert.
- API key for `vps-review` is stored in the routine prompt (least-privilege; revoke via `active=false` on the row).

## Blocked

- None.

## Next Action

Refresh the generated skills manifest after the GitHub push if immediate local discovery is needed.

## Last Verification

- Date: 2026-06-25
- Method: Audit-IT helper scripts parsed with Python; SKILL.md trigger/output checks passed;
  `write_audit_doc.py` created a numbered `_Audit-IT` handoff file in a temp project.
- Result: pass

## Known Risks

- Local edits in `code-AI_SKILLS` are not automatically published for agents.

## Update Rule

Every agent updates this file before stopping meaningful project work.
