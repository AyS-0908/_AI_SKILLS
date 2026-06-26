#requires -Version 7.2
<#
.SYNOPSIS
  Analyze, approve, apply, and roll back a complete folder organization plan.

.DESCRIPTION
  PowerShell inventories, hashes, extracts, validates, renders, applies, and
  journals. The host agent supplies context.json and semantic analysis-results.json.
  Analyze writes only inside the reserved artifacts folder (default _DATA_CLEANING)
  within the analyzed root and never modifies your existing files. Apply mode requires
  approval.json bound to the current organization-plan.json.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourcePath,
    [string]$OutputPath,
    [ValidateSet("analyze", "apply")][string]$Mode = "analyze",
    [switch]$SkipAI,
    [switch]$Resume,
    [switch]$ContinuePartial,
    [switch]$HydrateCloud,
    [switch]$Approve,
    [string]$PlanRevisionPath,
    [string]$ExpandFolder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path $ScriptRoot "lib\Common.ps1")
. (Join-Path $ScriptRoot "lib\Phase1-Resolve.ps1")
. (Join-Path $ScriptRoot "lib\Phase2-Inventory.ps1")
. (Join-Path $ScriptRoot "lib\Phase0-Preflight.ps1")
. (Join-Path $ScriptRoot "lib\Phase3-Extract.ps1")
. (Join-Path $ScriptRoot "lib\Phase4-Queue.ps1")
. (Join-Path $ScriptRoot "lib\Phase5-Ingest.ps1")
. (Join-Path $ScriptRoot "lib\Phase6-OrganizationPlan.ps1")
. (Join-Path $ScriptRoot "lib\Phase7-Apply.ps1")

