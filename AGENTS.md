# AGENTS.md - AI Skills

## Purpose

Local workbench for creating, editing, and reviewing AI agent skills before publishing them for agents to consume.

## Read Order

1. `Progress.md` for current state and next action.
2. `Architecture.md` only when system understanding is needed.
3. `README.md` for the short human-facing summary.

## Current Objective

Source: `Progress.md`

## Commands

- Install: Not defined
- Start: Not defined
- Build: Not defined
- Test: Not defined
- Verify: inspect changed `skill-*/SKILL.md` files and compare against `C:\Users\aymar\.ai-agents\Skills_usage.md`

## Docs Map

- Current state: `Progress.md`
- System structure: `Architecture.md`
- Human summary: `README.md`

## Constraints

- One active skill per folder: `skill-<slug>\SKILL.md`.
- This is the local authoring/workbench folder.
- Agents consume the published repo `AyS-0908/SKILLS`, not this folder directly.
- Do not use the old Google Drive / Apps Script cockpit unless the user explicitly revives it.

## Verification

Before stopping, show `git status` for this folder and confirm whether changes are local-only or published.

## Agent Ritual

1. Read this file.
2. Read `Progress.md`.
3. Work on one objective.
4. Verify.
5. Update `Progress.md` before stopping.
