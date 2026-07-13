---
name: code-audit
description: >
  Audit startup-sized technical projects by orchestrating PRD/spec review, repo
  inventory, native checks, installed plugins/MCPs, and AI judgment, then emit a
  single verdict: Greenlight or a Fix Plan written into the project's
  implementation plan. Trigger for: explicit codebase/PRD audit
  requests, "deep audit", "review this implementation plan", "check delivery
  before final", phase-gate review after an implementation milestone, or final
  delivery readiness checks for SaaS, Apps Script, n8n, and small web apps. Do
  NOT trigger for ordinary code edits, simple bug fixes, PR-only review when a
  dedicated PR-review tool is requested, or enterprise/governance audits needing
  ERP-style controls.
---

# Audit-IT

## Gotchas

- File reads can be stale, empty, encoded oddly, or pointed at old paths. Verify live files first.
- MCP/plugin availability differs between Codex and Claude Code. Detect before relying on it.
- Native project commands may write files or need network. Ask for approval when the runtime requires it.
- Security tools and AI reviewers are assistive, not proof. Prefer deterministic evidence and label uncertainty.

## Role

Audit startup-sized technical projects for buildability, correctness, security basics, testability, maintainability, and PRD/code alignment.

Do not invent a full audit framework when native tooling already exists. Use this ladder:

1. Project-native commands and config.
2. Installed plugins/MCPs/skills.
3. Available but not installed specialist tools, as recommendations.
4. Small bundled scripts.
5. AI judgment.

## Modes

Choose the smallest mode that matches the request:

| Mode | Use When | Scope |
|---|---|---|
| `prd` | PRD/spec only | Buildability, missing flows, acceptance criteria, contradictions |
| `repo` | Codebase only | Inventory, commands, tests, dependencies, security basics, maintainability |
| `alignment` | PRD + code | Implemented / missing / contradictory / undocumented |
| `phase-gate` | After an implementation phase | Changed files + delivered plan slice only |
| `final-gate` | Before delivery | Full PRD + repo + alignment audit |

Default:
- Explicit "deep audit" -> `final-gate` when PRD and repo exist, otherwise `repo`.
- After each phase delivery -> `phase-gate`, not full audit.
- At the very end -> `final-gate`.
- Do not auto-run for every audit-ish word if the user only wants a normal code review.

## Outputs

The audit emits exactly one verdict — **Greenlight** or a **Fix Plan** — plus a short chat message. There is no separate report file.

**Greenlight** (no Tier 1 or Tier 2 findings): write nothing to disk. Tell the user in chat: verdict + one-sentence reason + the native checks that passed. Do not create an empty fixes section.

**Fix Plan** (any Tier 1/2 finding, or actionable Tier 3): write into the project's implementation plan, then point the coder at it.

1. Find the implementation plan: the existing `*plan*.md` in the project root (or nearest docs folder). If none exists, create `implementation_plan.md` in the project root.
2. Append (do not overwrite prior content) a section:
   - `## Audit fixes to implement — <YYYY-MM-DD>`
   - one `### [ref] <one-line title>` sub-section per fix, in the format under "Fix Plan Format" below.
3. In chat, point the coder at the plan (see "Final chat response").

## Workflow

### 1. Discover

Run `scripts/discover_repo.py <project_root>` when a repo is available.

Use its JSON output to identify:
- project type and package managers
- PRD/spec/docs candidates
- native commands: test, lint, typecheck, build, audit
- installed or declared framework tooling
- obvious risk files: env examples, auth, config, deployment, workflows

Also check current session capabilities:
- Codex: GitHub, n8n, Supabase, browser/chrome, PDF/docs plugins if exposed.
- Claude Code: Ponytail, security-guidance, PR Review Toolkit, LSP plugins if installed.
- CLI tools: `rg`, `git`, `gh`, project package manager, language-native tools.

Do not assume Semgrep, CodeQL, gitleaks, trufflehog, Snyk, or OSV Scanner exist. Detect them first.

### 2. Run Native Checks

Prefer commands already declared by the project:
- `npm test`, `npm run test`, `npm run lint`, `npm run typecheck`, `npm run build`
- Apps Script/clasp verification when `.clasp.json` or `.gs` files exist
- n8n MCP validation when auditing n8n workflows
- framework-specific checks only when already installed/configured

Record command, exit status, and the smallest useful error excerpt.

### 3. Use Specialist Lanes

Run only lanes that match the project and request:

