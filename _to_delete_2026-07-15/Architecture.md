# Architecture.md - AI Skills

## Overview

Local skills workbench. Editable `skill-*/SKILL.md` folders live at the repo root and ARE the published set: a `Sync-SkillsManifest.ps1` run publishes them (it pushes the repo AND rebuilds the manifest that agents discover skills through — see Data Flow).

## Components

- `skill-*/SKILL.md`: active skill entrypoints (one skill per folder).
- `SKILLS-DESIGN.md`: the system design.
- `.WIP/`: work in progress, not ready for agent consumption. Never synced anywhere (excluded by the sync script + gitignored).
- `.dist/<slug>.skill`: generated upload packages for the manual claude.ai leg. Gitignored; rebuilt every sync run.

## Important Paths

- `C:\Users\aymar\AYS_CODING\_AI_SKILLS`: this local workbench (Git remote `https://github.com/AyS-0908/_AI_SKILLS`).
- `C:\Users\aymar\AYS_CODING\_AI_AGENTS\usage_skills.md`: global rule for how agents fetch and use skills.
- `C:\Users\aymar\AYS_CODING\_AI_AGENTS\skills-manifest.json`: auto-generated skill index agents read to discover skills.

## Data Flow

1. Create or edit a skill locally in `skill-<slug>\SKILL.md`.
2. Review and validate locally.
3. Run `Sync-SkillsManifest.ps1` — the ONE publish step. Source of truth is this local folder; it discovers `skill-*` dirs and fans them out to four automatic targets: rebuilds `skills-manifest.json` (ALL skills, with `status` as a field — consumers filter on it, see `usage_skills.md` § SELECT); mirrors the `status: active` ones to `C:\Users\aymar\.claude\skills` and `C:\Users\aymar\.codex\skills` (user-profile dirs, not the repo-local `.claude\`); commits + pushes the whole repo (`git add -A`). Flags: `-NoPush`, `-NoPackage`, `-SkipInstall` skip the push, packaging, and mirror legs respectively. NOTE: a Windows scheduled task (`Sync-SkillsManifest`) runs this every 3h as a safety net, so an un-synced local commit publishes itself within ~3h without you doing anything.
4. The same run packages `.dist\<slug>.skill` — the fifth target. Upload it to claude.ai Settings > Skills: the one MANUAL leg (that panel has no public API/CLI). Once per new skill.
5. Agents read `skills-manifest.json`, then fetch the selected `SKILL.md` from the GitHub remote (`gh api`), falling back to this local copy when `gh api` fails (offline or rate-limited) and marking that output `[ASSUMED]` — see `_AI_AGENTS\usage_skills.md` § LOAD.

## External Dependencies

- Git / GitHub CLI `gh`: version control and skill fetch.

## Constraints

- A local edit is draft-only until a `Sync-SkillsManifest.ps1` run. The run's GitHub push is what makes a skill fetchable — agents load `SKILL.md` from the remote (`_AI_AGENTS\usage_skills.md` § LOAD); the `.claude`/`.codex` mirrors serve locally-installed agents. The claude.ai panel additionally needs the manual `.dist\<slug>.skill` upload.
- "Draft-only" has a ~3h shelf life: the scheduled `Sync-SkillsManifest` task publishes committed work automatically. To hold something back, leave it uncommitted — not merely unpushed.
- Google Drive / Apps Script cockpit: see `AGENTS.md` § Constraints.
