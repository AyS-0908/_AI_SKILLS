# Phase7-Apply.ps1 — apply an approved plan with a prewritten transaction journal
# and a rollback script. Files are moved directly from source to final destination.

function Get-ApplyTargetPath {
    param($Entry, [string]$Source)
    return (Join-Path $Source "$($Entry.final_rel_path)")
}

function Test-FinalRelativePath {
    param([string]$RelativePath)
    $normalized = Normalize-RelativePath -Path $RelativePath
    foreach ($segment in @($normalized -split "\\")) {
        $error = Test-WindowsName -Name $segment
        if ($error) { return "'$segment': $error" }
    }
    return $null
}

function Get-MoveExecutionOrder {
    param($Operations)
    $sourceMap = @{}
    foreach ($operation in @($Operations)) { $sourceMap["$($operation.source_path)".ToLowerInvariant()] = $operation }

    foreach ($operation in @($Operations)) {
        $targetKey = "$($operation.target_path)".ToLowerInvariant()
        $sourceKey = "$($operation.source_path)".ToLowerInvariant()
        $operation.depends_on = $null
        if ($targetKey -ne $sourceKey -and $sourceMap.ContainsKey($targetKey)) {
            $operation.depends_on = "$($sourceMap[$targetKey].id)"
        } elseif ($targetKey -ne $sourceKey -and (Test-Path -LiteralPath $operation.target_path)) {
            throw "Target collision with a file outside the move set: $($operation.target_path)"
        }
    }

    $ordered = @()
    $pending = @($Operations)
    $completed = @{}
    while ($pending.Count -gt 0) {
        $ready = @($pending | Where-Object { -not $_.depends_on -or $completed.ContainsKey("$($_.depends_on)") })
        if ($ready.Count -eq 0) { throw "Move dependency cycle detected; direct single-move execution is impossible." }
        foreach ($operation in $ready) {
            $ordered += $operation
            $completed["$($operation.id)"] = $true
        }
        $readyIds = @($ready | ForEach-Object { "$($_.id)" })
        $pending = @($pending | Where-Object { $readyIds -notcontains "$($_.id)" })
    }
    return $ordered
}

