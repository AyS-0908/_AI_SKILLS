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

## Coding best practices

- **Node naming.** Short, unique, descriptive. Example: `Get User from Airtable`. For AI nodes, prefix `AI - <task>` (e.g., `AI - Classify Category`) so an LLM reading the workflow understands purpose.
- **Expressions over hardcoding.** `{{ $json.field }}`, `{{ $node["Name"].json.field }}`, `{{ $env.MY_VAR }}`.
- **Atomic nodes.** One logical task per node. No "API call + transform" combos.
- **Section labels.** Use Sticky Notes named `1 - Trigger`, `2 - Validate`, `3 - Process`, … for readability.
- **Centralize config early.** Put constants in a `Set` node near the trigger. Put tokens / URLs in env vars.
- **`continueOnFail` selectively.** Default `false`. Enable only when failure is expected AND handled downstream.
- **Native node shortlist.** Set / IF / Switch / Merge / built-in parsers before Function or Code.
- **Loops.** Use `Split In Batches`. Prefer bulk APIs over per-item calls.
- **Clean JSON for delivery.** No runtime-only fields (`id`, `createdAt`). Consistent indentation. No parameter noise.

## Known gotchas — high cost if missed

Cross-mode gotchas (Wait/HITL placement, LLM JSON parsing, MCP body check) live in [SKILL.md](SKILL.md) §Gotchas. Build-only additions:

- **HITL nodes invisible on the canvas?** Drop a Tools Agent node to trigger their loading.
- **Instruct LLMs to emit valid JSON**: double quotes only, no trailing commas, numbers unquoted, exact field casing (`spreadsheetId` not `SpreadsheetID`), matched brackets.
- **Preserve outer context inside loops.** When splitting a nested array, carry parent fields forward — e.g., `eventName` from the parent Webhook on every split child item.
- **Dot-notation auto-expansion.** Set / Function / Code nodes auto-expand a key like `"a.b": 1` into `{ a: { b: 1 } }`. If your keys legitimately contain dots, disable via the Set node's option `Support Dot Notation = false`.

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
