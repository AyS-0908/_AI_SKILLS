# Diagnostic scripts (copy-paste, run in the VPS SSH terminal)

Run these one block at a time and paste the output back. **Run the redaction
helper on any output before pasting if you're unsure it's clean.**

## 🟢 Redaction helper — run on any log before sharing

Pipe suspicious output through this to blank common secrets:

```bash
sed -E 's/(password|passwd|token|secret|api[_-]?key|authorization|bearer)[=: ]+\S+/\1=REDACTED/Ig'
```

## 🟢 One-shot health snapshot (safe, read-only)

```bash
echo "== OS / uptime =="; uname -a; uptime
echo "== Disk =="; df -h /
echo "== Memory =="; free -h
echo "== Docker =="; docker --version; systemctl is-active docker
echo "== Containers =="; docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo "== Failed services =="; systemctl --failed
echo "== Listening ports =="; ss -tulpn 2>/dev/null | grep LISTEN
```

## 🟢 Pending OS package updates (read-only, Debian/Ubuntu)

```bash
sudo apt-get update >/dev/null 2>&1; apt list --upgradable 2>/dev/null
echo "== Reboot required? =="; [ -f /var/run/reboot-required ] && echo "YES — reboot needed" || echo "no"
```

## 🟢 Coolify / proxy status (read-only)

```bash
docker ps --filter "name=coolify" --format 'table {{.Names}}\t{{.Status}}'
docker ps --filter "name=traefik" --format 'table {{.Names}}\t{{.Status}}'
docker ps --filter "name=caddy"   --format 'table {{.Names}}\t{{.Status}}'
```

## 🟢 Docker disk usage / images that could be cleaned (read-only)

```bash
docker system df
docker image ls --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
```

## 🟢 Recent logs for one service (read-only — replace <name>)

```bash
docker logs --tail 100 <name> 2>&1 | sed -E 's/(password|token|secret|api[_-]?key|bearer)[=: ]+\S+/\1=REDACTED/Ig'
```
