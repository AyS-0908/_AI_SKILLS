# n8n Orchestrator — Contract (pointer)

> **Single source of truth — do NOT duplicate the full contract here.**
> This file is a pointer + cheat-sheet. The authoritative contract lives in the orchestrator project:
> - **Caller / user guide:** `C:\Users\aymar\AYS_CODING\code-N8N_ORCHESTRATOR\orchestrator_user_guide.md`
> - **Full behavior spec (live contract):** `C:\Users\aymar\AYS_CODING\code-N8N_ORCHESTRATOR\orchestrator_spec_v1.md`
> - **Scope rules (V1 denylist, connectors):** `C:\Users\aymar\AYS_CODING\code-N8N_ORCHESTRATOR\AGENTS.md`
>
> Read the source file before any design or audit touching `search | publish | create | message`.
> If those files are unreachable, use the cheat-sheet below and label `[ASSUMPTION: contract not verified live]`.

---

## Cheat-sheet (decision + shape only — verify against source)

**Routes / operations**
- `search`: `web_search`, `linkedin_fetch`, `reddit_fetch`
- `publish`: `linkedin_draft`, `linkedin_publish_after_approval`
- `create`: `text_generation`
- `message`: `email_send`

**Use orchestrator when ALL true:** capability ∈ routes above · one service/request · sync response · body ≤1MB, files by reference. **Extend (don't bypass)** when a new capability fits a route family → add a Switch branch inside the existing domain subflow. **Skip** for deferred routes (`rag`, `deployer`, `agents_ia`), multi-service, async/callback, raw file upload.

**Risky ops** (`publish | post | deploy | delete | paid_ai_generation | restricted_extract | send`): two-call confirm. Call 1 (no `confirm`) → `pending_validation` + `planned_action`, no side effect. Call 2 (same `request_id`, `payload.confirm=true`) → executes; duplicate returns prior result. `options.dry_run=true` validates only.

**Caller MUST NOT send:** API keys/tokens/secrets · credential IDs · workflow IDs · node params · executable code · `callback_url`/async · more than one service.

**Three response envelopes only:** `success` (`ok:true`) · `rejected_failure` (`ok:false` + `error.{code,message,retryable}`) · `pending_validation` (`ok:false` + `planned_action` + `approval_required`).

**Invariants:** fail closed on unknown project/route/service/operation · authenticate every request · credentials stay platform-side · single service per request · references not raw files · no raw payload storage · AI side effects pass validation + approval.

---

## Round-trips / inbound events (the recurring "async" question)

The gateway is **synchronous by design**. Two needs look like "async" but neither justifies an async gateway:
- **Long job the caller awaits** → connector starts it (fire-and-forget child), returns a ref, caller polls a `<domain>_status` op. Proven: `video_generation` → `video_job_status`.
- **Inbound event** (a human's Telegram/WhatsApp reply) → a SEPARATE trigger workflow receives it; it is not a subflow the master calls.

Send-a-message-get-the-answer-back pattern:
- **Default (decoupled poll — use when you can't know when the human replies):** `<channel>_send` fires the message; a standalone `<channel>_INBOUND` trigger workflow writes replies to a domain-owned state table (same category as `video_jobs`, NOT a 4th core table); caller reads via a new `search` op `message_poll`. A fast reply is just found on the first poll, so this covers quick and slow replies alike.
- **Single paused run only:** native "Send and Wait for Response" inside that TRIGGERED workflow. Never inside a called subflow (breaks return to parent). Never hold the master HTTP request open for a human (150s timeout).
- **Do NOT rebuild the gateway async for this** — the inbound event still needs a trigger + state, so async wouldn't solve it. Async jobs/callbacks are V2, justified by multi-tenant demand only. Source: orchestrator `AGENTS.md` §ASYNC_ROUNDTRIPS + `orchestrator_future_versions.md` §G.

---

## Sync rule

When the orchestrator contract changes, edit the **source files above** (in `code-N8N_ORCHESTRATOR`). Only refresh this cheat-sheet if a route, envelope, or invariant changes. Never let this file become a second full copy.
