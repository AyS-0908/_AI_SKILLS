# Narrative Output Template

Used for single-entity mode ("X vs the market") or when the user asks for narrative
instead of a matrix. The pipeline is unchanged: `benchmark.json` is still built,
validated, and rendered — the narrative reshapes the rendered content, and the
matrix + sources move to an appendix.

```
## [Title] — Positioning Analysis
Scope: [Entity] vs [market refs] · [Purpose] · [Depth] · [Date]

### Context
[2 sentences: why this entity, which market references, comparison logic]

### Analysis
**[Main entity]** — positioning, strengths, weaknesses. Every claim anchored to
a matrix cell (cite the source number from the rendered appendix).
**[Ref 1]** / **[Ref 2]** — calibration only, shorter.

### Cross-cutting Findings
[What emerges across entities — structural arbitrage, shared risk, market dynamic]

### Recommendations
[Recommended posture for the stated purpose + condition under which it changes.
No recommendation without a finding behind it.]

### Appendix — Data
[Paste the rendered matrix, Sources, and Data Quality sections from benchmark.md verbatim.]
```

Rules carried over from the matrix format:

- The auto-generated Data Quality section is never edited or dropped — it is the
  reader's trust anchor.
- `[DATA GAP]` / `[NOT COMPARABLE]` labels stay visible in the appendix; if a gap
  affects a narrative claim, say so in the analysis.
