# Claude Fable 5 / Mythos 5

Apply this file only when the requested target is Claude Fable 5 or Mythos 5.
Write the prompt; do not perform the task.

## Contents

- [Gotchas](#gotchas)
- [Output contract](#output-contract)
- [Prompt structure](#prompt-structure)
- [Select directives](#select-directives)
- [Recommend effort](#recommend-effort)
- [Final check](#final-check)

## Gotchas

- Over-instruction is the main failure mode. Pick only the directives whose
  triggers match; never paste the whole directive catalogue.
- Never ask Fable to explain, show, or narrate its reasoning or thought process.
- IF the task touches cyber or bio -> warn the user that even benign adjacent
  work may trigger a refusal.
- Do not put API parameters in prompt text. Non-default sampling values, manual
  thinking budgets, and disabled thinking are unsupported.
- Put the complete task specification in one prompt instead of deferring pieces
  to follow-up turns.

## Output contract

Emit exactly:

```text
**Effort:** <level> - <one-line reason>

---
<the prompt, copy-paste ready>
---
```

IF the task touches cyber or bio -> add one warning line above the block.

## Prompt structure

Use these headings when sections improve readability:

```text
--- CONTEXT
Why the work exists and who it is for.

--- GOAL
The exact deliverable.

--- INPUT
Source material or facts to use.

--- INSTRUCTIONS
Constraints, boundaries, and the selected directive text.

--- DONE WHEN
Concrete success criteria.
```

- Omit empty or unnecessary sections, but keep `INSTRUCTIONS` for selected
  directives.
- IF source material is long (about 20k+ tokens) -> put `INPUT` before `GOAL`
  and the final `INSTRUCTIONS`.
- Do not add a generic role, foreword, scratchpad, critical-reminders block, or
  unmatched directives.
- State the intent, exact deliverable, constraints, boundaries, and completion
  criteria. Ask one grouped question only when a material gap prevents a sound
  prompt.

## Select directives

Include Outcome-first in every prompt unless Re-ground replaces it. Add zero to
three other directives whose IF fires. Four directives is the absolute maximum.
Put each selected directive's complete text only under `INSTRUCTIONS`.

| IF | Add |
|---|---|
| Always | Outcome-first, unless Re-ground replaces it |
| The task changes code and effort is `high` or `xhigh` | No-overbuild |
| The output asserts facts, findings, research, audit, review, or status | Evidence |
| Real choices remain and Fable may decide them | Act-once |
| Fable must change nothing | Assess-only |
| It runs unattended | Autonomous |
| The session shows a context countdown | Context |
| Independent subtasks exist and subagents are available | Delegate |
| A memory location exists and work spans sessions | Memory |
| Long agentic work ends with a summary read cold | Re-ground; replace Outcome-first |
| A real human decision checkpoint exists | Checkpoint |

### Directive text

**Outcome-first** - Lead with the outcome: your first sentence answers what
happened or what you found. Detail comes after. Keep it short by cutting
low-value content, not by compressing into fragments, arrow chains, or jargon.
Prefer clear over short.

**No-overbuild** - Don't add features, refactor, or introduce abstractions
beyond what the task requires. Don't design for hypothetical future
requirements or leave half-finished implementations. Add error handling and
validation only at system boundaries such as user input and external APIs;
trust internal code and framework guarantees.

**Evidence** - Before stating any finding, claim, or status, audit it against a
tool result from this session. State failures with their output, state skipped
steps, and state unverified items explicitly. Don't hedge on what you verified.

**Act-once** - When you have enough information to act, act. Do not re-derive
established facts, reopen settled decisions, or narrate options you won't
pursue. When weighing a choice, give one recommendation, not a survey.

**Assess-only** - Report findings and stop. Do not apply a fix, edit a file, or
run a state-changing command unless asked. Before any state-changing command,
check that the evidence supports that specific action.

**Autonomous** - The user cannot answer mid-task. For reversible actions that
follow from this request, proceed without asking. Before ending, check whether
your last paragraph is a plan, question, promise, or unfinished next step; do
that work now. End only when complete or blocked on input only the user can give.

**Context** - You have ample context remaining. Do not stop, summarize, or
suggest a new session because of context limits. Continue.

**Delegate** - Delegate independent subtasks to subagents and keep working while
they run. Prefer long-lived subagents and asynchronous communication. Intervene
if one drifts or lacks context. Verify the work periodically against the spec
with fresh subagents rather than relying only on self-critique.

**Memory** - Store one lesson per file with a one-line summary at the top.
Record corrections and confirmed approaches with why they mattered. Don't
duplicate existing repo or conversation knowledge; update an existing note when
appropriate and delete notes proven wrong.

**Re-ground** - Write the final summary as the user's first view of the work:
complete sentences, terms spelled out, no arrow chains, and no invented labels.
Give each file, commit, or flag its own plain clause. Open with one sentence on
what happened, then give the detail.

**Checkpoint** - Pause only for destructive or irreversible actions, real scope
changes, or input only the user can provide. In those cases ask and end the
turn. Never end on an unfulfilled promise.

## Recommend effort

| Task | Effort |
|---|---|
| Simple, high-volume, cost-sensitive, or latency-sensitive | `low` - efficient, with some capability reduction |
| Balanced speed, cost, and performance | `medium` |
| Most tasks | `high` - default starting point |
| Capability-sensitive or long-horizon | `xhigh` |
| Deepest reasoning and maximum capability without a token constraint | `max` - highest cost and latency |

At `high` and above, use No-overbuild for code changes. For prose, Outcome-first
is already the brake.

## Final check

- [ ] Outcome-first or Re-ground is present, never both.
- [ ] Four directives or fewer; every optional directive's IF fired.
- [ ] Selected directive text appears only in `INSTRUCTIONS`.
- [ ] No request for hidden reasoning appears.
- [ ] No unnecessary step-by-step scaffolding or API parameter appears.
- [ ] The whole task specification is present.
- [ ] Empty sections are omitted and long input precedes final instructions.

Client timeouts, model fallback, tools, and API configuration belong to the
harness or client, not to the pasted prompt.
