# n8n Orchestrator — Contract

Factual reference for the user's existing orchestrator (single webhook entry point fronting registered sub-workflows). Read before any design or audit that touches `search | publish | create | message`.

---

## DECISION — Use orchestrator or not?

### USE FULLY — call the orchestrator gateway

```yaml
trigger_when_ALL_true:
  - workflow needs capability already in registered routes: search | publish | create | message
  - operation = one of:
      search:  [web_search, linkedin_fetch, reddit_fetch]
      publish: [linkedin_draft, linkedin_publish_after_approval]
      create:  [text_generation]
      message: [email_send]
  - caller is a registered project with api_key
  - one service per request
  - sync response acceptable (no callbacks, no async)
  - body <= 1MB, files passed by reference (<=20 refs)
```

### USE PARTIALLY — extend the orchestrator, do not bypass it

```yaml
extend_when:
  - new capability fits an existing route family (search/publish/create/message)
    → add a Switch branch INSIDE the existing domain subflow
    → do NOT create a new top-level workflow

  - new connector is shared by >=2 domain subflows
    → extract it as its own workflow, called from the subflows

  - new internal validation/review needed inside a subflow
    → additive only; MUST NOT bypass master confirm/dry-run/policy
```

### DO NOT USE — build a standalone n8n workflow

```yaml
skip_orchestrator_when_ANY_true:
  - capability belongs to a deferred route (rag, deployer, agents_ia)
    → would return unknown_subflow

  - workflow is internal-only, single trusted user, no credential isolation needed

  - requires multi-service in one request (v1 rejects this)

  - requires async / callback_url / job polling (not v1)

  - raw file upload required (not allowed)

  - retention > 365 days, or volume above migration thresholds
      (>50k req/mo, >250k audit, >100k idempotency, latency >2s)
```

---

## HOW TO CALL — caller side

### Request shape

```json
{
  "request_id": "<unique per intended side effect>",
  "project": "<registered_project_id>",
  "subflow_id": "search | publish | create | message",
  "operation": "<allowed operation for that route>",
  "payload": {
    "...": "operation-specific",
    "confirm": true
  },
  "api_version": "v1",
  "service": null,
  "options": {
    "dry_run": false
  }
}
```

### Caller MUST NOT include

- API keys, tokens, secrets
- n8n credential IDs, workflow IDs, node parameters
- Executable code
- `callback_url` or async fields
- More than one service

### request_id rule

- Unique per intended side effect
- Reuse = deliberate retry
- Idempotency key = `(project, request_id)`

---

## RISKY OPERATIONS — two-call confirm

Operations: `publish`, `post`, `deploy`, `delete`, `paid_ai_generation`, `restricted_extract`, `send`.

### Call 1 — without `confirm`

Response:
```json
{ "status": "pending_validation" }
```
Contains `planned_action` and `approval_required`. No side effect.

### Call 2 — same `request_id`, `payload.confirm = true`

- Executes for real.
- Duplicate detection returns previous result if already completed.

### Dry-run

```yaml
options.dry_run = true
```
Behavior:
- Validates request
- Returns `planned_action`
- No side effect

Mandatory for risky ops on first call even if `dry_run = false`.

---

## RESPONSES — three envelope types only

### success
```yaml
ok: true
status: "success"
fields:
  - request_id
  - project
  - subflow_id
  - service
  - data
  - warnings
  - errors
  - meta.orchestrator_reference
```

### rejected_failure
```yaml
ok: false
fields:
  - request_id
  - status
  - error.code
  - error.message
  - error.retryable
```

### pending_validation
```yaml
ok: false
status: "pending_validation"
fields:
  - request_id
  - planned_action
  - approval_required
```

### Error codes to handle

```
validation_error
authentication_error
permission_error
unsupported_service
unsupported_operation
unknown_subflow
approval_required
approval_invalid
duplicate_request
external_service_error
subworkflow_error
timeout_error
```

### Retry logic

```yaml
retry only when error.retryable = true

on timeout_error with uncertain state:
  → DO NOT auto-retry
  → manual check

on duplicate_request (in_progress):
  → wait
  → do not retry concurrently
```

---

## BUILDING A NEW SUBFLOW BRANCH

### Input contract — internal normalized envelope

```yaml
[
  request_id,
  api_version,
  project,
  subflow_id,
  operation,
  service,
  payload,
  options,
  orchestrator.received_at,
  orchestrator.execution_reference,
  orchestrator.contract_version
]
```

### Output contract — success

```yaml
[
  ok,
  request_id,
  subflow_id,
  status,
  data,
  errors,
  warnings,
  meta.processed_at,
  meta.subflow_reference
]
```

### Output contract — failure

```yaml
[
  ok,
  request_id,
  subflow_id,
  status,
  error:
    {
      code,
      message,
      details,
      retryable
    }
]
```

### Hard rules for subflow code

- Never expose secrets, credential IDs, workflow IDs.
- Return structured errors only.
- Respect `dry_run` — no external side effect, return `planned_action`.
- Internal reviews are additive only — cannot bypass the master confirm flow.
- Timeout configured on the subflow workflow itself:
  ```yaml
  default: 60s
  search: 90s
  publish: 90s
  create: 120s
  message: 60s
  ```

### AI inside a subflow must define

- Task type
- Allowed input context / sources
- Expected output shape
- Validation rules before any side effect
- Confidence / quality checks
- Fallback for invalid or low-confidence output
- Human review requirement

---

## REGISTRIES — state lives in n8n Data Tables in v1

```yaml
projects:
  api_key
  name
  active
  allowed_capabilities[json]
  risky_ops_override[json]
  notes

allowed_capabilities format:
  "route:operation"

wildcards ok:
  "publish:*"
  "*:search"

idempotency_keys:
  key = (project, request_id)

audit_events:
  retention 90 days
```

---

## INVARIANTS — never violate

- Fail closed on unknown project / route / service / operation.
- Authenticate every gateway request.
- Credentials stay platform-side.
- v1 = single service per request.
- No raw file uploads — references only.
- No raw payload storage.
- Audit security-relevant events.
- AI side effects pass validation + policy approval.
