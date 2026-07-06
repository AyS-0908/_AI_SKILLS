# Harness Protocol

## Path Aliases

| Alias | Path |
|---|---|
| `ROOT` | `C:\Users\aymar\AYS_CODING\_AI_AGENTS` |
| `TEMPLATES` | `ROOT\templates` |

## Harness Rules

- Default harness: AGENTS.md, ARCHITECTURE.md, PROGRESS.md
- Use path aliases.
- Use Markdown, not YAML.
- Prefer `WHEN / DO / DO NOT`.
- Keep rules short, routed, exact, non-repetitive.
- Before adding a rule, ask: delete, move to `usage_*`, shorten, or replace with pointer?

## Bootstrap Project Harness

| WHEN | DO | DO NOT |
|---|---|---|
| Project is missing `AGENTS.md`, `ARCHITECTURE.md`, or `PROGRESS.md` | Inspect the project first, then generate only missing files. | Do not overwrite existing files unless user explicitly asks. |
| `AGENTS.md` is missing | Read `TEMPLATES\project-agents-template.md`; create `AGENTS.md`. | - |
| `ARCHITECTURE.md` is missing | Read `TEMPLATES\project-architecture-template.md`; create `ARCHITECTURE.md`. | - |
| `PROGRESS.md` is missing | Read `TEMPLATES\project-progress-template.md`; create `PROGRESS.md`. | Do not create per-agent progress files. |
| Needed facts are missing | Ask only for missing facts. | Do not ask broad discovery questions. |
| Claude Code project has no `CLAUDE.md` | Create `CLAUDE.md` with exactly: `See [AGENTS.md](AGENTS.md) - single source of truth.` | Do not add Claude-only rules. |
| Bootstrap is complete | Return to `AGENTS-canonical.md` routing. | Do not keep reading bootstrap templates. |

## Optional Project Files

Create only when the trigger is real.

| File | WHEN | DO |
|---|---|---|
| `design.md` | Frontend or visual decisions matter. | Read `TEMPLATES\project-design-template.md`. |
| `features.md` | Scope or roadmap keeps drifting. | Record accepted scope only. |
| `decisions.md` | Architecture has multiple valid paths. | Record durable decisions. |
| `data_model.md` | Schemas, fields, entities, or formats drift. | Define the current model. |
| `api_contracts.md` | APIs or contracts are fragile. | Define inputs, outputs, and errors. |
| `scripts/check.md` | Verification is manual and no test/build command exists. | Record exact check steps. |
| `change_log.md` | `PROGRESS.md` completed history gets too long. | Move old done history there. |
| `.env.example` | Environment variables or secrets exist. | List variable names and safe examples. |