| Lane | Reuse First | AI Focus |
|---|---|---|
| Security basics | GitHub CodeQL/Dependabot/secret scanning, Claude security-guidance, Codex Security if available | Trust boundaries, auth, secrets, injection, SSRF, IDOR |
| Tests | native tests/coverage, PR Review Toolkit if installed | Missing behavioral tests for critical flows |
| Error handling | native tests, PR Review Toolkit silent-failure lane if installed | Silent failures, swallowed errors, unsafe fallback |
| Code quality / optimization | Ponytail / ponytail-audit | Delete bloat, stdlib/native replacement, YAGNI, simpler code |
| n8n | official n8n skills + MCP | Workflow correctness, credentials, error paths |
| Apps Script | appscript skill + clasp/project verifier | Triggers, quotas, locks, PropertiesService, deployment |
| Data | Supabase/Postgres tools if project uses them | RLS, migrations, schema drift, unsafe queries |

Ponytail is not a security or correctness audit. Use it only for complexity reduction.
Do not drop Ponytail-style findings only because they are non-blocking. Put them in Tier 2 or Tier 3.

### 4. Audit PRD / Spec

Extract only what is needed:
- objective
- target user
- scope and non-goals
- critical flows
- data model / state
- auth and permissions
- external services
- error behavior
- acceptance criteria

Flag gaps only when they block implementation, validation, safe operation, or future changes.

### 5. Align PRD and Code

For each critical PRD flow, classify:
- `implemented`
- `missing`
- `partial`
- `contradicts_prd`
- `implemented_but_undocumented`
- `not_verifiable`

Use exact file paths, function names, workflow names, or config keys when possible.

### 6. Compile Findings

Classify findings:

| Tier | Meaning |
|---|---|
| Tier 1 | Blocking issue: must fix before commit/push/release |
| Tier 2 | Should-fix: code quality, robustness, scalability, security hygiene, testability, or maintainability issue that affects confidence |
| Tier 3 | Cleanup/optimization: non-blocking but useful for a clean codebase, including Ponytail simplifications |

Severity:
- `CRITICAL`: can cause data loss, security exposure, failed deployment, or unusable core flow
- `HIGH`: blocks reliable delivery or important implementation work
- `MEDIUM`: should fix soon but not blocking
- `LOW`: advisory

Every Tier 1 finding needs:
- evidence
- impact only if not obvious
- exact fix intent
- confidence

Every Tier 2 and Tier 3 finding needs the same fields only when actionable now.
Do not suppress Tier 2/3 because "the AI judged it secondary." The user wants a clean, robust codebase.
If a Tier 2/3 item is intentionally deferred, label it `DEFERRED_WITH_REASON`.
Do not write deferred items into the plan unless the AI coder must act on them in this pass.

## Fix Plan Format

On a Fix Plan verdict, append this to the implementation plan. Lead with a status line, then one sub-section per fix:

````markdown
## Audit fixes to implement — <YYYY-MM-DD>
BLOCKING_STATUS: BLOCKING | NON_BLOCKING
READINESS: NOT_READY | READY_WITH_FIXES
REASON: one sentence
NATIVE CHECKS: `command` PASS/FAIL/SKIPPED — smallest useful excerpt (one line each)

### A-001 | Tier 1 | HIGH | `path:line`
- issue: one sentence
- fix: one sentence
- test: smallest check that proves the fix

### A-002 | Tier 2 | MEDIUM | `path:line`
- issue: one sentence
- fix: one sentence
- test: smallest check that proves the fix
````

Hard output rules:
- Max 7 fix sub-sections. If there are more, keep the delivery blockers and add a one-line backlog note for the rest.
- Max 2 evidence refs per fix. Use the best `file:line` refs, not every supporting observation.
- Do not append PRD alignment tables, architecture assessments, robustness essays, coverage inventories, or live-smoke lists unless they create a fix.
- Do not include headings like `Concrete failure scenario`, `Minimal fix`, or `Smallest useful test`. Use `issue`, `fix`, and `test`.
- Native checks are command/result only. No interpretation paragraphs unless a failed check changes a fix.
- Tier 3 cleanup goes in the plan only when it should be done in this pass. Otherwise omit it.
- Do not overwrite the plan's existing content — append a new dated section each audit run.

Final chat response:

- **Greenlight:** `Greenlight — <one-sentence reason>. Native checks: <list>. Nothing to fix.`
- **Fix Plan:** `Fix Plan written to <plan path> (N fixes, M blocking). Give the AI coder this: implement the "Audit fixes to implement — <date>" section only, keep the diff minimal, and run the tests listed per fix.`

## Stop Rules

Stop and ask only when:
- the audit target is unclear and the wrong target would waste substantial time
- required files are missing
- a native command needs approval/network/write access
- security-sensitive credentials or production systems are involved

Otherwise make the conservative choice and proceed.
