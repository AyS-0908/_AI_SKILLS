---
name: ai-agent-harness
description: >
  Build, repair, or improve a portable AI-agent harness for a given role, topic,
  function, or domain such as HR Director, marketing director, CTO, doctor,
  lawyer, student, or teacher. Trigger for: requests to create a harness from
  scratch, define a reusable agent operating system, standardize agent context
  files, generate AGENTS.md / ARCHITECTURE.md / PROGRESS.md and scoped docs, or
  list customization questions for a harness. Do NOT trigger for ordinary
  one-off prompt writing, coding tasks inside an existing app, generic business
  strategy, or creating a Codex/Claude skill unless the user specifically asks
  for a harness-building skill.
---

# AI Agent Harness

## Gotchas

- File reads can point to stale paths. Reopen the live source files before using them.
- Internet/GitHub research can be unavailable or stale. If current research fails, say so and use local best practices as fallback.
- Do not copy a large framework blindly. A useful harness is small, scoped, and testable.
- Do not duplicate rules across files. One topic must have one owner file.

## Purpose

Build a minimal, deterministic harness that helps an AI agent work reliably for a specific user, role, or topic.

Default skill type: `GUIDED`.

## Output Rule

Produce the smallest complete harness that can pass one real use case.

Always separate:
- draft files to create;
- questions the user must answer;
- assumptions;
- next validation step.

## Workflow

### 1. Confirm The Harness Target

Ask only missing facts. Use options and a recommendation when useful.

Required answers:
- Topic or role: who the harness serves.
- User profile: beginner, expert, operator, manager, student, etc.
- Main objective: what the user wants the agent to help with.
- First real use case: one concrete task to test the harness.
- Risk level: low, medium, high.
- Source documents: none, existing files, web sources, business docs, legal/medical data, etc.
- Target runtime: Claude, Codex, ChatGPT, Gemini, Cursor, or portable across AI Agents.

If the user gives enough information, do not ask again. Proceed with labelled assumptions.

### 2. Research Current Harness Practices

Before drafting the standard architecture, check the most recent reliable sources available.

Priority:
1. Recognized GitHub repositories or official docs for major agent tools: OpenAI Codex, Anthropic Claude/Claude Code, Google Gemini CLI, GitHub Copilot/Coding Agent, Cursor, or similar.
2. Recent (2 months) threads on Reddit, X (ex-Twitter), or Linkedin
3. `illustration_*` files in `references/` (inside this skill folder).
4. Local proven harness if one exists.

Extract only reusable structural practices:
- context file names and scope;
- read-order patterns;
- safety and permission rules;
- progress or memory handling;
- skill or workflow triggers;
- validation patterns;
- anti-patterns to avoid.

Do not import tool-specific setup, secrets, deployment rules, or coding-only rules unless the harness topic needs them.

If live research is unavailable, state: `[SOURCE LIMITATION: current GitHub research unavailable; using local _AI_AGENTS best practices]`.

### 3. Select The Standard Architecture

Use this default architecture unless the topic proves it needs less or more:

```txt
AGENTS.md
CLAUDE.md                 optional pointer to AGENTS.md when Claude is used
ARCHITECTURE.md
PROGRESS.md
docs/access_rules.md
docs/project_context.md
docs/operating_principles.md
docs/document_inventory.md
docs/decision_log.md
.claude/skills/<first-use-case>/SKILL.md   only if Claude skills are useful
.claude/skills/<first-use-case>/references.md   optional
.claude/skills/<first-use-case>/templates.md    optional
```

Do not create optional files until a real need exists.

### 4. Define File Ownership

Use one owner per topic:

| Scope | Owner file |
|---|---|
| Routing, read order, precedence, verification | `AGENTS.md` |
| Components, ownership, data flow, constraints | `ARCHITECTURE.md` |
| Current objective, done, blocked, next action | `PROGRESS.md` |
| Access, approvals, sensitive data, external use | `docs/access_rules.md` |
| User, role, organization, facts, assumptions, unknowns | `docs/project_context.md` |
| Thinking style, challenge style, writing style | `docs/operating_principles.md` |
| Business/source documents and status | `docs/document_inventory.md` |
| Durable decisions that change harness behavior | `docs/decision_log.md` |
| Repeatable use-case workflow | `.claude/skills/<first-use-case>/SKILL.md` |
| Benchmarks and inspiration | `references.md` |
| Repeatable output structures | `templates.md` |

If two files would say the same rule, keep it only in the owner file and point to it elsewhere.

### 5. Draft The Standard Files

Draft each file with minimal content customized to the user.

Rules:
- Keep `AGENTS.md` as a router, not a manual.
- Keep `ARCHITECTURE.md` as a map, not a rulebook.
- Keep `PROGRESS.md` as current state, not full history.
- Keep `access_rules.md` strict for high-risk domains: legal, medical, HR, finance, children, personal data.
- Keep `project_context.md` factual. Separate facts, assumptions, and unknowns.
- Keep `operating_principles.md` about behavior and style.
- Keep `document_inventory.md` free of machine-specific local paths.
- Keep `decision_log.md` for durable decisions only.
- Keep the first skill focused on one use case.

AI-native structure:
- short headings;
- bullets and tables;
- explicit IF/THEN rules where decisions branch;
- exact read order;
- exact owner files;
- no long prose;
- no hidden conditional rules in paragraphs.

### 6. Generate Customization Questions

After the draft, list all questions the user should answer to customize each document.

Format:
```txt
## <file>
1. <question>
   Options: <A> / <B> / <C>
   Reco: <recommended option> because <short reason>
```

Question areas:
- user goal;
- first use case;
- scope boundaries;
- sensitive data;
- approval rules;
- source documents;
- tone and challenge level;
- output formats;
- validation method;
- durable decisions;
- future skills.

Ask only questions that change the harness. Skip curiosity questions.

### 7. Validate With One Real Use Case

Run or simulate the first real prompt.

Check:
- Did the agent read the right docs?
- Did it avoid unauthorized sources?
- Did it ask only missing questions?
- Did it use options and recommendations?
- Did it challenge weak assumptions?
- Did it produce a useful next step?
- Did it avoid duplicated rules?

Patch only the file that owns the failed behavior.

### 8. Expand Only After Validation

Add a second skill or optional document only when:
- the first use case works;
- the new use case repeats often;
- the owner file cannot handle it cleanly.

Default next step:
- add one use-case skill;
- update `PROGRESS.md`;
- record a decision only if harness behavior changed.

## Best Practices To Retain From `_AI_AGENTS`

Use these by default:
- ask only missing facts;
- give options plus a recommendation;
- read extra docs only when relevant;
- keep one source of truth per rule;
- use `PROGRESS.md` as shared project memory;
- update progress before stopping meaningful work;
- add optional docs only when justified;
- challenge overbuilt plans;
- verify against a real use case;
- keep local paths out of portable harness instructions.

## Anti-Patterns

Avoid:
- full libraries of skills before the first use case works;
- separate memory files per agent;
- copied rules across docs;
- vague values, slogans, or principles with no behavior;
- external research presented as current without checking;
- high-risk advice without approval and boundaries;
- technical jargon for non-technical users.

## Final Deliverable

Return:
1. Draft harness file tree.
2. Draft content for each standard file.
3. Customization questions by file.
4. First validation prompt.
5. Minimal next action.

If writing files, create only the files needed for the validated V1 harness.
