# Skill Plan — doc-hygiene

**What this is:** open improvements found during the skill's FIRST live test (2026-07-09, run on the `_AI_SKILLS` project docs; run passed, edits were correct). Each item is small; do in any order.

## To-Do

### [ ] 1 — Handle docs the ownership map doesn't anticipate
The role→file map assumes GO_VIRAL-style filenames. Unmapped docs (e.g. `SKILLS-DESIGN.md`, `CLAUDE.md`) forced improvisation. Add one line: "unmapped doc → assign the nearest role, or mark it as a pointer doc and only verify its pointers."

### [ ] 2 — Encode the "owning doc is outside this repo" fallback
The relocation rule collides with "never delete a fact" when the owning doc lives in another project. Encode the fallback in the SKILL itself: leave a pointer in the cleaned doc, list the facts in the report for the caller to confirm/transcribe — never write into other projects' folders.

### [ ] 3 — Say what to do when no CHANGELOG exists
"Progress must not carry completed history" has no destination without a changelog. Add: "no changelog doc → keep a condensed recent-history list in Progress; do not create a CHANGELOG unless the user asks."

### [ ] 4 — Sharpen the condense-vs-delete boundary
Collapsing a 9-line entry to 1 line drops sub-facts (scores, paths). Add a test: a detail is CUTTABLE if it can be re-derived from git/code/the owning doc; otherwise it must MOVE, not vanish.

### [ ] 5 — Specify the report's anchor status for a dirty tree
Unclear whether the anchor line reports pre-edit or post-edit `git status`. Pick one (pre-edit) and say so.
