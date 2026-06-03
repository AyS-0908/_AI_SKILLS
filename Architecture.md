# Architecture.md - AI Skills

## Overview

This folder is a local skills workbench. It stores editable `skill-*` folders and supporting draft/reference material. Published skills for agents live in the GitHub repo `AyS-0908/SKILLS`.

## Components

- `skill-*/SKILL.md`: active skill entrypoints.
- `_SKILLS TO REWORK`: older or unfinished material to review before promotion.
- `x_.WIP`: work in progress that is not ready for agent consumption.
- `x_*`: supporting reference, knowledge, icons, or archive material.

## Important Paths

- `C:\Users\aymar\AYS_CODING\code-AI_SKILLS`: local authoring/workbench folder.
- `C:\Users\aymar\.ai-agents\Skills_usage.md`: global rule for how agents fetch and use published skills.
- `https://github.com/AyS-0908/SKILLS`: active published skills repo consumed by agents.
- `https://github.com/AyS-0908/AI_SKILLS`: current Git remote for this local workbench.

## Data Flow

1. Create or edit a skill locally in `skill-<slug>\SKILL.md`.
2. Review and validate the skill locally.
3. Publish the approved skill into `AyS-0908/SKILLS`.
4. Agents fetch `sync_manifest.json` from `AyS-0908/SKILLS` and then fetch the selected `SKILL.md`.

## External Dependencies

- GitHub CLI `gh`: used by global skill fetch instructions.
- Git: used for local version control.

## Constraints

- Do not treat `code-SKILLS_COCKPIT` as the live workflow.
- Do not assume a local edit is usable by agents until it is published to `AyS-0908/SKILLS`.

## Known Risks

- The local repo remote is `AyS-0908/AI_SKILLS`, while agents consume `AyS-0908/SKILLS`; publishing still needs an explicit step.
