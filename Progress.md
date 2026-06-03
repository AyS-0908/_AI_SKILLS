# Progress.md - AI Skills

Last updated: 2026-06-03

## Current Objective

Clarify the AI skills management workflow and remove confusion with the old Apps Script cockpit.

## Done

- Confirmed active published skills are consumed from `AyS-0908/SKILLS`.
- Confirmed `code-AI_SKILLS` is the local skills workbench.
- Confirmed `code-SKILLS_COCKPIT` is the old Google Drive -> Apps Script -> GitHub cockpit.
- Rewrote `README.md` to describe this folder correctly.
- Added project harness docs.

## In Progress

- Publishing workflow from local workbench to `AyS-0908/SKILLS` still needs a dedicated command/script if desired.

## Blocked

- None.

## Next Action

Decide whether to add a small publish script that copies approved `skill-*` folders into the `AyS-0908/SKILLS` repo structure and updates `sync_manifest.json`.

## Last Verification

- Date: 2026-06-03
- Method: local folder inspection, Git remote/status checks, GitHub manifest check
- Result: pass

## Known Risks

- Local edits in `code-AI_SKILLS` are not automatically published for agents.

## Update Rule

Every agent updates this file before stopping meaningful project work.
