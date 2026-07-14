# Progress.md - AI Skills

Last updated: 2026-07-15

## Current Objective

System design DECIDED and published in `SKILLS-DESIGN.md` (read that first). `code-audit-loop` finished and published (items 1+2 of its `skill_plan.md`). NEXT: item 3 — live test of the loop on GO_VIRAL D-1b (awaiting user go, costly run).

## Done (recent skills work)

- 2026-07-15: Rebuilt and PUBLISHED `skill-appscript` (commit `d94851e`). An audit confirmed the owner's hypothesis: documentation-heavy, too few executable rules. The v2 `playbook/` folder (CORE + 3 references + two-hop routing) is now DELETED, replaced by a flat set — `SKILL.md` (single routing table) + `data-sheets.md`, `apis-ui.md`, `build-operate.md`, `reviewing.md` (audit+debug+test merged), `build-patterns.md` — with each rule sitting next to its "how". Forward tests showed a BUILD agent shipping code that contradicted the very rule it cited (held a lock across UrlFetch), because the rule existed only as prose; so claim/call/finalize, checkpoint/resume, schema constants and log redaction became copy-paste recipes with embedded `selfCheck_*`. New offline harness `references/tools/gas_mock_run.js` executes every recipe against fake Google services (11/11 checks pass) — recipes are now proven, not just reviewed. Legacy docs (incl. `validation.md`) quarantined in `references/archive/`. Manifest propagated to `.claude\skills` + `.codex\skills`; `.skill` upload to claude.ai remains manual.
- 2026-07-14: Owner approved the Apps Script product path: lightly styled/status-driven bound MVP, a small versioned namespaced library for about 20-user testing, and a Sheets Editor add-on using Google's official add-on CSS as the target. Encoded thin local trigger/menu entrypoints, separate add-on testing, no checkbox-as-button pattern, no third-party UI framework by default, and CardService only when active-document context is unnecessary. Published 2026-07-15 in `d94851e`.
- 2026-07-14: Externally audited the Apps Script playbook against current official Google guidance (10/10 platform claims confirmed, none overstated). Corrected over-broad formula/code ownership, same-workbook tenant security, cross-system atomicity, PropertiesService secret handling, logging/redaction, confirmation payloads, reconciliation, trigger identity, deployment, and scale-exit rules. Those corrections carry into the rebuilt rule tables; the source evidence log is archived at `references/archive/validation.md`.
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

1. Await user go for the `code-audit-loop` live test on GO_VIRAL D-1b (`skill-code-audit-loop/skill_plan.md` item 3).
2. Open thread on `skill-appscript`: decide what else to make deterministic. The rebuild made the recipes executable, but the rule tables (A/P/S/D/T/C/U/E/V) still carry only an "applies when" gate + DO/DO NOT with no attached executable check; SPEC mode has no template or worked example; and the fallback output schemas permit superficial compliance (only AUDIT forces proof via `evidence_gate`).

## Last Verification

- Date: 2026-07-15
- Method: `skill-appscript` rebuild — four fresh-agent forward tests (SPEC/BUILD/AUDIT/DEBUG), external platform check of 10 claims against official Google docs, `node references/tools/gas_mock_run.js` (executes every recipe against fake Google services), rule-ID completeness grep, dangling-reference scan, independent completeness critic, and Git status/publication check.
- Result: pass. Harness 11/11; all 42 rule IDs present exactly once; no dangling refs. The critic caught a P-03 duplication (data-sheets + build-operate) and a stale `CORE.md` pointer — both fixed before publish.

## Known Risks

- Local edits are not usable by agents until pushed to `AyS-0908/_AI_SKILLS` and the manifest is rebuilt.

## Relocated (off-topic — owning doc elsewhere)

VPS / n8n / Gmail weekly-review automation history and watch-items (orchestrator email contract, `vps-review` least-privilege project, cloud routine → native n8n workflow `VPS Weekly Review`, Gmail OAuth token durability, "don't delete the report email before Monday", API-key storage) are DevOps operational facts, not skills-workbench state → see `_DEVOPS` and `skill-hostinger/reference/weekly-review.md`.

## Update Rule

Every agent updates this file before stopping meaningful project work.
