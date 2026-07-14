# EXTERNAL APIS AND UI BOUNDARIES

> **Purpose:** co-located rules and implementation guidance for external API adapters (validation, retry, reconciliation, secrets) and for HTML UI, menus, dialogs, forms, surfaces, and server trust.

## Contents

1. [External APIs](#external-apis) — rules A-04, E-01..E-08; adapter policy, response validation, retry and reconciliation, secret changes.
2. [UI boundaries](#ui-boundaries) — rules U-01..U-05; UI trust model, surface selection, irreversible actions, result UX.

---

## External APIs

### Rules

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| A-04 | DEFAULT | SYNTHESIZED | External API | Support one provider first. Add one explicit adapter per provider actually supported. | Build hypothetical provider abstractions or expect one wire format to fit unrelated APIs. |

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| E-01 | DEFAULT | SYNTHESIZED | Provider integration | Keep one thin adapter per real provider/boundary. Let a registry select validated adapters and safe parameters only when users truly switch providers. | Build dynamic arbitrary endpoint/auth/response execution or hypothetical strategy layers. |
| E-02 | MUST | PROJECT_REPORTED | Every call | Validate transport errors, HTTP status, semantic error bodies, JSON shape, and load-bearing fields before state changes. | Treat HTTP 200 or parseable JSON as success. |
| E-03 | MUST | PROJECT_REPORTED | External side effect | Mint a trace/idempotency ID before the call and thread it through the row, log, and provider header when supported. | Make an ambiguous side effect untraceable. |
| E-04 | MUST | SYNTHESIZED | Retry | Base retry on operation idempotency and failure type. Each adapter defines safe failures, attempt cap, delay, and reconciliation contract. | Use one universal retry policy, blind-retry ambiguous writes, or retry forever. |
| E-05 | MUST | SYNTHESIZED | Ambiguous write | Mark for reconciliation. Use a provider lookup only when it has a stable key and unambiguous match contract; otherwise require manual resolution. | Guess whether the write succeeded or issue another create. |
| E-06 | MUST | SYNTHESIZED | Credentials/config write | Keep the old value until the candidate passes a safe validation, then swap once under the appropriate lock; retain a recovery path without echoing either value. | Overwrite first and attempt a racy rollback after failure. |
| E-07 | MUST | PROJECT_REPORTED | AI/provider output | Be strict on fields that drive behavior; tolerate optional metadata; clamp/drop invalid optional values with counts. | Reject a usable result for optional metadata or write off-vocabulary values. |
| E-08 | MUST | PROJECT_REPORTED | Error reporting | Sanitize URLs, headers, bodies, and debug dumps before showing or logging them. | Surface raw provider exceptions that may embed credentials. |

### ADAPTER POLICY

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

### RESPONSE VALIDATION

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

### RETRY AND RECONCILIATION

| Boundary | Default |
|---|---|
| Idempotent read | Retry only classified transient failures, with a small cap. |
| Rate-limited request | Respect provider signals; use bounded backoff. |
| Non-idempotent write rejected before send | Retry only when the failure proves nothing was accepted. |
| Write with ambiguous outcome | Do not retry; mark `needs_reconcile`. |

Reconciliation may perform a provider read only when stable identifiers and an unambiguous lookup exist. Otherwise route the item to manual resolution; a guessed retry is unsafe.

Each adapter must declare its retryable failures, maximum attempts, delay policy, and whether reliable reconciliation exists. There is no universal retry cap that is correct for every provider.

Mint the request ID before the external call and record it in the row, structured log, and provider idempotency header when supported.

### SECRET CHANGES

Use:

`keep current -> validate candidate safely -> swap once under the right lock -> retain recovery reference`

- Never echo the current or candidate value.
- UI may reveal only whether a key exists.
- Scrub credentials from URLs, headers, response bodies, and debug dumps.
- Do not spend paid/high-impact work merely to validate a key when a cheap authenticated check exists.

---

## UI boundaries

### Rules

| ID | Priority | Confidence | Applies when | DO | DO NOT |
|---|---|---|---|---|---|
| U-01 | MUST | EXTERNAL + PROJECT_REPORTED | HTML Service | Keep business logic server-side and render untrusted/user/AI text with DOM text nodes or contextually escaped template output. | Put secrets/business rules in HTML or force-print/inject external text as HTML. |
| U-02 | DEFAULT | SYNTHESIZED | Several similar forms | Reuse one field-spec renderer only after repeated form shapes exist. | Build a generic form engine for a single simple dialog. |
| U-03 | MUST | SYNTHESIZED | Irreversible external action | Show the exact intended scope, send only stable selectors needed to express the user's choice, then re-authorize and re-validate server-side. Reconfirm if the scope materially changed. | Treat client IDs/counts as authority or silently execute a different set than the user confirmed. |
| U-04 | DEFAULT | PROJECT_REPORTED | Action result | Return one clear outcome, one next action, and navigate only after success. | Emit multiple dialogs or hide a data-caused empty state. |
| U-05 | DEFAULT | EXTERNAL + SYNTHESIZED | Choosing an interaction surface | Use the lightest native surface that fits. For a Sheet-led add-on path: use validated status cells plus one menu entrypoint in the MVP, then a Sheets Editor add-on sidebar/dialog styled with Google's add-on CSS. | Build a custom HTML dashboard, checkbox-as-button controls, or decorative control layer before the workflow needs it. |

### UI TRUST MODEL

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

### UI SURFACE SELECTION

Choose the smallest surface that communicates the action clearly:

| Need | Default surface | Caveat |
|---|---|---|
| A few stable actions | Custom menu | Bound scripts only; keep labels task-oriented. |
| Editable structured data | Validated/protected sheet ranges | Protection prevents accidental edits, not data disclosure. |
| Short non-blocking progress/result | Toast | Do not use it for a decision or error the user must acknowledge. |
| Multi-field validated input | Dialog or sidebar | Keep validation and authority server-side. |
| Desktop visual shortcut | Assigned image/drawing | It does not execute from the Sheets mobile app; keep another entrypoint. |
| Read-only visual indicator | Conditional formatting or presentation-only formula | Never let presentation formulas own IDs, workflow state, or side effects. |

For a Sheet-led tool expected to become an add-on, use this progression:

1. MVP: a lightly styled Sheet, validated status dropdowns, and one task-oriented menu item that opens setup, review, or confirmation UI.
2. Target: a Sheets Editor add-on using HTML Service plus Google's official `add-ons1.css` package and only small local layout CSS.
3. Use a Google Workspace add-on/CardService only when the product does not depend on active-document context or current platform support explicitly provides the required context.

Do not add Tailwind, Materialize, Hyperscript, icon libraries, or another CDN dependency merely to make a Sheet resemble SaaS. The official Editor add-on CSS is the native default; local CSS may refine spacing/layout without replacing its controls.

Gridline hiding, frozen navigation bands, card styling, emojis, color pills, sparklines, hidden unused rows/columns, and typography tokens are optional product design. Apply them only when they improve the actual operator workflow, preserve accessibility, and do not hide the spreadsheet's editable/data nature.

Use status as workflow state, not a checkbox as a button:

- A validated status change may initiate a reversible, duplicate-safe transition when the product contract says so.
- Keep status codes and legal transitions server-owned; reject invalid or stale edits.
- Use an explicit sidebar/dialog button plus confirmation for irreversible or externally billed actions.
- Use checkboxes only for genuine boolean or multi-select input, never as a disguised command control.

### IRREVERSIBLE ACTIONS

Confirmation flow:

1. Server computes the eligible set and count.
2. UI displays the count and plain-language consequence.
3. Client returns only the stable selectors needed to express the user's choice.
4. Server re-authorizes, re-derives, and re-validates the set.
5. If the final scope materially differs, show a new confirmation; otherwise execute under the required lock/idempotency controls.

Client selectors are intent, never authority. A selected stable-ID list is valid when row selection is the feature; the server must still verify every ID and reject additions/substitutions.

For a web app, decide and test deployment access plus execute-as identity. Do not assume `Session.getActiveUser().getEmail()` is available, especially when the app executes as the developer.

### RESULT UX

- Return one outcome, one next action, and an optional success-only destination.
- Disable repeat submission after a non-repeatable success.
- Explain empty states by naming the operator action that creates the missing data.
- Keep test/mock mode visibly labeled at shared result seams.
- Do not prescribe exact modal timing as a universal rule; choose it per interaction.
