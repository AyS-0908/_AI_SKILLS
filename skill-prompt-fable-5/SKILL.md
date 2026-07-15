---
name: prompt-fable-5
description: >
  Write a ready-to-paste prompt tuned for Claude Fable 5 / Mythos 5 on a task the
  user names. Produces the prompt text itself plus a recommended effort setting —
  the user copies it into a fresh Fable 5 session.
  Trigger for: "write/prepare/draft a prompt for Fable 5", "tune this prompt for
  Fable", "I want to run X on Fable 5", "prompt for my Fable session", or handing
  any task off to a fresh Fable 5 / Mythos 5 session.
  Do NOT trigger for: model-agnostic prompt writing (use prompt-engineer);
  writing Claude API or SDK request code, model IDs, params, pricing, or
  migrations (use claude-api); explaining what Fable 5 is or how it compares to
  Opus; or performing the task itself instead of writing the prompt for it.
status: active
---

# Prompt for Fable 5

Applies to `claude-fable-5` and `claude-mythos-5`.

**Input:** a task the user wants Fable 5 to do. 
**Output:** the prompt, ready to copy. You write the prompt — you do not do the task.

## Gotchas

- **Over-instructing is the main failure mode.** Fable 5 follows instructions literally, and prompts written for older models reduce its output quality. Never paste all the Directives below. Pick the two to four whose trigger genuinely matches. When unsure, include fewer.
- **Never write "explain your reasoning", "show your thinking", or "walk me through your thought process" into the prompt.** Fable 5's safety classifiers treat that as reasoning-extraction and decline the request (`stop_reason: "refusal"`, category `reasoning_extraction`). Fable 5 never returns its raw chain of thought — there is nothing to extract.
- **Cyber and bio topics can be declined**, and benign adjacent work (security tooling, life-sciences) sometimes false-positives. IF the task is in either domain → tell the user before handing over the prompt, so a refusal doesn't read as your mistake.
- **No API parameters in prompt text.** `temperature`, `top_p`, `budget_tokens`, and `thinking` config all return a 400 on Fable 5 and are meaningless in pasted text. Reasoning depth is the effort setting (Step 3), never a sentence in the prompt.
- The task spec must be **complete in this one prompt**. Fable 5 is more autonomous and more literal than prior models: a full spec up front produces better and cheaper output than the same information dripped across follow-up turns.

## What you produce

Emit exactly this, nothing else:

```
**Effort:** <level> — <one-line reason>

---
<the prompt, copy-paste ready>
---
```

IF the task touches cyber or bio → add one line above the block flagging refusal risk.

## Step 1 — Frame the task (always)

Open every prompt with intent, not just instruction. Fable 5 connects a task to relevant context when it knows why the work exists; without it, it infers.

> I'm working on [the larger task] for [who it's for]. They need [what the output enables]. With that in mind: [the request].

Then state the full spec: what to produce, the constraints, what "done" means, and what it must not touch. Ask the user for anything missing — a gap here costs more than the question does.

## Step 2 — Directives

Match the task against the triggers. Embed the matching text verbatim into the prompt. Skip the rest.

**You do the matching — never Fable 5.** The table stays here; only the selected directive text goes into the prompt. Pasting the table, or telling Fable 5 to pick for itself, puts all thirteen directives in its context and re-creates the over-instruction failure above.

| IF the task… | THEN add |
|---|---|
| is ambiguous or under-specified | **Act-once** |
| is one you'd run at high or xhigh effort | **No-overbuild** |
| ends in something the user reads | **Outcome-first** |
| runs unattended (overnight, nobody watching) | **Autonomous** + **Context** |
| involves reporting progress or status | **Evidence** |
| is a question, diagnosis, or think-aloud — not a change request | **Assess-only** |
| has independent subtasks and the harness has subagents | **Delegate** |
| spans sessions and a notes location exists | **Memory** |
| is long agentic work whose summary the user reads cold | **Re-ground** (use instead of Outcome-first, not alongside) |
| has real checkpoints needing a human decision | **Checkpoint** |

