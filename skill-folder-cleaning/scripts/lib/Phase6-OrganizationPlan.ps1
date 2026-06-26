# Phase6-OrganizationPlan.ps1 — finalize and validate the plan, preserve display
# identifiers, apply structured revisions, render approval views, and bind approval.

function ConvertTo-RegistryMap {
    param($Object)
    $map = @{}
    if ($Object) {
        foreach ($property in $Object.PSObject.Properties) { $map[$property.Name] = "$($property.Value)" }
    }
    return $map
}

function Get-DisplayRegistry {
    param([string]$OutputPath)
    $path = Join-Path $OutputPath "display-id-registry.json"
    $saved = Read-Json -Path $path
    if (-not $saved) {
        return @{
            schema = 1
            next_folder = 1
            next_decision = 1
            next_file = 1
            folders = @{}
            decisions = @{}
            files = @{}
        }
    }
    return @{
        schema = 1
        next_folder = [int]$saved.next_folder
        next_decision = [int]$saved.next_decision
        next_file = [int]$saved.next_file
        folders = ConvertTo-RegistryMap -Object $saved.folders
        decisions = ConvertTo-RegistryMap -Object $saved.decisions
        files = ConvertTo-RegistryMap -Object $saved.files
    }
}

function Save-DisplayRegistry {
    param($Registry, [string]$OutputPath)
    Save-Json -Object $Registry -Path (Join-Path $OutputPath "display-id-registry.json")
}

function Get-OrCreateDisplayId {
    param(
        [hashtable]$Map,
        [string]$InternalId,
        [string]$Prefix,
        [ref]$Next
    )
    if ($Map.ContainsKey($InternalId)) { return "$($Map[$InternalId])" }
    $display = "{0}{1:D3}" -f $Prefix, $Next.Value
    $Next.Value++
    $Map[$InternalId] = $display
    return $display
}

function Get-RegistryInternalId {
    param([hashtable]$Map, [string]$DisplayId)
    foreach ($key in $Map.Keys) {
        if ("$($Map[$key])" -eq $DisplayId) { return $key }
    }
    return $null
}

function Add-MandatoryFolders {
    param($Plan, $Context, $Config)
    $folderMap = @{}
    foreach ($folder in @($Plan.folders)) { $folderMap["$($folder.path)".ToLowerInvariant()] = $folder }

    $required = @("ROOT", "to_review")
    if ("$($Context.folder_type)" -eq "startup_project") { $required = @($Config.organization.startup_level1) }
    foreach ($path in $required) {
        if (-not $folderMap.ContainsKey($path.ToLowerInvariant())) {
            $folder = [pscustomobject]@{
                internal_id = Get-StableInternalId -Prefix "folder" -Key $path
                path = $path
                reason = if ($path -eq "to_review") { "Uncertain files requiring user judgment." } else { "Mandatory folder for this folder type." }
            }
            $folderMap[$path.ToLowerInvariant()] = $folder
        }
    }
    $Plan.folders = @($folderMap.Values | Sort-Object { $_.path.ToLowerInvariant() })
}

