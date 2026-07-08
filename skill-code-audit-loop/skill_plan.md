# Skill Plan — code-audit-loop

**What this is:** the open to-do for the `code-audit-loop` skill, written so a fresh AI session can run each item on its own. Do them in order.

**Effort scale:** 2 = medium · 3 = high · 4 = xhigh · 5 = max. (1 = never used.)

---

## Decisions already locked (encode these — do not re-debate)

**How the loop works**

| Part | Rule |
|---|---|
| Who codes | Main agent — it conducts, codes, and fixes |
| Who audits | One FRESH subagent per round — it audits only, never fixes |
| Auditor engine | Calls the `audit-it` skill; never re-writes audit logic |
| Doc cleanup | Light tidy each turn; full `doc-hygiene` pass only when the whole feature is done |
| Safety | Max 3 rounds, then stop · human gives the final OK · fresh auditor every round |

**Models & effort** — use RANK, not names. Today's names (e.g. "Opus / Sonnet / 4.5") are only examples and WILL change in a few months.

| Job | Model rank | Effort |
|---|---|---|
| Code + Fix (main session) | best-1 | 4/5 |
| Code + Fix — *sensitive* phase\* | best | 4/5 |
| Audit (subagent) | best | 3/5 |
| **Floors — never go below** | **best-1** | **2/5** |

\*Sensitive = touches security, secrets, login, money, or data migration.
**Rule that must always hold:** the auditor is at least as strong as the coder.

---

## To-Do

### [ ] 1 — Add the Models & Effort rules to the skill
**Goal:** make the loop set model + effort by itself (per the table above), so you never set it by hand.
**Run on:** best-1 @ 2/5 (simple doc edit).
**Prompt for the AI Coder:**
> Read `C:\Users\aymar\AYS_CODING\_AI_SKILLS\skill-code-audit-loop\SKILL.md` and its `USER-GUIDE.md`, and the "Models & effort" table in current doc (`skill_plan.md`).
> Add a new `## Models & effort` section to SKILL.md that encodes that table. Write it in RANK terms (best / best-1), and add ONE line saying the model names are only examples that will change. Floors: never below best-1, never below 2/5.
> Update the AUDIT-turn step so the fresh auditor is spawned at **best tier, effort 3/5**. Add a note that the main session runs the coder at **best-1 @ 4/5** (jump to **best @ 4/5** for sensitive phases).
> Add a plain-English 3-line version to USER-GUIDE.md. Keep it short. No new scripts.
> Last: update `skill_plan.md` — tick item 1 and write one line on what changed.

### [ ] 2 — Publish the updated skill
**Goal:** get the change live everywhere: GitHub + Claude + Codex + manifest.
**Run on:** best-1 @ 2/5 (mechanical).
**Prompt for the AI Coder:**
> Use the `skill-github-sync` skill to commit and push ONLY the `skill-code-audit-loop` folder in `C:\Users\aymar\AYS_CODING\_AI_SKILLS` to origin `main`. Do NOT stage `.WIP`, `.agents`, or other skills.
> Then run `Sync-SkillsManifest.ps1 -Force` to install into `.claude\skills` and `.codex\skills` and rebuild the manifest. Verify the folder exists in BOTH install dirs and appears in the manifest.
> Last: update `skill_plan.md` — tick item 2 and note the commit id.

### [ ] 3 — Test the loop for real on D-1b
**Goal:** prove the whole loop works on a live build before trusting it. Run this in the GO_VIRAL project (not the skills folder).
**Run on:** Coder best @ 4/5 (D-1b is sensitive) · Auditor best @ 3/5.
**Prompt for the AI Coder:**
> Run the `code-audit-loop` skill on **D-1b (library/container split)**. Plan file: `C:\Users\aymar\AYS_CODING\code-GO_VIRAL\goviral_plan_module_1.md`. Also fold in the pending D-1b-time audit fix **A-604**.
> Follow the skill exactly: build → fresh-subagent audit → fix → repeat, max 3 rounds, then stop for my final OK. The live two-workbook smoke test is MINE to run — do not claim D-1b done without it.
> Last: update `skill_plan.md` — note what worked and any rough edges to fix in the skill.