try {
    $config = Get-Config -ScriptRoot $ScriptRoot
    $configSha = Get-FileSha256 -Path (Join-Path $ScriptRoot "config\config.json")

    if ($Mode -eq "apply" -and [string]::IsNullOrWhiteSpace($OutputPath)) {
        throw "Apply mode requires the existing analyze OutputPath."
    }
    if ($Mode -eq "apply" -and $SkipAI) { throw "SkipAI plans cannot be applied." }

    $resolved = Invoke-Phase1Resolve -SourcePath $SourcePath -OutputPath $OutputPath -Mode $Mode -Config $config
    $Source = $resolved.Source
    $OutputPath = $resolved.Output
    $sourceId = $Source.ToLowerInvariant()

    if ($Mode -eq "apply") {
        [void](Invoke-Phase7Apply -Source $Source -OutputPath $OutputPath -Config $config)
        exit 0
    }

    $state = if ($Resume) { Read-State -OutputPath $OutputPath } else { $null }
    if ($Resume -and -not $state) { throw "-Resume given but state.json is missing from '$OutputPath'." }
    if ($state) {
        if ([int]$state.schema -ne 3) { throw "State schema is obsolete. Start a fresh run." }
        if ("$($state.source_id)" -ne $sourceId) { throw "Resume mismatch: source changed." }
        if ("$($state.config_sha)" -ne $configSha) { throw "Resume mismatch: config.json changed. Start a fresh run." }
        if ($PSBoundParameters.ContainsKey("SkipAI") -and [bool]$SkipAI -ne [bool]$state.skip_ai) {
            throw "Resume mismatch: -SkipAI is immutable for a run."
        }
        if ($PSBoundParameters.ContainsKey("HydrateCloud") -and [bool]$HydrateCloud -ne [bool](Get-ObjectProperty $state 'hydrate_cloud' $false)) {
            throw "Resume mismatch: -HydrateCloud is immutable for a run (it changes inventory). Start a fresh run to change it."
        }
        # -ContinuePartial may be toggled on resume; it only changes preflight severity,
        # so re-run preflight under the new setting (e.g. to clear a reader/scan stop).
        if ($PSBoundParameters.ContainsKey("ContinuePartial") -and [bool]$ContinuePartial -ne [bool]$state.continue_partial) {
            $state.continue_partial = [bool]$ContinuePartial
            Set-PhaseState -State $state -Phase "preflight" -Value "pending" -OutputPath $OutputPath
            Write-Phase "resume" "ContinuePartial set to $([bool]$ContinuePartial); preflight will re-run." "warn"
        }
        $SkipAI = [bool]$state.skip_ai
        $ContinuePartial = [bool]$state.continue_partial
        $HydrateCloud = [bool](Get-ObjectProperty $state 'hydrate_cloud' $false)
        Write-Phase "resume" "Resuming run $($state.run_id)" "ok"
    } else {
        $state = [pscustomobject]@{
            schema = 3
            run_id = [guid]::NewGuid().ToString()
            source = $Source
            source_id = $sourceId
            output = $OutputPath
            mode = "analyze"
            config_sha = $configSha
            skip_ai = [bool]$SkipAI
            continue_partial = [bool]$ContinuePartial
            hydrate_cloud = [bool]$HydrateCloud
            started = (Get-Date).ToString("o")
            updated = $null
            phases = [pscustomobject]@{
                resolve = "done"
                inventory = "pending"
                preflight = "pending"
                intake = "pending"
                extraction = "pending"
                queue = "pending"
                ingest = "pending"
                plan = "pending"
            }
        }
        Save-State -State $state -OutputPath $OutputPath
    }

    if (Test-PhaseDone $state "inventory") {
        $manifest = Read-Json -Path (Join-Path $OutputPath "manifest.json")
        Write-Phase "inventory" "already done" "ok"
    } else {
        $manifest = Invoke-Phase2Inventory -Source $Source -OutputPath $OutputPath -Config $config -HydrateCloud ([bool]$HydrateCloud)
        Set-PhaseDone -State $state -Phase "inventory" -OutputPath $OutputPath
    }

    if (Test-PhaseDone $state "preflight") {
        $preflight = Read-Json -Path (Join-Path $OutputPath "preflight.json")
        $manifest = Read-Json -Path (Join-Path $OutputPath "manifest.json")
        Write-Phase "preflight" "already done" "ok"
    } else {
        $preflight = Invoke-Phase0Preflight -Source $Source -OutputPath $OutputPath -Manifest $manifest -Config $config -ContinuePartial ([bool]$ContinuePartial)
        if ($preflight.status -eq "stop") {
            Set-PhaseState -State $state -Phase "preflight" -Value "blocked" -OutputPath $OutputPath
            Write-Phase "preflight" "Stopped before extraction. Fix access/readers, or start a fresh run with -ContinuePartial." "error"
            exit 2
        }
        Set-PhaseDone -State $state -Phase "preflight" -OutputPath $OutputPath
    }

    $contextPath = Join-Path $OutputPath "context.json"
    if ($SkipAI -and -not (Test-Path -LiteralPath $contextPath)) {
        $context = [ordered]@{
            schema = 1
            folder_type = "generic"
            folder_objective = "SkipAI smoke validation"
            core_documents = @()
            naming_convention = "preserve existing names"
            protected_items_confirmed = $true
            protected_items = @()
            files_prefix_supplied_by_user = $false
            files_prefix = ""
            max_depth = [int]$config.organization.max_folder_depth
            free_comments = @()
        }
        Save-Json -Object $context -Path $contextPath
    }

    $context = Read-Json -Path $contextPath
    if (-not $context) {
        Set-PhaseState -State $state -Phase "intake" -Value "awaiting_context" -OutputPath $OutputPath
        Write-Phase "awaiting_context" "STATUS: awaiting_context" "warn"
        Write-Phase "awaiting_context" "Inspect manifest.json, explicitly confirm protected items, then write context.json per reference/organization-contract.md and resume." "warn"
        exit 0
    }
    $contextValidation = Test-ContextFile -Context $context -Manifest $manifest -Config $config
    Save-Json -Object ([ordered]@{
        schema = 1
        valid = [bool]$contextValidation.valid
        errors = @($contextValidation.errors)
        generated = (Get-Date).ToString("o")
    }) -Path (Join-Path $OutputPath "context-validation.json")
    if (-not $contextValidation.valid) {
        Set-PhaseState -State $state -Phase "intake" -Value "awaiting_context" -OutputPath $OutputPath
        Write-Phase "awaiting_context" "context.json is invalid; see context-validation.json" "warn"
        exit 0
    }
    if (-not (Test-PhaseDone $state "intake")) { Set-PhaseDone -State $state -Phase "intake" -OutputPath $OutputPath }

    if ($SkipAI) {
        Set-PhaseState -State $state -Phase "extraction" -Value "skipped" -OutputPath $OutputPath
        Set-PhaseState -State $state -Phase "queue" -Value "skipped" -OutputPath $OutputPath
        Set-PhaseState -State $state -Phase "ingest" -Value "skipped" -OutputPath $OutputPath
        $plan = New-SkipAIOrganizationPlan -Manifest $manifest -Preflight $preflight -Context $context -Config $config -RunId $state.run_id
        Save-Json -Object $plan -Path (Join-Path $OutputPath "organization-plan.json")
    } else {
        if (Test-PhaseDone $state "extraction") {
            $manifest = Read-Json -Path (Join-Path $OutputPath "manifest.json")
            Write-Phase "extraction" "already done" "ok"
        } else {
            $manifest = Invoke-Phase3Extract -Manifest $manifest -Source $Source -OutputPath $OutputPath -Config $config
            Set-PhaseDone -State $state -Phase "extraction" -OutputPath $OutputPath
        }

        if ($state.phases.queue -eq "pending") {
            [void](Invoke-Phase4Queue -Manifest $manifest -Context $context -OutputPath $OutputPath -RunId $state.run_id -Config $config)
            Set-PhaseState -State $state -Phase "queue" -Value "awaiting_host" -OutputPath $OutputPath
        }

        if (Test-PhaseDone $state "ingest") {
            $plan = Read-Json -Path (Join-Path $OutputPath "organization-plan.json")
            Write-Phase "ingest" "already done" "ok"
        } elseif (Test-AnalysisResultsFile -OutputPath $OutputPath) {
            $manifest = Read-Json -Path (Join-Path $OutputPath "manifest.json")
            $plan = Invoke-Phase5Ingest -Manifest $manifest -Context $context -Preflight $preflight -OutputPath $OutputPath -RunId $state.run_id -Config $config
            Set-PhaseState -State $state -Phase "queue" -Value "done" -OutputPath $OutputPath
            Set-PhaseDone -State $state -Phase "ingest" -OutputPath $OutputPath
        } else {
            Write-Phase "awaiting_host" "STATUS: awaiting_host" "warn"
            Write-Phase "awaiting_host" "Complete every batch result and analysis-results.json per reference/organization-contract.md, then resume." "warn"
            exit 0
        }
    }

    $mustRender = (-not (Test-PhaseDone $state "plan") -or $Approve -or $PlanRevisionPath -or $ExpandFolder)
    if ($mustRender) {
        $result = Invoke-Phase6OrganizationPlan `
            -Plan $plan -Manifest $manifest -Context $context -Preflight $preflight -Config $config `
            -OutputPath $OutputPath -SkipAI ([bool]$SkipAI) -RevisionPath $PlanRevisionPath `
            -ExpandFolder $ExpandFolder -Approve ([bool]$Approve)
        if (-not $result.validation.valid) { exit 2 }
        Set-PhaseDone -State $state -Phase "plan" -OutputPath $OutputPath
    } else {
        Write-Phase "plan" "already done" "ok"
    }

    Write-Phase "done" "Artifacts: $OutputPath" "ok"
    Write-Phase "done" "Review approval-view.md. Nothing changes until a matching approval.json is applied." "ok"
    exit 0
} catch {
    Write-Phase "fatal" "$($_.Exception.Message)" "error"
    Write-Host $_.ScriptStackTrace
    exit 1
}
