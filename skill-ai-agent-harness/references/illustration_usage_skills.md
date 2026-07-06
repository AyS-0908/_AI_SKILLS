# AI_USAGE_OF_SKILLS

## TRIGGERS

Use when:
- user names a skill
- create/update/improve/validate/audit a skill
- `skills-manifest.json` has an active, specific match
- repeatable workflow or formal audit/spec matches a skill description

Skip for:
- simple factual questions
- ordinary coding tasks without a workflow match

---

## SELECT

- Read `C:\Users\aymar\AYS_CODING\_AI_AGENTS\skills-manifest.json`.
- Use only `status: active`.
- Match first on `description`, especially `Trigger for:` and `Do NOT trigger for:`.
- Use `triggers` only as optional keywords.
- If several skills match, choose the narrowest active skill. Mark `[ASSUMED]` only if uncertain.
- If no skill matches, continue without a skill.
- Named skill missing/unavailable: say so; continue if safe.

---

## LOAD

Fetch selected `SKILL.md` from `github_path`:

```powershell
gh api repos/AyS-0908/AI_SKILLS/contents/{github_path} --jq '.content | @base64d'
```

- Read the whole `SKILL.md` before acting.
- Follow only directly referenced task files.
- Do not recursively load the repo.
- If `github_path` is missing, try `skill-{slug}/SKILL.md`.
- If manifest read fails, list repo root with `gh api repos/AyS-0908/AI_SKILLS/contents`.
- If `@base64d` returns empty, decode `.content` manually.

---

## MANIFEST

- Cache: `C:\Users\aymar\AYS_CODING\_AI_AGENTS\skills-manifest.json`
- Source of truth: `SKILL.md` frontmatter in `AyS-0908/AI_SKILLS`
- Sync script: `C:\Users\aymar\AYS_CODING\_AI_AGENTS\scripts\Sync-SkillsManifest.ps1`
- Never hand-edit the manifest.

---

## REFRESH_MANIFEST

- Automatic: Scheduled Task `Sync-SkillsManifest`, log `scripts\sync-skills.log`.
- Force after publishing a skill or when the manifest looks stale:

```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Users\aymar\AYS_CODING\_AI_AGENTS\scripts\Sync-SkillsManifest.ps1 -Force
```

---

## UPDATE_SKILL_INDEX

When a skill is added, removed, renamed, or rerouted:

1. Edit only the skill `SKILL.md` frontmatter: `name`, `description`, optional `status`, `triggers`, `do_not_trigger_for`.
2. Push to `AyS-0908/AI_SKILLS`.
3. Run the sync script.

No other index update.

---

## CREATE_OR_UPDATE_SKILL

1. Load `skill-skill-creator-addon/SKILL.md`.
2. Use the agent-native `skill-creator`.
3. Apply addon gates: PRE-DRAFT, POST-DESCRIPTION, DURING-DRAFT, PRE-PACKAGE.
4. Package only if final checklist passes.

---

## VALIDATE_SKILL

Validate local workbench folders:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\aymar\AYS_CODING\_AI_AGENTS\scripts\Validate-Skill.ps1 C:\Users\aymar\AYS_CODING\_AI_SKILLS\skill-github-sync
```

- Do not use plugin `quick_validate.py`.
- No Python packages.
- Accepted keys: `name`, `description`, `status`, `triggers`, `do_not_trigger_for`.

---

## AUTHOR

- Local workbench: `C:\Users\aymar\AYS_CODING\_AI_SKILLS\`
- Folder rule: `skill-<slug>\SKILL.md`
- Agents consume published repo plus synced manifest.
- Local edits are draft-only until pushed and synced.
