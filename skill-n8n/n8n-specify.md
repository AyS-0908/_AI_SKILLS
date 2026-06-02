# n8n — Specify mode

**Role:** n8n expert producing a **Functional Specification only**.
**Input:** requirement for a new workflow.
**Output:** implementation-ready spec — no JSON, no node-by-node prescription.

Shared rules, knowledge sources, source labels, missing-info protocol → [SKILL.md](SKILL.md).

## Steps

1. **Match an archetype** to frame the spec:
   - Linear: trigger → process → output
   - Multi-branch decision
   - Batch processing
   - Integration / enrichment
   - Approval / human-in-the-loop
   - AI classification / extraction / generation
   - Error notification
   - Scheduled synchronization
   - Webhook intake + response
2. **Check the orchestrator.** If the capability fits `search | publish | create | message`, the spec must route or extend the orchestrator, not propose a new top-level workflow. See decision matrix in [reference/n8n-orchestrator-contract.md](reference/n8n-orchestrator-contract.md).
3. **Draft** the spec using the template below.
4. **Self-audit** against the Specification review checklist in [n8n-audit.md](n8n-audit.md). Fix gaps before delivering.

## Specify these things — drop the rest

- **Functional intent** — business outcome, scope, non-goals.
- **Data contract between stages** — what each stage receives and returns.
- **Decision criteria** — what makes a branch take path A vs B.
- **Success and failure definitions** — measurable.
- **Idempotency** — required for any workflow that creates, sends, updates, or charges anything.
- **Human review points** — where uncertainty or risk is high.
- **AI tasks** (if any): task definition, allowed input sources, expected output shape, confidence/validation rules, fallback, HITL trigger condition.

## Do NOT include in a spec

- n8n workflow JSON
- Node type names presented as authoritative requirements
- Exact package names, credential IDs, model names, expression syntax (all volatile — leave to live MCP at build time)
- Implementation details that MCP / docs should decide

## Anti-patterns to avoid in the spec

| ❌ Vague | ✅ Specific |
|---|---|
| "Get data from Google Sheets" | "Monitor sheet 'Leads' for new rows. Read columns A–E (name, email, phone, company, status). Filter `status = 'new'`." |
| "Process some data and send it somewhere" | "Extract `name`, `email`, `phone` from webhook payload. Validate email format. Create contact in HubSpot." |
| "Handle errors" | "On API failure: retry 3× with 5s delay. Then log to sheet 'errors' and alert Slack `#alerts`." |
| "Code a custom form for user validation" | "Use the n8n Human-in-the-Loop 'Form' node with fields X, Y, Z." |

## Output template

```
# n8n Functional Specification

## Build-readiness verdict
[Ready / Ready with assumptions / Not ready — one short reason]

## Workflow objective
[Business outcome, scope, non-goals]

## Trigger and start condition
[What starts it and under what conditions]

## Inputs and data contract
[Required + optional inputs, expected shape, validation rules, examples if available]

## Processing stages
[Business-purpose stages — not node-by-node. AI / HITL requirements inline if any]

## Synergies with n8n Orchestrator
[Sub-flows to reuse OR candidate for becoming a reusable sub-flow]

## External systems and access needs
[Systems + functional access description — no credential IDs, no auth field names]

## Field mappings and transformations
[Important mappings, formatting, calculations, normalization, enrichment, validation]

## Branching, looping, volume
[Decisions, routes, approvals, batching, pagination, expected volume, rate-limit sensitivity]

## Reliability, errors, idempotency
[Retries, fallbacks, duplicate prevention, partial failure, safe-stop, alerting]

## Security, privacy, compliance
[Sensitive data, access limits, retention, redaction, unsafe-action confirmations]

## Storage / configuration
[Tables, registries, config that must persist between runs — only if relevant]

## Observability / logging
[What to log, where, retention — only if relevant]

## Outputs and success criteria
[Final destination, format, success conditions, measurable completion]

## Test cases
[Happy path, edge cases, failure, duplicate, invalid input — only relevant ones]

## Assumptions and open questions
[Material only]

## Implementation notes requiring live verification
[Volatile n8n / integration details to verify with MCP at build time]
```

Drop any section that adds no value for the specific workflow. Better empty than padded.
