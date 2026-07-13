# Code-Audit Loop — Plain-English Guide

*A one-page guide for a non-technical solo developer. If you never read the other file (`SKILL.md`), that's fine — that one is for the AI. This one is for you.*

## What is it, in one sentence?

It's a **referee** that runs your usual habit for you: the AI writes a phase, a *second, fresh* AI checks it, fixes get made, and it repeats until the work passes — then it stops and asks **you** for the final OK.

## The problem it removes

Today you do this by hand:
1. Ask an AI to build Phase X.
2. Open a **new session** and ask another AI to audit it.
3. Copy the fixes back, ask the first AI to fix them.
4. Repeat until it's good.

That works, but you rewrite the same prompts and babysit every hand-off. This skill does the hand-offs for you. You stay the boss; it does the shuttling.

## How to use it

Just tell your AI, in plain words:

> **"Run the code-audit-loop on Phase 3 of my plan."**

To check where things stand at any time:

> **"Where are we in the loop?"**

To pick up after a break:

> **"Continue the loop."**

That's the whole interface. No commands to memorize.

## What happens behind the scenes

```
You:  "Run the loop on Phase 3."

  1. CODER writes Phase 3 and updates its notes.
  2. A FRESH AUDITOR checks it        ── this is your code-audit skill, reused
        │
        ├─ Looks good?  → stops, tells you what passed, waits for YOUR OK.
        │
        └─ Found issues? → writes a fix list into your plan,
                            the Coder fixes ONLY those, then re-checks.
                            (back to step 2)

  Safety rail: after 3 rounds it stops and shows you the leftovers,
  instead of arguing with itself forever.
```

*The AI pauses between each step so you can see the progress (and the cost) — just say **"continue"** to move to the next one. Same idea as the 3-round limit: nothing runs away on its own.*

## The two safety rails (why you can trust it)

1. **It can't loop forever.** After 3 back-and-forths it stops and hands you the open issues. No runaway, no surprise bills.
2. **It never ships on its own.** It gets the work to "green," then *you* give the final go-ahead. The AI does the grunt work; the decision stays yours.

And one more: the checker always runs as a **fresh** AI with no memory of writing the code — so it can't rubber-stamp its own work. That's exactly why you used to open a new session by hand.

## Does this replace my `code-audit` skill?

**No — it uses it.** Think of `code-audit` as the inspector. This skill is the foreman who calls the inspector at the right moments. Your `code-audit` skill still works on its own whenever you want a one-off review, and it's also the "Auditor" step inside this loop. Nothing was copied or duplicated — the loop simply *calls* it.

## It already follows your usual standards

You don't have to re-teach it. Each round it:
- **follows your coding rules** (`usage_coding.md`) — small, careful changes, reuse before adding;
- **briefs the checker fully** — the builder writes a complete hand-off note (context, what to read first, goal, risks, tests) so the fresh Auditor starts with everything it needs and nothing assumed. That same note is copy-pasteable into a new session if you ever want to run the check by hand;
- **tidies the docs** it touched (brief, no clutter, no repeating itself). For a full clean-up across *all* your project docs, it can call your `doc-hygiene` skill once the whole feature is finished — not after every phase.

None of this is re-invented — the skill points at rules and skills you already own.

## Which AI it uses (you don't set this)

The loop picks the AI power and effort by itself. The builder runs on a strong model at high effort — and jumps to the *top* model for sensitive work (logins, money, secrets, data moves). The checker always runs at least as strong as the builder, so it can never be the weaker judge. You never dial any of this in.

## What it will NOT do

- It won't invent work outside the phase you named.
- It won't audit by itself (it always calls `code-audit`).
- It won't declare the phase "done and shipped" — only you do that.
- If `code-audit` isn't available, it stops right away (before writing any code) and tells you — it never fakes a review.

## The one file you might see

The skill keeps a tiny note of its progress in a folder called `code-audit-loop/`
inside your project (just which phase, which round, whose turn). You can ignore
it. If you're ever curious, ask *"where are we in the loop?"* and you'll get a
plain-English answer.
