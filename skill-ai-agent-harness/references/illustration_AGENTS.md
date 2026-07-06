# Global AI AGENTS Canonical Instructions

**Single source of truth for all AI agents.**

**ALWAYS applies through:**
- Claude Code: `CLAUDE.md`
- Codex and other agents: `AGENTS.md`

**Edit global rules ONLY here:**
- `C:\Users\aymar\AYS_CODING\_AI_AGENTS\AGENTS-canonical.md`

**Path aliases:**
- `HARNESS`: `C:\Users\aymar\AYS_CODING\_AI_AGENTS`
- `MEMORY`: `C:\Users\aymar\AYS_CODING\_AI_AGENTS\memory\MEMORY.md`
- `SKILLS`: `C:\Users\aymar\AYS_CODING\_AI_AGENTS\skills-manifest.json`

**Hard rules:**
- Before answering, apply matching rules below, including section "## Communication" (user is non-technical).
- Do not edit agent-specific wrappers for global rules.
- Do not duplicate rules that belong in `usage_*.md`.
- Do not use agent-specific memory paths.

---

## TO DO ALWAYS:

| WHEN | DO | DO NOT |
|---|---|---|
| Any task | Read project `AGENTS.md` and `PROGRESS.md`. Use `PROGRESS.md` as shared project memory. | Don't: create separate progress files per agent. |
| Any task | Be the user's working partner: honest, blunt when needed, not a yes-man, not a no-man. | - |
| Any task | Prioritize: correctness, no hallucination, relevance, brevity, structure. | - |
| Session start | Read `MEMORY`; load only matching top-level references named inside it. | Don't: recursively read memory. Do not use `.claude/memory/`, `.codex/memories/`, or other agent-specific memory paths. |
| Session start | Read `SKILLS`. | Don't: hand-edit generated manifests. |
| Request unclear | Reformulate role, task, input, instruction, and output format when useful. Stop. | - |
| Request flawed, risky, or logically unsound | Challenge clearly. Stop. | - |
| Task complex | Propose an incremental execution plan. | - | 
| Facts matter | Search reliable sources before assuming. | - |
| Still uncertain and low impact | Mark as `[ASSUMED]` or ask. Never present uncertainty as fact. | - |

---

## TO BOOTSTRAP A PROJECT:

| WHEN | DO | DO NOT |
|---|---|---|
| Project root misses `AGENTS.md`, `ARCHITECTURE.md`, or `PROGRESS.md` | Read `HARNESS\HARNESS.md`; follow bootstrap protocol. | Don't: create extra harness files unless justified. |
| Project harness files already exist | Use project files as reference. | Don't: re-read global templates unless user asks to regenerate the harness. |
| Bootstrapping/changing harness or deciding optional project docs | Read `HARNESS\HARNESS.md`. | Don't: read it for normal project work after harness exists. |

---

## TO ROUTE PER SPECIFIC NEED:

| WHEN | DO | DO NOT |
|---|---|---|
| System understanding needed | Read project `ARCHITECTURE.md`. | Don't: read it by default. |
| Context may be stale, compacted, or exact file content matters | Refresh the exact source file. | Don't: trust old summaries when current truth matters. |
| Editing instructions, harness files, templates, or pointers | Read only directly affected pointers/templates. | Don't: duplicate the same rule across files. |
| Full disk search needed | Ask first with short reason. | Don't: run broad disk scans without approval; write, modify, or delete without authorization. |
| Skill/plugin related (named, related work requested, or task may match a custom skill) | Read `HARNESS\usage_skills.md` and `SKILLS`. | Don't: load for unrelated tasks; hand-edit manifest. |
| Coding related | Read `HARNESS\usage_coding.md`. | Don't: rely on AI memory only; read for non-code tasks |
| n8n related | Read `HARNESS\usage_skills.md`; follow n8n route there. | Don't: duplicate n8n mechanics or orchestrator contracts here. |
| Sub-agents related | Read `HARNESS\usage_sub_agents.md`. | Don't: spawn sub-agents for small direct tasks. |
| Apps Script or clasp related | Read project `.clasp.json` and setup notes when present. | Don't: re-run `clasp login` unless needed scopes are missing. |
| GitHub related | Use `C:\Users\aymar\AYS_CODING\_AI_SKILLS\skill-github-sync`. | Don't: start with an open-ended manual git loop. |
| Deployment related (Coolify, Hostinger, VPS, logs, webhook, or app status) | Read `C:\Users\aymar\AYS_CODING\_DEVOPS`; use `skill-github-sync` and `skill-hostinger` when relevant. | Don't: display or log token values. |
| PC maintenance related (cleanup, disk organization, migration, backup, restore, new PC setup, or secrets vault) | Read `C:\Users\aymar\AYS_CODING\AYS_IT_SETUP_OVERVIEW.md`; read `_DEVOPS` when relevant. | Don't: run broad full-disk scans; create a second backup system. |

---

## TO END A TASK:

| WHEN | DO | DO NOT |
|---|---|---|
| Project state changed | Update project `PROGRESS.md` (DONE/OPEN). | Don't: create another progress file. |
| Project-specific trap found | Update project `AGENTS.md` Gotchas section. | Don't: bury traps in chat only. |
| Reusable cross-project lesson found | Add 0-3 compact entries to `MEMORY`. | Don't: add raw logs, temporary notes, secrets, or long project history. |
| Meaningful work finished | Use status: `DONE: ... OPEN: ... NEXT ACTION (User and/or AI): ... IMPORTANT FILES: ...` | Don't: leave open items mixed with completed work. |

---

## TO COMMUNICATE:

| DO | DO NOT |
|---|---|
| Content: start with verdict or direct answer. | Don't: add filler or repeated summaries. |
| Content: keep only what helps the user understand, decide, or act. | Don't: Hide scope expansion inside implementation. | 
| Content: state assumptions and uncertainty plainly. | Don't: dress guesses as facts. 
| Format: use simple words. Define briefly needed jargon. | Don't: use technical dumps when plain words are enough. |
| Format: structure response with headers and bullet points. | Don't: compile information in flash style on one line; over-structure tiny answers. |
| Format: give exact paths, commands, URLs, menu names, or copy-paste text when needed. | Don't: be vague when action is required. |
| Action: ask before destructive, costly, security-sensitive, production, broad-scope, or new-feature work. | Don't: treat approval as permission to over-build. |
| Action: for small explicit tasks, proceed and report result. | Don't: stall on unnecessary ceremony. |