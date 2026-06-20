# OpenAI setup, model choice & cost

## API key
The orchestrator reads the key from the environment variable `OPENAI_API_KEY`.
Set it for the current PowerShell session:

```powershell
$env:OPENAI_API_KEY = "sk-..."
```

Or persist it for your user account (new terminals only):

```powershell
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "sk-...", "User")
```

If the key is missing, AI phases are **skipped, not faked**. Use `-SkipAI` to run
inventory + extraction with no key at all (a good first smoke test).

## Models (config.json → `models`)
| Tier | Default | Fallback | Used for |
|---|---|---|---|
| bulk | `gpt-5-mini` | `gpt-4o-mini` | Phase 4 — classify every analyzable file |
| complex | `gpt-5` | `gpt-4o` | Phase 5 — version chains, near-dupes, contradictions |

If a primary model 404s (not enabled on the account), the wrapper automatically
retries on the fallback and records which model actually answered each file. To
change models, edit `config.json` — never hard-code them in scripts.

## PDF extraction
Office files (docx/xlsx/pptx) are parsed natively — no dependency. **PDFs need an
external text extractor.** Default is `pdftotext` (from Poppler). Install one of:

- Poppler for Windows (provides `pdftotext.exe`) — put it on `PATH`.
- Or set `config.json → pdf_extractor` to another CLI that takes `<in> <out>`.

Without an extractor, PDFs are recorded as `extraction_failed` (reason logged) and
classified `unreadable` — never silently skipped.

## Cost
Pricing in `config.json → pricing_per_mtok` is approximate and only drives the USD
*estimate*; it is not billing-accurate. Real spend depends on file count and text
length. Controls:

- `extract_char_cap` (default 12000) caps text per file before it's sent.
- Classification sends ≤6000 chars/file; complex analysis ≤2500 chars/file.
- `-MaxAiFiles` and `-MaxUsd` stop the AI phases early; remaining files become
  `unclear`. Defaults: `caps.max_ai_files = 2000`, `caps.max_usd = 5.0`.

Rule of thumb: a few hundred small documents on the bulk tier is typically well
under a dollar. Run `-SkipAI` first to see the file count before spending anything.

## Privacy
Extracted **text content** of analyzable files is sent to OpenAI. Binary files are
never uploaded (not extracted). Cloud-only files are never downloaded or uploaded.
If a folder contains sensitive documents, run `-SkipAI` (no upload) or exclude those
files before running.
