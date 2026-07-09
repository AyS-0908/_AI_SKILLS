# Skills — The Design (START HERE)

**Status: THE DESIGN IS DECIDED. This file explains the whole system and lists the work left to do.**
This is the "read me first" file for how all your skills fit together and why. The small to-do list for finishing one skill lives separately in `skill-code-audit-loop/skill_plan.md`.

> A *skill* = a short written method the AI follows automatically when the moment matches. You keep about 12 of them.

---

## 1. Why this system exists

**In one sentence:** hand work to AI the way a business owner hands work to a team he cannot personally inspect — short instructions, trusted methods, independent quality control — so a non-technical person safely gets technical results.

Three goals, in plain terms:

| Goal | What it means |
|---|---|
| **Maximum reliability** | Work is checked by something *other* than the AI that did it: a fresh second AI, an automatic script, a retry cap, and your final OK. |
| **Minimum instruction time** | One short sentence from you fires the right written method automatically. You don't re-explain the method each time. |
| **Safe delegation while non-technical** | The judgment you can't provide lives *inside* the method: reuse before build, simple before clever, no theoretical features, push back on inflated requests. |

**The principle that follows — the heart of the whole thing:**
> **Trust comes from the SYSTEM, not from the owner's review.**
> A skill = a written method **+ its built-in check**. A skill with no check is just a written hope.

---

## 2. The universal pattern (works in any domain)

Every job — code today, documents tomorrow, anything later — is the same four beats:

**DEFINE** (what do we want) → **MAKE** (produce a draft) → **ROAST** (an independent check attacks the draft) → **FORMALIZE** (lock the approved result into its final file).

Skills are the written methods for these beats. This pattern is deliberately domain-free. It must still be true when you move from code to documents, analyses, or workflows — without rewriting it.

---

## 3. The five skill types (each has ONE rule)

Every skill is exactly one of these. The type carries its own non-negotiable rule.

| Type | What it is | Its one rule | Skills today |
|---|---|---|---|
| **LOOP** | Repeats make → roast → fix until green | **Safety rails are mandatory:** a round cap, a FRESH reviewer (new context — never the maker grading its own work), and your final OK | `code-audit-loop` (the only true loop) |
| **PIPELINE** | Ordered stages, run once through, each producing a file; stop/resume anywhere | Stages never overlap; a later stage *points back* to earlier files, never re-does them | `ideasup-flow` |
| **BLOCK** | A small reusable helper *meant* to be called by other skills — your reuse shelf | One clear output, assumes zero context, safe to call from anywhere | `audit-it`, `doc-hygiene`, `github-sync` |
| **DOER** | One concrete job in one area, called directly by you | Sharp "Do NOT trigger" lines so it never collides with a neighbour | `appscript`, `n8n`, `hostinger`, `benchmark`, `folder-cleaning` |
| **META** | Acts on skills themselves | Never fires during normal work | `ai-agent-harness`, `skill-creator-addon` |

**Why Blocks matter most for reuse:** any skill that needs "review this", "clean the docs", or "push to GitHub" *calls the Block* — it never rewrites it. That is how the system stays small as it grows.

---

## 4. How skills find each other (decided — do not reopen)

Two directions, handled two different ways on purpose:

| Direction | Question | How it's answered |
|---|---|---|
| **Downward** | "What do I call?" | A `**Uses:**` line written inside the skill, right next to where it calls another. It lives where you already edit, so it can't drift. |
| **Upward** | "Who calls me? What already exists?" | **Not kept anywhere.** Derived on demand: search the `Uses:` lines and read the auto-built list of all skills (`skills-manifest.json`, refreshed automatically). |

Today the entire call graph (who-calls-whom) is one line: `code-audit-loop → audit-it (hard dependency), doc-hygiene, github-sync`. Every other skill calls nothing.
No central hand-kept table, no map-generator script. At 12 skills that would rot faster than it helps (that's the "YAGNI" rule — *You Aren't Gonna Need It*). How agents load skills is documented in `_AI_AGENTS/usage_skills.md` — not repeated here.

---

## 5. Birth rules for every FUTURE skill

This is what keeps the design alive as you add skills. Any new skill (created through `skill-creator` + `skill-creator-addon`) must be **born with all five**:

