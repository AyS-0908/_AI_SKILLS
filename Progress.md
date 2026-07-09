# Progress.md - AI Skills

Last updated: 2026-07-09

## Current Objective

System design DECIDED and published in `SKILLS-DESIGN.md` (read that first). `code-audit-loop` finished and published (items 1+2 of its `skill_plan.md`). NEXT: item 3 — live test of the loop on GO_VIRAL D-1b (awaiting user go, costly run).

## Done (recent skills work)

- 2026-07-09: `doc-hygiene` passed its first live test (on this project's docs), then all 6 test-feedback improvements encoded into its SKILL.md (incl. whole-file removal candidates: report-only → `_to_delete_<DATE>\` on user OK). Its skill_plan.md deleted (done; recoverable in git). Design plan step 5 gained the fresh-helper-canonical clause.
- 2026-07-09: `SKILLS-DESIGN.md` rewritten as the system backbone (5 skill types, birth rules, DEFINE→MAKE→ROAST→FORMALIZE, gaps+plan). Delegate-then-audit: writer → fresh auditor → fix. Commit `18e7261`.
- 2026-07-09: `code-audit-loop` Models & effort rules encoded (rank-based; auditor ≥ coder). Published: commit `8c28d09`, manifest rebuilt, mirrored to `.claude\skills` + `.codex\skills`.
- 2026-07-09: Fixed `_AI_AGENTS/scripts/Sync-SkillsManifest.ps1` em-dash crash on Windows PowerShell 5 (scheduled sync was silently broken).
- Created `skill-hostinger/` (SKILL.md + reference/: stack, diagnostics, backup-restore, status-template, weekly-review).
- Published `skill-audit-it/` (Tier 1/2/3 findings; writes `_Audit-IT/audit_it__NNN_title.md` handoffs).
- Published `skill-ideasup-flow/` (2026-07-06): pipeline Pain→…→Specification; Stage 4 Business Plan and Stage 8 AI-Coder rules remain MISSING SOURCE. File-based handoff + `scripts/status.py`; added `check_mockup.py` + `check_spec.py` (tested).
- Fixed `skill-github-sync` commit-push: pre-staged paths outside `--files` now fail fast (`staged_outside_files`); test added.
- Published `skill-benchmark/` (2026-07-08): deterministic pipeline — model collects `benchmark.json`, `scripts/benchmark.py validate` machine-checks every entity × criterion cell + source URLs/dates, `render` builds the matrix. Pushed to `AyS-0908/_AI_SKILLS`; manifest propagated.

## In Progress

- None open on the skills workbench beyond the Current Objective.

## Next Action

Await user go for the `code-audit-loop` live test on GO_VIRAL D-1b (`skill-code-audit-loop/skill_plan.md` item 3).

## Last Verification

- Date: 2026-07-06
- Method: `skill-ideasup-flow/scripts/status.py` on empty + partial pipelines (correct NEXT / MISSING-SOURCE detection). Subagent smoke test of the published skill: correct reference selected, stopped at first validation point. One defect (ownership table drift) fixed.
- Result: pass

## Known Risks

- Local edits are not usable by agents until pushed to `AyS-0908/_AI_SKILLS` and the manifest is rebuilt.

## Relocated (off-topic — owning doc elsewhere)

VPS / n8n / Gmail weekly-review automation history and watch-items (orchestrator email contract, `vps-review` least-privilege project, cloud routine → native n8n workflow `VPS Weekly Review`, Gmail OAuth token durability, "don't delete the report email before Monday", API-key storage) are DevOps operational facts, not skills-workbench state → see `_DEVOPS` and `skill-hostinger/reference/weekly-review.md`.

## Update Rule

Every agent updates this file before stopping meaningful project work.
