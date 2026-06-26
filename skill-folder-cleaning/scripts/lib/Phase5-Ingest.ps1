# Phase5-Ingest.ps1 — validate all host batches and the global organization result,
# then merge them into exactly one proposed entry per source file.

function Test-AnalysisResultsFile {
    param([string]$OutputPath)
    return (Test-Path -LiteralPath (Join-Path $OutputPath "analysis-results.json"))
}

function Test-AnalysisItem {
    param(
        $Item,
        [string]$Id,
        [hashtable]$KnownIds,
        [ref]$Errors
    )
    if ($script:DOCUMENT_ROLES -notcontains "$(Get-ObjectProperty $Item 'document_role' '')") {
        $Errors.Value += "$Id`: invalid document_role"
    }
    $confidence = 0
    try { $confidence = [int](Get-ObjectProperty $Item "confidence" 0) } catch { $confidence = 0 }
    if ($confidence -lt 1 -or $confidence -gt 10) { $Errors.Value += "$Id`: confidence must be 1..10" }
    if ([string]::IsNullOrWhiteSpace("$(Get-ObjectProperty $Item 'content_summary' '')")) {
        $Errors.Value += "$Id`: content_summary is required"
    }
    if ([string]::IsNullOrWhiteSpace("$(Get-ObjectProperty $Item 'evidence' '')")) {
        $Errors.Value += "$Id`: evidence is required"
    }
    $seenRelated = @{}
    foreach ($relatedId in @(Get-ObjectProperty $Item "related_ids" @())) {
        $key = "$relatedId"
        if (-not $KnownIds.ContainsKey($key)) { $Errors.Value += "$Id`: unknown related_id '$key'" }
        if ($key -eq $Id) { $Errors.Value += "$Id`: related_ids cannot include itself" }
        if ($seenRelated.ContainsKey($key)) { $Errors.Value += "$Id`: duplicate related_id '$key'" }
        $seenRelated[$key] = $true
    }
}

function Test-DispositionItem {
    param(
        $Disposition,
        $Entry,
        $Context,
        [ref]$Errors
    )
    $id = "$($Entry.id)"
    $action = "$(Get-ObjectProperty $Disposition 'action' '')"
    if ($script:PLAN_ACTIONS -notcontains $action) { $Errors.Value += "$id`: invalid action '$action'" }

    $proposedName = "$(Get-ObjectProperty $Disposition 'proposed_name' '')"
    if ([string]::IsNullOrWhiteSpace($proposedName)) {
        $Errors.Value += "$id`: proposed_name is required"
    } else {
        if ($proposedName -ne [System.IO.Path]::GetFileName($proposedName)) {
            $Errors.Value += "$id`: proposed_name must be a filename, not a path"
        }
        $nameError = Test-WindowsName -Name $proposedName
        if ($nameError) { $Errors.Value += "$id`: $nameError" }
        if ([System.IO.Path]::GetExtension($proposedName).ToLowerInvariant() -ne "$($Entry.ext)".ToLowerInvariant()) {
            $Errors.Value += "$id`: proposed_name must preserve extension '$($Entry.ext)'"
        }
    }

    $targetFolder = $null
    try { $targetFolder = Normalize-RelativePath -Path "$(Get-ObjectProperty $Disposition 'target_folder' '')" -AllowRoot }
    catch { $Errors.Value += "$id`: invalid target_folder: $($_.Exception.Message)" }

    $originalName = Get-RelativeLeaf -RelativePath "$($Entry.rel_path)"
    $originalFolder = Get-RelativeParent -RelativePath "$($Entry.rel_path)"
    if ($action -eq "keep" -and ($proposedName -ne $originalName -or $targetFolder -ne $originalFolder)) {
        $Errors.Value += "$id`: action keep must preserve name and folder"
    }
    if ($action -eq "rename" -and $targetFolder -ne $originalFolder) {
        $Errors.Value += "$id`: action rename must preserve the current folder"
    }
    if ($action -eq "archive" -and ($proposedName -ne $originalName -or $targetFolder -ne $originalFolder)) {
        $Errors.Value += "$id`: action archive must preserve the original filename and relative folder"
    }

    $protectedMap = Get-ProtectedItemMap -Context $Context
    $pathKey = "$($Entry.rel_path)".ToLowerInvariant()
    if ($protectedMap.ContainsKey($pathKey)) {
        $protected = $protectedMap[$pathKey]
        if ([bool]$protected.protect_name -and $proposedName -ne $originalName) {
            $Errors.Value += "$id`: protected name cannot change"
        }
        if ([bool]$protected.protect_location -and ($targetFolder -ne $originalFolder -or $action -eq "archive")) {
            $Errors.Value += "$id`: protected location cannot change"
        }
    }

    $prefix = "$(Get-ObjectProperty $Context 'files_prefix' '')"
    $prefixSupplied = [bool](Get-ObjectProperty $Context "files_prefix_supplied_by_user" $false)
    $nameProtected = ($protectedMap.ContainsKey($pathKey) -and [bool]$protectedMap[$pathKey].protect_name)
    if ($prefixSupplied -and $prefix -and -not $nameProtected -and $action -ne "archive" -and
        -not $proposedName.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        $Errors.Value += "$id`: proposed_name must use the user-supplied prefix '$prefix'"
    }
}

