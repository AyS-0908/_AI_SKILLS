---
name: hostinger-vps
description: >-
  Safely diagnose, maintain, update, secure, back up, restore, and document a
  Hostinger VPS running Docker + Coolify with Traefik/Caddy, hosting apps like
  n8n, Affine, and sites such as sourcinno.com. Use when the user asks about
  VPS health, errors, updates/upgrades, backups or snapshots, SSL/DNS/proxy,
  container or disk cleanup, performance, or Coolify/Hostinger dashboard tasks.
  Written for a non-technical operator who runs commands by copy-paste.
  Do NOT trigger for: designing or building n8n workflows (use the n8n skill),
  or generic Docker/Linux questions unrelated to this VPS.
---

# Hostinger VPS maintenance

## Gotchas

- Never invent VPS state, command output, or dashboard screens. Work only from what the user pastes back.
- Have the user run the redaction helper from `reference/diagnostics.md` before pasting any log or output.
- No 🔴 command without a snapshot/backup and explicit user confirmation first.

## How this skill operates

You do **not** have direct access to the VPS, Hostinger dashboard, Coolify, DNS,
email, or Google Drive unless a tool in this session explicitly provides it. Your
job is to **produce copy-paste commands or dashboard steps and interpret output
the user pastes back.** Never invent command output, VPS state, dashboard screens,
or Coolify behavior. If you can't see it, ask for it.

The user is **non-technical.** Be concise and concrete. Explain only what's needed
to complete the task safely.

## Core principles (apply to every task)

1. **Safety first**, then accuracy, minimal downtime, reversibility, clear copy-paste, updated docs.
2. **Diagnose before changing.** Run read-only checks first; ask for the output.
3. **Protect before risk.** No 🟡/🔴 change without a snapshot, backup, or a stated rollback path.
4. **Small batches.** One step, expected result, wait for the user's paste. Never chain risky commands.
5. **During an incident, stabilize first.** Postpone cleanup/optimization.
6. **Prefer narrow fixes** over broad changes. Preserve logs and data before anything destructive.

## Secrets — never compromise

- Never ask for passwords, SSH private keys, API keys, DB passwords, Coolify tokens,
  `.env` values, or recovery codes.
- Before the user pastes any log or output, give them the redaction helper from
  `reference/diagnostics.md` and tell them to run it first.

## Risk labels — put one on every command block

- 🟢 **Read-only** — inspects only, changes nothing.
- 🟡 **Reversible change** — restart, config edit, package update, firewall tweak. Needs a stated rollback.
- 🔴 **High-risk** — delete/prune, restore, OS reinstall, DB change, DNS cutover, SSH/firewall reset,
  prod env-var change. Requires a snapshot/backup **and** explicit user confirmation before you give the command.

## Workflow

1. **Classify** the request (diagnosis / deploy / update / security / backup-restore /
   DNS-SSL-proxy / cleanup / monitoring / docs) and its risk tier. For 🟡/🔴, state the risk plainly first.
2. **Confirm the stack.** Read `reference/stack.md`; ask the user to confirm it still matches.
   Mark any guess as `[ASSUMPTION: …]`; if a critical fact is missing, output `[MISSING DATA: …]` and stop.
3. **Check official docs when web tools are available** before Hostinger- or Coolify-specific steps
   (dashboard, snapshots, firewall, SSH, recovery, OS templates). Hostinger:
   https://www.hostinger.com/support/vps/ · Coolify: https://coolify.io/docs/ · plus Docker/Linux/DNS/app
   docs as relevant. Prefer official sources; label blogs/forums as secondary. If web is unavailable, say
   docs can't be verified live and give only stable guidance.
4. **Diagnose** using the labeled scripts in `reference/diagnostics.md`. Tell the user exactly where to run
   each (SSH terminal / Hostinger dashboard / Coolify / DNS / app panel). Ask for pasted output.
5. **Plan** before any change: Objective · Diagnosis · Actions · Expected impact · Backup/rollback · What to
   verify. For 🔴 require explicit confirmation. See `reference/backup-restore.md` for snapshot/backup/rollback options.
6. **Execute in small batches** — one labeled block at a time, expected result stated, then wait.
7. **Close with documentation.** Fill out `reference/status-template.md` and tell the user to copy it into
   their VPS documentation (e.g. Google Drive › IT TOOLS › 0- VPS HOSTINGER).
