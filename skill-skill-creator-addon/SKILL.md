---
name: skill-creator-addon
description: >
  Quality gates that wrap Anthropic's skill-creator. Forces explicit skill-type
  classification, collision check against existing skills in AyS-0908/SKILLS,
  gotchas inventory, three-part description, structural lint, and final
  checklist.
  Trigger for: any request to create, improve, update, or audit a skill —
  ALWAYS apply this addon alongside skill-creator. Gates fire inline at four
  injection points inside the standard workflow.
  Do NOT trigger for: skill consumption (fetching and applying an existing
  skill), or any task unrelated to skill authoring.
status: active
---

# Skill Creator Addon — Quality Gates

This skill is a wrapper. It does NOT replace Anthropic's `skill-creator`. It runs alongside it: gates fire at four marked moments inside the standard workflow.

| Point | When (inside skill-creator) | Gate |
|---|---|---|
| PRE-DRAFT | After "Capture Intent", before writing SKILL.md | GATE 1 — Design Intent |
| POST-DESCRIPTION | After description written, before body | GATE 2 |
| DURING-DRAFT | Before committing the SKILL.md draft | GATE 3 |
| PRE-PACKAGE | Before running `package_skill.py` | GATE 4 — Final Checklist |

The agent must read this file at the start of any skill creation and apply each gate at its declared injection point — not after skill-creator finishes.

---

## GATE 1 — Design Intent [PRE-DRAFT]

Ask all four questions in one block. Lock answers before any drafting.

### Q.A — Skill Type

User picks one:
- `RIGID` — fixed recipe, step order matters (output of step N feeds step N+1)
- `GUIDED` — pseudocode + user-adjustable params. Default if unsure.
- `HEURISTIC` — principles + examples, defers to judgment

→ Store as `[skill_type]`. Gate 3 uses it.

### Q.B — Collision

- Fetch the manifest from the SKILLS repo: `gh api repos/AyS-0908/SKILLS/contents/sync_manifest.json --jq '.content | @base64d'`.
- For each existing skill, compare its `description` and `triggers` against the new skill's intent.
- For each match → label `[OVERLAP]` or `[ADJACENT]`.
- Write one-line differentiator per match — this anchors the description later.
- IF none found → `No collision detected`.

### Q.C — Tool Quirks

Ask: "Does this skill call any external tool (Drive, API, file system, MCP)?"

IF yes → list failure modes per class:
- File reads: silent empty return, encoding issues
- MCP calls: auth expiry, rate limits, out-of-order events
- API responses: HTTP 200 with error in body — check body, not status code
- User uploads: silent truncation above size limit

→ Draft a `## Gotchas` block. Gate 4A inserts it verbatim.

IF no → `No known gotchas`.

### Q.D — Automation

For each step in the captured intent:
- IF deterministic given fixed input → flag `[SCRIPT CANDIDATE]` → `scripts/` folder
- IF multi-step external workflow → flag `[WORKFLOW CANDIDATE]` (n8n / webhook)

→ Output annotated step list.

### Research Step (after Gate 1, before drafting)

Not a gate — no pass/fail.

1. Check skills tagged `[OVERLAP]` or `[ADJACENT]` in Q.B — scan their section structure, gotcha handling, progressive disclosure.
2. Extract: section headings, error-handling patterns, description phrasing. Ignore implementations.

→ Output 2–3 bullets of structural observations, or "No relevant patterns found."

---

## GATE 2 — Description & Collision [POST-DESCRIPTION]

### 2A — Description Pattern

Verify description contains three parts:
```
[WHAT the skill does]
Trigger for: [specific phrases / contexts]
Do NOT trigger for: [adjacent cases]
```

IF any part missing → flag it, propose rewrite. Author may override with stated rationale. Default: rewrite.

### 2B — Collision Re-check

- Re-run Q.B using the written description (not just intent).
- For each `[OVERLAP]` from Gate 1 → confirm no co-fire risk.
- IF ambiguous → add exclusion clause to `Do NOT trigger for:`.

→ `Collision: CLEAR` or `Collision: RESOLVED — [what was added]`.

---

## GATE 3 — LLM-Syntax Lint [DURING-DRAFT]

Single pass over SKILL.md body. Severity: **P0** = must fix before packaging. **P1** = log for author, may override with rationale.

| Rule | Check | RIGID | GUIDED | HEURISTIC |
|---|---|---|---|---|
| R1 Lists > Prose | Instruction blocks use lists or IF/THEN, not prose paragraphs | P0 | P0 | P1 |
| R2 IF/THEN | No conditional logic buried in prose | P0 | P0 | P1 |
| R3 Token Budget | "Does deleting this sentence change behavior?" If no → delete | P0 | P0 | P1 |
| R4 Output Format | Machine-consumed output (script, API, downstream skill) → exact format. Human-facing → guidance only. | P0 | P1 | P1 |

→ Output per-rule: `P0` / `P1` / `PASS` with line pointer. All P0 resolved before packaging.

---

## GATE 4 — Documentation Quality [PRE-PACKAGE]

### 4A — Gotchas Block

- Insert `## Gotchas` as first section of SKILL.md body.
- Content = Q.C output from Gate 1.
- IF no gotchas → write `No known gotchas`. Section must exist either way.

### 4B — Validation Coverage

For each external dependency from Q.C → confirm error-handling clause exists in SKILL.md.

Mandatory: file reads, MCP calls, API responses, user uploads.
Skip: pure computation, internal state.

→ Output table: `[Dependency | Handled Y/N]`.

### 4C — Error Handling

For every external call → confirm pattern:
```
IF error → log → notify user → fallback action
```
HTTP 200 with error-in-body: must check response body explicitly.

### 4D — Negative Trigger Verification

- IF `run_loop.py` available (Claude Code with Anthropic skill-creator plugin) → defer to skill-creator's Description Optimization. Done.
- IF not (Claude.ai, Codex, no CLI) → write 4+ near-miss prompts sharing keywords but different intent. Confirm none co-fire. IF any fires → strengthen `Do NOT trigger for:`, retest.

→ `Negative triggers: VERIFIED via [run_loop / manual] — [N/N passed]`.

---

## FINAL CHECKLIST

All boxes checked before `package_skill.py`.

```
[ ] Q.A skill_type declared
[ ] Q.B collision check done (manifest fetched)
[ ] Q.C gotchas inventory complete
[ ] Q.D script/workflow candidates flagged
[ ] Research step done (or "no relevant patterns")
[ ] 2A description: WHAT / Trigger / Do NOT trigger (or override rationale)
[ ] 2B collision re-check CLEAR or RESOLVED
[ ] Gate 3 all P0 resolved
[ ] Gate 3 P1 items logged (resolved or deferred)
[ ] 4A Gotchas block present as first section
[ ] 4B validation coverage table complete
[ ] 4C error handling confirmed for all external calls
[ ] 4D negative trigger verification done
```