function Invoke-Phase5Ingest {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Preflight,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)]$Config
    )

    Write-Phase "ingest" "Validating host batches and global organization result"
    $errors = @()
    $queuePath = Join-Path $OutputPath "analysis-queue.json"
    $resultPath = Join-Path $OutputPath "analysis-results.json"
    $queue = Read-Json -Path $queuePath
    $result = Read-Json -Path $resultPath
    if (-not $queue) { throw "analysis-queue.json is missing." }
    if (-not $result) { throw "analysis-results.json is missing." }

    $queueSha = Get-FileSha256 -Path $queuePath
    $manifestPath = Join-Path $OutputPath "manifest.json"
    $contextPath = Join-Path $OutputPath "context.json"
    if ("$(Get-ObjectProperty $result 'run_id' '')" -ne $RunId) { $errors += "run_id mismatch" }
    if ([int](Get-ObjectProperty $result "schema" 0) -ne 2) { $errors += "analysis-results.schema must be 2" }
    if ("$(Get-ObjectProperty $result 'queue_sha256' '')" -ne $queueSha) { $errors += "queue_sha256 mismatch" }
    if ("$($queue.manifest_sha256)" -ne (Get-FileSha256 -Path $manifestPath)) { $errors += "manifest.json changed after queue creation" }
    if ("$($queue.context_sha256)" -ne (Get-FileSha256 -Path $contextPath)) { $errors += "context.json changed after queue creation" }

    $taskById = @{}
    foreach ($task in @($queue.tasks)) { $taskById["$($task.id)"] = $task }

    foreach ($batchInfo in @($queue.batch_index)) {
        $batchInput = Read-Json -Path (Join-Path $OutputPath "$($batchInfo.input_ref)")
        $batchResult = Read-Json -Path (Join-Path $OutputPath "$($batchInfo.result_ref)")
        if (-not $batchResult) {
            $errors += "$($batchInfo.batch_id): batch result missing"
            continue
        }
        if ([int](Get-ObjectProperty $batchResult "schema" 0) -ne 1) { $errors += "$($batchInfo.batch_id): schema must be 1" }
        if ("$(Get-ObjectProperty $batchResult 'run_id' '')" -ne $RunId) { $errors += "$($batchInfo.batch_id): run_id mismatch" }
        if ("$(Get-ObjectProperty $batchResult 'batch_id' '')" -ne "$($batchInfo.batch_id)") { $errors += "$($batchInfo.batch_id): batch_id mismatch" }

        $expected = @{}
        foreach ($id in @($batchInput.task_ids)) { $expected["$id"] = $true }
        $seenBatch = @{}
        foreach ($summary in @(Get-ObjectProperty $batchResult "summaries" @())) {
            $id = "$(Get-ObjectProperty $summary 'id' '')"
            if (-not $expected.ContainsKey($id)) { $errors += "$($batchInfo.batch_id): unknown id '$id'"; continue }
            if ($seenBatch.ContainsKey($id)) { $errors += "$($batchInfo.batch_id): duplicate id '$id'"; continue }
            $seenBatch[$id] = $true
            Test-AnalysisItem -Item $summary -Id $id -KnownIds $taskById -Errors ([ref]$errors)
        }
        foreach ($id in $expected.Keys) {
            if (-not $seenBatch.ContainsKey($id)) { $errors += "$($batchInfo.batch_id): missing summary for '$id'" }
        }
    }

    $analysisById = @{}
    foreach ($analysis in @(Get-ObjectProperty $result "analysis" @())) {
        $id = "$(Get-ObjectProperty $analysis 'id' '')"
        if (-not $taskById.ContainsKey($id)) { $errors += "analysis: unknown id '$id'"; continue }
        if ($analysisById.ContainsKey($id)) { $errors += "analysis: duplicate id '$id'"; continue }
        $analysisById[$id] = $analysis
        Test-AnalysisItem -Item $analysis -Id $id -KnownIds $taskById -Errors ([ref]$errors)

        $task = $taskById[$id]
        if ($task.content_ref) {
            $contentPath = Join-Path $OutputPath "$($task.content_ref)"
            if (-not (Test-Path -LiteralPath $contentPath)) {
                $errors += "$id`: extracted content is missing"
            } else {
                $currentHash = Get-StringSha256 -Text (Get-Content -LiteralPath $contentPath -Raw -Encoding UTF8)
                if ($currentHash -ne "$($task.content_sha256)") { $errors += "$id`: extracted content changed after queue creation" }
            }
        }
    }
    foreach ($id in $taskById.Keys) {
        if (-not $analysisById.ContainsKey($id)) { $errors += "analysis: missing id '$id'" }
    }

    $entryById = @{}
    $entryByPath = @{}
    foreach ($entry in @($Manifest.files)) {
        $entryById["$($entry.id)"] = $entry
        $entryByPath["$($entry.rel_path)".ToLowerInvariant()] = $entry
    }

    $expectedDispositionIds = @{}
    foreach ($id in @($queue.non_duplicate_disposition_ids)) { $expectedDispositionIds["$id"] = $true }
    $dispositionById = @{}
    foreach ($disposition in @(Get-ObjectProperty $result "dispositions" @())) {
        $id = "$(Get-ObjectProperty $disposition 'id' '')"
        if (-not $expectedDispositionIds.ContainsKey($id)) { $errors += "dispositions: unknown id '$id'"; continue }
        if ($dispositionById.ContainsKey($id)) { $errors += "dispositions: duplicate id '$id'"; continue }
        $dispositionById[$id] = $disposition
        Test-DispositionItem -Disposition $disposition -Entry $entryById[$id] -Context $Context -Errors ([ref]$errors)
    }
    foreach ($id in $expectedDispositionIds.Keys) {
        if (-not $dispositionById.ContainsKey($id)) { $errors += "dispositions: missing id '$id'" }
    }

    $expectedOccurrencePaths = @{}
    foreach ($path in @($queue.duplicate_occurrence_paths)) { $expectedOccurrencePaths["$path".ToLowerInvariant()] = "$path" }
    $duplicateDispositionByPath = @{}
    foreach ($disposition in @(Get-ObjectProperty $result "duplicate_occurrence_dispositions" @())) {
        $path = "$(Get-ObjectProperty $disposition 'occurrence_path' '')"
        $key = $path.ToLowerInvariant()
        if (-not $expectedOccurrencePaths.ContainsKey($key)) { $errors += "duplicate occurrences: unknown path '$path'"; continue }
        if ($duplicateDispositionByPath.ContainsKey($key)) { $errors += "duplicate occurrences: duplicate path '$path'"; continue }
        $duplicateDispositionByPath[$key] = $disposition
        Test-DispositionItem -Disposition $disposition -Entry $entryByPath[$key] -Context $Context -Errors ([ref]$errors)
    }
    foreach ($key in $expectedOccurrencePaths.Keys) {
        if (-not $duplicateDispositionByPath.ContainsKey($key)) { $errors += "duplicate occurrences: missing path '$($expectedOccurrencePaths[$key])'" }
    }

    $folderObjects = @(Get-ObjectProperty $result "folder_structure" @())
    if ($folderObjects.Count -eq 0) { $errors += "folder_structure is required" }
    $folders = @{}
    foreach ($folder in $folderObjects) {
        try { $path = Normalize-RelativePath -Path "$(Get-ObjectProperty $folder 'path' '')" -AllowRoot }
        catch { $errors += "folder_structure: $($_.Exception.Message)"; continue }
        $key = $path.ToLowerInvariant()
        if ($folders.ContainsKey($key)) { $errors += "folder_structure: duplicate path '$path'"; continue }
        $folders[$key] = [pscustomobject]@{
            internal_id = Get-StableInternalId -Prefix "folder" -Key $path
            path = $path
            reason = "$(Get-ObjectProperty $folder 'reason' '')"
        }
    }
    if (-not $folders.ContainsKey("to_review")) { $errors += "folder_structure must include to_review" }

    $validation = [ordered]@{
        schema = 2
        valid = ($errors.Count -eq 0)
        error_count = $errors.Count
        errors = $errors
        generated = (Get-Date).ToString("o")
    }
    Save-Json -Object $validation -Path (Join-Path $OutputPath "ingest-validation.json")
    if ($errors.Count -gt 0) {
        Write-Phase "ingest" "REJECTED ($($errors.Count) error(s)); see ingest-validation.json" "error"
        throw "analysis-results.json failed validation: $($errors[0])"
    }

    $sourceHashIndex = [ordered]@{}
    $finalEntries = @()
    foreach ($entry in @($Manifest.files)) {
        $sourceHashIndex["$($entry.rel_path)"] = $entry.sha256
        $analysis = $null
        $disposition = $null
        if ($entry.exact_duplicate_group) {
            $analysis = $analysisById["$($entry.analysis_representative_id)"]
            $disposition = $duplicateDispositionByPath["$($entry.rel_path)".ToLowerInvariant()]
        } elseif ($entry.submit_to_host) {
            $analysis = $analysisById["$($entry.id)"]
            $disposition = $dispositionById["$($entry.id)"]
        } else {
            $analysis = $entry.deterministic_disposition
            $disposition = $entry.deterministic_disposition
        }
        if (-not $analysis -or -not $disposition) {
            throw "Internal merge error: no complete result for '$($entry.rel_path)'."
        }

        $targetFolder = Normalize-RelativePath -Path "$($disposition.target_folder)" -AllowRoot
        $proposedName = "$($disposition.proposed_name)"
        $protectedMap = Get-ProtectedItemMap -Context $Context
        $pathKey = "$($entry.rel_path)".ToLowerInvariant()
        if ($protectedMap.ContainsKey($pathKey)) {
            $protected = $protectedMap[$pathKey]
            if ([bool]$protected.protect_name) { $proposedName = Get-RelativeLeaf -RelativePath "$($entry.rel_path)" }
            if ([bool]$protected.protect_location) { $targetFolder = Get-RelativeParent -RelativePath "$($entry.rel_path)" }
        }

        $finalEntries += [pscustomobject]@{
            id = "$($entry.id)"
            source_rel_path = "$($entry.rel_path)"
            source_sha256 = $entry.sha256
            size_bytes = [long]$entry.size_bytes
            kind = "$($entry.kind)"
            exact_duplicate_group = $entry.exact_duplicate_group
            content_summary = "$($analysis.content_summary)"
            document_role = "$($analysis.document_role)"
            proposed_name = $proposedName
            target_folder = $targetFolder
            action = "$($disposition.action)"
            confidence = [int]$analysis.confidence
            related_ids = @($analysis.related_ids)
            evidence = "$($analysis.evidence)"
        }

        if ("$($disposition.action)" -ne "archive" -and -not $folders.ContainsKey($targetFolder.ToLowerInvariant())) {
            $folders[$targetFolder.ToLowerInvariant()] = [pscustomobject]@{
                internal_id = Get-StableInternalId -Prefix "folder" -Key $targetFolder
                path = $targetFolder
                reason = "Required by a validated file disposition."
            }
        }
    }

    if (-not $folders.ContainsKey("root")) {
        $folders["root"] = [pscustomobject]@{ internal_id = Get-StableInternalId -Prefix "folder" -Key "ROOT"; path = "ROOT"; reason = "Folder root." }
    }
    if (-not $folders.ContainsKey("to_review")) {
        $folders["to_review"] = [pscustomobject]@{ internal_id = Get-StableInternalId -Prefix "folder" -Key "to_review"; path = "to_review"; reason = "Uncertain files." }
    }

    $draft = [ordered]@{
        schema = 3
        generated = (Get-Date).ToString("o")
        run_id = $RunId
        source = "$($Manifest.source)"
        mode = "analyze"
        approvable = $false
        manifest_complete = [bool]$Manifest.complete
        continue_partial = [bool]$Preflight.continue_partial
        preflight_approval_blocked = [bool]$Preflight.approval_blocked
        source_hash_index = $sourceHashIndex
        folders = @($folders.Values | Sort-Object { $_.path.ToLowerInvariant() })
        entries = $finalEntries
        groups = @(Get-ObjectProperty $result "groups" @())
        host_decisions = @(Get-ObjectProperty $result "decisions" @())
        warnings = @($Preflight.issues | ForEach-Object { $_.message })
    }
    Save-Json -Object $draft -Path (Join-Path $OutputPath "organization-plan.json")
    Write-Phase "ingest" "$($finalEntries.Count) source file(s) merged exactly once" "ok"
    return [pscustomobject]$draft
}
