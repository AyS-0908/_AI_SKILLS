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

## In Progress

- User to do the real end-to-end test (restore one report email so the trigger fires) and ACTIVATE the
  workflow in n8n (toggle active).
- Publishing workflow from local workbench to `AyS-0908/SKILLS` still needs a dedicated command/script if desired.

## Watch items

- Gmail OAuth (`Gmail_Perso`) token durability: if the GCP OAuth consent screen is in "Testing", the token
  expires ~every 7 days and the weekly send breaks. Observe over the next ~10 days; if it breaks, publish the consent screen.
- Do not delete the weekly report email before Monday's run, or the routine sends a "report not received" alert.
- API key for `vps-review` is stored in the routine prompt (least-privilege; revoke via `active=false` on the row).

## Blocked

- None.

## Next Action

User restores one VPS report email + activates the "VPS Weekly Review" n8n workflow; optionally run one
real manual send to confirm delivery. Then the weekly automation is fully live.

## Last Verification

- Date: 2026-06-18
- Method: orchestrator email path tested via curl (exec 120) and n8n MCP execute_workflow (exec 122), both ok:true
  with Gmail message_id; weekly cloud routine created and updated to the MCP send method
- Result: pass (cloud-session MCP send pending final confirmation)

## Known Risks

- Local edits in `code-AI_SKILLS` are not automatically published for agents.

## Update Rule

Every agent updates this file before stopping meaningful project work.
