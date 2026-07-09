# Skill Plan — doc-hygiene

**What this is:** the open to-do for the `doc-hygiene` skill, written so a fresh AI session can run each item on its own. Do them in order.

**Effort scale:** 2 = medium · 3 = high · 4 = xhigh · 5 = max. (1 = never used.)

---

## Rough edges found during live use

### [x] 1 — Deterministic "broken references" scan is not applied to NEWLY-WRITTEN pointers (MEDIUM — found on AI4CEO, 2026-07-09) — FIXED 2026-07-09
**Done:** new final line in the §4 checklist: APPLY mode re-runs the broken-reference scan on every pointer the pass itself wrote.
**Symptom:** the pass replaces duplicated blocks with pointers like `see AGENTS.md § Hard technical constraints`. On AI4CEO the maker wrote a pointer whose `§` heading was wrong (deployment facts live under `## Deployment target`, not under `Hard technical constraints`). The skill's own §4 checklist already says to check "broken references: `§` / heading anchors" — but that check was run on *pre-existing* refs, not on the pointers the pass itself introduces. A fresh auditor caught it; the skill should have.
**Fix:** add an explicit final step to the per-doc loop / §4 checklist: "Re-run the broken-reference scan against every pointer THIS pass wrote — confirm each `§ heading` and `[file]` target actually exists." One line in SKILL.md. Cheap, closes a self-inflicted-error class.
**Run on:** best-1 @ 2/5 (doc edit).

### [x] 2 — No built-in fresh-context verification when run standalone (LOW/by-design — note only) — DONE 2026-07-09
**Done:** one-line note added under the skill-type intro: standalone runs can have a fresh context verify the applied diff, as code-audit-loop does.
**Observation:** doc-hygiene is a BLOCK; its "check" per SKILLS-DESIGN is the fixed 5-section report (a measurable done-bar) + guardrails, and the fresh reviewer is expected to come from the *caller* (e.g. code-audit-loop). Run standalone by a user, nothing forces a second-context audit. On AI4CEO the orchestrator added a fresh-auditor pass manually and it caught the item-1 pointer nit. Not a bug — but worth a one-line note in SKILL.md: "Run standalone? The report is the done-bar; for higher assurance have a fresh context verify the diff (as code-audit-loop does)." Item 1 reduces the need for this.
**Run on:** best-1 @ 2/5.

### [ ] 3 — Ownership map is hardcoded to code-GO_VIRAL filenames (LOW — friction note)
**Observation:** §2's map uses concrete GO_VIRAL files (`goviral_prd_module_1.md`, etc.) and says "In another repo, map each ROLE to its file." Works, but a fresh agent on a *different* repo (AI4CEO: AGENTS.md/CLAUDE.md/macro_prd.md/design.md) must be handed the role→file mapping or infer it. For micro-projects (4 tiny docs, most roles empty, CLAUDE.md an unmapped pointer) the route is a lot of ceremony. The skill DOES handle it ("Unmapped doc → assign nearest role or mark pointer"), so this is a friction note, not a defect. No change unless it recurs.

---

## Notes for whoever picks this up
- The skill performed well on AI4CEO: correctly de-duplicated triplicated editorial rules to one owner + pointers, fixed a broken `functional_spec.md` ref, rebuilt a stale/wrong page list from the code anchor, and cut a stale build-roadmap — with no fact loss. Only defect was item 1 (a wrong pointer heading it wrote itself).
