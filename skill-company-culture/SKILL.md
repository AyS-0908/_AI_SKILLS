---
name: company-culture
description: >
  Guide scaling SMBs with approximately 50-250 employees through company-culture
  context intake, diagnosis, definition, alignment, activation, and reinforcement.
  Trigger for: "help me define our company culture", culture diagnosis or review,
  values, leadership principles, observable behaviours, manager expectations,
  rituals, workshops, or culture rollout. Do NOT trigger for: broad HR strategy or
  12-month HR roadmaps, one-off hiring or performance questions, legal compliance
  decisions, or generic team-building with no culture objective.
---

# Company Culture

**Type:** DOER

## Gotchas

- Treat stated values as claims until behaviour and decisions support them.
- IF a required file read fails, returns empty, or has encoding problems, name the source and error, tell the user, then continue only with other confirmed context or ask for the missing facts.
- IF an approved web check fails, name the source and reason, tell the user, use dated references only as non-live background, and make no current legal claim.
- IF a supplied document or upload is missing or appears truncated, tell the user and ask them to reattach it or paste the relevant excerpt; do not fill gaps by inference.
- Culture principles never replace country-specific employer obligations.

## Required Context

- Read `docs/access_rules.md` before using sources, documents, sensitive data, or external-use outputs.
- Look for company context in the current conversation, `docs/company_context.md`, and approved supplied documents.
- Apply `docs/hr_operating_principles.md` when available.
- Read `references.md` before selecting the method.
- Read `templates.md` only when producing a concrete culture artifact.

## Guided Context Intake

- Run this intake at the start of every new culture engagement.

1. Gather available context before asking questions.
2. Briefly summarize what is already known as facts and assumptions.
3. Ask the user to confirm or correct that summary.
4. In the same message, ask no more than three material missing-context questions.
5. Tell the user they may answer naturally, paste notes, or point to a document. Never require a formal prompt or questionnaire.
6. Wait for sufficient context before drafting values, principles, workshops, or a complete culture framework.
7. Reuse confirmed context later unless it is missing, stale, or contradictory.

- IF no company context is available, ask only:

1. What does the company do, in which market and locations?
2. What is the current employee size, expected growth, and business stage?
3. What are the main business priorities and people or culture challenges?

- IF Dapple context is available, summarize the known product, France/UK/US footprint, current size, growth plan, and startup stage. Ask only for corrections, updates, current business priorities, behavioural evidence, or leadership context that is still missing. Do not ask the user to repeat known Dapple facts.

- Treat context as sufficient only when the company, size and growth direction, business outcome, current behavioural evidence, and relevant leadership context are clear enough for the next useful step.
- Treat the CEO's behaviour and personality as possible leadership context because leaders reinforce culture; do not treat personality as the culture itself.

## Operating Range

- Use this method for scaling SMBs with approximately 50-250 employees.
- Tailor the answer to the company's actual current size and growth plan; never assume it is permanently at 50-70 employees.
- For every material recommendation, state:
  - **Needed now:** the smallest reliable practice.
  - **Add when:** an observable complexity, risk, or growth trigger.
  - **Not needed yet:** heavier process to avoid.
- Do not use headcount alone as the trigger for more process.

## Route the Request

- IF context is not confirmed or sufficient, run Guided Context Intake and stop before substantive output.
- IF defining culture, run the full workflow.
- IF diagnosing culture, focus on Diagnose and end with the few decisions needed next.
- IF drafting values or principles, complete Diagnose before drafting.
- IF planning rollout or rituals, confirm the principles are settled, then use Activate and Reinforce.
- IF reviewing an existing draft, test it against evidence, observable behaviour, trade-offs, and business usefulness.

## Workflow

### 1. Diagnose

- Separate current culture from desired culture.
- Examine:
  - **Artifacts:** visible routines, language, decisions, processes, and stories.
  - **Espoused values:** what leaders say should matter.
  - **Underlying assumptions:** beliefs revealed by repeated behaviour and trade-offs.
- Identify strengths to preserve, tensions to resolve, and behaviours to stop tolerating.

### 2. Define and Align

- Draft 3-5 principles only after diagnosis.
- For each principle, define observable behaviours, anti-behaviours, a real trade-off, and supporting evidence.
- Connect principles to business priorities, manager expectations, decisions, and only the relevant people processes: hiring, onboarding, feedback, recognition, performance, promotion, or exits.
- Remove any principle that would not change a decision or behaviour.

### 3. Activate

- Define what leaders must model and managers must reinforce.
- Prefer an existing meeting, decision routine, working agreement, role clarification, retrospective, story, or recognition practice.
- Add OKRs or formal measures only when they execute a specific culture priority.
- Pilot with a small manager group before company-wide rollout.

### 4. Reinforce

- Reinforce principles through existing systems before creating new processes.
- Choose a few observable signals and a review cadence tied to decisions.
- Apply **Needed now / Add when / Not needed yet**.
- Name the owner and next review point.

## Completion Check

- Before calling the work complete, report `PASS` or the remaining gap for each item:

- Company context was confirmed and material unknowns are explicit.
- Current reality and aspiration are separated.
- Principles describe behaviours, anti-behaviours, evidence, and trade-offs rather than slogans.
- Leader modelling, manager reinforcement, rituals, decisions, and relevant people processes are connected.
- Needed now, Add when, and Not needed yet are explicit.
- The output names an owner, next action, success signal, and review point.
- Country-specific legal questions are flagged for live verification.
- External-use drafts have the approval required by `docs/access_rules.md`.
