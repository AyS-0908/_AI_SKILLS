# Phase4-Queue.ps1 — create the global-analysis handoff and deterministic batches.

function Invoke-Phase4Queue {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)]$Config
    )

    Write-Phase "queue" "Building host analysis handoff and batches"

    $duplicateById = @{}
    foreach ($group in @($Manifest.duplicate_groups)) {
        $duplicateById["$($group.analysis_representative_id)"] = $group
    }

    $tasks = @()
    foreach ($entry in @($Manifest.files)) {
        if ($entry.exact_duplicate_group -and -not $entry.is_analysis_representative) { continue }
        if (-not [bool]$entry.submit_to_host) { continue }

        $group = $null
        if ($duplicateById.ContainsKey("$($entry.id)")) { $group = $duplicateById["$($entry.id)"] }
        $tasks += [pscustomobject]@{
            id = "$($entry.id)"
            rel_path = "$($entry.rel_path)"
            occurrence_paths = if ($group) { @($group.occurrence_paths) } else { @($entry.rel_path) }
            exact_duplicate_group = if ($group) { "$($group.group_id)" } else { $null }
            type = "$($entry.type)"
            kind = "$($entry.kind)"
            size_bytes = [long]$entry.size_bytes
            modified = "$($entry.modified)"
            content_ref = $entry.extracted_file
            content_sha256 = $entry.extracted_sha256
            extraction_status = "$($entry.extraction_status)"
            extraction_reason = $entry.extraction_reason
            extraction_truncated = ($entry.extraction_status -eq "truncated")
            decoding_errors = [bool]$entry.decoding_errors
            image_metadata = $entry.image_metadata
            needs_visual = [bool]$entry.needs_visual
            notes = @($entry.notes)
        }
    }

    $batchDir = Join-Path $OutputPath "analysis-batches"
    $batchResultDir = Join-Path $OutputPath "batch-results"
    New-Item -ItemType Directory -Force -Path $batchDir | Out-Null
    New-Item -ItemType Directory -Force -Path $batchResultDir | Out-Null

    $maxFiles = [int]$Config.analysis.batch_limits.max_files
    $maxChars = [int]$Config.analysis.batch_limits.max_total_chars
    $batches = @()
    $current = @()
    $currentChars = 0

    foreach ($task in $tasks) {
        $chars = 0
        if ($task.content_ref) {
            $contentPath = Join-Path $OutputPath "$($task.content_ref)"
            if (Test-Path -LiteralPath $contentPath) {
                $chars = (Get-Content -LiteralPath $contentPath -Raw -Encoding UTF8).Length
            }
        }
        if ($current.Count -gt 0 -and ($current.Count -ge $maxFiles -or ($currentChars + $chars) -gt $maxChars)) {
            $batches += ,@($current)
            $current = @()
            $currentChars = 0
        }
        $current += $task
        $currentChars += $chars
    }
    if ($current.Count -gt 0) { $batches += ,@($current) }

    $batchIndex = @()
    for ($i = 0; $i -lt $batches.Count; $i++) {
        $batchId = "b{0:D3}" -f ($i + 1)
        $batchFile = "analysis-batches/$batchId.json"
        $resultFile = "batch-results/$batchId.json"
        $batchObject = [ordered]@{
            schema = 1
            run_id = $RunId
            batch_id = $batchId
            context_ref = "context.json"
            task_ids = @($batches[$i] | ForEach-Object { $_.id })
            tasks = @($batches[$i])
        }
        Save-Json -Object $batchObject -Path (Join-Path $OutputPath $batchFile)
        $batchIndex += [pscustomobject]@{
            batch_id = $batchId
            task_count = @($batches[$i]).Count
            input_ref = $batchFile
            result_ref = $resultFile
        }
    }

    Save-Json -Object $Manifest -Path (Join-Path $OutputPath "manifest.json")
    $manifestSha = Get-FileSha256 -Path (Join-Path $OutputPath "manifest.json")
    $contextSha = Get-FileSha256 -Path (Join-Path $OutputPath "context.json")
    $nonDuplicateIds = @($tasks | Where-Object { -not $_.exact_duplicate_group } | ForEach-Object { $_.id })
    $duplicatePaths = @($Manifest.duplicate_groups | ForEach-Object { @($_.occurrence_paths) })

    $queue = [ordered]@{
        schema = 2
        run_id = $RunId
        manifest_sha256 = $manifestSha
        context_sha256 = $contextSha
        created_at = (Get-Date).ToString("o")
        status = "awaiting_host"
        context_ref = "context.json"
        roles = $script:DOCUMENT_ROLES
        actions = $script:PLAN_ACTIONS
        tasks = $tasks
        non_duplicate_disposition_ids = $nonDuplicateIds
        duplicate_occurrence_paths = $duplicatePaths
        duplicate_groups = @($Manifest.duplicate_groups)
        batch_limits = $Config.analysis.batch_limits
        batch_index = $batchIndex
        final_output_ref = "analysis-results.json"
    }
    $queuePath = Join-Path $OutputPath "analysis-queue.json"
    Save-Json -Object $queue -Path $queuePath

    Write-Phase "queue" "$($tasks.Count) semantic file(s) in $($batches.Count) batch(es) -> analysis-queue.json" "ok"
    return [pscustomobject]$queue
}
