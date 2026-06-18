# Backup, snapshot & rollback

> Dashboard flows change. When web tools are available, verify steps against
> https://www.hostinger.com/support/vps/ and https://coolify.io/docs/ before instructing the user.

## Choose protection before any 🟡/🔴 change

Pick at least one, strongest first:

1. **Hostinger snapshot** (🟡) — whole-VPS point-in-time image, taken in the Hostinger panel
   (hPanel › VPS › Snapshots). Best single safety net before OS-level or broad changes.
   Note: typically only one snapshot is kept and a new one overwrites it — confirm before creating.
2. **Coolify backup** (🟡) — per-application / database backups configured inside Coolify.
3. **Database dump** (🟡) — explicit `pg_dump` / `mysqldump` of the affected DB to a file, before DB changes.
4. **File/volume backup** (🟡) — `tar` the relevant Docker volume or config dir before editing.
5. **Stated rollback path** — if none of the above fits, write down the exact command/steps to undo the change.

## Generic DB dump examples (🟡 — adapt names; run in SSH)

```bash
# Postgres in a container
docker exec <db_container> pg_dump -U <user> <database> > ~/backup_<database>_$(date +%F).sql
# MySQL/MariaDB in a container
docker exec <db_container> sh -c 'exec mysqldump -u<user> -p"$MYSQL_PWD" <database>' > ~/backup_<database>_$(date +%F).sql
```

## Volume / config backup (🟡)

```bash
tar czf ~/backup_<name>_$(date +%F).tgz /path/to/config_or_volume
```

## Restore (🔴 — requires explicit confirmation)

- Hostinger snapshot restore: hPanel › VPS › Snapshots › Restore. **Overwrites the whole VPS** to the
  snapshot moment; anything newer is lost. Confirm the user accepts that data loss window first.
- DB restore: stop the app, restore the dump into a clean DB, restart. Keep the old DB until verified.
- Never delete the backup you restored from until the user confirms the restore is healthy.