function Get-PlanDecisions {
    param($Plan)
    $decisions = @()
    $seen = @{}

    foreach ($hostDecision in @($Plan.host_decisions)) {
        $key = "$(Get-ObjectProperty $hostDecision 'key' '')"
        if (-not $key) { $key = Get-StringSha256 -Text ($hostDecision | ConvertTo-Json -Depth 12) }
        $internalId = Get-StableInternalId -Prefix "decision" -Key $key
        if ($seen.ContainsKey($internalId)) { continue }
        $seen[$internalId] = $true
        $decisions += [pscustomobject]@{
            internal_id = $internalId
            type = "$(Get-ObjectProperty $hostDecision 'type' 'host')"
            title = "$(Get-ObjectProperty $hostDecision 'title' 'Choose an organization option')"
            recommended = "$(Get-ObjectProperty $hostDecision 'recommended' '')"
            alternatives = @(Get-ObjectProperty $hostDecision "alternatives" @())
            file_ids = @(Get-ObjectProperty $hostDecision "file_ids" @())
        }
    }

    foreach ($entry in @($Plan.entries)) {
        $needsDecision = ($entry.action -eq "archive" -or $entry.document_role -in @("outdated", "duplicate", "uncertain") -or [int]$entry.confidence -le 5)
        if (-not $needsDecision) { continue }
        $key = "file:$($entry.id)"
        $internalId = Get-StableInternalId -Prefix "decision" -Key $key
        if ($seen.ContainsKey($internalId)) { continue }
        $seen[$internalId] = $true
        $recommended = if ($entry.action -eq "archive") {
            "Archive '$($entry.source_rel_path)' to the reversible archive."
        } else {
            "Use '$($entry.target_folder)\$($entry.proposed_name)' with action '$($entry.action)'."
        }
        $decisions += [pscustomobject]@{
            internal_id = $internalId
            type = "file_judgment"
            title = "Review $($entry.source_rel_path)"
            recommended = $recommended
            alternatives = @("Keep the original file in its current location.")
            file_ids = @($entry.id)
        }
    }

    foreach ($group in @($Plan.groups)) {
        $kind = "$(Get-ObjectProperty $group 'kind' '')"
        if ($kind -notin @("version_chain", "near_duplicate", "contradiction", "overlap")) { continue }
        $members = @(Get-ObjectProperty $group "members" @())
        $key = "group:${kind}:$($members -join ',')"
        $internalId = Get-StableInternalId -Prefix "decision" -Key $key
        if ($seen.ContainsKey($internalId)) { continue }
        $seen[$internalId] = $true
        $authoritative = "$(Get-ObjectProperty $group 'authoritative' '')"
        $decisions += [pscustomobject]@{
            internal_id = $internalId
            type = $kind
            title = "Review $kind relationship"
            recommended = if ($authoritative) { "Use $authoritative as authoritative." } else { "$(Get-ObjectProperty $group 'evidence' 'Review the related files.')" }
            alternatives = @("Keep all related files.")
            file_ids = $members
        }
    }
    return $decisions
}

