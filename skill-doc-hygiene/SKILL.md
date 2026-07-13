---
name: doc-hygiene
description: >-
  Run a repeatable content-hygiene pass over a project's OWN docs
  (agents / prd / architecture / plan / progress / changelog): build a
  current-reality model from the code + git anchor first, then clean each doc
  in trust order — cut stale, obvious, or duplicated lines, reconcile against
  the anchor and higher-trust docs, move every off-topic fact to its owning
  doc, and emit one fixed report. The route is deterministic; the cleaning is
  judgment. Trigger for: "clean / tidy / prune / dedupe / reconcile the project
  docs", a daily or recurring doc-hygiene pass, "my docs have gone stale or
  contradict each other", "progress / changelog / plan drifted from the code".
  Do NOT trigger for: readiness or quality audits and fix plans (use code-audit),
  memory-file consolidation (use consolidate-memory), moving / renaming /
  deduping FILES or folder reorganization (use folder-cleaning), or writing
  brand-new docs from scratch (use ai-agent-harness).
---

# Doc hygiene

Deterministic ROUTE (which docs, what order, what each doc may own, the fixed
report) + judgment CLEANING (is this line still useful to an AI coder? does it
contradict / duplicate / belong in another doc?). Skill type: **RIGID route,
heuristic per-doc work** — the route is written-down rules; the cleaning cannot
be scripted.

Run standalone? The fixed report (§6) is the done-bar; for higher assurance have
a FRESH context verify the applied diff (as code-audit-loop does with its auditor).

## Gotchas

- File reads can be stale, empty, or wrongly encoded. Read the LIVE file before judging it — never clean from memory.
- The code + git state is the ground truth, not any doc. When a doc and the code disagree on a STATE fact, the doc is the suspect.
- Not a git repo, or no doc set found → say so and stop. Do not invent docs or an ownership map.
- A cross-reference (`[SSOT-x]`, `path.md §4`, `[[link]]`, a file path) may point at something moved or deleted. A broken ref is a finding, not a fact to trust.
- Never DELETE a fact. Cutting a stale or trivially-inferable LINE is fine; a still-true fact only MOVES to its owner (leaving a pointer) or gets FLAGGED. Unsure if something is still true, or was intentionally omitted → FLAG, don't decide.
- Default to REPORT-ONLY (dry-run). Make edits only when the request says clean / apply / fix.

## 1. Anchor, then route (trust-descending)

**ANCHOR (read-only ground truth — build the "current reality" model from this FIRST, before opening any doc):**
- `git status` (is the tree dirty?), `git diff` / `git log --oneline -10` (what actually changed recently).
- the code itself for any doc claim it can confirm: test / suite / harness counts, module / tool counts, file & symbol names, versions, feature flags.
- Record reality as a short fact list. Every STATE claim in a doc is checked against it.

**Then clean docs in descending recency-of-trust** (most-current-truth first). Each doc is reconciled against (a) the anchor and (b) the already-finalized higher-trust docs above it:

`progress → changelog → plan → architecture → prd → agents`

**CONTRADICTION RULE — trust flips by FACT TYPE, not by position in the route:**
- **STATE fact** (status / shipped / current step / counts): the newest doc or the code wins → fix the stale one.
- **INTENT or RULE fact** (product goal / design decision / operating rule): the canonical owner (agents, prd, architecture) wins → if the CODE drifted from it, FLAG the code; do NOT edit the doc to match a drifted implementation.

## 2. Ownership map (the core artifact — every fact has exactly one owning doc)

Concrete files below = `code-GO_VIRAL`. In another repo, map each ROLE to its file and skip roles with no doc.

Unmapped doc (no matching role, e.g. `SKILLS-DESIGN.md`, `CLAUDE.md`) → assign the nearest role and clean under it, OR mark it a pointer doc and only verify its pointers resolve.

| Role → file | Owns | Must NOT contain |
|---|---|---|
| agents → `AGENTS.md` | routing, project rules, commands, gotchas, verification pointers | live state, detailed specs, phase history, implementation narrative |
| prd → `goviral_prd_module_1.md` | scope + build/spec SSOT: entities, schema, statuses, endpoints, prompts, invariants (`[SSOT-*]`) | build order, current state, history, roadmap |
| architecture → `ARCHITECTURE.md` | system boundaries, modules, data flow, layering, state ownership | routing, current state, full rules/schemas, build order, roadmap, history |
| plan → `goviral_plan_module_1.md` | implementation order, phase build rules, the open `[PLAN-todo]` queue | completed-work narrative, current state, product rules |
| progress → `PROGRESS.md` | live state, current objective, next action, verification, open risks/decisions, rollout | build narratives + completed history, the full plan, product rules |
| changelog → `CHANGELOG.md` | completed changes / audit-history trail (per pass) | live state, future plans |
| (vision → `goviral_vision.md`) | suite vision + roadmap / product direction | module build specifics, current state |

