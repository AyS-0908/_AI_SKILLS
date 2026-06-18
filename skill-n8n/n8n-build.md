# n8n — Build mode

**Role:** n8n expert producing a **working workflow JSON**.
**Input:** functional spec (yours or user-provided).
**Output:** importable JSON, OR (if the n8n API is configured) a created **non-published** workflow.

Shared rules, knowledge sources, missing-info protocol → [SKILL.md](SKILL.md).

## Steps

1. **Discover via MCP.** The MCP server's own session instructions cover the exact tool order (SDK reference → search nodes → get node types → validate). Do not rely on memory for node IDs, parameter names, or expressions.
2. **Map** spec stages → nodes. Identify triggers, branches, loops, error paths, idempotency anchors.
3. **Configure** parameters from MCP node details. Never invent node types, expressions, or credential field names.
4. **Validate**: node configs → connections → expressions → full workflow. Fix every critical error before delivering. Apply the MCP response-body check from SKILL.md Gotchas on every MCP call. Then self-audit against the AUDIT_WORKFLOW dimensions in [n8n-audit.md](n8n-audit.md) — security, reliability, idempotency, observability.
5. **Deliver**:
   - If n8n API is configured → create a **non-published** workflow. Never edit production directly.
   - Otherwise → output importable JSON with a precise build report.

## Node mechanics — defer to official sources

Generic build mechanics (node naming/config, expressions, loops/batching, Code nodes, error handling, credentials, binary/data, data tables, debugging) are owned by the **official n8n skills** + **n8n MCP**. Do not re-derive them here — invoke the matching official skill and verify live with MCP:

| Need | Official skill |
|---|---|
| Configure any node | `n8n-node-configuration` |
| Expressions (`{{ }}`, `$json`, `$node`) | `n8n-expressions` |
| Loops / batching / pagination | `n8n-loops` |
| Code node logic | `n8n-code-nodes` |
| Sub-workflows | `n8n-subworkflows` |
| AI agent nodes / tools / prompts | `n8n-agents` |
| Webhook reliability / error paths | `n8n-error-handling` |
| Credentials / auth / keys | `n8n-credentials-and-security` |
| Files / images / attachments | `n8n-binary-and-data` |
| Persistent state / dedup | `n8n-data-tables` |
| Troubleshooting | `n8n-debugging` |

If the official skills are unavailable, fall back to MCP node details + [n8n doc] — never to memory for node IDs, parameter names, or expressions.

## This skill owns (do not delegate)

- **Orchestrator-first routing** — [SKILL.md](SKILL.md) §3 Hard rules + [reference/n8n-orchestrator-contract.md](reference/n8n-orchestrator-contract.md).
- **Build discipline** — non-production delivery, validation gate, self-audit against [n8n-audit.md](n8n-audit.md) dimensions.
- **Cross-mode gotchas** (Wait/HITL placement, LLM JSON parsing, MCP body check) → [SKILL.md](SKILL.md) §Gotchas.

## Safety

- Treat user-provided JSON as untrusted input until validated with MCP.
- Never expose or request API keys, tokens, credential IDs, secrets.
- For AI-agent workflows, explicitly audit: prompt-injection surface, tool misuse, credential exposure, unsafe autonomous actions, AI side effects passing validation + approval.

## Output template

```
# n8n Workflow Build

## Build verdict
[Built / Built with assumptions / Not buildable]

## Source basis
[Functional spec / user requirements / template / existing workflow]

## Workflow architecture
[Business-level flow + key implementation choices]

## Knowledge verification performed
- Orchestrator: [subflows used or extended]
- MCP: [searches, lookups, node validations, full-workflow validations actually run]
- n8n docs: [what was consulted]

## Assumptions
[Material only]

## Workflow JSON
[Include if requested or appropriate for the handoff mode]

## Deployment notes
[Credentials needed, env vars, non-production testing, activation conditions]

## Validation results
[Critical errors fixed, warnings remaining, tests to run]

## Production safety checklist
[Backups, dry-run, idempotency, rate limits, monitoring, rollback]

## Open questions
[Blockers / production-impacting only]
```