function Apply-PlanRevision {
    param(
        $Plan,
        [string]$RevisionPath,
        [string]$OutputPath,
        $Registry
    )
    if (-not $RevisionPath) { return $Plan }
    $revision = Read-Json -Path $RevisionPath
    if (-not $revision) { throw "Plan revision file not found: $RevisionPath" }
    $planPath = Join-Path $OutputPath "organization-plan.json"
    if ("$(Get-ObjectProperty $revision 'base_plan_sha256' '')" -ne (Get-FileSha256 -Path $planPath)) {
        throw "plan-revision.json does not match the current organization-plan.json."
    }
    $approvalPath = Join-Path $OutputPath "approval.json"
    if (Test-Path -LiteralPath $approvalPath) { Remove-Item -LiteralPath $approvalPath -Force }

    foreach ($correction in @(Get-ObjectProperty $revision "corrections" @())) {
        $displayId = "$(Get-ObjectProperty $correction 'display_id' '')"
        $operation = "$(Get-ObjectProperty $correction 'operation' '')"
        $value = Get-ObjectProperty $correction "value" $null
        if ($displayId -match "^F\d{3}$") {
            $internalId = Get-RegistryInternalId -Map $Registry.folders -DisplayId $displayId
            $folder = @($Plan.folders | Where-Object { $_.internal_id -eq $internalId }) | Select-Object -First 1
            if (-not $folder) { throw "Unknown folder display id: $displayId" }
            $oldPath = "$($folder.path)"
            if ($operation -eq "rename") {
                $leaf = Normalize-RelativePath -Path "$value"
                if ($leaf.Contains("\")) { throw "Folder rename value must be one folder name." }
                if ($oldPath -eq "ROOT") { throw "ROOT cannot be renamed." }
                $parent = if ($oldPath.Contains("\")) { Split-Path -Parent $oldPath } else { "ROOT" }
                $newPath = if ($parent -eq "ROOT") { $leaf } else { Join-Path $parent $leaf }
            } elseif ($operation -eq "move_under") {
                $parentInternal = Get-RegistryInternalId -Map $Registry.folders -DisplayId "$value"
                $parentFolder = @($Plan.folders | Where-Object { $_.internal_id -eq $parentInternal }) | Select-Object -First 1
                if (-not $parentFolder) { throw "Unknown destination folder display id: $value" }
                if ($parentFolder.path -eq $oldPath -or $parentFolder.path.StartsWith("$oldPath\", [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "A folder cannot be moved under itself or one of its descendants."
                }
                $newPath = if ($parentFolder.path -eq "ROOT") { Split-Path -Leaf $oldPath } else { Join-Path $parentFolder.path (Split-Path -Leaf $oldPath) }
            } else {
                throw "Unsupported folder correction operation '$operation'."
            }
            $newPath = Normalize-RelativePath -Path $newPath -AllowRoot
            foreach ($candidate in @($Plan.folders)) {
                if ($candidate.path -eq $oldPath -or $candidate.path.StartsWith("$oldPath\", [System.StringComparison]::OrdinalIgnoreCase)) {
                    $candidate.path = $newPath + $candidate.path.Substring($oldPath.Length)
                }
            }
            foreach ($entry in @($Plan.entries)) {
                if ($entry.target_folder -eq $oldPath -or $entry.target_folder.StartsWith("$oldPath\", [System.StringComparison]::OrdinalIgnoreCase)) {
                    $entry.target_folder = $newPath + $entry.target_folder.Substring($oldPath.Length)
                }
            }
        } elseif ($displayId -match "^I\d{3}$") {
            $fileId = Get-RegistryInternalId -Map $Registry.files -DisplayId $displayId
            $entry = @($Plan.entries | Where-Object { $_.id -eq $fileId }) | Select-Object -First 1
            if (-not $entry) { throw "Unknown file display id: $displayId" }
            if ($operation -eq "rename") {
                $entry.proposed_name = "$value"
                $entry.action = if ($entry.target_folder -eq (Get-RelativeParent $entry.source_rel_path)) { "rename" } else { "move" }
            } elseif ($operation -eq "move") {
                $folderInternal = Get-RegistryInternalId -Map $Registry.folders -DisplayId "$value"
                $folder = @($Plan.folders | Where-Object { $_.internal_id -eq $folderInternal }) | Select-Object -First 1
                if (-not $folder) { throw "Unknown destination folder display id: $value" }
                $entry.target_folder = "$($folder.path)"
                $entry.action = "move"
            } else {
                throw "Unsupported file correction operation '$operation'."
            }
        } elseif ($displayId -match "^D\d{3}$") {
            $decisionInternal = Get-RegistryInternalId -Map $Registry.decisions -DisplayId $displayId
            $decision = @($Plan.decisions | Where-Object { $_.internal_id -eq $decisionInternal }) | Select-Object -First 1
            if (-not $decision) { throw "Unknown decision display id: $displayId" }
            if ($operation -eq "use_recommended") { continue }
            if ($operation -eq "keep_both") {
                foreach ($fileId in @($decision.file_ids)) {
                    $entry = @($Plan.entries | Where-Object { $_.id -eq "$fileId" }) | Select-Object -First 1
                    if ($entry) {
                        $originalFolder = Get-RelativeParent -RelativePath $entry.source_rel_path
                        $entry.proposed_name = Get-RelativeLeaf -RelativePath $entry.source_rel_path
                        $entry.target_folder = $originalFolder
                        $entry.action = "keep"
                        if (-not @($Plan.folders | Where-Object { $_.path -eq $originalFolder })) {
                            $Plan.folders += [pscustomobject]@{
                                internal_id = Get-StableInternalId -Prefix "folder" -Key $originalFolder
                                path = $originalFolder
                                reason = "Original folder retained by an approved keep-both correction."
                            }
                        }
                    }
                }
            } else {
                throw "Unsupported decision correction operation '$operation'."
            }
        } else {
            throw "Unknown correction display id: $displayId"
        }
    }
    $Plan.generated = (Get-Date).ToString("o")
    return $Plan
}

function Test-AndFinalizeOrganizationPlan {
    param($Plan, $Manifest, $Context, $Preflight, $Config, [bool]$SkipAI)

    Add-MandatoryFolders -Plan $Plan -Context $Context -Config $Config
    $errors = @()
    $warnings = @($Plan.warnings)
    $exceptions = @()
    $folderMap = @{}
    foreach ($folder in @($Plan.folders)) {
        try { $folder.path = Normalize-RelativePath -Path "$($folder.path)" -AllowRoot }
        catch { $errors += "Invalid folder '$($folder.path)': $($_.Exception.Message)"; continue }
        $folderKey = $folder.path.ToLowerInvariant()
        if ($folderMap.ContainsKey($folderKey)) {
            $errors += "Duplicate folder path '$($folder.path)'"
            continue
        }
        $folderMap[$folderKey] = $folder
    }

    $maxDepth = [int](Get-ObjectProperty $Context "max_depth" $Config.organization.max_folder_depth)
    $minLevel2 = [int]$Config.organization.level_2_min_files
    $protectedMap = Get-ProtectedItemMap -Context $Context
    $seenIds = @{}
    $seenSources = @{}
    $seenTargets = @{}
    $folderCounts = @{}
    $hasUnverifiableSource = $false
    $manifestById = @{}
    foreach ($manifestEntry in @($Manifest.files)) { $manifestById["$($manifestEntry.id)"] = $manifestEntry }

    foreach ($entry in @($Plan.entries)) {
        if ($seenIds.ContainsKey("$($entry.id)")) { $errors += "Duplicate file id '$($entry.id)' in plan" }
        $seenIds["$($entry.id)"] = $true
        $sourceKey = "$($entry.source_rel_path)".ToLowerInvariant()
        if ($seenSources.ContainsKey($sourceKey)) { $errors += "Source file appears more than once: $($entry.source_rel_path)" }
        $seenSources[$sourceKey] = $true
        if ($script:PLAN_ACTIONS -notcontains "$($entry.action)") { $errors += "$($entry.id): invalid action '$($entry.action)'" }
        if ($script:DOCUMENT_ROLES -notcontains "$($entry.document_role)") { $errors += "$($entry.id): invalid document_role '$($entry.document_role)'" }
        if (-not $entry.source_sha256) { $hasUnverifiableSource = $true }
        if (-not $manifestById.ContainsKey("$($entry.id)")) {
            $errors += "Unknown manifest id '$($entry.id)'"
            continue
        }
        $revisionDisposition = [pscustomobject]@{
            proposed_name = "$($entry.proposed_name)"
            target_folder = "$($entry.target_folder)"
            action = "$($entry.action)"
        }
        Test-DispositionItem -Disposition $revisionDisposition -Entry $manifestById["$($entry.id)"] -Context $Context -Errors ([ref]$errors)
        $originalName = Get-RelativeLeaf -RelativePath "$($entry.source_rel_path)"
        if ($entry.kind -eq "image" -and $entry.proposed_name -ne $originalName -and
            @($entry.related_ids).Count -eq 0 -and "$($entry.evidence)" -notmatch "(?i)visual|image|ocr|photo|screenshot") {
            $errors += "$($entry.id): image rename requires a clear relationship or visual/OCR evidence"
        }

        try { $entry.target_folder = Normalize-RelativePath -Path "$($entry.target_folder)" -AllowRoot }
        catch { $errors += "$($entry.id): invalid target folder"; continue }
        if ((Get-PathDepth -Folder $entry.target_folder) -gt $maxDepth) {
            $errors += "$($entry.id): target folder exceeds max_depth=$maxDepth"
        }
        if ($entry.action -ne "archive" -and -not $folderMap.ContainsKey($entry.target_folder.ToLowerInvariant())) {
            $errors += "$($entry.id): target folder '$($entry.target_folder)' is absent from folder_structure"
        }

        if ($entry.document_role -eq "core" -and $entry.target_folder -ne "ROOT") {
            $protected = if ($protectedMap.ContainsKey($sourceKey)) { $protectedMap[$sourceKey] } else { $null }
            if (-not ($protected -and [bool]$protected.protect_location)) {
                $errors += "$($entry.id): core documents must remain at ROOT"
            }
        }

        $finalPath = if ($entry.action -eq "archive") {
            Join-Path "$($Config.organization.archive_destination)" "$($entry.source_rel_path)"
        } else {
            Join-OrganizationPath -Folder $entry.target_folder -Name "$($entry.proposed_name)"
        }
        $entry | Add-Member -NotePropertyName final_rel_path -NotePropertyValue $finalPath -Force
        $targetKey = $finalPath.ToLowerInvariant()
        if ($seenTargets.ContainsKey($targetKey)) { $errors += "Target collision: '$finalPath'" }
        $seenTargets[$targetKey] = $true
        if ($entry.action -ne "archive") {
            if (-not $folderCounts.ContainsKey($entry.target_folder)) { $folderCounts[$entry.target_folder] = 0 }
            $folderCounts[$entry.target_folder]++
        }
    }

    if ($seenSources.Count -ne [int]$Manifest.file_count) {
        $errors += "Plan accounts for $($seenSources.Count) files; manifest contains $($Manifest.file_count)"
    }

    $mandatory = @("ROOT", "to_review")
    if ("$($Context.folder_type)" -eq "startup_project") { $mandatory = @($Config.organization.startup_level1) }
    $keptFolders = @()
    foreach ($folder in @($Plan.folders)) {
        $count = if ($folderCounts.ContainsKey("$($folder.path)")) { [int]$folderCounts["$($folder.path)"] } else { 0 }
        $folder | Add-Member -NotePropertyName file_count -NotePropertyValue $count -Force
        $isMandatory = $mandatory -contains "$($folder.path)"
        if ($count -eq 0 -and -not $isMandatory) { continue }
        if ((Get-PathDepth -Folder "$($folder.path)") -ge 2 -and $count -lt $minLevel2) {
            if ([string]::IsNullOrWhiteSpace("$($folder.reason)")) {
                $errors += "Small Level-2 folder '$($folder.path)' requires a reason"
            } else {
                $exceptions += [pscustomobject]@{ folder = "$($folder.path)"; file_count = $count; guideline = $minLevel2; reason = "$($folder.reason)" }
            }
        }
        $keptFolders += $folder
    }
    $Plan.folders = @($keptFolders | Sort-Object { $_.path.ToLowerInvariant() })
    $Plan | Add-Member -NotePropertyName level_2_exceptions -NotePropertyValue $exceptions -Force
    $Plan | Add-Member -NotePropertyName decisions -NotePropertyValue @(Get-PlanDecisions -Plan $Plan) -Force

    if ($SkipAI) { $warnings += "SkipAI smoke mode: semantic organization was not performed; this plan cannot be approved or applied." }
    if ($hasUnverifiableSource) { $warnings += "At least one source file has no verified SHA-256; make it locally readable before approval." }
    foreach ($exception in $exceptions) {
        $warnings += "Level-2 guideline exception: '$($exception.folder)' has $($exception.file_count) file(s). Reason: $($exception.reason)"
    }
    $Plan | Add-Member -NotePropertyName warnings -NotePropertyValue @($warnings | Where-Object { $_ } | Select-Object -Unique) -Force
    $valid = ($errors.Count -eq 0)
    $Plan.approvable = ($valid -and -not $SkipAI -and -not [bool]$Preflight.approval_blocked -and -not $hasUnverifiableSource)

    return [pscustomobject]@{
        plan = $Plan
        validation = [ordered]@{
            schema = 3
            valid = $valid
            approvable = [bool]$Plan.approvable
            error_count = $errors.Count
            errors = $errors
            warning_count = @($Plan.warnings).Count
            warnings = @($Plan.warnings)
            level_2_exceptions = $exceptions
            generated = (Get-Date).ToString("o")
        }
    }
}

function Render-ApprovalView {
    param($Plan, $Registry, [string]$OutputPath)
    $folderNext = [ref]$Registry.next_folder
    $treeFolders = @($Plan.folders | Sort-Object {
        if ($_.path -eq "ROOT") { "!" } else { $_.path.ToLowerInvariant() }
    })
    foreach ($folder in $treeFolders) {
        $folder | Add-Member -NotePropertyName display_id -NotePropertyValue (
            Get-OrCreateDisplayId -Map $Registry.folders -InternalId "$($folder.internal_id)" -Prefix "F" -Next $folderNext
        ) -Force
    }
    $Registry.next_folder = $folderNext.Value

    $decisionNext = [ref]$Registry.next_decision
    foreach ($decision in @($Plan.decisions | Where-Object { $null -ne $_ })) {
        $decision | Add-Member -NotePropertyName display_id -NotePropertyValue (
            Get-OrCreateDisplayId -Map $Registry.decisions -InternalId "$($decision.internal_id)" -Prefix "D" -Next $decisionNext
        ) -Force
    }
    $Registry.next_decision = $decisionNext.Value

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine("# Folder organization proposal")
    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("Status: $(if ($Plan.approvable) { 'ready for approval' } else { 'not approvable yet' })")
    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("## DECISIONS")
    [void]$builder.AppendLine("")
    if (@($Plan.decisions).Count -eq 0) {
        [void]$builder.AppendLine("No judgment decision remains.")
    } else {
        foreach ($decision in @($Plan.decisions | Sort-Object display_id)) {
            [void]$builder.AppendLine("$($decision.display_id) — $($decision.title)")
            [void]$builder.AppendLine("Recommended: $($decision.recommended)")
            foreach ($alternative in @($decision.alternatives)) { [void]$builder.AppendLine("Alternative: $alternative") }
            [void]$builder.AppendLine("")
        }
    }
    [void]$builder.AppendLine("")

    [void]$builder.AppendLine("## TARGET STRUCTURE")
    [void]$builder.AppendLine("")
    foreach ($folder in $treeFolders) {
        $indent = "  " * (Get-PathDepth -Folder "$($folder.path)")
        [void]$builder.AppendLine("$indent$($folder.display_id) — $($folder.path) ($($folder.file_count) files)")
    }

    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("## MOVES & RENAMES")
    [void]$builder.AppendLine("")
    $changes = @($Plan.entries | Where-Object { "$($_.action)" -in @("move", "rename") } | Sort-Object source_rel_path)
    if ($changes.Count -eq 0) {
        [void]$builder.AppendLine("None. (Files are kept in place, archived, or routed to review per the decisions above.)")
    } else {
        foreach ($change in $changes) {
            [void]$builder.AppendLine("- $($change.source_rel_path) -> $($change.final_rel_path)  ($($change.action))")
        }
    }

    $authoritative = @($Plan.groups | Where-Object { Get-ObjectProperty $_ "authoritative" $null })
    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("## RECOMMENDED AUTHORITATIVE DOCUMENTS")
    [void]$builder.AppendLine("")
    if ($authoritative.Count -eq 0) {
        [void]$builder.AppendLine("None identified.")
    } else {
        foreach ($group in $authoritative) {
            $authoritativeId = Get-ObjectProperty $group "authoritative" ""
            $authoritativeEvidence = Get-ObjectProperty $group "evidence" ""
            $authoritativeEntry = @($Plan.entries | Where-Object { $_.id -eq "$authoritativeId" }) | Select-Object -First 1
            $authoritativeLabel = if ($authoritativeEntry) { "$($authoritativeEntry.source_rel_path)" } else { "$authoritativeId" }
            [void]$builder.AppendLine("- $authoritativeLabel — $authoritativeEvidence")
        }
    }

    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("## WARNINGS")
    [void]$builder.AppendLine("")
    if (@($Plan.warnings).Count -eq 0) {
        [void]$builder.AppendLine("None.")
    } else {
        foreach ($warning in @($Plan.warnings)) { [void]$builder.AppendLine("- $warning") }
    }

    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("## RESPONSES")
    [void]$builder.AppendLine("")
    [void]$builder.AppendLine('- `OK`')
    [void]$builder.AppendLine('- `D001: use recommended` or `D001: keep both`')
    [void]$builder.AppendLine('- `F002: rename to "New name"`')
    [void]$builder.AppendLine('- `F003: move under F001`')
    [void]$builder.AppendLine('- `EXPAND F003`')
    [void]$builder.AppendLine('- `I001: move to F002` or `I001: rename to "New filename.ext"`')
    [void]$builder.AppendLine('- `KO: redo the structure`')

    [System.IO.File]::WriteAllText(
        (Get-LongPath (Join-Path $OutputPath "approval-view.md")),
        $builder.ToString(),
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Render-ExpandedFolder {
    param($Plan, $Registry, [string]$DisplayFolderId, [string]$OutputPath)
    $folderInternal = Get-RegistryInternalId -Map $Registry.folders -DisplayId $DisplayFolderId
    $folder = @($Plan.folders | Where-Object { $_.internal_id -eq $folderInternal }) | Select-Object -First 1
    if (-not $folder) { throw "Unknown folder display id: $DisplayFolderId" }

    $fileNext = [ref]$Registry.next_file
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine("# Expanded mapping — $DisplayFolderId")
    [void]$builder.AppendLine("")
    foreach ($entry in @($Plan.entries | Where-Object { $_.target_folder -eq $folder.path } | Sort-Object source_rel_path)) {
        $fileDisplay = Get-OrCreateDisplayId -Map $Registry.files -InternalId "$($entry.id)" -Prefix "I" -Next $fileNext
        [void]$builder.AppendLine("$fileDisplay — $($entry.source_rel_path)")
        [void]$builder.AppendLine("Target: $($entry.final_rel_path)")
        [void]$builder.AppendLine("Action: $($entry.action)")
        [void]$builder.AppendLine("")
    }
    $Registry.next_file = $fileNext.Value
    $path = Join-Path $OutputPath "approval-expanded-$DisplayFolderId.md"
    [System.IO.File]::WriteAllText((Get-LongPath $path), $builder.ToString(), (New-Object System.Text.UTF8Encoding($false)))
}

function New-SkipAIOrganizationPlan {
    param($Manifest, $Preflight, $Context, $Config, [string]$RunId)
    $folders = @{}
    $entries = @()
    $hashes = [ordered]@{}
    foreach ($entry in @($Manifest.files)) {
        $folder = Get-RelativeParent -RelativePath "$($entry.rel_path)"
        $folders[$folder.ToLowerInvariant()] = [pscustomobject]@{
            internal_id = Get-StableInternalId -Prefix "folder" -Key $folder
            path = $folder
            reason = "Existing source folder retained by SkipAI smoke mode."
        }
        $hashes["$($entry.rel_path)"] = $entry.sha256
        $entries += [pscustomobject]@{
            id = "$($entry.id)"
            source_rel_path = "$($entry.rel_path)"
            source_sha256 = $entry.sha256
            size_bytes = [long]$entry.size_bytes
            kind = "$($entry.kind)"
            exact_duplicate_group = $entry.exact_duplicate_group
            content_summary = "Semantic analysis skipped."
            document_role = "uncertain"
            proposed_name = Get-RelativeLeaf -RelativePath "$($entry.rel_path)"
            target_folder = $folder
            action = "review"
            confidence = 10
            related_ids = @()
            evidence = "SkipAI smoke mode preserves the original name and parent folder."
        }
    }
    foreach ($path in @("ROOT", "to_review")) {
        $folders[$path.ToLowerInvariant()] = [pscustomobject]@{
            internal_id = Get-StableInternalId -Prefix "folder" -Key $path
            path = $path
            reason = "Required folder."
        }
    }
    return [pscustomobject]@{
        schema = 3
        generated = (Get-Date).ToString("o")
        run_id = $RunId
        source = "$($Manifest.source)"
        mode = "analyze"
        approvable = $false
        manifest_complete = [bool]$Manifest.complete
        continue_partial = [bool]$Preflight.continue_partial
        preflight_approval_blocked = $true
        source_hash_index = $hashes
        folders = @($folders.Values)
        entries = $entries
        groups = @()
        host_decisions = @()
        warnings = @("SkipAI smoke mode preserves all names and parent folders and marks every file for review.")
    }
}

function Invoke-Phase6OrganizationPlan {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Preflight,
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$OutputPath,
        [bool]$SkipAI,
        [string]$RevisionPath,
        [string]$ExpandFolder,
        [bool]$Approve
    )

    Write-Phase "plan" "Validating organization plan and rendering approval view"
    $registry = Get-DisplayRegistry -OutputPath $OutputPath
    $Plan | Add-Member -NotePropertyName decisions -NotePropertyValue @(Get-PlanDecisions -Plan $Plan) -Force
    $Plan = Apply-PlanRevision -Plan $Plan -RevisionPath $RevisionPath -OutputPath $OutputPath -Registry $registry
    $result = Test-AndFinalizeOrganizationPlan -Plan $Plan -Manifest $Manifest -Context $Context -Preflight $Preflight -Config $Config -SkipAI $SkipAI
    $Plan = $result.plan
    Save-Json -Object $Plan -Path (Join-Path $OutputPath "organization-plan.json")
    Save-Json -Object $result.validation -Path (Join-Path $OutputPath "plan-validation.json")
    Render-ApprovalView -Plan $Plan -Registry $registry -OutputPath $OutputPath
    if ($ExpandFolder) { Render-ExpandedFolder -Plan $Plan -Registry $registry -DisplayFolderId $ExpandFolder -OutputPath $OutputPath }
    Save-DisplayRegistry -Registry $registry -OutputPath $OutputPath

    if ($Approve) {
        if (-not $result.validation.valid) { throw "Cannot approve an invalid organization plan." }
        if (-not $Plan.approvable) { throw "This organization plan is not approvable; resolve warnings and rerun analysis." }
        $planHash = Get-FileSha256 -Path (Join-Path $OutputPath "organization-plan.json")
        Save-Json -Object ([ordered]@{
            schema = 1
            run_id = "$($Plan.run_id)"
            approved_at = (Get-Date).ToString("o")
            organization_plan_sha256 = $planHash
        }) -Path (Join-Path $OutputPath "approval.json")
        Write-Phase "approval" "approval.json bound to the current organization-plan.json" "ok"
    }

    $level = if ($result.validation.valid) { "ok" } else { "error" }
    Write-Phase "plan" "valid=$($result.validation.valid) | approvable=$($Plan.approvable) | decisions=$(@($Plan.decisions).Count)" $level
    return [pscustomobject]@{ plan = $Plan; validation = $result.validation }
}
