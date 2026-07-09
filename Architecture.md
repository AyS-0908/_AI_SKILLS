# Architecture.md - AI Skills

## Overview

Local skills workbench. Editable `skill-*/SKILL.md` folders live at the repo root and ARE the published set: pushing this repo to its GitHub remote publishes the skills for agents.

## Components

- `skill-*/SKILL.md`: active skill entrypoints (one skill per folder).
- `SKILLS-DESIGN.md`: the system design (read first).
- `.WIP/`: work in progress, not ready for agent consumption.

## Important Paths

- `C:\Users\aymar\AYS_CODING\_AI_SKILLS`: this local workbench (Git remote `https://github.com/AyS-0908/_AI_SKILLS`).
- `C:\Users\aymar\AYS_CODING\_AI_AGENTS\usage_skills.md`: global rule for how agents fetch and use skills.
- `C:\Users\aymar\AYS_CODING\_AI_AGENTS\skills-manifest.json`: auto-generated skill index agents read to discover skills.

## Data Flow

1. Create or edit a skill locally in `skill-<slug>\SKILL.md`.
2. Review and validate locally.
3. Push to `AyS-0908/_AI_SKILLS`; `Sync-SkillsManifest.ps1` rebuilds `skills-manifest.json`.
4. Agents read `skills-manifest.json`, then fetch the selected `SKILL.md`.

## External Dependencies

- Git / GitHub CLI `gh`: version control and skill fetch.

## Constraints

- A local edit is not usable by agents until pushed and the manifest is rebuilt.
- Do not revive the old Google Drive / Apps Script cockpit unless explicitly asked.