1. A declared **TYPE** (Loop / Pipeline / Block / Doer / Meta) — and it inherits that type's rule from section 3.
2. A **collision check** against the manifest — **Blocks checked first** ("does a Block already do this? then reuse it").
3. A **`**Uses:**` line** if it calls other skills.
4. A **built-in check** — a script, a fresh-reviewer step, or a measurable "done" bar. **No skill ships as advice-only.**
5. Sharp **Trigger / Do NOT trigger** lines so it fires exactly when it should.

---

## 6. Proof the design is domain-free — the document family

The real test of section 1–5: can they absorb your *next* planned family — producing serious documents — with **zero changes**? Walk it:

| Beat | Document journey | Maps to type |
|---|---|---|
| DEFINE | Thinking assistant clarifies what the document must achieve | (part of the loop) |
| MAKE | Draft writing | inside a **LOOP** |
| ROAST | A fresh-context critic attacks the draft | a **BLOCK** — the doc-roaster, sibling to `audit-it` (which is the *code*-roaster) |
| FORMALIZE | Render to Word / PowerPoint / Excel | **DOERs** (or reuse the existing `docx` / `pptx` / `xlsx` skills) |

The orchestrating **doc-loop** is a LOOP with the *same* rails: round cap, fresh roaster, your final OK. If the whole journey chains stages with file hand-offs, that chain is a **PIPELINE**, exactly like `ideasup-flow`.

**Punchline:** nothing in sections 1–5 had to change to fit this new family. **That is the test every future family must pass.**
What gets **reused, not rebuilt:** `github-sync`, `doc-hygiene`, and the loop pattern copied from `code-audit-loop`.

---

## 7. Where you are today — the journey and its gaps

Walked through one real use case ("a tool to help a freelancer send invoices"):

| Step | Need | Skill | State |
|---|---|---|---|
| 1 | Define the product | `ideasup-flow` | 🟡 (two stages missing: Stage 4 Business Plan and Stage 8 AI-Coder rules — not blocking) |
| 2 | Spec → build plan | — | 🔴 **GAP #1: not built** — but `ideasup-flow` already reserves Stage 8 for this, with authoring material at `skill-ideasup-flow/references/pipeline-source-spec.md` |
| 3 | Build phase by phase | `code-audit-loop` | 🟡 Built but unfinished (3 items in `skill_plan.md`), never tested on a real project |
| 4 | Stop over-engineering | scattered advice | 🔴 **GAP #2: no check verifies it** — the weakest point vs Goal 3 |
| 5 | Publish / deploy | `github-sync` + `hostinger` | ✅ |
| 6 | Route to the right skill | manifest + trigger lines | ✅ |
| 7 | Create future skills | `skill-creator-addon` | 🟡 (still needs section-5 birth rules wired in) |

Legend: ✅ done · 🟡 in progress · 🔴 missing.

---

## 8. The plan (in order — no new machinery)

1. **This rewrite.** ✅ (this document).
2. **Finish `code-audit-loop`** — the 3 items in `skill_plan.md` (the last of which is the live test on project D-1b).
3. **Add a "roast" checklist to `audit-it`:** reuse checked? over-engineered? scope crept in silently? → **closes GAP #2.**
4. **Build the missing Spec → Plan step** — this is likely `ideasup-flow`'s reserved Stage 8; check `skill-ideasup-flow/references/pipeline-source-spec.md` and decide reuse-vs-new before building anything → **closes GAP #1.**
5. **Wire the section-5 birth rules into `skill-creator-addon`** (type declaration + Blocks-first collision check), plus one clause: any skill that spawns a fresh helper must put `AGENTS-canonical.md` in that helper's read-first list (fresh helpers start with zero context; the main session gets the canonical automatically, helpers don't).
6. **LATER, only after 1–5 are proven:** loop #2 = Story → Spec (copy `code-audit-loop` — do **not** extract a shared engine yet; earn it with two real loops first); the business-plan stage; the document family.

**Deliberately rejected** (a choice, not an oversight): a central dependency table, an automated skill map, and a shared loop engine *now*.

---

## How to resume this design work in a fresh session

Open the `_AI_SKILLS` folder in a new session and say:
> **"Read SKILLS-DESIGN.md, continue from The Plan."**
