# Confirmed VPS stack (source of truth — keep this updated)

> Confirmed from the weekly maintenance report dated 2026-06-15. Ask the user to
> confirm it still matches before acting on it.

- Provider: Hostinger VPS
- Hostname: srv577644
- OS: Ubuntu 24.04 (noble)
- Disk: 96 GB root (`/dev/sda1`)
- Container layer: Docker (docker-ce 29.x)
- PaaS: Coolify 4.0.0 (UI on port 8000; coolify-db postgres:15, coolify-redis, coolify-realtime, coolify-sentinel)
- Reverse proxy: Traefik v3.6 (container `coolify-proxy`, ports 80/443/8080)
- Apps:
  - n8n 2.18.5 (+ its own postgres:16)
  - Affine stable (+ pgvector/pgvector:pg16, redis)
- Sites: sourcinno.com

## Weekly report channel (no VPS access needed to read it)

- Delivered by email every Monday ~09:00 UTC.
- From: `aymard.de.scorbiac@10321917.brevosend.com` (Brevo relay)
- Subject: `[VPS] Weekly Maintenance Report`
- Body is plain text and self-contained: disk, available apt updates, docker system df,
  running containers + versions, and manual-check reminders.

## Manual checks the report reminds about

1. In Coolify (port 8000): check for newer Coolify and n8n versions.
2. Before major updates: run `docker-snapshot-helper.sh` (take a snapshot first).
3. Verify websites (e.g. sourcinno.com) load correctly.

## Still unconfirmed — ask when relevant

- VPS plan / CPU / RAM
- SSH host / user (only needed if doing live diagnostics, not for the weekly review)
