---
name: n8n
description: |
  Specify, build, or audit n8n workflows for a non-technical user.
  Trigger for: requests mentioning n8n, the user's n8n orchestrator, or asking to design / implement / review an n8n automation.
  Do NOT trigger for: other automation platforms (Make, Zapier, Power Automate, Airflow), generic "workflow" questions unrelated to n8n, or pure n8n usage questions answerable by docs alone (e.g., "what does the Set node do?").
status: active
---

# n8n Skill — Entry

## Gotchas — read before any mode

- **Wait / Human-in-the-Loop nodes must live in the main workflow**, never inside a called sub-workflow. Sub-workflows with wait nodes do not return data to the parent.
- **Orchestrator round-trips (send a message → get a human's reply back) do NOT need an async gateway.** Recurring question; the answer is always the same: gateway stays synchronous. Outbound = a `message` send branch. Inbound reply = a SEPARATE trigger workflow + a domain-owned state table + a `message_poll`-style `search` op (the video `start → poll` pattern). Native "Send and Wait for Response" only inside a standalone triggered workflow, never a called subflow. Never rebuild the gateway async to solve this — the inbound event still needs a trigger + state. Detail in `[n8n orchestrator]` contract §"Round-trips / inbound events".
- **LLM JSON output is a string until parsed.** Always wrap `JSON.parse()` in `try / catch`.
- **n8n MCP can return `200 OK` with `success:false` (or `error`) in the body.** Check the response body, not the status code, before treating a call as valid.
- **Mode-specific gotchas:** see Build mode "Known gotchas" in [n8n-build.md](n8n-build.md).

## 1. Mode router — pick ONE, never blend deliverables

| User verb / intent | Open this file | Single deliverable |
|---|---|---|
| specify, scope, design, plan | [n8n-specify.md](n8n-specify.md) | Functional Specification (no JSON) |
| build, implement, code, generate | [n8n-build.md](n8n-build.md) | Working n8n workflow JSON |
| audit, review, analyse, critique, challenge | [n8n-audit.md](n8n-audit.md) | Review only (no spec, no JSON) |

If intent is ambiguous, ask the user which one. Do not pick two.

## 2. Knowledge sources — priority order, cite inline

This skill is the **governance layer**. Node build mechanics belong to the official n8n skills + MCP — defer, do not duplicate.

| Tag to use | Source | When |
|---|---|---|
| `[n8n orchestrator]` | [reference/n8n-orchestrator-contract.md](reference/n8n-orchestrator-contract.md) | Always — read before any design touching `search` / `publish` / `create` / `message` |
| `[n8n skill]` | official n8n skills (`n8n-node-configuration`, `n8n-expressions`, `n8n-loops`, `n8n-code-nodes`, `n8n-error-handling`, `n8n-credentials-and-security`, `n8n-binary-and-data`, `n8n-data-tables`, `n8n-subworkflows`, `n8n-agents`, `n8n-debugging`) | Any node-level build mechanics — table in [n8n-build.md](n8n-build.md) |
| `[n8n MCP]` | `mcp__*_n8n__*` tools | Volatile live facts: node names, parameters, expressions, validation, templates. Authoritative over skill text |
| `[n8n doc]` | https://docs.n8n.io/ | Standard concepts (triggers, expressions, item model) |
| `[internal memory]` | cross-session preferences | Only if previously saved |

Never cite a source you did not actually consult.

## 3. Hard rules — apply to all modes

- **Orchestrator first.** If the capability fits `search` / `publish` / `create` / `message`, route through the orchestrator or extend it additively. Never build a parallel top-level workflow. Decision matrix in [reference/n8n-orchestrator-contract.md](reference/n8n-orchestrator-contract.md) §"USE FULLY / PARTIALLY / NOT".
- **Risky operations** (`publish | post | deploy | delete | paid_ai_generation | restricted_extract | send`) require the two-call confirm pattern and respect `dry_run`.
- **Durable over volatile.** Business behavior, data contracts, decisions, validation criteria are durable. Node configuration is volatile → MCP-verify live or label `[ASSUMPTION: …]`.
- **No false verification.** Never claim MCP / doc / execution checks that did not happen.
- **No secrets.** Never request or print API keys, tokens, credential IDs, or private URLs. Describe access functionally.
- **No over-engineering.** Every step must have a business rationale AND a technical rationale ("why"). If you cannot state both, cut it.
- **Modern n8n only.** Prefer current built-in nodes over custom code or outdated patterns. Example: use the Human-in-the-Loop "Form" node, not a custom form coded in a Function node.
- **Separation of concerns.** Specify produces no JSON. Audit produces no spec or JSON. Build produces JSON.
- **Missing-info protocol.**
  - Critical missing → output exactly: `[MISSING INFO.: <what>]`
  - Non-critical → proceed and label: `[ASSUMPTION: <what>]`

## 4. Communication style

User is non-technical. Plain words. Headers + bullets. Short direct sentences. No trailing summary. No emojis unless asked. For exploratory questions: recommendation + main trade-off in 2–3 sentences — no implementation until agreed.
