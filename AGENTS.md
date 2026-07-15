# AGENTS.md - AI Skills

## Purpose

Local workbench for creating, editing, and reviewing AI agent skills. This folder IS the published set.

## Docs map (per read Order)

1. `SKILLS-DESIGN.md`: the whole-system design — read first.
2. `Progress.md`: current state and next action.

## Current Objective

Source: `Progress.md`

## Layout

- `skill-<slug>\SKILL.md`: one active skill per folder. Flat — that is the whole architecture.
- `.WIP/`: drafts. Never synced (sync-excluded + gitignored).
- `.dist/<slug>.skill`: generated upload packages. Gitignored; rebuilt every sync run.
- Remote: `https://github.com/AyS-0908/_AI_SKILLS`.

## Publishing (the only non-obvious flow)

`_AI_AGENTS\scripts\Sync-SkillsManifest.ps1` is the ONE publish step. Source of truth is this local folder. One run:

- rebuilds `_AI_AGENTS\skills-manifest.json` — ALL skills, with `status` as a field; consumers filter on it (`usage_skills.md` § SELECT);
- mirrors the `status: active` ones to `C:\Users\aymar\.claude\skills` + `C:\Users\aymar\.codex\skills`;
- commits + pushes the whole repo (`git add -A`);
- packages `.dist\<slug>.skill` for the ONE manual leg — upload to claude.ai Settings > Skills (that panel has no API).

Flags `-NoPush` / `-NoPackage` / `-SkipInstall` skip the push / packaging / mirror legs.

A bare `git push` does NOT publish: it leaves the manifest stale. Agents fetch `SKILL.md` from the GitHub remote via `gh api`, falling back to this local copy only when `gh api` fails (offline or rate-limited) and marking that output `[ASSUMED]` — see `_AI_AGENTS\usage_skills.md` § LOAD.

**A scheduled task (`Sync-SkillsManifest`) runs the sync every 3h**, so work publishes itself. Leaving it uncommitted does NOT hold it back — the run's `git add -A` stages untracked and modified files alike, commits them as `skills: sync <timestamp>`, and pushes. To hold something back, put it in `.WIP/` (sync-excluded + gitignored). That is the only withholding mechanism.

## Commands

- Install / Start / Build: none.
- Test: no repo-wide runner. Self-contained: `node skill-appscript/references/tools/gas_mock_run.js`, `python skill-github-sync/scripts/test_git_sync.py`, `pwsh -NoProfile -File skill-folder-cleaning/tests/Run-Tests.ps1`. `skill-ideasup-flow/scripts/check_mockup.py` and `check_spec.py` validate a TARGET project's artifacts and each need a file argument (a bare call prints usage and exits 1).
- Verify: inspect changed `skill-*/SKILL.md` against `_AI_AGENTS\usage_skills.md`.

## Constraints

- Do not use the old Google Drive / Apps Script cockpit unless the user explicitly revives it.

## Gotchas

- Claude.ai rejects `.skill` archives whose ZIP entries use Windows `\` path
  separators. Always build packages through `Sync-SkillsManifest.ps1`, which
  writes portable `/` entry paths; do not package them with `Compress-Archive`.

## Agent Ritual

0. `C:\Users\aymar\AYS_CODING\_AI_AGENTS\AGENTS-canonical.md`: guidelines for any AI agents in any projects.
1. Read this file.
2. Read `Progress.md`.
3. Work on one objective.
4. Verify: show `git status`; confirm local-only vs published.
5. Update `Progress.md` before stopping.
