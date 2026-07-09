# AGENTS.md - AI Skills

## Purpose

Local workbench for creating, editing, and reviewing AI agent skills before publishing them for agents to consume.

## Docs map (per read Order)

1. `SKILLS-DESIGN.md`: the whole-system design — read first.
2. `Progress.md`: for current state and next action.
3. `Architecture.md`: when system understanding is needed.
4. `README.md`: for the short human-facing summary.

## Current Objective

Source: `Progress.md`

## Commands

- Install: Not defined
- Start: Not defined
- Build: Not defined
- Test: Not defined
- Verify: inspect changed `skill-*/SKILL.md` files and compare against `C:\Users\aymar\AYS_CODING\_AI_AGENTS\usage_skills.md`


## Constraints

- One active skill per folder: `skill-<slug>\SKILL.md`.
- This is the local authoring/workbench folder.
- This folder IS the published set: agents consume the skills by pushing it to `AyS-0908/_AI_SKILLS` and reading the generated `skills-manifest.json`.
- Do not use the old Google Drive / Apps Script cockpit unless the user explicitly revives it.

## Verification

Before stopping, show `git status` for this folder and confirm whether changes are local-only or published.

## Agent Ritual

1. Read this file.
2. Read `Progress.md`.
3. Work on one objective.
4. Verify.
5. Update `Progress.md` before stopping.
