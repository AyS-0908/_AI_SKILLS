# Phase4-Classify.ps1 — bulk classification (cheap OpenAI tier).
# Sends ONLY extracted content + path as evidence. Never name/date alone.
# Deterministic cases (dupes, temp, empty, cloud-only, unreadable) are labelled
# without calling the model.

$script:LABELS = @("active","reference","outdated_candidate","duplicate","unrelated_candidate","unclear","unreadable")

function Get-FolderContext {
    param($Manifest, [string]$Source)
    $subdirs = $Manifest.files | ForEach-Object { Split-Path $_.rel_path -Parent } |
        Where-Object { $_ } | Sort-Object -Unique | Select-Object -First 20
    $exts = $Manifest.files | Group-Object ext | Sort-Object Count -Descending |
        Select-Object -First 8 | ForEach-Object { "$($_.Name)($($_.Count))" }
    $leaf = Split-Path $Source -Leaf
    return "Folder: $leaf`nSubfolders: $($subdirs -join ', ')`nFile types: $($exts -join ', ')"
}

function Set-DeterministicLabel {
    param($Entry)
    # Returns $true if labelled without AI.
    if ($Entry.availability -eq "unreadable" -or $Entry.extraction_status -eq "failed") {
        $reason = if ($Entry.extraction_reason) { $Entry.extraction_reason } else { "no readable content" }
        $Entry.classification = @{ label="unreadable"; confidence=1.0; evidence=$reason; needs_complex=$false; model="deterministic" }; return $true
    }
    if ($Entry.dup_group -and $Entry.analyze -eq $false -and ($Entry.notes -join ' ') -match 'exact duplicate of') {
        $Entry.classification = @{ label="duplicate"; confidence=1.0; evidence=(($Entry.notes | Where-Object { $_ -match 'exact duplicate' }) -join ''); needs_complex=$false; model="deterministic" }; return $true
    }
    if ($Entry.is_temp) {
        $Entry.classification = @{ label="outdated_candidate"; confidence=0.9; evidence="temporary/backup file by type"; needs_complex=$false; model="deterministic" }; return $true
    }
    if ($Entry.is_empty) {
        $Entry.classification = @{ label="outdated_candidate"; confidence=0.85; evidence="empty file (0 bytes)"; needs_complex=$false; model="deterministic" }; return $true
    }
    if ($Entry.availability -eq "cloud_only") {
        $Entry.classification = @{ label="unclear"; confidence=0.3; evidence="cloud-only (OneDrive); make available to analyze"; needs_complex=$false; model="deterministic" }; return $true
    }
    if ($Entry.availability -eq "broken_shortcut") {
        $Entry.classification = @{ label="outdated_candidate"; confidence=0.7; evidence="broken shortcut (target missing)"; needs_complex=$false; model="deterministic" }; return $true
    }
    if ($Entry.type -eq "binary_skip" -or $Entry.type -eq "other") {
        $Entry.classification = @{ label="unclear"; confidence=0.3; evidence="binary/unsupported; content not analyzable"; needs_complex=$false; model="deterministic" }; return $true
    }
    return $false
}

function Invoke-Phase4Classify {
    param(
        [Parameter(Mandatory)] $Manifest,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)] $Config,
        [int]$MaxAiFiles,
        [double]$MaxUsd
    )

    Write-Phase "classify" "Classifying files (bulk tier: $($Config.models.bulk.name))"
    $ctx = Get-FolderContext -Manifest $Manifest -Source $Source
    $sys = @"
You classify ONE file for a folder-cleanup audit. Judge ONLY from the provided
content and path — never from the filename or date alone. Labels:
- active: current, in active use.
- reference: kept for reference, not actively edited.
- outdated_candidate: superseded or an old version of something.
- duplicate: content duplicates another file.
- unrelated_candidate: does not belong with this folder's theme.
- unclear: not enough evidence to decide.
- unreadable: no usable content.
Return STRICT JSON only:
{"label":"<one label>","confidence":<0..1>,"evidence":"<=200 chars citing content","needs_complex":<true if this looks like an old version, a near-duplicate, contradicts another document, or you are unsure>}
"@

    $spentUsd = 0.0; $calls = 0; $capHit = $false
    $aiFiles = $Manifest.files | Where-Object { $_.analyze -and $_.extracted_file }

    foreach ($e in $Manifest.files) {
        if (Set-DeterministicLabel -Entry $e) { continue }
        if (-not ($e.analyze -and $e.extracted_file)) {
            $e.classification = @{ label="unclear"; confidence=0.3; evidence="no extracted content"; needs_complex=$false; model="deterministic" }
            continue
        }
        if ($capHit) {
            $e.classification = @{ label="unclear"; confidence=0.0; evidence="AI cap reached before this file"; needs_complex=$false; model="capped" }
            continue
        }

        $snippetPath = Join-Path $OutputPath $e.extracted_file
        $snippet = Get-Content -LiteralPath $snippetPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($snippet.Length -gt 6000) { $snippet = $snippet.Substring(0, 6000) }
        $user = "$ctx`n`nFile path: $($e.rel_path)`nType: $($e.type)`nContent (may be truncated):`n$snippet"

        $r = Invoke-OpenAIJson -Config $Config -Model $Config.models.bulk.name -FallbackModel $Config.models.bulk.fallback `
            -System $sys -User $user -MaxOutTok 400
        $calls++

        if (-not $r.ok) {
            $e.classification = @{ label="unreadable"; confidence=0.0; evidence="classify error: $($r.error)"; needs_complex=$false; model=$r.model }
            $e.notes += "classify error: $($r.error)"
        } else {
            $spentUsd += Get-CostUsd -Config $Config -Model $r.model -InTok $r.in_tok -OutTok $r.out_tok
            $parsed = ConvertFrom-ModelJson -Content $r.content
            if ($r.truncated -or -not $parsed -or -not ($script:LABELS -contains $parsed.label)) {
                $e.classification = @{ label="unclear"; confidence=0.2; evidence="model output unusable/truncated"; needs_complex=$true; model=$r.model }
            } else {
                $e.classification = @{ label=$parsed.label; confidence=[double]$parsed.confidence; evidence="$($parsed.evidence)"; needs_complex=[bool]$parsed.needs_complex; model=$r.model }
            }
        }

        if ($calls -ge $MaxAiFiles -or $spentUsd -ge $MaxUsd) {
            $capHit = $true
            Write-Phase "classify" "AI cap reached ($calls files / `$$([math]::Round($spentUsd,3))). Remaining files marked unclear." "warn"
        }
    }

    Save-Json -Object $Manifest -Path (Join-Path $OutputPath "manifest.json")
    Save-Json -Object @{ phase="classify"; calls=$calls; est_usd=[math]::Round($spentUsd,4); cap_hit=$capHit } -Path (Join-Path $OutputPath "cost-classify.json")
    Write-Phase "classify" "$calls model calls, ~`$$([math]::Round($spentUsd,3)) spent" "ok"
    return $Manifest
}
