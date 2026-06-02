# AGENTS.md - IdeaUp Flow Skill Workspace

## Global Rules
Read and apply `C:\Users\aymar\.ai-agents\AGENTS-canonical.md` before any task.
This file adds local project rules only; it does not replace or duplicate the global rules.

## Purpose
Convert the IdeaUp Flow prompt suite into an AI Agent Skill while preserving the original stage intent and boundaries.

## Project Sources
- `ideasup_flow_micro_specification.txt`: pipeline overview, stage contracts, source-of-truth rules, and prompt-suite setup notes.
- `1-stage-pain.md`: Pain discovery stage.
- `2-stage-opportunity.md`: Opportunity discovery stage.
- `3-stage-idea.md`: Idea definition stage.
- `4-stage-user-story.md`: User Story stage.
- `5- stage-mockup.md`: Mockup stage.
- `6- stage-specification.md`: Specification stage.

## Local Constraints
- Treat the stage files as source material until the user explicitly asks to edit or transform them.
- Preserve stage ownership: each stage should own only its declared layer and avoid overlap with upstream or downstream stages.
- Keep reusable workflow logic separate from ChatGPT/GPT Action/Google Sheets packaging details.
- Do not carry over copy-paste navigation instructions into a Skill unless the user explicitly wants chat-to-chat navigation behavior.
- Flag missing referenced stages instead of inventing them. Business Plan and AI-Coder rules are referenced but not present in this folder.
- Treat draft markers such as "to rework" as unstable source material that needs user validation before becoming Skill guidance.

## Skill Work Rules
- Use `C:\Users\aymar\.ai-agents\Skills_usage.md` and the local `skill-creator` guidance when creating or improving a Skill.
- Keep the future `SKILL.md` concise and procedural.
- Put detailed stage instructions, templates, and examples into Skill references when they are too large for the main Skill file.
- Exclude deployment, API, spreadsheet, and GPT wrapper setup unless the requested Skill must operate that external system.

## Verification
For edits in this workspace, show the changed files and verify that the result is scoped to the user's request.
