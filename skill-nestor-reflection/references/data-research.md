# Data Research

Use this file only after scope validation. The AI proposes the source plan; do not require the user to know suitable sources. Ask only missing questions. Use the stage, validation, resume, and handoff rules in `SKILL.md`.

## Method Questions

1. **Decision claims:** Which macro questions or claims need evidence? Propose a claim list from the validated scope.
2. **Time period:** Which historical period and recency cutoff apply?
3. **Geographic detail:** Is the validated geography sufficient, or are country/region comparisons required?
4. **Evidence depth:** Which standard applies?
   1. Directional - one strong source per material claim
   2. Decision-ready - triangulate consequential claims (Recommended)
   3. Deep - broader source and methodology review
5. **Source access:** Which sources may be used?
   1. Free public sources only
   2. User-provided subscriptions or databases
   3. Paid sources within the validated budget
6. **Internal evidence:** Which user-provided documents or datasets should be included? Label them as internal.
7. **Exclusions:** Are any publishers, source types, methods, or data classes prohibited?

Present the proposed claim and source plan. End with: `Reply VALIDATE SOURCE PLAN or correct the numbered field(s).`

## Source Plan

For each claim, propose:

`claim_id`, `claim`, `preferred_source_types`, `candidate_publishers`, `search_terms`, `geography`, `date_range`, `triangulation_needed`.

Do not treat candidate publishers as pre-approved evidence. Evaluate the actual source.

## Reliability Gate

Before using a source as evidence:

1. Verify the actual page or document; never cite a search-result snippet or AI memory.
2. Record author or publisher, title, URL, publication date, access date, geography, source type, and methodology when relevant.
3. Judge reliability for the specific claim:
   1. **A - Authoritative primary:** law, regulator, official statistics, standards body, original dataset, company filing, or original research.
   2. **B - Recognized independent:** established research institution, academic publisher, or reputable specialist source with transparent methods.
   3. **C - User-provided internal:** useful internal evidence; label it and do not present it as independent validation.
   4. **D - Discovery only:** anonymous, promotional, aggregating, or methodologically opaque material. Use only to find stronger sources.
4. Reject a material claim supported only by class D.
5. For a consequential, surprising, or contested claim, require two independent sources where available, preferably including one class A source.
6. Record conflicts instead of averaging them away. Explain whether differences come from date, geography, definitions, sample, method, or incentives.
7. Mark unavailable, outdated, or non-comparable evidence as a gap. Do not invent precision.

IF the gate fails -> exclude the claim from conclusions or label it provisional and request user approval to continue.

## Research Sheet Schema

Create one Sheet with exactly these tabs:

### `Brief`

| field | value | validation_status |
|---|---|---|

Include validated scope, claim plan, inclusions, exclusions, date range, and budget.

### `Sources`

| source_id | title | author_or_publisher | url | source_type | publication_date | access_date | geography | reliability_class | reliability_rationale | status |
|---|---|---|---|---|---|---|---|---|---|---|

Allowed `status`: `candidate`, `accepted`, `rejected`, `unavailable`.

### `Evidence`

| evidence_id | claim_id | claim | source_id | source_type | publication_date | geography | evidence | reliability_rationale | conflicts | gaps |
|---|---|---|---|---|---|---|---|---|---|---|

This preserves the PRD-required claim, source, type, date, geography, reliability, conflicts, and gaps fields.

### `Analysis`

Use the schema in `analysis-report.md`.

## Validation Gates

- **Source-plan gate:** Require `VALIDATE SOURCE PLAN` before broad collection.
- **Evidence gate:** Check every conclusion against accepted evidence and the reliability gate.
- **Analysis gate:** Require user validation after the independent challenge and before final-report generation.