No changelog doc in the repo → keep a condensed recent-history list in progress; do NOT create a CHANGELOG unless the user asks.

Each doc here already self-declares its boundary (`ARCHITECTURE.md` "Do not put here", `PROGRESS.md` "Update Rule", `AGENTS.md` "File scope"). Treat that as the authoritative owner test: a line that violates the doc's own stated scope is a scope violation, not a judgment call.

## 3. Per-doc two-pass loop

For each doc, in route order:

**Pass A — in-doc (tighten):**
- cut content the anchor proves stale or wrong (fix a STATE fact; FLAG a drifted RULE fact per the contradiction rule).
- cut lines an AI coder can trivially infer, or that restate a neighboring line (obvious / low-value).
- CUTTABLE test: a detail (score, path, sub-fact) is cuttable ONLY if re-derivable from git / code / the owning doc; otherwise it MOVES, never vanishes.
- cut in-doc redundancy (the same fact stated twice).
- tighten to AI-native terse style: brief, factual, no marketing or narration.

**Pass B — cross-doc (place):**
- flag anything that contradicts or duplicates another doc.
- for every fact outside this doc's "Owns" column → MOVE it to its owner, leaving a one-line pointer (`see <owner> §x`).
- a fact duplicated across two docs → keep it in the owner; replace the other copy with a pointer.

## 4. Deterministic scan checklist (run these explicitly, every doc, every run)

Mechanical / greppable — done every run so nothing is silently skipped:
- duplicate headings or repeated blocks.
- stale-word markers: `TBD`, `TODO`, `deprecated`, `previously`, `old`, `for now`, `maybe`, `~~strikethrough~~`, a "Last updated" date older than recent commits.
- broken references: file paths, `§` / heading anchors, `[SSOT-*]` / `[PLAN-*]` / `[[links]]` that don't resolve.
- verbosity outliers: paragraphs or lines far longer than the doc's norm (e.g. a current-state doc carrying a multi-paragraph build narrative).
- scope violations vs the ownership map (including each doc's self-declared "do not put here").
- drift vs reality: `git diff` / `git status` and doc counts / claims vs the code anchor.
- self-written pointers (APPLY mode, after all edits): re-run the broken-reference scan on every pointer THIS pass wrote — confirm each `§ heading` and `[file]` target actually exists. The pass must not introduce the very defect it hunts.
- whole-file removal candidates (final step): a task-scoped file whose task is closed and nothing references it. REPORT-ONLY — one line each (file + why + instruction to the user). On user OK only: MOVE to `_to_delete_<DATE>\` inside the project folder; never rename in place, never delete outright.

These are scriptable but deliberately NOT scripted (prompt-only MVP). Add a `scan.ps1` only if a run shows these checks being skipped or applied inconsistently.

## 5. Guardrails (never simplify these away)

- **Never DELETE a fact.** Cut stale / obvious LINES; a true fact only MOVES (with a pointer) or gets FLAGGED.
- **Owning doc is outside this repo.** Do NOT write into another project's folder. Leave a pointer in the cleaned doc + list the facts in the report for the caller to confirm / transcribe.
- **One fact, one doc.** No fact in two docs unless one copy is a pointer.
- Keep each doc focused on its "Owns" scope.
- **Do NOT auto-resolve these — list them for the user instead:**
  - "is this line still useful?" when genuinely ambiguous.
  - a suspected contradiction you cannot confirm from the anchor.
  - whether a missing detail was intentionally omitted vs lost.
  - any STATE count you cannot verify without running the suite (name the command that would settle it).

## 6. Fixed output report (identical every run)

Header line: `MODE: DRY-RUN (report only)` **or** `MODE: APPLY (edits made)` · anchor one-liner (branch · dirty? · latest commit) — reports the PRE-edit `git status`.

Then exactly these five sections:

- **Per doc** — one compact block per file: `<file>` → what changed (or WOULD change) and why; one bullet per item.
- **Unresolved — needs your decision** — contradictions + judgment calls from the Guardrails, numbered. If none, say "none".
- **Facts moved** — `fact — <from> → <to>`, one line each.
- **Whole-file removal candidates** — one line each (file + why + instruction to the user); MOVE to `_to_delete_<DATE>\` on user OK only. If none, say "none".
- **Anchor check** — `git diff --check` result + `git status` (short) + any doc-vs-code drift found.
