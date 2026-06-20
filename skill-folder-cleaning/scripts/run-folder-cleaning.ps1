<#
.SYNOPSIS
  Audit a local Windows folder and propose a safe, reversible cleanup (Phases 1-6).

.DESCRIPTION
  Read-only by default. Deterministic facts (inventory, SHA-256, exact duplicates,
  extraction) are pure PowerShell/.NET. Only semantic judgement is sent to OpenAI,
  on two tiers. Produces manifest.json, plan.json, plan-validation.json and a
  human-readable cleaning-report.md in OutputPath. Apply (Phase 7) is not built yet.

.EXAMPLE
  .\run-folder-cleaning.ps1 -SourcePath "C:\Users\me\Downloads\stuff" -Mode analyze

.EXAMPLE
  .\run-folder-cleaning.ps1 -SourcePath "C:\data\proj" -SkipAI   # inventory only, no API key
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourcePath,
    [string]$OutputPath,
    [ValidateSet("analyze")][string]$Mode = "analyze",
    [switch]$SkipAI,
    [switch]$Resume,
    [int]$MaxAiFiles,
    [double]$MaxUsd
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load libraries.
. (Join-Path $ScriptRoot "lib\Common.ps1")
. (Join-Path $ScriptRoot "lib\Phase1-Resolve.ps1")
. (Join-Path $ScriptRoot "lib\Phase2-Inventory.ps1")
. (Join-Path $ScriptRoot "lib\Phase3-Extract.ps1")
. (Join-Path $ScriptRoot "lib\OpenAI.ps1")
. (Join-Path $ScriptRoot "lib\Phase4-Classify.ps1")
. (Join-Path $ScriptRoot "lib\Phase5-Analyze.ps1")
. (Join-Path $ScriptRoot "lib\Phase6-Report.ps1")

try {
    $config = Get-Config -ScriptRoot $ScriptRoot
    if (-not $PSBoundParameters.ContainsKey('MaxAiFiles')) { $MaxAiFiles = [int]$config.caps.max_ai_files }
    if (-not $PSBoundParameters.ContainsKey('MaxUsd'))     { $MaxUsd = [double]$config.caps.max_usd }

    # No key and AI not explicitly skipped -> degrade to deterministic-only rather
    # than marking good files unreadable. Tell the user plainly.
    if (-not $SkipAI -and [string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
        Write-Phase "setup" "OPENAI_API_KEY not set — running inventory + extraction only (no AI classification). See reference/openai-setup.md." "warn"
        $SkipAI = $true
    }

    # ---- Phase 1: Resolve (always) ----
    $resolved = Invoke-Phase1Resolve -SourcePath $SourcePath -OutputPath $OutputPath -Mode $Mode -Config $config
    $Source = $resolved.Source
    $OutputPath = $resolved.Output

    # ---- State / resume ----
    $state = if ($Resume) { Read-State -OutputPath $OutputPath } else { $null }
    if (-not $state) {
        $state = [pscustomobject]@{
            schema = 1; source = $Source; output = $OutputPath; mode = $Mode
            skip_ai = [bool]$SkipAI; started = (Get-Date).ToString("o"); updated = $null
            phases = [pscustomobject]@{ resolve="done"; inventory="pending"; extraction="pending"; classify="pending"; analyze="pending"; report="pending" }
        }
        Save-State -State $state -OutputPath $OutputPath
    } else {
        Write-Phase "resume" "Resuming; completed: $(( $state.phases.PSObject.Properties | Where-Object { $_.Value -eq 'done' } | ForEach-Object { $_.Name }) -join ', ')" "ok"
    }

    # ---- Phase 2: Inventory ----
    if (Test-PhaseDone $state "inventory") {
        $manifest = Read-Json -Path (Join-Path $OutputPath "manifest.json")
        Write-Phase "inventory" "already done — loaded manifest.json" "ok"
    } else {
        $manifest = Invoke-Phase2Inventory -Source $Source -OutputPath $OutputPath -Config $config
        Set-PhaseDone $state "inventory" $OutputPath
    }

    # ---- Phase 3: Extraction ----
    if (Test-PhaseDone $state "extraction") {
        Write-Phase "extraction" "already done — skipping" "ok"
    } else {
        $manifest = Invoke-Phase3Extract -Manifest $manifest -Source $Source -OutputPath $OutputPath -Config $config
        Set-PhaseDone $state "extraction" $OutputPath
    }

    $aiRan = $false
    if ($SkipAI) {
        Write-Phase "classify" "-SkipAI: deterministic labels only, no model calls" "warn"
        foreach ($e in $manifest.files) {
            if (-not (Set-DeterministicLabel -Entry $e)) {
                $e.classification = @{ label="unclear"; confidence=0.0; evidence="AI skipped (-SkipAI)"; needs_complex=$false; model="skipped" }
            }
        }
        Save-Json -Object $manifest -Path (Join-Path $OutputPath "manifest.json")
    } else {
        # ---- Phase 4: Bulk classify ----
        if (Test-PhaseDone $state "classify") {
            $manifest = Read-Json -Path (Join-Path $OutputPath "manifest.json")
            Write-Phase "classify" "already done — loaded manifest.json" "ok"
        } else {
            $manifest = Invoke-Phase4Classify -Manifest $manifest -Source $Source -OutputPath $OutputPath -Config $config -MaxAiFiles $MaxAiFiles -MaxUsd $MaxUsd
            Set-PhaseDone $state "classify" $OutputPath
        }
        # ---- Phase 5: Complex analysis ----
        if (Test-PhaseDone $state "analyze") {
            $manifest = Read-Json -Path (Join-Path $OutputPath "manifest.json")
            Write-Phase "analyze" "already done — loaded manifest.json" "ok"
        } else {
            $manifest = Invoke-Phase5Analyze -Manifest $manifest -OutputPath $OutputPath -Config $config -MaxAiFiles $MaxAiFiles -MaxUsd $MaxUsd
            Set-PhaseDone $state "analyze" $OutputPath
        }
        $aiRan = $true
    }

    # ---- Phase 6: Report ----
    $valid = Invoke-Phase6Report -Manifest $manifest -Source $Source -OutputPath $OutputPath -Config $config -AiRan $aiRan
    Set-PhaseDone $state "report" $OutputPath

    Write-Host ""
    Write-Phase "done" "Artifacts in: $OutputPath" "ok"
    Write-Phase "done" "Read cleaning-report.md to review the proposal." "ok"
    if (-not $valid) { exit 2 }
    exit 0
}
catch {
    Write-Phase "fatal" "$($_.Exception.Message)" "error"
    Write-Host $_.ScriptStackTrace
    exit 1
}
