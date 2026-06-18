# Progress.md - AI Skills

Last updated: 2026-06-18

## Current Objective

Author and harden the `skill-hostinger` VPS-maintenance skill, including an automated weekly VPS review.

## Done

- Confirmed active published skills are consumed from `AyS-0908/SKILLS`.
- Confirmed `code-AI_SKILLS` is the local skills workbench.
- Confirmed `code-SKILLS_COCKPIT` is the old Google Drive -> Apps Script -> GitHub cockpit.
- Rewrote `README.md` to describe this folder correctly.
- Added project harness docs.
- Created `skill-hostinger/` (SKILL.md + reference/: stack, diagnostics, backup-restore, status-template, weekly-review).
- Reverse-engineered the n8n orchestrator email contract (POST /webhook/orchestrator, subflow_id=message,
  service=email_send, payload.confirm=true required to actually send) and documented it in `reference/weekly-review.md`.

## In Progress

- Weekly VPS review automation: pending two secrets from the user (PROJECT_API_KEY + PROJECT_NAME from the
  n8n `projects` data table) to run a manual test send and then create the weekly schedule.
- Publishing workflow from local workbench to `AyS-0908/SKILLS` still needs a dedicated command/script if desired.

## Blocked

- None.

## Next Action

Get PROJECT_API_KEY + PROJECT_NAME, run a one-off `confirm:true` test email through the orchestrator, then
create the weekly schedule for the VPS review.

## Last Verification

- Date: 2026-06-18
- Method: local folder inspection; n8n orchestrator + message subflow read via MCP; Git remote/status checks
- Result: pass

## Known Risks

- Local edits in `code-AI_SKILLS` are not automatically published for agents.

## Update Rule

Every agent updates this file before stopping meaningful project work.
