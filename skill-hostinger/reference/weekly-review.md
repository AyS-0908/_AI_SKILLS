# Weekly VPS review — automation (n8n-native)

Reviews the VPS using the weekly maintenance email only. **No VPS access needed.**
Runs entirely inside n8n, where internet and Gmail sending already work.

## Architecture (current — built 2026-06-18)

n8n workflow **"VPS Weekly Review"** (id `0WyF42knSiTROPzv`,
https://n8n.sourcinno.com/workflow/0WyF42knSiTROPzv):

```
Gmail Trigger ("On VPS Report Email")
   - polls hourly, filter q:
     from:aymard.de.scorbiac@10321917.brevosend.com subject:"[VPS] Weekly Maintenance Report"
   - simple:false (returns full body in $json.text); readStatus: both
   - credential: Gmail_Perso
        |
        v
Code ("Analyze Report", runOnceForAllItems, deterministic — no LLM)
   parses the report body and builds emailSubject + emailHtml:
   - disk root Use%   -> green <70, amber 70-85, red >85
   - "<N> packages can be upgraded" -> N
   - Docker stack pending? (docker-ce | containerd.io | docker-compose-plugin)
        -> if yes: recommend a Hostinger snapshot BEFORE updating (daemon restart cycles all containers)
   - container count ("Up") + unhealthy flag (unhealthy|Restarting|Exited|Dead)
   - quotes the report's "REMINDER" block verbatim
   - overall verdict (red if disk>85 or unhealthy; amber if docker-stack or disk>=70; else green)
        |
        v
Gmail ("Email Recommendations", message:send, html)
   - to: aymard.de.scorbiac@gmail.com ; credential: Gmail_Perso
```

## Why not a Claude cloud routine (the path we abandoned)

A Claude cloud routine was created first (`trig_01QPTysp4mBbYa9yb4yjjvtN`) but **disabled** because the
cloud sandbox: (a) has no outbound internet (curl to n8n fails), and (b) its n8n connector exposes only a
read-only tool subset (no `execute_workflow`), and (c) the Gmail connector can only draft, not send.
So a cloud routine cannot send email. The n8n-native workflow above avoids all three limits.

> The orchestrator itself is healthy — the curl failure was the sandbox's missing egress, not n8n.
> Any caller with normal internet can still POST to the orchestrator webhook.

## Code-node gotcha (learned the hard way)

When generating the Code node via the n8n SDK, regex backslashes were corrupted because the jsCode was
embedded in a template literal (`\s`, `\d`, `\/` collapsed). Fix: set `/jsCode` via `update_workflow`
`setNodeParameter` with properly escaped backslashes, or write the parser with string methods (no regex).

## To send via the orchestrator instead (alternative, e.g. from a normal-internet caller)

The least-privilege project `vps-review` (capability `message:send`) is still in the `projects` data table.
Call: `POST https://n8n.sourcinno.com/webhook/orchestrator`, header `X-API-Key: <vps-review key>`, body
`{request_id, project:"vps-review", subflow_id:"message", operation:"send", service:"email_send",
payload:{to,subject,body,confirm:true}}`. `confirm:true` is mandatory or it only previews.

## Maintenance notes

- Don't delete the weekly report before the trigger polls it (hourly), or that week is skipped.
- Gmail_Perso OAuth: if the Google consent screen is in "Testing", the token expires ~weekly — publish it.
- To pause: toggle the workflow inactive in n8n. To change recipient/threshold: edit the Code node.
