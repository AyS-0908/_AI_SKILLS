# Progress.md - AI Skills

Last updated: 2026-07-15

## Current Objective

System design DECIDED and published in `SKILLS-DESIGN.md` (read that first). `code-audit-loop` finished and published (items 1+2 of its `skill_plan.md`). NEXT: item 3 — live test of the loop on GO_VIRAL D-1b (awaiting user go, costly run).

## Done (recent skills work)

Condensed: one line per change, decisions only. The narrative is in `git log`; each skill's own rules live in its `SKILL.md`.

- 2026-07-17: Created, validated, and published `skill-company-culture` as a DOER for culture diagnosis, principles, behaviours, rituals, and rollout in 50-250-person SMBs. It uses sourced Gallup, MIT Schein, Atlassian, CIPD, and official employer guidance, with a Dapple-aware project context. Scoped GitHub sync kept unrelated `skill-nestor-reflection` planning work untouched; `Sync-SkillsManifest.ps1 -NoPush` rebuilt the manifest, global Claude/Codex mirrors, and `.dist/company-culture.skill`.
- 2026-07-15: Merged prompt generation into one active `prompt-engineer` skill. Its short `SKILL.md` holds only the shared workflow and deterministic routing; it loads either `references/fable-5.md`, `references/sol-5-6.md`, or neither. The obsolete standalone `skill-prompt-fable-5` was removed. Addon compliance was completed as `GUIDED`: explicit IF/THEN rules, reference/documentation failure handling, manual negative-trigger checks, and navigation for the long Fable reference. Repository validation passed. The project sync ran with `-NoPush -SkipInstall`: the manifest now names only `prompt-engineer`, `.dist/prompt-engineer.skill` was built, and stale `.dist/prompt-fable-5.skill` was pruned. No generated prompt has yet been executed by Fable 5.
- 2026-07-15: Fixed `.skill` packaging after Claude.ai rejected `prompt-engineer.skill`: Windows `Compress-Archive` stored nested paths with `\`. `Sync-SkillsManifest.ps1` now writes `/` paths through the .NET ZIP API, excludes dev-metadata directories, validates every archived path, and rebuilt all 13 packages with `-NoPush -SkipInstall`.
- 2026-07-15: `doc-hygiene` pass on the root docs. Merged `Architecture.md` into `AGENTS.md` and retired `README.md` (both in `_to_delete_2026-07-15/`) — at 13 flat skill folders neither earned a file. Fixed 7 doc-vs-code falsehoods; killed the hardcoded skill count (had drifted 12→13). Decision recorded: three fresh-auditor rounds each returned FAIL (7, 9, 8 defects) on the pass's own diff — twice for cardinal errors (a true fact deleted, the publish gate inverted). The maker cannot grade its own diff; a standalone `doc-hygiene` run needs the fresh-auditor step.
- 2026-07-15: Created and PUBLISHED `skill-prompt-fable-5/` (v1 `d9eb4cc`, v2 `9761ff1`). A prompt *generator*, not a Fable 5 manual. Core constraint: Fable 5 degrades under over-instruction, so the skill picks ≤4 directives from a trigger table rather than pasting all 13. Verification finding with no other home: the minimum cacheable prefix is **per-model** — Fable 5 is **2048** tokens (Opus 4.8/4.7/4.6/4.5 + Haiku 4.5 = 4096; Sonnet 4.5 and older = 1024), refuting the bundled `claude-api` skill's `<unverified>` 512 claim. v1 shipped defective: the trigger table described directives instead of selecting them; v2 made every IF a yes/no question about the task. **Rejected twice, on the record:** embedding the table in the generated prompt for Fable 5 to self-select — it pastes every directive into context (over-instruction is what is IN the prompt, not what the model deems relevant) and makes the prompt unauditable.
- 2026-07-15: Rebuilt and PUBLISHED `skill-appscript` (`d94851e`). Audit confirmed: documentation-heavy, too few executable rules. The `playbook/` folder is gone, replaced by a flat set with each rule next to its "how". Driver: forward tests showed a BUILD agent shipping code that contradicted the rule it cited (held a lock across UrlFetch) because the rule existed only as prose — so the recipes became copy-paste with embedded `selfCheck_*`, proven by an offline harness (`references/tools/gas_mock_run.js`, 15 checks / 11 code blocks at `d94851e`). Verified at publish: all 42 rule IDs present exactly once, no dangling refs.
- 2026-07-14: Owner approved the Apps Script product path: bound MVP → small versioned namespaced library (~20-user testing) → Sheets Editor add-on using Google's official add-on CSS. No checkbox-as-button, no third-party UI framework by default, CardService only when active-document context is unnecessary.
- 2026-07-14: Externally audited the Apps Script playbook against official Google guidance (10/10 platform claims confirmed). Evidence log was archived at `references/archive/validation.md` — see Next Action 3.
- 2026-07-09: `doc-hygiene` passed its first live test (on AI4CEO, per its `skill_plan.md` findings; the same-day pass on this repo's docs is `1ff06e2`). 6 test-feedback improvements encoded into its `SKILL.md`. Its `skill_plan.md` remains: items 1+2 done, item 3 (ownership map hardcoded to `code-GO_VIRAL` filenames) open.
- 2026-07-09: `SKILLS-DESIGN.md` rewritten as the system backbone (`18e7261`). Delegate-then-audit: writer → fresh auditor → fix.
- 2026-07-09: `code-audit-loop` Models & effort rules encoded, rank-based, auditor ≥ coder (`8c28d09`).
- 2026-07-09: Fixed `Sync-SkillsManifest.ps1` em-dash crash on Windows PowerShell 5 (scheduled sync was silently broken).
- Published `skill-code-audit/` (Tier 1/2/3 findings). The `_Audit-IT/` report-file convention was dropped in `cc28e16` (07-05), then the skill was renamed from `skill-audit-it` in `ba6a6e6` (07-13) — see `skill-code-audit/SKILL.md` for the current output contract.
- Published `skill-ideasup-flow/` (07-06): Pain→…→Specification. Stage 4 Business Plan and Stage 8 AI-Coder rules remain MISSING SOURCE.
- Published `skill-benchmark/` (07-08), `skill-hostinger/`. Fixed `skill-github-sync` commit-push: pre-staged paths outside `--files` now fail fast.

## In Progress

- None open beyond the Current Objective.

## Next Action

1. **The Fable branch of `prompt-engineer` has never been proven end-to-end.** Generator-side tests pass, but no prompt it wrote has been executed by Fable 5. A prompt to audit `skill-code-audit` is ready to paste at `high` effort. Until one runs, the branch's central bet — that one to four picked directives beat a hand-written prompt — is reasoned, not observed.
2. Await user go for the `code-audit-loop` live test — see Current Objective above.
3. **UNCOMMITTED `skill-appscript` work, not from the doc pass:** 6 modified (`SKILL.md`; `references/`: `apis-ui.md`, `build-operate.md`, `build-patterns.md`, `data-sheets.md`, `tools/gas_mock_run.js`), 3 deleted (all of `references/archive/`), and an untracked `references/starter/` tree (10 files). Decide: intended work-in-progress, or an accident? Then commit or restore. Until then the `references/archive/` pointers above are broken, and the harness reports 17 checks / 13 code blocks in the working tree vs 15/11 at `d94851e`. NOTE: the 3h sync task auto-commits (`git add -A`) — this will publish itself.
4. Optional: `SKILLS-DESIGN.md` §7/§8 carry live state that duplicates this file — it is why both drifted, and "item 3 open" now lives in 4 places. Both are accurate today; pointing them here instead is a structural call, not a fix.
5. Open thread on `skill-appscript`: decide what else to make deterministic. Rule tables (A/P/S/D/T/C/U/E/V) carry an "applies when" gate + DO/DO NOT with no executable check; SPEC mode has no template; fallback output schemas permit superficial compliance (only AUDIT forces proof via `evidence_gate`).

## Last Verification

- Date: 2026-07-15
- Method: `doc-hygiene` pass — code+git anchor, 90-agent audit (81 raw → 52 confirmed, 29 refuted), then three fresh-context auditor rounds on the applied diff.
- Result: all three rounds FAIL (7, 9, 8 defects), each fixed. Self-written pointers resolve.

## Known Risks

- The Fable branch of `prompt-engineer` is unproven end-to-end (Next Action 1).
- Two design gaps open: Spec→Plan (GAP #1) and the over-engineering check (GAP #2) — see `SKILLS-DESIGN.md` §7.
- Publishing is a standing constraint, not a risk — see `AGENTS.md` § Publishing.

## Relocated (off-topic — owning doc elsewhere)

VPS / n8n / Gmail weekly-review automation facts are DevOps, not skills-workbench state → see `_DEVOPS` and `skill-hostinger/reference/weekly-review.md`.

## Update Rule

Every agent updates this file before stopping meaningful project work.
