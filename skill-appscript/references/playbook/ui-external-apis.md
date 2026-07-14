# UI AND EXTERNAL API BOUNDARIES

Load with `CORE.md` when the tool uses HTML Service or external APIs.

## UI TRUST MODEL

The browser is a display and selection surface, not a source of authority.

- Re-check privileged actions at the server entrypoint.
- Re-resolve tenant/entity selections server-side.
- Recompute actionable IDs from durable state.
- Validate every submitted field against the server-owned contract.
- Render operator, AI, and API text through `textContent`/DOM nodes.
- Return sanitized messages; log secret-free technical context separately.

Use one generic form renderer only when several forms genuinely share a field-spec shape. A single simple dialog does not earn a framework.

## IRREVERSIBLE ACTIONS

Confirmation flow:

1. Server computes the eligible set and count.
2. UI displays the count and plain-language consequence.
3. Client returns only the action and stable tenant/entity selector.
4. Server re-derives and re-validates the set.
5. Server executes under the required lock/idempotency controls.

Do not carry free text or a row-ID list through the confirmation payload when the server can derive it.

## RESULT UX

- Return one outcome, one next action, and an optional success-only destination.
- Disable repeat submission after a non-repeatable success.
- Explain empty states by naming the operator action that creates the missing data.
- Keep test/mock mode visibly labeled at shared result seams.
- Do not prescribe exact modal timing as a universal rule; choose it per interaction.

## ADAPTER POLICY

Create one thin adapter per external provider or distinct boundary actually supported.

Each adapter owns:

- endpoint and authentication shape
- request construction
- HTTP and semantic-response validation
- provider response -> internal result mapping
- safe retry policy
- secret-free error translation

Business logic consumes a small internal result such as `{ok, data, errorCode, retryable, externalRef}`. UI wrappers may convert a failed result into one friendly thrown error.

A provider registry is conditional. It may select a known adapter and supply validated model/temperature/token parameters. Do not execute arbitrary endpoints, auth schemes, or response expressions directly from sheet cells.

## RESPONSE VALIDATION

Check in this order:

1. Transport exception.
2. HTTP status.
3. Error indicated inside a nominally successful body.
4. JSON parse and expected envelope.
5. Load-bearing business fields.
6. Optional metadata.

For AI output:

- Fail if required content, locale, size, or safety constraints are invalid.
- Default missing optional metadata.
- Clamp off-vocabulary optional values to blank or an explicit fallback.
- Drop invalid list items when partial output is safe; return the dropped count.

## RETRY AND RECONCILIATION

| Boundary | Default |
|---|---|
| Idempotent read | Retry only classified transient failures, with a small cap. |
| Rate-limited request | Respect provider signals; use bounded backoff. |
| Non-idempotent write rejected before send | Retry only when the failure proves nothing was accepted. |
| Write with ambiguous outcome | Do not retry; mark `needs_reconcile`. |

Reconciliation performs a provider read using stable request/tenant/content identifiers and accepts success only when exactly one match exists.

Each adapter must declare its retryable failures, maximum attempts, delay policy, and whether reliable reconciliation exists. There is no universal retry cap that is correct for every provider.

Mint the request ID before the external call and record it in the row, structured log, and provider idempotency header when supported.

## SECRET CHANGES

Use:

`snapshot current -> validate candidate cheaply -> write -> re-read/validate -> rollback on failure`

- Never echo the current or candidate value.
- UI may reveal only whether a key exists.
- Scrub credentials from URLs, headers, response bodies, and debug dumps.
- Do not spend paid/high-impact work merely to validate a key when a cheap authenticated check exists.
