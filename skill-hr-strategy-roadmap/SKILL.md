---
name: hr-strategy-roadmap
description: >
  Build a focused 12-month HR strategy and practical HR roadmap for scaling
  SMBs after guided company-context intake and employer-foundation checks.
  Trigger for: "build my HR strategy for the next 12 months", "turn this into
  an HR roadmap", "what should HR focus on before we grow", HR priorities,
  people strategy, workforce implications, or growth from 50 to 70 employees.
  Do NOT trigger for: general corporate, product, or technology roadmaps;
  company-culture definition without a broader HR strategy; one-off HR policy,
  hiring, performance, or legal questions; or multi-year enterprise HR transformation.
---

# HR Strategy Roadmap

**Type:** DOER

## Gotchas

- Do not turn an HR topic catalogue into a strategy; strategy requires choices and deliberate deferrals.
- IF a required file read fails, returns empty, or has encoding problems, name the source and error, tell the user, then continue only with other confirmed context or ask for the missing facts.
- IF an approved web or legal check fails, name the source and reason, tell the user, use dated references only as non-live background, and mark the affected recommendation as requiring verification.
- IF a supplied document or upload is missing or appears truncated, tell the user and ask them to reattach it or paste the relevant excerpt; do not infer its contents.
- Treat country-specific employer guidance as time-sensitive and advisory; the HR Director decides when legal counsel is required.

## Required Context

- Read `docs/access_rules.md` before using sources, documents, sensitive data, or external-use outputs.
- Look for company context in the current conversation, `docs/company_context.md`, and approved supplied documents.
- Apply `docs/hr_operating_principles.md` when available.
- Read `references.md` before assessing priorities or employer foundations.

## Guided Context Intake

- Run this intake at the start of every new strategy or roadmap engagement, including requests to "turn this" into a roadmap.

1. Gather available context before asking questions.
2. Briefly summarize what is already known as facts and assumptions.
3. Ask the user to confirm or correct that summary.
4. In the same message, ask no more than three material missing-context questions.
5. Tell the user they may answer naturally, paste notes, or point to a document. Never require a formal prompt or questionnaire.
6. Wait for sufficient context before drafting the strategy, priorities, or roadmap.
7. Reuse confirmed context later unless it is missing, stale, or contradictory.

- IF no company context is available, ask only:

1. What does the company do, in which market and locations?
2. What is the current employee size, expected growth, and business stage?
3. What are the main business priorities and people or culture challenges for the next 12 months?

- IF Dapple context is available, summarize the known product, France/UK/US footprint, current size, growth plan, startup stage, HR build-out, and COO reporting line. Ask only for corrections, updates, business priorities, workforce constraints, or foundation gaps that remain material. Do not ask the user to repeat known Dapple facts or assume Dapple stays at 50-70 employees.

- Treat context as sufficient only when the business priorities, locations, current and expected workforce, material people risks, current HR foundations, and execution constraints are clear enough to prioritize.
- IF context is insufficient, ask the next smallest question set and wait.

## Role and Scale Boundaries

- Keep the CHRO or HR Director capability active.
- Use the COO only as the HR Director's reporting-line and execution lens: operational impact, manager workload, capacity, rollout complexity, and measurable next step.
- Do not activate or simulate other executive roles.
- Use this method for scaling SMBs with approximately 50-250 employees, tailored to actual current size and stage.
- Do not use multi-agent workflows, hooks, Apify, or recurring monitoring.

## Route the Request

- IF context is not confirmed or sufficient, run Guided Context Intake and stop before substantive output.
- IF building a strategy, connect business priorities to workforce implications, choose HR priorities, then sequence them.
- IF turning supplied material into a roadmap, preserve its confirmed decisions, identify missing context, then sequence only agreed priorities.
- IF asking what HR should focus on before growth, assess foundations and growth constraints before proposing programs.

## Workflow

### 1. Translate Business Priorities

- For each confirmed business priority, state:

- Required workforce capacity and critical capabilities.
- Organisation, role, or manager implications.
- Main people risk if nothing changes.
- HR contribution and boundary.

- Reject HR activity with no clear link to a business outcome, employer obligation, or material people risk.

### 2. Check Minimum Employer Foundations

- Before advanced programs, assess only what is relevant in each country:

- Employment setup, classification, contracts, payroll, required records, leave, benefits, notices, and core policies.
- Clear roles, decision ownership, organisation structure, and reliable workforce data.
- Repeatable recruitment, compliant onboarding, manager basics, and issue escalation.

- IF a foundation is missing and creates legal, payroll, data, or employee-relations risk, place it in **Needed now** before discretionary programs.
- Flag legal conclusions for live verification.

### 3. Assess the HR Portfolio

- Scan these areas, but select only those that materially support the next 12 months:

- Workforce planning.
- Organisation and capability.
- Recruitment and onboarding.
- Management.
- Performance and development.
- Engagement and culture.
- Compensation and benefits.
- HR operations, systems, data, and compliance.

- For each material item, classify:

- **Needed now:** required for the current business plan, employer foundation, or active risk.
- **Add when:** a named trigger makes it useful.
- **Not needed yet:** deliberately deferred because cost or complexity exceeds current value.

### 4. Prioritize

- Choose 3-5 strategic HR priorities at most.
- Rank by business impact, risk, urgency, dependency, and delivery capacity.
- State the intended outcome, not just the HR activity.
- Sequence foundations before dependent programs.
- Name what will not be done in the 12 months.

### 5. Build the 12-Month Roadmap

- Use quarters or equivalent timing. For every roadmap item include:

| Priority | Intended outcome | Timing | Owner | Dependencies | Success measure | Key risk | Deliberately deferred |
|---|---|---|---|---|---|---|---|

- Keep owners real; use `HR Director`, `COO`, `manager`, or a confirmed role, not invented executive agents.
- Use outcome measures that can change a decision; avoid vanity metrics.
- Keep delivery feasible for the stated HR and manager capacity.
- End with the smallest concrete next actions for the HR Director and any decision needed from the COO.

## Completion Check

- Before calling the work complete, report `PASS` or the remaining gap for each item:

- Company context and the 12-month business priorities were confirmed.
- Workforce implications and HR priorities are explicitly linked.
- Minimum employer foundations were assessed before advanced programs.
- All relevant HR areas were scanned, but only 3-5 priorities were selected.
- Needed now, Add when, and Not needed yet are explicit.
- Every roadmap item has timing, owner, dependencies, success measure, risk, and deliberate deferral.
- The plan fits available HR and manager capacity and uses the COO only as an execution lens.
- Country-specific obligations are live-verified or clearly flagged.
- The next review point and smallest next actions are explicit.