function Write-RollbackScript {
    param([string]$OutputPath)
    $scriptPath = Join-Path $OutputPath "rollback.ps1"
    $content = @'
#requires -Version 7.2
[CmdletBinding()]
param([string]$TransactionPath = (Join-Path $PSScriptRoot "transaction.json"))

$ErrorActionPreference = "Stop"

function Get-LP {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.Length -ge 248 -and -not $full.StartsWith("\\?\")) {
        if ($full.StartsWith("\\")) { return "\\?\UNC\" + $full.Substring(2) }
        return "\\?\" + $full
    }
    return $full
}

function Save-Transaction {
    $json = $transaction | ConvertTo-Json -Depth 64
    $tmp = "$TransactionPath.tmp"
    [System.IO.File]::WriteAllText((Get-LP $tmp), $json, (New-Object System.Text.UTF8Encoding($false)))
    $null = Get-Content -LiteralPath (Get-LP $tmp) -Raw -Encoding UTF8 | ConvertFrom-Json
    [System.IO.File]::Move((Get-LP $tmp), (Get-LP $TransactionPath), $true)
}

$transaction = Get-Content -LiteralPath $TransactionPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($transaction.status -notin @("planned", "running", "completed", "failed", "rolled_back")) {
    throw "Transaction status '$($transaction.status)' is not rollback-ready."
}

$moves = @($transaction.operations | Where-Object { $_.status -ne "rolled_back" })
[array]::Reverse($moves)
$reversed = 0
$removedFolders = 0
Write-Host "Rollback: reversing $($moves.Count) pending operation(s) from $TransactionPath"
foreach ($operation in $moves) {
    $sourcePath = Get-LP "$($operation.source_path)"
    $targetPath = Get-LP "$($operation.target_path)"
    $sourceExists = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $targetExists = Test-Path -LiteralPath $targetPath -PathType Leaf

    if ($sourceExists -and -not $targetExists) {
        $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
        if ($sourceHash -ne $operation.source_sha256) {
            throw "Rollback refused: original file changed: $($operation.source_path)"
        }
        $operation.status = "rolled_back"
        $reversed++
        Save-Transaction
        continue
    }
    if ($sourceExists -and $targetExists) {
        throw "Rollback refused: original path is occupied: $($operation.source_path)"
    }
    if (-not $targetExists) {
        throw "Rollback refused: moved file is missing: $($operation.target_path)"
    }

    $currentHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash
    if ($currentHash -ne $operation.source_sha256) {
        throw "Rollback refused: moved file changed after apply: $($operation.target_path)"
    }
    $parent = Split-Path -Parent $operation.source_path
    if (-not (Test-Path -LiteralPath (Get-LP $parent))) { New-Item -ItemType Directory -Force -Path (Get-LP $parent) | Out-Null }
    [System.IO.File]::Move($targetPath, $sourcePath, $false)
    $operation.status = "rolled_back"
    $reversed++
    $operation | Add-Member -NotePropertyName rolled_back_at -NotePropertyValue (Get-Date).ToString("o") -Force
    Save-Transaction
}

foreach ($folder in @($transaction.folders | Where-Object { $_.created -eq $true } | Sort-Object { $_.path.Length } -Descending)) {
    $folderPath = Get-LP "$($folder.path)"
    if (Test-Path -LiteralPath $folderPath -PathType Container) {
        $children = @(Get-ChildItem -LiteralPath $folderPath -Force)
        if ($children.Count -eq 0) { Remove-Item -LiteralPath $folderPath -Force; $removedFolders++ }
    }
}

$transaction.rollback_status = "completed"
$transaction.status = "rolled_back"
$transaction | Add-Member -NotePropertyName rolled_back_at -NotePropertyValue (Get-Date).ToString("o") -Force
Save-Transaction
Write-Host "Rollback complete: $reversed move(s) reversed; $removedFolders created folder(s) removed. Originals restored."
'@
    [System.IO.File]::WriteAllText((Get-LongPath $scriptPath), $content, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-Phase7Apply {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)]$Config
    )

    Write-Phase "apply" "Validating approval, source hashes, and final paths"
    $planPath = Join-Path $OutputPath "organization-plan.json"
    $approvalPath = Join-Path $OutputPath "approval.json"
    $validationPath = Join-Path $OutputPath "plan-validation.json"
    $plan = Read-Json -Path $planPath
    $approval = Read-Json -Path $approvalPath
    $validation = Read-Json -Path $validationPath
    if (-not $plan) { throw "organization-plan.json is required for apply mode." }
    if (-not $approval) { throw "approval.json is required for apply mode." }
    if (-not $validation -or -not [bool]$validation.valid) { throw "A valid plan-validation.json is required for apply mode." }
    if (-not [bool]$plan.approvable) { throw "This plan is not approvable and cannot be applied." }
    if ("$($plan.source)" -ne $Source) { throw "Plan source '$($plan.source)' does not match '$Source'." }

    $planHash = Get-FileSha256 -Path $planPath
    if ("$($approval.organization_plan_sha256)" -ne $planHash) {
        throw "approval.json does not match the current organization-plan.json."
    }
    $existingTransactionPath = Join-Path $OutputPath "transaction.json"
    if (Test-Path -LiteralPath $existingTransactionPath) {
        $existingTransaction = Read-Json -Path $existingTransactionPath
        if ("$($existingTransaction.status)" -ne "rolled_back") {
            throw "transaction.json already exists. Review or roll back the previous apply before starting another."
        }
        # The previous apply was fully reversed; archive its journal and allow a fresh apply.
        $archivedName = "transaction-rolledback-$((Get-Date).ToString('yyyyMMdd-HHmmss-fff')).json"
        Move-Item -LiteralPath $existingTransactionPath -Destination (Join-Path $OutputPath $archivedName) -Force
    }

    $moveOperations = @()
    $targetSeen = @{}
    foreach ($entry in @($plan.entries)) {
        if ($entry.action -notin $script:PLAN_ACTIONS) { throw "Unsupported action '$($entry.action)' for $($entry.id)." }
        if (-not $entry.source_sha256) { throw "Source hash is missing for '$($entry.source_rel_path)'." }
        $sourcePath = Join-Path $Source "$($entry.source_rel_path)"
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Source file is missing: $sourcePath" }
        $currentHash = Get-FileSha256 -Path $sourcePath
        if ($currentHash -ne "$($entry.source_sha256)") { throw "Source file changed after approval: $($entry.source_rel_path)" }

        $relativeError = Test-FinalRelativePath -RelativePath "$($entry.final_rel_path)"
        if ($relativeError) { throw "Invalid final path for '$($entry.id)': $relativeError" }
        $targetPath = Get-ApplyTargetPath -Entry $entry -Source $Source
        $targetResolved = Resolve-FinalPath -Path $targetPath
        $sourcePrefix = $Source.TrimEnd("\") + "\"
        if (-not ($targetResolved + "\").StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Final target escapes the source folder: $targetPath"
        }
        if ($targetPath.Length -ge 32760) { throw "Final path is too long: $targetPath" }
        $targetKey = $targetPath.ToLowerInvariant()
        if ($targetSeen.ContainsKey($targetKey)) { throw "Target collision: $targetPath" }
        $targetSeen[$targetKey] = $true

        if (-not $sourcePath.Equals($targetPath, [System.StringComparison]::Ordinal)) {
            $moveOperations += [pscustomobject]@{
                id = "$($entry.id)"
                action = "$($entry.action)"
                source_path = $sourcePath
                target_path = $targetPath
                source_sha256 = "$($entry.source_sha256)"
                status = "pending"
                completed_at = $null
                depends_on = $null
            }
        }
    }
    $orderedMoves = @(Get-MoveExecutionOrder -Operations $moveOperations)

    # Track every ancestor folder up to (but excluding) the source root, not just the
    # direct parent, so rollback can remove all empty folders that apply created.
    $folderPaths = @()
    $seenFolderKeys = @{}
    $sourcePrefixLength = $Source.TrimEnd("\").Length
    foreach ($operation in $orderedMoves) {
        $relativeParent = (Split-Path -Parent "$($operation.target_path)").Substring($sourcePrefixLength).TrimStart("\")
        if ([string]::IsNullOrEmpty($relativeParent)) { continue }
        $accumulated = ""
        foreach ($segment in @($relativeParent -split "\\")) {
            $accumulated = if ($accumulated) { "$accumulated\$segment" } else { $segment }
            $fullPath = Join-Path $Source $accumulated
            $key = $fullPath.ToLowerInvariant()
            if (-not $seenFolderKeys.ContainsKey($key)) {
                $seenFolderKeys[$key] = $true
                $folderPaths += $fullPath
            }
        }
    }
    $folders = @($folderPaths | ForEach-Object {
        [pscustomobject]@{ path = "$_"; existed_before = (Test-Path -LiteralPath (Get-LongPath $_) -PathType Container); created = $false }
    })

    $transaction = [ordered]@{
        schema = 1
        plan_sha256 = $planHash
        source = $Source
        created_at = (Get-Date).ToString("o")
        status = "planned"
        failure = $null
        folders = $folders
        operations = $orderedMoves
        rollback_status = "not_started"
    }
    $transactionPath = Join-Path $OutputPath "transaction.json"
    Save-Json -Object $transaction -Path $transactionPath
    Write-RollbackScript -OutputPath $OutputPath

    try {
        $transaction.status = "running"
        Save-Json -Object $transaction -Path $transactionPath

        foreach ($folder in @($transaction.folders)) {
            if (-not [bool]$folder.existed_before) {
                New-Item -ItemType Directory -Force -Path (Get-LongPath "$($folder.path)") | Out-Null
                $folder.created = $true
                Save-Json -Object $transaction -Path $transactionPath
            }
        }

        foreach ($operation in @($transaction.operations)) {
            $parent = Split-Path -Parent "$($operation.target_path)"
            if (-not (Test-Path -LiteralPath (Get-LongPath $parent) -PathType Container)) { throw "Target parent disappeared: $parent" }
            $operation.status = "moving"
            Save-Json -Object $transaction -Path $transactionPath
            [System.IO.File]::Move((Get-LongPath "$($operation.source_path)"), (Get-LongPath "$($operation.target_path)"), $false)
            $operation.status = "completed"
            $operation.completed_at = (Get-Date).ToString("o")
            Save-Json -Object $transaction -Path $transactionPath
        }

        $transaction.status = "completed"
        $transaction.completed_at = (Get-Date).ToString("o")
        Save-Json -Object $transaction -Path $transactionPath
        Write-Phase "apply" "$(@($transaction.operations).Count) file move(s) completed; rollback.ps1 is ready" "ok"
        return [pscustomobject]$transaction
    } catch {
        $transaction.status = "failed"
        $transaction.failure = "$($_.Exception.Message)"
        $transaction.failed_at = (Get-Date).ToString("o")
        Save-Json -Object $transaction -Path $transactionPath
        Save-Json -Object ([ordered]@{
            schema = 1
            failed_at = (Get-Date).ToString("o")
            error = "$($_.Exception.Message)"
            rollback = (Join-Path $OutputPath "rollback.ps1")
        }) -Path (Join-Path $OutputPath "execution-error.json")
        throw
    }
}
