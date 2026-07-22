# Claude Fable 5 / Mythos 5

Apply this file only when the requested target is Claude Fable 5 or Mythos 5.
Write the prompt; do not perform the task.

## Contents

- [Gotchas](#gotchas)
- [Output contract](#output-contract)
- [Fable-specific adjustments](#fable-specific-adjustments)
- [Recommend effort](#recommend-effort)
- [Final check](#final-check)

## Gotchas

- Over-instruction is the main failure mode. Pick only the directives whose
  triggers match; never paste the whole directive catalogue.
- Never ask Fable to explain, show, or narrate its reasoning or thought process.
- IF the task touches cyber or bio -> warn the user that even benign adjacent
  work may trigger a refusal.
- Do not put API parameters in prompt text. Non-default sampling values, manual
  thinking budgets, and disabled thinking are unsupported.
- Put the complete task specification in one prompt instead of deferring pieces
  to follow-up turns.
- Use the shared prompt architecture and behavior decisions from `SKILL.md`.
  Do not reproduce a separate Fable template or directive catalogue.

## Output contract

Emit exactly:

```text
**Effort:** <level> - <one-line reason>

---
<the prompt, copy-paste ready>
---
```

IF the task touches cyber or bio -> add one warning line above the block.

## Fable-specific adjustments

- Fable follows brief instructions strongly. Use the shared behavior decisions
  as intent, not as text to copy. Prefer one task-specific sentence over several
  generic reminders.
- IF the task combines several file reads with external research, spans many
  tool calls, or otherwise runs unattended for a long time -> tell Fable once
  to continue safe in-scope work until complete or blocked on user-only input.
- IF the harness exposes a context countdown during a long task -> state that
  compaction or continuation is available and that Fable must not stop solely
  because of the displayed budget.
- IF work spans sessions and a memory location already exists -> tell Fable to
  update the smallest relevant existing note with confirmed lessons and remove
  notes proven wrong. Do not invent a memory system for one-shot work.
- IF the task asks Fable to inspect its own reasoning, reproduce hidden thought,
  or narrate private reflection -> remove that request. Ask only for conclusions,
  evidence, checks, or concise rationale.
- Do not add model-behavior labels such as `Outcome-first`, `Act-once`, or
  `Assess-only` to the generated prompt.

## Recommend effort

| Task | Effort |
|---|---|
| Simple, high-volume, cost-sensitive, or latency-sensitive | `low` - efficient, with some capability reduction |
| Balanced speed, cost, and performance | `medium` |
| Most tasks | `high` - default starting point |
| Capability-sensitive or long-horizon | `xhigh` |
| Deepest reasoning and maximum capability without a token constraint | `max` - highest cost and latency |

At `high` and above, apply the shared scope rule for code changes. For prose,
the shared conclusion-first behavior is usually sufficient.

## Final check

- [ ] The `Effort` line and prompt wrapper from the output contract are present.
- [ ] Shared behavior decisions were adapted and merged, not copied as named
      directives.
- [ ] No Fable-specific adjustment appears unless its condition fired.
- [ ] No request for hidden reasoning appears.
- [ ] No unnecessary step-by-step scaffolding or API parameter appears.
- [ ] The whole task specification is present.
- [ ] The shared section ownership, de-duplication, and conflict checks pass.
- [ ] An edited prompt is no longer than its source unless a genuinely missing
      correctness requirement was added.

Client timeouts, model fallback, tools, and API configuration belong to the
harness or client, not to the pasted prompt.
