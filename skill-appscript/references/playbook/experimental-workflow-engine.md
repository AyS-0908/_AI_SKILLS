# EXPERIMENTAL CONFIG-DRIVEN WORKFLOW ENGINE

> **Confidence: `SPEC` — design-only / unfinished.**
>
> Do not load by default. Do not present this architecture, its named files, or its APIs as reusable assets. The original playbook says the AIssistant section came from a specification rather than line-by-line verified shipped code.
> Official platform validation cannot promote a design-only architecture. Only a runnable implementation and real usage can change this confidence.

## ADMISSION GATE

Use an engine only when all are true:

- The owner must create and edit many similar workflows without redeployment.
- Workflow count and change frequency make coded v1 changes materially costly.
- The owner accepts a second executable source of truth in a sheet.
- The project will build validation, guided authoring, versioning/backup, and engine tests.

Otherwise stay with a coded v1 workflow.

## IDEAS WORTH RETAINING

These are leads for implementation, not files to copy:

1. **One row per generated target column.** Keep machine identity, human label, type, order, parameters, prerequisites, and next step explicit.
2. **BUILD and RUN are separate.** BUILD validates configuration before generating sheets; RUN executes validated definitions.
3. **Validate before any structural write.** Aggregate configuration errors and identify the exact row/cell.
4. **Explicit type dispatch.** Use a small validated handler map for implemented step types; reject unknown types.
5. **One config adapter.** Parse and validate JSON/config fields at one seam before workers consume typed values.
6. **Cycle protection.** Follow one next-step reference with a visited set unless branching is deliberately designed and tested.
7. **Registered helpers only.** Resolve named transforms from an allowlisted registry; never evaluate sheet text.
8. **Workers own one action.** Each validates inputs, performs one task, writes its own outcome, and does not know the chain.
9. **Cell-size and output checks happen before writes.** Oversized or invalid AI output must not partially advance state.
10. **Guided authoring is part of the engine tax.** Config templates and validation must prevent unsupported combinations.

## DELIBERATELY NOT RETAINED AS DEFAULTS

- Formula-generated workflow columns: they reintroduce `#REF!`/recalculation risk.
- Generic retrying `callGemini` utility: retry safety depends on the boundary and failure.
- Backup/delete/regenerate file recipes: unverified implementation detail.
- Tool auto-discovery by naming convention: unnecessary until manual registration becomes a measured burden.
- Generic external-API execution from arbitrary sheet endpoint/auth/response mappings.
- Illustrative use-case configurations that the described validator would reject.
- Branching/fan-out: explicitly unbuilt in the described V2.1 design.

## IF THIS GATE IS APPROVED LATER

Before coding:

1. Inspect the real engine source, not the old specification summary.
2. Record supported step types and config schema from code.
3. Add per-item confidence tags based on runnable checks.
4. Prototype one workflow end to end.
5. Verify invalid config causes zero structural writes.
6. Only then promote specific patterns or assets from `SPEC` to `PROJECT_REPORTED` or another evidence-backed tag.
