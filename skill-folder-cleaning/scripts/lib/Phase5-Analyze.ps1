# Phase5-Analyze.ps1 — complex analysis (strong OpenAI tier).
# Only runs on the hard cases: needs_complex=true, low confidence, or possible
# version chains / near-duplicates. Obvious files from Phase 4 are not re-examined.

function Get-ComplexCandidates {
    param($Manifest)
    return $Manifest.files | Where-Object {
        $_.classification -and (
            $_.classification.needs_complex -eq $true -or
            ([double]$_.classification.confidence -lt 0.6 -and $_.classification.model -notmatch 'deterministic') -or
            $_.classification.label -eq "outdated_candidate" -or
            $_.classification.label -eq "duplicate"
        ) -and $_.extracted_file
    }
}

function Invoke-Phase5Analyze {
    param(
        [Parameter(Mandatory)] $Manifest,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)] $Config,
        [int]$MaxAiFiles,
        [double]$MaxUsd
    )

    $candidates = @(Get-ComplexCandidates -Manifest $Manifest)
    Write-Phase "analyze" "Complex analysis on $($candidates.Count) candidate(s) (strong tier: $($Config.models.complex.name))"
    if ($candidates.Count -eq 0) {
        Save-Json -Object @{ schema=1; generated=(Get-Date).ToString("o"); groups=@(); overrides=@() } -Path (Join-Path $OutputPath "analysis.json")
        return $Manifest
    }

    $sys = @"
You resolve the HARD cases in a folder-cleanup audit. Given a batch of candidate
files (path, current label, evidence, content snippet), find relationships and
finalize judgements. Focus on: version chains (which file supersedes which),
near-duplicates (similar but not identical content), and contradictory documents.
Use content evidence, not filenames or dates alone — but a later date CONFIRMING
newer content is valid supporting evidence.
Return STRICT JSON only:
{"groups":[{"kind":"version_chain|near_duplicate|contradiction","members":["id",...],"authoritative":"id or null","evidence":"<=240 chars","confidence":<0..1>}],
"overrides":[{"id":"id","label":"active|reference|outdated_candidate|duplicate|unrelated_candidate|unclear","confidence":<0..1>,"evidence":"<=200 chars"}]}
"@

    # Group by parent folder so version chains stay in the same call; chunk to bound tokens.
    $byDir = $candidates | Group-Object { Split-Path $_.rel_path -Parent }
    $allGroups = @(); $allOverrides = @()
    $spentUsd = 0.0; $calls = 0; $capHit = $false

    foreach ($grp in $byDir) {
        $chunks = @(); $cur = @()
        foreach ($f in $grp.Group) { $cur += $f; if ($cur.Count -ge 20) { $chunks += ,$cur; $cur = @() } }
        if ($cur.Count -gt 0) { $chunks += ,$cur }

        foreach ($chunk in $chunks) {
            if ($capHit) { break }
            $records = foreach ($f in $chunk) {
                $snip = Get-Content -LiteralPath (Join-Path $OutputPath $f.extracted_file) -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                if ($snip.Length -gt 2500) { $snip = $snip.Substring(0, 2500) }
                "id=$($f.id) | path=$($f.rel_path) | label=$($f.classification.label) | evidence=$($f.classification.evidence)`n--snippet--`n$snip`n"
            }
            $user = "Candidate files in folder '$($grp.Name)':`n`n" + ($records -join "`n====`n")

            $r = Invoke-OpenAIJson -Config $Config -Model $Config.models.complex.name -FallbackModel $Config.models.complex.fallback `
                -System $sys -User $user -MaxOutTok 1500
            $calls++
            if ($r.ok) {
                $spentUsd += Get-CostUsd -Config $Config -Model $r.model -InTok $r.in_tok -OutTok $r.out_tok
                $parsed = ConvertFrom-ModelJson -Content $r.content
                if ($parsed) {
                    if ($parsed.PSObject.Properties.Name -contains "groups" -and $parsed.groups) { $allGroups += $parsed.groups }
                    if ($parsed.PSObject.Properties.Name -contains "overrides" -and $parsed.overrides) { $allOverrides += $parsed.overrides }
                }
            } else {
                Write-Phase "analyze" "batch error: $($r.error)" "warn"
            }
            if ($calls -ge $MaxAiFiles -or $spentUsd -ge $MaxUsd) { $capHit = $true; Write-Phase "analyze" "AI cap reached in complex analysis." "warn" }
        }
    }

    # Apply overrides to manifest classifications (record provenance).
    foreach ($ov in $allOverrides) {
        $target = $Manifest.files | Where-Object { $_.id -eq $ov.id } | Select-Object -First 1
        if ($target -and $target.classification) {
            $target.classification.label = $ov.label
            $target.classification.confidence = [double]$ov.confidence
            $target.classification.evidence = "$($ov.evidence) [complex]"
            $target.classification.model = $Config.models.complex.name
            $target.classification.needs_complex = $false
        }
    }

    Save-Json -Object @{ schema=1; generated=(Get-Date).ToString("o"); groups=$allGroups; overrides=$allOverrides; calls=$calls; est_usd=[math]::Round($spentUsd,4) } -Path (Join-Path $OutputPath "analysis.json")
    Save-Json -Object $Manifest -Path (Join-Path $OutputPath "manifest.json")
    Write-Phase "analyze" "$calls model calls, ~`$$([math]::Round($spentUsd,3)) spent, $($allGroups.Count) relationship group(s)" "ok"
    return $Manifest
}
