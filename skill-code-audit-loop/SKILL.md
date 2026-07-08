---
name: code-audit-loop
description: >
  Run a controlled build -> audit -> fix loop for one phase of an
  implementation plan. An AI Coder implements the phase and updates its docs, a
  FRESH AI Auditor reviews it by invoking the audit-it skill (phase-gate mode)
  and returns Greenlight or a Fix Plan written into the plan, the Coder applies
  only those fixes, and the loop repeats until Greenlight or a round cap.
  Trigger for: "run the loop on Phase X", "build-audit loop", "implement and
  audit phase N until greenlight", continuing or resuming an in-progress phase
  loop, or checking loop status. Do NOT trigger for: a one-off review with no
  fix cycle (use audit-it or /code-review directly), ordinary single edits,
  non-phase work, or building the auditor itself.
---

# Code-Audit Loop

**Uses:** audit-it (hard dep), doc-hygiene, github-sync

Conductor skill. It does not audit and it does not invent a coder. It runs the
back-and-forth between a Coder and the existing **audit-it** skill until a phase
is green, with a hard round cap and a human final greenlight.

## Gotchas

- Skill type: RIGID conductor. Run ONE turn per invocation, update state, stop. Do not fast-forward the whole loop silently.
- The Auditor is `audit-it`, CALLED not copied. Never re-implement audit logic here. If `audit-it` is unavailable, stop and tell the user — do not fake an audit.
- The Auditor must run as a FRESH helper (sub-agent / new context). A same-context audit inherits the Coder's blind spots and is not trustworthy.
- Greenlight writes nothing to disk (audit-it contract). Detect the verdict by COUNTING `## Audit fixes to implement` sections in the plan before vs after the audit: one more section = Fix Plan; same count = Greenlight. Do not rely on the date heading — several rounds can share today's date. Record the result in state.
- Round cap is a safety rail, not a suggestion. At the cap, STOP and surface. Never loop past it hoping it converges.
- Reads can be stale. Re-read the plan and changed files live before acting.

## Roles

| Role | Who | Job |
|---|---|---|
| **Conductor** | Main agent (this skill) | Track state, run each turn, enforce the cap, report. |
| **Coder** | Main agent | Implement the phase; later, apply only the audit's fixes. |
| **Auditor** | FRESH helper running `audit-it` | Review the phase, return Greenlight or a Fix Plan in the plan. |

Pragmatic default (solo dev): the main agent is both Conductor and Coder. Only
the **Auditor runs as a fresh helper** — that fresh context is the whole point,
and it is the one part worth the extra cost. One helper per audit round.

## What each role reads first

Both roles are AI agents in this harness, so their rules already EXIST — this skill POINTS to them, it does not restate them.

- **Coder** (main agent) — already bound by `AGENTS-canonical.md` -> project `AGENTS.md` / `PROGRESS.md`. For the build and the doc updates, follow `usage_coding.md` (surgical diffs, reuse-first, the doc-update discipline, and the auditor-prompt contract). The canonical routes there automatically.
- **Auditor** (fresh helper) — starts COLD, no context. It only knows what the Handoff Prompt tells it to read: the canonical, the project `AGENTS.md`, the plan slice, and the changed files. Never assume it knows anything (`usage_coding.md`: "Do not assume the external auditor has any context").

## Inputs the conductor needs

- **Phase**: which phase of which plan (e.g. "Phase 3 of `implementation_plan.md`").
- **Plan file**: the `*plan*.md` the Coder follows and `audit-it` writes fixes into. Ask once if unclear.
- **Round cap**: default 3. Honor a user override.

## The Loop

Run turns in order. One turn = one invocation. After each turn, update state and tell the user the next action.

**Before round 1:** confirm the `audit-it` skill is available in this session and the exact plan file path is known. If `audit-it` is missing, STOP and tell the user — do not write any code (the loop is worthless without its auditor).

