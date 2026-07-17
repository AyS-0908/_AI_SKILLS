# Brainstorming

Use this file only after scope validation. Ask only missing questions. Use the stage, validation, resume, and handoff rules in `SKILL.md`.

## Method Questions

1. **Challenge:** What single question should the ideas answer? Propose one from the validated scope.
2. **Breadth:** How wide should exploration be?
   1. Focused on near-term options
   2. Balanced adjacent and new options (Recommended)
   3. Deliberately broad or disruptive
3. **Idea volume:** How many raw ideas are wanted?
   1. 10-15 focused ideas
   2. 20-30 varied ideas (Recommended)
   3. 40+ broad ideas
4. **Participants:** Who contributes?
   1. AI-assisted individual reflection
   2. Named workshop participants
   3. Combination
5. **Evaluation criteria:** Which criteria decide the shortlist? Propose 3-5 criteria and a weight for each.
6. **Scoring scale:** Which scale applies?
   1. 1-3 for speed
   2. 1-5 for useful discrimination (Recommended)
   3. Pass/fail gates plus 1-5 ranking

Present a compact method brief with challenge, volume, participants, criteria, weights, and scale. End with: `Reply VALIDATE METHOD or correct the numbered field(s).`

## Generation Rules

1. Separate idea generation from evaluation.
2. Generate the approved volume across distinct angles; do not pad with renamed duplicates.
3. State assumptions; do not present invented facts as evidence.
4. Keep raw ideas before clustering.
5. Merge duplicates in `Clusters`, retaining every source idea ID.
6. Score only after the user validates the clusters and criteria.
7. Show the weighted score calculation; use native Sheet formulas where possible.

## Brainstorming Sheet Schema

Create one Sheet with exactly these tabs:

### `Brief`

| field | value | validation_status |
|---|---|---|

Include validated challenge, breadth, target volume, participants, criteria, weights, scale, assumptions, and exclusions.

### `Ideas`

| idea_id | idea | short_description | angle | contributor | assumptions | status |
|---|---|---|---|---|---|---|

Allowed `status`: `raw`, `duplicate`, `retained`.

### `Clusters`

| cluster_id | cluster_name | idea_ids | consolidated_idea | distinction | validation_status |
|---|---|---|---|---|---|

### `Evaluation`

| cluster_id | criterion | weight | score | weighted_score | rationale | evidence_or_assumption | rank |
|---|---|---:|---:|---:|---|---|---:|

### `Analysis`

Use the schema in `analysis-report.md`.

## Validation Gates

- **Brief gate:** Require `VALIDATE METHOD` before generation.
- **Idea gate:** Require `VALIDATE IDEAS` before clustering changes raw-idea status.
- **Cluster gate:** Require `VALIDATE CLUSTERS AND CRITERIA` before scoring.
- **Analysis gate:** Require user validation after the independent challenge and before final-report generation.
