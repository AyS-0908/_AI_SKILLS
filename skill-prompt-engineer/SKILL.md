---
name: prompt-engineer
description: >
  Write, review, or improve concise reusable prompts for AI models, including
  model-specific prompts for Claude Fable 5 / Mythos 5 and OpenAI GPT-5.6 Sol.
  Trigger for: "write/create/build a prompt", "improve/review/audit/optimize my
  prompt", "rewrite this system prompt", "prompt engineering", "meta-prompt",
  "prompt for Fable 5", "tune this prompt for Fable", "prompt for Sol 5.6", or
  any request where the deliverable is prompt text. Do NOT trigger for:
  performing the task instead of writing its prompt; ordinary content generation
  such as "write a sales email"; API/SDK model configuration; or conceptual
  explanations that do not create, review, or improve a prompt.
status: active
---

# Prompt Engineer

## Gotchas

- Never request a scratchpad, hidden chain of thought, or private reasoning.
  IF concise rationale, evidence, or checks improve the result -> ask for them.
- Preserve every valid user constraint. Flag conflicts instead of silently
  rewriting them.
- Keep prompts readable, but foster AI understanding. Remove reminders and
  instructions that do not change likely model behavior. Keep prompts concise. 
- IF a selected model reference cannot be read, is empty, or appears corrupted
  -> record the failure, notify the user, and use only the shared rules below.
- IF official model documentation cannot be checked or returns an error ->
  record the failure, tell the user that model-specific advice is unverified,
  and use the shared rules; never invent guidance.

## Route

Choose exactly one route before writing:

- IF the target is Claude Fable 5 or Mythos 5 -> read also
  `references/fable-5.md` completely and follow it. Its output contract and
  model-specific rules override shared defaults.
- ELSE IF the target is OpenAI GPT-5.6 Sol -> read also
  `references/sol-5-6.md` completely and follow it.
- ELSE -> use only this file. IF the user names another current model, verify
  any model-specific advice in that provider's official documentation. IF
  verification is unavailable -> use the shared rules and say so briefly.

- Do not read an unselected model reference.

## Shared workflow

1. IF an existing prompt is supplied -> review it. ELSE -> generate one.
2. Capture the goal, relevant context and input, hard requirements, observable
   done criteria, and expected output.
3. IF critical information is missing -> ask one grouped question. ELSE -> make
   the smallest reasonable assumption and proceed.
4. Choose the smallest readable structure that makes the task unambiguous.
5. IF the selected model reference defines an output contract -> use it.
   ELSE -> return the ready-to-use prompt in one code block.

IF reviewing an existing prompt:
- Preserve requirements; find conflicts, repetition, unclear inputs, lines
  that do not change behavior, and obvious useless instructions for an AI.
- IF changes are minor -> provide exact replacement text. ELSE -> provide the
  complete revised prompt.
- Explain only material changes; do not force a ceremonial user pause.

## Shared prompt architecture

For each field, **IF** it adds value -> include it. ELSE -> omit it:
- **Goal** - the result to produce.
- **Context** - background that affects the result.
- **Input** - source material, data, files, or placeholders.
- **Requirements** - hard instructions, limits, boundaries, and priorities.
- **Done when** - observable success criteria.
- **Output** - required format, length, audience, or destination.

- IF a role, example, tool, fallback, or step order resolves a real ambiguity ->
  include it. ELSE -> omit it.
- IF XML materially clarifies complex boundaries -> use a few semantic tags.
  ELSE -> use readable headings and lists.
- IF source material is long -> place context and input first, then keep the
  goal and final instructions near the end.

## Check before delivery

- [ ] The selected model reference, if any, was read completely.
- [ ] No unselected model reference was loaded or blended into the prompt.
- [ ] Every section and instruction changes likely model behavior.
- [ ] Goal, requirements, done criteria, and output are unambiguous.
- [ ] Inputs are clearly separated from instructions.
- [ ] No request for hidden reasoning or chain of thought appears.
- [ ] Named-model advice is verified or clearly marked unverified.
- [ ] The prompt is readable, concise, not verbose and no longer than the task needs.