**Turn: CODE** (round 1 only, or first entry)
1. Follow `usage_coding.md`. Read the Phase X plan slice + the touched code. Implement ONLY that phase; surgical diff; reuse before adding.
2. Update the docs the change made stale, per `usage_coding.md`: keep ONLY what an AI coder needs, AI-native terse style, no rule duplicated across docs. (Deeper cross-doc cleanup = the doc-hygiene skill; see "When to deep-clean docs".)
3. Run the smallest self-check that proves it works (project test/lint/build if declared). Keep the evidence.
4. Write the AUDITOR HANDOFF PROMPT (see that section).
5. Set state: `turn=audit`, `round=1`, `verdict=pending`, `max_rounds=<cap>` (default 3, or the user's override). Hand to AUDIT.

**Turn: AUDIT**
1. Count the `## Audit fixes to implement` sections already in the plan file (call it N).
2. Spawn a FRESH helper. Give it the AUDITOR HANDOFF PROMPT, then: *"Use the audit-it skill in phase-gate mode. Scope = the changed files for this phase plus the Phase X slice of `<absolute plan path>`. Write any Fix Plan into that exact file. Return the verdict."*
3. Re-read the plan and count the sections again:
   - **Still N** (no new section) -> Greenlight. Set `verdict=greenlight`, `turn=done`. Go to DONE.
   - **Now N+1** -> Fix Plan. Set `verdict=fixes`, `turn=fix`. Go to FIX.
   - The helper's own summary is a cross-check, not the deciding signal — the section count decides.

**Turn: FIX**
1. If `round >= max_rounds`: STOP. Set `turn=blocked`. Report the open Fix Plan to the user and ask how to proceed. Do not audit again automatically.
2. Otherwise implement ONLY the bottom-most `## Audit fixes to implement` section (the newest one). Minimal diff. Run each fix's stated `test`. Refresh the AUDITOR HANDOFF PROMPT for the re-audit.
3. Increment `round`. Set `turn=audit`, `verdict=pending`. Go back to AUDIT.

**Turn: DONE**
- Report to the user with proof (`usage_coding.md` close-out): phase is green, the checks that passed (evidence), the docs updated, and it awaits their final OK. Offer to commit the phase via `skill-github-sync`. The human gives the last greenlight — the loop does the grunt work, not the sign-off.

## Auditor Handoff Prompt

Every Coder turn ENDS by writing this prompt. It is what the fresh Auditor is handed — and it is copy-pasteable into a new session if you ever run the audit by hand (this is what bridges "let the loop do it" and "do it myself"). Fields follow `usage_coding.md`'s auditor-prompt rule; assume the Auditor has ZERO context.

- **Role** — You are an AI Auditor. Use the audit-it skill in phase-gate mode.
- **Read first** — `AGENTS-canonical.md`, the project `AGENTS.md`, `<plan path>` (Phase X slice), and the changed files listed below.
- **Context** — what this project and Phase X are, in 2-3 lines.
- **What was built** — Phase X: the change and the files touched.
- **Goal / acceptance** — what "done" means for Phase X (from the plan).
- **Key risks to check** — the 2-4 things most likely wrong here.
- **Constraints** — scope limits; what NOT to touch.
- **Tests / evidence** — the self-check run and its result.
- **Verify + verdict** — confirm the behavior, then return Greenlight or write a Fix Plan into `<plan path>`.

## When to deep-clean docs

Per-turn doc updates (CODE step 2) keep each phase's own docs tidy. For a full cross-doc pass — every fact in its owning doc, no redundancy across `AGENTS` / `PRD` / `ARCHITECTURE` / `PLAN` / `PROGRESS` — call the **doc-hygiene** skill. Run it at FEATURE completion (final greenlight), not after every phase — every-phase is overkill.

## Guardrails (do not remove)

- **Round cap** (default 3): at the cap, stop and surface the open fixes. No endless ping-pong, no self-approval of a phase the Auditor still rejects.
- **Fresh Auditor**: every audit turn is a new-context helper. Never reuse the Coder's context to grade the Coder.
- **Human final greenlight**: the loop reaches "green"; the user confirms ship. Never mark the phase shipped on the Auditor's word alone.

## State and Resume

State lives in `code-audit-loop/state.json` in the project. The Fix Plans live
in the implementation plan (audit-it owns those). Round/turn/verdict live in state.

- Update state with: `python <skill>/scripts/status.py code-audit-loop set phase=3 round=1 turn=audit verdict=pending`
- "where are we" / "status" / "continue" / "resume" -> run `python <skill>/scripts/status.py code-audit-loop`, report the plain-English status, then run the turn it names.
- No state file yet -> treat as a fresh start (Turn: CODE).

At end of meaningful work, update the project `PROGRESS.md` per project convention (DONE / OPEN / NEXT ACTION). Do not create a second progress file.

## Stop Rules

Stop and ask only when:
- the target phase or plan file is genuinely unclear and guessing would waste real work,
- `audit-it` is not available in this session,
- a required native command needs approval, network, or write access,
- the round cap is hit.

Otherwise make the conservative choice and run the next turn.
