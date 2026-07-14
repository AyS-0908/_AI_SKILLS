# UI AND EXTERNAL API BOUNDARIES

Load with `CORE.md` when the tool uses HTML Service or external APIs.

## UI TRUST MODEL

The browser is a display and selection surface, not a source of authority.

- Re-check privileged actions at the server entrypoint.
- Re-resolve tenant/entity selections server-side.
- Recompute actionable IDs from durable state.
- Validate every submitted field against the server-owned contract.
- Render operator, AI, and API text through `textContent`/DOM nodes.
- Prefer contextually escaped `<?= ... ?>` template output; use force-printing only for trusted static markup.
- Return sanitized messages; log secret-free technical context separately.
- Minimize repeated short `google.script.run` calls; batch UI reads when it stays simple.

Use one generic form renderer only when several forms genuinely share a field-spec shape. A single simple dialog does not earn a framework.

## IRREVERSIBLE ACTIONS

Confirmation flow:

1. Server computes the eligible set and count.
2. UI displays the count and plain-language consequence.
3. Client returns only the stable selectors needed to express the user's choice.
4. Server re-authorizes, re-derives, and re-validates the set.
5. If the final scope materially differs, show a new confirmation; otherwise execute under the required lock/idempotency controls.

Client selectors are intent, never authority. A selected stable-ID list is valid when row selection is the feature; the server must still verify every ID and reject additions/substitutions.

For a web app, decide and test deployment access plus execute-as identity. Do not assume `Session.getActiveUser().getEmail()` is available, especially when the app executes as the developer.

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

Reconciliation may perform a provider read only when stable identifiers and an unambiguous lookup exist. Otherwise route the item to manual resolution; a guessed retry is unsafe.

Each adapter must declare its retryable failures, maximum attempts, delay policy, and whether reliable reconciliation exists. There is no universal retry cap that is correct for every provider.

Mint the request ID before the external call and record it in the row, structured log, and provider idempotency header when supported.

## SECRET CHANGES

Use:

`keep current -> validate candidate safely -> swap once under the right lock -> retain recovery reference`

- Never echo the current or candidate value.
- UI may reveal only whether a key exists.
- Scrub credentials from URLs, headers, response bodies, and debug dumps.
- Do not spend paid/high-impact work merely to validate a key when a cheap authenticated check exists.
