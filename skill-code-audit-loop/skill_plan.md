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
| Auditor engine | Calls the `code-audit` skill; never re-writes audit logic |
| Doc cleanup | Light tidy each turn; full `doc-hygiene` pass only when the whole feature is done |
| Safety | Max 3 rounds, then stop · human gives the final OK · fresh auditor every round |

**Models & effort** — see the authoritative `## Models & effort` table in `SKILL.md` (encoded there by item 1). Not duplicated here, so the two can't drift.

---

## To-Do

### [x] 1 — Add the Models & Effort rules to the skill
_Done: added `## Models & effort` (rank-based table + invariant) to SKILL.md, set the AUDIT turn to spawn the auditor at best @ 3/5 with a Coder best-1 @ 4/5 note (best @ 4/5 sensitive), and added a plain-English "Which AI it uses" blurb to USER-GUIDE.md._
**Goal:** make the loop set model + effort by itself (per the table above), so you never set it by hand.
**Run on:** best-1 @ 2/5 (simple doc edit).
**Prompt for the AI Coder:**
> Read `C:\Users\aymar\AYS_CODING\_AI_SKILLS\skill-code-audit-loop\SKILL.md` and its `USER-GUIDE.md`, and the "Models & effort" table in current doc (`skill_plan.md`).
> Add a new `## Models & effort` section to SKILL.md that encodes that table. Write it in RANK terms (best / best-1), and add ONE line saying the model names are only examples that will change. Floors: never below best-1, never below 2/5.
> Update the AUDIT-turn step so the fresh auditor is spawned at **best tier, effort 3/5**. Add a note that the main session runs the coder at **best-1 @ 4/5** (jump to **best @ 4/5** for sensitive phases).
> Add a plain-English 3-line version to USER-GUIDE.md. Keep it short. No new scripts.
> Last: update `skill_plan.md` — tick item 1 and write one line on what changed.

### [x] 2 — Publish the updated skill
_Done: commit `8c28d09` pushed to AyS-0908/_AI_SKILLS; manifest + installs refreshed via Sync-SkillsManifest.ps1._
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