**Act-once** — When you have enough information to act, act. Do not re-derive facts already established, re-open settled decisions, or narrate options you won't pursue. When weighing a choice, give one recommendation, not a survey. This does not apply to your thinking.

**No-overbuild** — Don't add features, refactor, or introduce abstractions beyond what the task requires. Don't design for hypothetical future requirements or leave half-finished implementations. Add error handling and validation only at system boundaries (user input, external APIs); trust internal code and framework guarantees.

**Outcome-first** — Lead with the outcome: your first sentence answers "what happened" or "what did you find". Detail comes after. Keep it short by cutting low-value content, not by compressing into fragments, arrow chains, or jargon. Prefer clear over short.

**Autonomous** — You are operating autonomously; the user cannot answer mid-task, so asking "Want me to…?" blocks the work. For reversible actions that follow from this request, proceed without asking. Before ending your turn, check your last paragraph: if it is a plan, a question, a list of next steps, or a promise ("I'll…"), do that work now with tool calls. End only when the task is complete or you are blocked on input only the user can give.

**Context** — You have ample context remaining. Do not stop, summarize, or suggest a new session over context limits. Continue.

**Evidence** — Before reporting progress, audit each claim against a tool result from this session. State failures with their output, state skipped steps, and state unverified items explicitly. Don't hedge on work you have verified.

**Assess-only** — When I'm describing a problem or thinking out loud rather than requesting a change, the deliverable is your assessment: report findings and stop. Don't apply a fix until asked. Before any state-changing command, check that the evidence supports that specific action — a familiar-looking signal may have a different cause.

**Delegate** — Delegate independent subtasks to subagents and keep working while they run. Prefer long-lived subagents and async communication over blocking on each one. Intervene if a subagent drifts or lacks context. Establish a way to check your own work as you build and run it periodically, verifying against the spec with fresh subagents rather than self-critique.

**Memory** — Store one lesson per file with a one-line summary at the top. Record corrections and confirmed approaches alike, with why they mattered. Don't duplicate what the repo or this conversation already records; update an existing note rather than creating a duplicate; delete notes that turn out to be wrong.

**Re-ground** — Terse shorthand is fine while you work. Your final summary is different: it's the user's first look at all of it. Write it as a re-grounding, not a continuation — complete sentences, terms spelled out, no arrow chains and no labels you invented along the way. Give each file, commit, or flag its own plain clause. Open with one sentence on what happened, then the detail.

**Checkpoint** — Pause and ask only for destructive or irreversible actions, real scope changes, or input only I can give. In those cases ask and end your turn. Never end on an unfulfilled promise.

## Step 3 — Recommend effort

| Task | Effort |
|---|---|
| Routine, scoped, or latency-sensitive | `low` / `medium` — still beats older models at their top settings |
| Most real work | `high` |
| Hardest reasoning, long-horizon autonomous runs, correctness over cost | `xhigh` |
| Ceiling test only | `max` — diminishing returns, prone to overthinking |

At high and above Fable 5 over-gathers context and over-builds on routine work. IF you recommend high or xhigh → **No-overbuild** is near-mandatory.

## Step 4 — Check before emitting

- [ ] No request to explain, show, or narrate reasoning anywhere in the prompt
- [ ] Four directives or fewer, each with a trigger that actually fires
- [ ] No step-by-step scaffolding Fable 5 can derive itself
- [ ] No API parameters written as prompt text
- [ ] Whole spec is in this one prompt — nothing deferred to a follow-up turn
- [ ] Opens with why the work exists and who it's for

## Not this skill's job

Client timeouts, refusal fallbacks to Opus 4.8, and defining tools like `send_to_user` are harness configuration — a pasted prompt cannot set them. IF the user is building a Fable 5 application rather than pasting a prompt → send them to the `claude-api` skill.
