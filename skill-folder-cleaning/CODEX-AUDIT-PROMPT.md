# Codex audit prompt — folder-cleaning skill

> **How to run this audit:** point Codex online at the GitHub repo
> `https://github.com/AyS-0908/AI_SKILLS` (folder `skill-folder-cleaning/`), or open
> Codex CLI/IDE locally at `C:\Users\aymar\AYS_CODING\code-AI_SKILLS`.
> This is a **static + design audit — Codex does not need to execute the code**, so the
> Windows-only nature of the scripts is irrelevant here. (Running the skill for real is a
> separate, local-Windows step.)

---

You are auditing a Claude/Codex **skill** called `folder-cleaning`. It audits a messy
local Windows folder (read-only) and proposes a safe, reversible cleanup. Read these
files before judging anything — do not assume, verify against the code:

- `skill-folder-cleaning/SKILL.md`
- `skill-folder-cleaning/scripts/run-folder-cleaning.ps1`
- `skill-folder-cleaning/scripts/lib/Common.ps1`
- `skill-folder-cleaning/scripts/lib/Phase1-Resolve.ps1`
- `skill-folder-cleaning/scripts/lib/Phase2-Inventory.ps1`
- `skill-folder-cleaning/scripts/lib/Phase3-Extract.ps1`
- `skill-folder-cleaning/scripts/lib/Phase4-Classify.ps1`
- `skill-folder-cleaning/scripts/lib/Phase5-Analyze.ps1`
- `skill-folder-cleaning/scripts/lib/OpenAI.ps1`
- `skill-folder-cleaning/scripts/lib/Phase6-Report.ps1`
- `skill-folder-cleaning/scripts/config/config.json`
- `skill-folder-cleaning/reference/architecture.md`

## Context you must factor in

- The pipeline runs as a fixed, resumable sequence: Phase 1 Resolve -> 2 Inventory ->
  3 Extraction -> 4 Classify -> 5 Complex analysis -> 6 Report. Only `analyze`
  (read-only) mode is built; Phase 7 (apply: move to `_ARCHIVE`, rollback) is deferred.
- Safety invariants the code MUST uphold: no writes to the source tree in analyze mode;
  artifacts never written inside the source folder; no hard delete anywhere; every file
  accounted for (no silent skips); never classify a file from name/date alone; exact
  duplicates detected deterministically by SHA-256 (never sent to a model).
- **Architecture is pivoting — judge the code against where it is going, not just where
  it is:** the OpenAI REST integration (`OpenAI.ps1`, the API-key path in Phase 4/5) is
  being REMOVED. The skill must become **host-agnostic with no API key**: the host agent
  that runs the skill (Codex, or Claude Code) performs the semantic classification
  itself. The intended contract is — the orchestrator runs Phases 1-3 and emits a
  classification queue (`extracted/<id>.txt` plus a tasks file); the host agent reads it,
  classifies each file with evidence + confidence, and writes `classifications.json`
  back; the orchestrator ingests that and builds the report (Phase 6). "Model routing"
  becomes a host concern: in Claude, Haiku for bulk/clear-cut, Sonnet for low-complexity,
  Opus for hard cases (version chains, near-duplicates, contradictions, low confidence).

## Deliverable

Produce a prioritized findings report. For each finding give: severity (P0 = correctness
or safety bug, must fix; P1 = should fix; P2 = nice-to-have), the `file:line`, the
problem, and a concrete fix.

Audit these areas specifically:

1. **Safety invariants** — prove or disprove that analyze mode cannot write to the source,
   that the output-inside-source guard is correct (including path-prefix edge cases like
   `C:\src` vs `C:\src2`), and that nothing hard-deletes.
2. **Determinism & correctness** — SHA-256 dedupe and "keep oldest" logic; empty/temp
   detection; exact-duplicate vs the `analyze` flag interactions; manifest integrity
   across phases.
3. **Windows edge cases** — long paths (`\\?\`), OneDrive cloud-only detection
   (`FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS` / Offline; is the attribute check correct and
   sufficient?), `.lnk` resolution via WScript.Shell, UTF-8/BOM decoding, files with no
   read permission, reparse points / symlink loops in recursion.
4. **Extraction** — the .NET zip parsing of docx/xlsx/pptx (correctness, truncation,
   malformed Office files); PDF via external `pdftotext` (missing-tool handling); the
   `extract_char_cap` logic; guarantee that no analyzable file is silently dropped.
5. **Checkpoint / resume** — is `state.json` + per-phase `done` reload sound? Can a run
   interrupted mid-phase resume without corrupting `manifest.json`? Are partial writes
   atomic enough?
6. **PowerShell robustness** — StrictMode pitfalls (scalar-vs-array, null `.Count`),
   `ConvertTo-Json -Depth` truncation risk, error-handling completeness, PS 5.1 vs 7
   compatibility.
7. **The pivot (design review, not line-level)** — critique the planned host-agnostic
   classification handoff. Propose the exact contract: queue file shape, how the
   orchestrator pauses and resumes around the agent, how `classifications.json` is
   validated on ingest (schema, unknown labels, missing ids), and how the Haiku/Sonnet/
   Opus tiering should be expressed so it works identically under Codex and Claude. Call
   out any risk in removing `OpenAI.ps1` (e.g. should a headless fallback remain?).
8. **Whether the Windows-only design blocks running under Codex cloud (Linux)** — and if
   so, what minimal portability changes would unblock it.

End with a short, ordered refactor plan to reach the host-agnostic, no-API-key target.
