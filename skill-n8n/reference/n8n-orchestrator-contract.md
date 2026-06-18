# n8n Orchestrator — Contract (pointer)

> **Single source of truth — do NOT duplicate the full contract here.**
> This file is a pointer + cheat-sheet. The authoritative contract lives in the orchestrator project:
> - **Caller / AI-skill contract:** `C:\Users\aymar\AYS_CODING\code-N8N_ORCHESTRATOR\n8n_orchestrator_introduction.txt`
> - **Full behavior spec:** `C:\Users\aymar\AYS_CODING\code-N8N_ORCHESTRATOR\n8n_orchestrator_specification_v_1_2.txt`
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

## Sync rule

When the orchestrator contract changes, edit the **source files above** (in `code-N8N_ORCHESTRATOR`). Only refresh this cheat-sheet if a route, envelope, or invariant changes. Never let this file become a second full copy.
