# Phase6-Report.ps1 — build plan.json, validate it, and write cleaning-report.md.
# No source writes. The plan is a PROPOSAL; nothing is executed here.

function Get-Bucket {
    param($Entry)
    # Map a classification to a proposed disposition.
    $label = if ($Entry.classification) { $Entry.classification.label } else { "unclear" }
    if ($Entry.dup_group -and (($Entry.notes -join ' ') -match 'exact duplicate of')) {
        return @{ op="archive"; bucket="duplicates"; needs_decision=$false }
    }
    switch ($label) {
        "duplicate"           { return @{ op="archive"; bucket="duplicates";  needs_decision=$false } }
        "outdated_candidate"  { return @{ op="archive"; bucket="outdated";     needs_decision=$false } }
        "unrelated_candidate" { return @{ op="review";  bucket="unrelated";    needs_decision=$true  } }
        "active"              { return @{ op="keep";    bucket=$null;          needs_decision=$false } }
        "reference"           { return @{ op="keep";    bucket=$null;          needs_decision=$false } }
        "unreadable"          { return @{ op="review";  bucket=$null;          needs_decision=$true  } }
        default               { return @{ op="review";  bucket=$null;          needs_decision=$true  } }  # unclear
    }
}

function Invoke-Phase6Report {
    param(
        [Parameter(Mandatory)] $Manifest,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)] $Config,
        [bool]$AiRan
    )

    Write-Phase "report" "Building cleaning proposal"
    $ops = @(); $decisions = @(); $hashIndex = @{}
    foreach ($e in $Manifest.files) {
        if ($e.sha256) { $hashIndex[$e.rel_path] = $e.sha256 }
        $b = Get-Bucket -Entry $e
        $conf = if ($e.classification) { [double]$e.classification.confidence } else { 0 }
        $ev   = if ($e.classification) { "$($e.classification.evidence)" } else { "" }
        $to = $null
        if ($b.op -eq "archive") { $to = "_ARCHIVE/$($b.bucket)/$($e.rel_path)" }

        $ops += [pscustomobject]@{
            id = $e.id; rel_path = $e.rel_path; op = $b.op; to = $to
            label = $(if ($e.classification) { $e.classification.label } else { "unclear" })
            reason = $ev; confidence = $conf; size_bytes = $e.size_bytes
        }
        # Decisions: anything the user must confirm.
        if ($b.needs_decision -or $e.availability -eq "cloud_only" -or ($conf -lt 0.5 -and $b.op -ne "keep")) {
            $decisions += [pscustomobject]@{
                id=$e.id; rel_path=$e.rel_path
                question=$(switch ($e.availability) {
                    "cloud_only" { "Cloud-only file — make available locally so it can be analyzed?" }
                    default { "Confirm proposed action '$($b.op)' (label=$($(if($e.classification){$e.classification.label})), confidence=$conf)" }
                })
                evidence=$ev
            }
        }
    }

    $plan = [ordered]@{
        schema = 1
        generated = (Get-Date).ToString("o")
        source = $Source
        mode = "analyze"
        ai_ran = $AiRan
        source_hash_index = $hashIndex
        operations = $ops
        decisions = $decisions
    }
    Save-Json -Object $plan -Path (Join-Path $OutputPath "plan.json")

    # Structural validation (no source writes; in-process, no external schema engine).
    $errors = @()
    if ($plan.schema -ne 1) { $errors += "schema must be 1" }
    foreach ($o in $ops) {
        if (-not $o.id) { $errors += "operation missing id" }
        if (@("keep","archive","review","move","rename") -notcontains $o.op) { $errors += "$($o.id): bad op '$($o.op)'" }
        if ($o.op -eq "archive" -and -not $o.to) { $errors += "$($o.id): archive without destination" }
    }
    $valid = ($errors.Count -eq 0)
    Save-Json -Object @{ schema=1; valid=$valid; error_count=$errors.Count; errors=$errors; generated=(Get-Date).ToString("o") } -Path (Join-Path $OutputPath "plan-validation.json")

    # ---- Human-readable report ----
    $archive = @($ops | Where-Object { $_.op -eq "archive" })
    $review  = @($ops | Where-Object { $_.op -eq "review" })
    $keep    = @($ops | Where-Object { $_.op -eq "keep" })
    $reclaim = ($archive | Measure-Object size_bytes -Sum).Sum
    if (-not $reclaim) { $reclaim = 0 }
    $reclaimMb = [math]::Round($reclaim / 1MB, 2)
    $cloud = @($Manifest.files | Where-Object { $_.availability -eq "cloud_only" })
    $unread = @($Manifest.files | Where-Object { $_.classification -and $_.classification.label -eq "unreadable" })

    $md = New-Object System.Text.StringBuilder
    [void]$md.AppendLine("# Cleaning report")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("**Source:** ``$Source``  ")
    [void]$md.AppendLine("**Generated:** $((Get-Date).ToString('u'))  ")
    [void]$md.AppendLine("**Mode:** analyze (read-only — nothing has been moved or deleted)  ")
    [void]$md.AppendLine("**AI classification:** $(if ($AiRan) { 'yes' } else { 'SKIPPED (inventory only)' })")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## Summary")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("| Metric | Value |")
    [void]$md.AppendLine("|---|---|")
    [void]$md.AppendLine("| Files scanned | $($Manifest.file_count) |")
    [void]$md.AppendLine("| Exact-duplicate groups | $($Manifest.dup_groups) |")
    [void]$md.AppendLine("| Proposed to archive | $($archive.Count) |")
    [void]$md.AppendLine("| Needs your decision | $($review.Count) |")
    [void]$md.AppendLine("| Keep as-is | $($keep.Count) |")
    [void]$md.AppendLine("| Reclaimable (archive) | $reclaimMb MB |")
    [void]$md.AppendLine("| Cloud-only (not analyzed) | $($cloud.Count) |")
    [void]$md.AppendLine("| Unreadable | $($unread.Count) |")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("> Approve by telling the operator. Do **not** edit ``plan.json`` by hand.")
    [void]$md.AppendLine("")

    [void]$md.AppendLine("## Proposed structure (apply mode, not yet executed)")
    [void]$md.AppendLine("")
    [void]$md.AppendLine('```')
    [void]$md.AppendLine("$(Split-Path $Source -Leaf)/")
    [void]$md.AppendLine("  <kept files in place>")
    [void]$md.AppendLine("  _ARCHIVE/")
    [void]$md.AppendLine("    duplicates/   ($(@($archive | Where-Object { $_.to -like '*duplicates*' }).Count) files)")
    [void]$md.AppendLine("    outdated/     ($(@($archive | Where-Object { $_.to -like '*outdated*' }).Count) files)")
    [void]$md.AppendLine("    unrelated/    (only after you confirm)")
    [void]$md.AppendLine('```')
    [void]$md.AppendLine("")

    [void]$md.AppendLine("## Archive candidates (safe, reversible)")
    [void]$md.AppendLine("")
    if ($archive.Count -eq 0) { [void]$md.AppendLine("_None._") }
    else {
        [void]$md.AppendLine("| File | Label | Why | Confidence |")
        [void]$md.AppendLine("|---|---|---|---|")
        foreach ($o in ($archive | Sort-Object confidence -Descending)) {
            [void]$md.AppendLine("| ``$($o.rel_path)`` | $($o.label) | $($o.reason) | $([math]::Round($o.confidence,2)) |")
        }
    }
    [void]$md.AppendLine("")

    [void]$md.AppendLine("## Decisions needed from you")
    [void]$md.AppendLine("")
    if ($decisions.Count -eq 0) { [void]$md.AppendLine("_None._") }
    else {
        foreach ($d in $decisions) {
            [void]$md.AppendLine("- **``$($d.rel_path)``** — $($d.question)")
            if ($d.evidence) { [void]$md.AppendLine("  - evidence: $($d.evidence)") }
        }
    }
    [void]$md.AppendLine("")

    [void]$md.AppendLine("## Unavailable / unreadable")
    [void]$md.AppendLine("")
    if ($cloud.Count -eq 0 -and $unread.Count -eq 0) { [void]$md.AppendLine("_None._") }
    else {
        foreach ($f in $cloud)  { [void]$md.AppendLine("- ☁️ ``$($f.rel_path)`` — cloud-only (OneDrive); make available to analyze") }
        foreach ($f in $unread) { [void]$md.AppendLine("- ⚠️ ``$($f.rel_path)`` — $($f.classification.evidence)") }
    }
    [void]$md.AppendLine("")
    [void]$md.AppendLine("---")
    [void]$md.AppendLine("_Artifacts: manifest.json · plan.json · plan-validation.json · analysis.json · extraction-log.json_")

    [System.IO.File]::WriteAllText((Get-LongPath (Join-Path $OutputPath "cleaning-report.md")), $md.ToString(), (New-Object System.Text.UTF8Encoding($false)))

    if (-not $valid) { Write-Phase "report" "plan validation FAILED ($($errors.Count) errors) — see plan-validation.json" "error" }
    Write-Phase "report" "cleaning-report.md ready | archive=$($archive.Count) review=$($review.Count) keep=$($keep.Count) | ~$reclaimMb MB reclaimable" "ok"
    return $valid
}
