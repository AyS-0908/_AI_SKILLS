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
- Preserve logical force and verification anchors exactly: `and` versus `or`,
  `only`, `must`, `never`, quantities, dates, named cases, identifiers, paths,
  baselines, destinations, required evidence, stated purpose, and epistemic
  markers such as `about`, `estimate`, `hypothesis`, or `unverified`. Preserve
  `A/B`, `A or B`, and similar alternatives as alternatives unless the source
  clearly requires both; never expand an ambiguous slash into two mandatory
  outputs. Do not simplify away a detail that may be needed to verify success.
- IF supplied requirements conflict -> keep the conflict explicit and require a
  decision or report it as unresolved. Until resolved, neither side may appear
  later as the authoritative rule, and neither may be narrowed, combined, or
  normalized into a new rule.
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

1. IF an existing prompt is supplied -> edit it from the source. ELSE -> create
   a new prompt.
2. Before drafting, build a private source map with one row per atomic
   requirement: exact clause, owner, destination, and `preserve`, `conflict`, or
   `remove`. `Remove` is allowed only for true repetition or non-behavioral text.
   Keep exact logical and verification anchors: `and`/`or`, `only`, `must`,
   `never`, slash alternatives, quantities, dates, named cases, IDs, paths,
   destinations, evidence, purpose, epistemic status, model level, and every
   nested branch or handoff. Do not emit the map.
3. Run two conflict scans across the whole source:
   - group clauses by actor, artifact or deliverable, and condition; action versus
     prohibition, obligation versus possibility, incompatible labels, or routes
     are conflicts;
   - record every handoff as `author -> recipient -> requested next recipient`;
     repeated recipients, bypassed required roles, or incompatible routes are
     conflicts.
   Keep both sides verbatim or near-verbatim in one short conflict block. Never
   narrow, merge, normalize, or silently choose a side.
4. IF the user explicitly requests structural refactoring, or scattered or
   duplicated instruction ownership is a diagnosed defect -> restructure only
   enough to fix it, using the smallest helpful subset of the shared architecture.
   ELSE IF the existing structure works -> make a minimal-diff edit: keep its
   headings, order, voice, and dense blocks; change only diagnosed lines. ELSE ->
   use the smallest helpful subset below.
5. IF the source exceeds about 1,000 words, contains three or more roles or
   branches, or contains a conflict, and fresh subagents are available -> give a
   fresh reviewer only the source, draft, and four gates below. Ask for material
   omissions, altered logical force, silent conflicts, unmatched additions,
   duplicate ownership, and measured source-versus-draft length; do not ask it
   to rewrite. Require a result for each gate and allow overall `PASS` only when
   all four pass; exceeding the source length is `FAIL` even without a P0/P1.
   Fix every P0/P1 or failed gate. Repeat once only if either remains.
6. Run these gates in order before delivery:
   - **Coverage:** every `preserve` and `conflict` row appears with the same force;
     dense lists, role branches, model levels, named examples, handoff contents,
     purposes, and evidence anchors remain intact.
   - **No additions:** every new instruction maps to a source row or a triggered
     model adjustment. Delete unmatched features, style devices, synonyms,
     scopes, caps, or deliverables.
   - **Ownership:** each behavior has one authoritative location; `CONTEXT` and
     `INPUT` contain no hidden rules; `DONE WHEN` adds no instruction and omits
     checks already owned elsewhere.
   - **Length:** for an edited prompt, measure the final body with an available
     tool. Do not deliver while it exceeds the source body. Compress repetition,
     scaffolding, and non-dense prose first; never compress a source-map anchor.
7. IF critical information is missing -> ask one grouped question. ELSE -> make
   the smallest reasonable assumption and proceed.
8. IF the selected model reference defines an output contract -> use it.
   ELSE -> return the ready-to-use prompt in one code block.

IF changes are minor -> provide exact replacement text. ELSE -> provide the
complete revised prompt. Explain only material changes when the output contract
allows commentary.

## Shared prompt architecture

For a new complex prompt or a materially unclear source, use this editorial aid.
It is not a mandatory template. Omit every section that adds no value:

```text
# <TITLE>

## GOAL

## ROLE

## CONTEXT

## INPUT

## INSTRUCTIONS

### READ FIRST

## OUTPUT

## DONE WHEN
```

- `TITLE`: task name; omit for short prompts.
- `GOAL`: exact deliverable.
- `ROLE`: only a perspective that changes judgment, scope, or tone; never a
  generic expert role.
- `CONTEXT`: background only; label assumptions, hypotheses, and disputes.
- `INPUT`: sources, data, files, placeholders, and verification anchors.
- `INSTRUCTIONS`: methods, constraints, boundaries, priorities, and checks.
- `READ FIRST`: first Instructions subsection only when named sources must be
  inspected, especially in order.
- `OUTPUT`: response shape, audience, length, or destination only.
- `DONE WHEN`: distinct observable completion criteria only.

For a simple prompt, commonly use only `GOAL`, `INSTRUCTIONS`, and either
`OUTPUT` or `DONE WHEN`. IF input exceeds about 20k tokens -> place it before the
final goal and instructions. Use XML only when it materially clarifies nesting.

## Shared behavior decisions

Apply only the decisions whose condition fires. Express each selected behavior
in task-specific wording, merge it with related instructions, and never expose
internal directive names or paste stock text when the prompt already covers it.

- IF the output is a report, review, audit, recommendation, or status -> require
  the conclusion first, followed by only decision-useful support.
- IF the task asserts factual findings -> require evidence for factual claims,
  and label inference, judgment, and unverified items separately.
- IF the task changes code or another artifact -> prohibit unrequested
  features, cleanup, refactoring, and speculative flexibility.
- IF the task is assessment-only -> state the no-change boundary once. IF it
  authorizes action -> state the permitted actions and approval boundaries once.
- IF the task runs unattended -> allow safe in-scope reversible work and pause
  only for irreversible action, real scope change, or user-only input.
- IF independent high-judgment subtasks exist and the target environment
  supports fresh subagents -> use them for separate work or verification and
  require one final synthesis.
- IF prior decisions are settled and the task does not review them -> do not
  reopen them without new contradictory evidence. Never use this rule when the
  task explicitly audits, challenges, or redesigns prior decisions.
- IF long agentic work ends with a user summary -> make that summary readable
  without the hidden working context: outcome first, complete sentences, and
  terms explained.

## Final check

- [ ] The selected model reference alone was read and its output contract passes.
- [ ] The four gates—coverage, no additions, ownership, and measured length—pass.
- [ ] Every conflict scan result remains explicit and unnormalized.
- [ ] Inputs, instructions, output shape, and distinct done criteria are separate.
- [ ] No hidden-reasoning request or unverified model claim appears.
- [ ] Every remaining line changes likely model behavior.
