# Progress.md - AI Skills

Last updated: 2026-07-06

## Current Objective

Publish `skill-ideasup-flow` (startup-definition pipeline) from the `.WIP/skill-ideaup-flow` workspace.

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
- Published `skill-ideasup-flow/` (2026-07-06): RIGID startup-definition pipeline (Pain -> Opportunity ->
  Idea -> User Story -> Mockup -> Specification; stages 4 Business Plan and 8 AI-Coder rules remain
  MISSING SOURCE). Added file-based artifact handoff (`<project>/ideasup/N-stage.md`), resume/flow mode,
  and deterministic `scripts/status.py` (tested: empty dir + partial pipeline both correct).
- Audited `.WIP/skill-ideaup-flow`: distilled references verified faithful to original prompts;
  duplicates confirmed and the whole WIP folder deleted with user approval (2026-07-06). The source spec
  was preserved as `skill-ideasup-flow/references/pipeline-source-spec.md` (holds stage 4/8 contract rows).
  Only an empty husk + `.claude/` remains (held busy as the live session cwd) — delete manually later.
- Added deterministic checks to `skill-ideasup-flow/scripts/`: `check_mockup.py` (single style/script,
  no external deps, Brief fields, DEMO ONLY balance, no persistence APIs) and `check_spec.py` (required
  spec sections, Do Not Build count). Both tested on pass/fail fixtures; wired into SKILL.md.
- Fixed `skill-github-sync` commit-push: pre-staged paths outside `--files` now fail fast
  (`staged_outside_files`) instead of being silently swept into the commit; test added.
- Audited + reworked `.WIP/skill-benchmark` (2026-07-06): pipeline is now deterministic — model
  collects web data into `benchmark.json`, `scripts/benchmark.py validate` machine-checks
  completeness (every entity × criterion cell), source URLs + accessed dates, units, gap rate;
  `render` produces the matrix + auto-computed Data Quality section; model writes only
  findings/recommendations/limits. E2E tested new vs old skill on a Todoist/TickTick pricing
  benchmark: new 6/6 assertions, old 3/6 (no data artifact, no accessed dates, no cell-level
  source refs). Old version snapshotted in `.WIP/skill-benchmark-workspace/skill-snapshot/`;
  eval results + review.html in `.WIP/skill-benchmark-workspace/iteration-1/`.

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

- Date: 2026-07-06
- Method: `skill-ideasup-flow/scripts/status.py` tested on empty and partial pipelines (correct NEXT
  detection, MISSING SOURCE skip). Subagent smoke test of the published skill: correct reference selected
  (stage-3-idea.md only), stopped at first validation point, artifact I/O unambiguous. One found defect
  (ownership table out of sync with Idea reference) fixed; language-default and persist-timing clarified.
- Result: pass

## Known Risks

- Local edits in `code-AI_SKILLS` are not automatically published for agents.

## Update Rule

Every agent updates this file before stopping meaningful project work.
