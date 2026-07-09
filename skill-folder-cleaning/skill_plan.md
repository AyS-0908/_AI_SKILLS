# Skill Plan — folder-cleaning

**What this is:** the open to-do for the `folder-cleaning` skill, written so a fresh AI session can run each item on its own. Do them in order.

**Effort scale:** 2 = medium · 3 = high · 4 = xhigh · 5 = max. (1 = never used.)

---

## Rough edges found during live use

### [x] 1 — No `.git` / VCS / dev-metadata exclusion (HIGH — found on AI4CEO, 2026-07-09) — FIXED 2026-07-09
**Done:** `organization.scan_exclude_dirs` added to `config.json` (`.git`, `node_modules`, `.venv`, `__pycache__`, `.idea`, `.vs`); Phase2-Inventory filters by directory name at any depth (also catches a `.git` FILE — submodule/worktree pointer); regression asserts added to the default-output test; SKILL.md documents the default. All 14 test groups pass.
**Symptom:** ran the skill on a git-tracked project (`code-AI4CEO`, 6 real files). Phase 2 inventory scanned the `.git` tree and reported **46 files / 24 folders** — 38 of the 46 were git plumbing (`.git\objects\*`, `.git\hooks\*.sample`, `.git\refs\*`, `.git\logs\*`). The **2 "exact-duplicate groups"** it flagged were both normal git state, not clutter:
- `d001` = `.git\refs\heads\main` ≡ `.git\refs\remotes\origin\main` (local == remote ref)
- `d002` = `.git\logs\HEAD` ≡ `.git\logs\refs\heads\main` (reflog)

**Why it matters:**
1. **Waste** — host-analysis batches would ask the LLM to summarize dozens of binary git objects and sample hooks. Meaningless tokens.
2. **Danger** — the plan/apply phases could propose a `move`/`rename`/`archive` on a git internal. Applying that corrupts the repo. `.git` must be untouchable, not merely "protected on request."
3. **Wrong signal** — a clean 6-file repo looks like a 46-file mess with duplicates.

**Fix:** add a default scan-exclusion list in `config.json` (sibling to `artifacts_dir`), excluded the same way `_DATA_CLEANING` already is in `Phase2-Inventory.ps1`. Minimum set: `.git`, `.github` is debatable (it holds real workflow files — keep it IN, exclude only `.git`). Also reasonable to add: `node_modules`, `.venv`, `__pycache__`, `.idea`, `.vs`. Keep it a config array so it is tunable. Do NOT hard-code in the scan loop.
**Run on:** best-1 @ 3/5 (touches deterministic scan + apply safety).

### [x] 2 — `context.json` has no exclude channel, only `protected_items` — MOOT 2026-07-09 (item 1 excludes at scan time)
**Symptom:** once the manifest already contains `.git` files, the only lever the host has is `protected_items` (protect name + location = keep in place). There is no "drop from consideration entirely" input. So even the workaround is verbose (list every git path) and still leaves them in host-analysis batches.
**Fix:** if item 1 excludes at scan time this is moot. Otherwise add an `exclude_paths` array to the `context.json` contract that removes IDs from host submission. Prefer fixing at item 1.
**Run on:** best-1 @ 2/5.

---

## Notes for whoever picks this up
- Reproduce: `pwsh run-folder-cleaning.ps1 -SourcePath <any git repo>` and read `manifest.json.folders` — you'll see the `.git` subtree.
- The skill is otherwise sound on this run: preflight passed, in-source artifacts correctly written under `_DATA_CLEANING` and self-excluded, `desktop.ini` correctly inventoried (it's already gitignored at the project level).
