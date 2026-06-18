# Weekly VPS review — automated routine

Reviews the VPS using the weekly maintenance email only. **No VPS access needed.**
The whole job: read one email → analyze → email recommendations via the existing n8n orchestrator.

## Schedule

- Run weekly, e.g. **Monday 12:00 Europe/Paris** (the report arrives ~11:00). Set up with the `schedule` skill.
- The scheduled run must have the **Gmail connector** and **n8n** access (or HTTP access to the
  orchestrator webhook). Verify at creation.

## Step 1 — Read the latest report (Gmail, read-only)

Search Gmail for:

```
from:aymard.de.scorbiac@10321917.brevosend.com subject:"[VPS] Weekly Maintenance Report" newer_than:8d
```

Take the most recent thread, read the plain-text body. If none found this week, skip to Step 3 and send a
"⚠️ weekly report not received" alert instead of an analysis.

## Step 2 — Analyze (apply ../SKILL.md logic)

From the report body, assess and summarize with risk tags:

- **Disk** — `Use%` of root. 🟢 < 70%, 🟡 70–85%, 🔴 > 85%.
- **Docker disk** — note `RECLAIMABLE`. Only suggest cleanup if it's non-trivial (e.g. > ~2 GB). 0% = do nothing.
- **Container health** — flag any not `healthy` / `Up`. All healthy = 🟢.
- **OS updates** — separate routine security updates (apply anytime) from the **Docker stack**
  (`docker-ce`, `containerd.io`, `docker-compose-plugin`): those restart the Docker daemon and briefly
  cycle every container → 🟡, recommend a **Hostinger snapshot first** (report reminder #2: `docker-snapshot-helper.sh`).
- **Manual reminders** — surface report's reminders #1–3 (check Coolify/n8n versions; verify sourcinno.com).

Produce a short HTML email: one-line overall verdict, then bullet findings with tags, then a
"Recommended this week" action list. Keep it skimmable.

## Step 3 — Send via the existing n8n orchestrator

**Endpoint:** `POST https://n8n.sourcinno.com/webhook/orchestrator`
**Header:** `X-API-Key: <PROJECT_API_KEY>`  ← secret, provided at setup; never hard-code in the skill
**Body:**

```json
{
  "request_id": "vps-weekly-<YYYY-MM-DD>",
  "project": "<PROJECT_NAME>",
  "subflow_id": "message",
  "operation": "send",
  "service": "email_send",
  "payload": {
    "to": "aymard.de.scorbiac@gmail.com",
    "subject": "VPS Weekly Review — <YYYY-MM-DD>",
    "body": "<html> ...analysis... </html>",
    "confirm": true
  }
}
```

### Critical details (verified from the orchestrator + message subflow)

- `payload.confirm: true` is **required to actually send.** `email_send` is a risky service; without it the
  orchestrator forces a dry-run and only returns a `planned_action` preview (no email goes out).
- Required payload fields: `to`, `subject`, `body` (HTML). Optional: `cc`, `bcc`, `sender_name`, `reply_to`.
- `request_id` is idempotency-keyed per `(project, request_id)` — use a fresh one each week
  (the date) or a repeat send returns the cached result instead of sending again.
- The project (identified by `X-API-Key`) must have capability `message:send` in its `allowed_capabilities`.
- Success = HTTP 200, `ok: true`, `data.message_id` populated. Other statuses: 401 auth, 403 capability,
  400 invalid payload, 502 subflow error.

## Two secrets needed at setup (do NOT store in the skill repo)

1. `PROJECT_API_KEY` — the X-API-Key for the project allowed to call `message:send`.
2. `PROJECT_NAME` — must match that key's owner exactly.
