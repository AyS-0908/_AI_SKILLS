# Common.ps1 — shared helpers for the folder-cleaning pipeline.
# Dot-sourced by run-folder-cleaning.ps1. No side effects on load.

Set-StrictMode -Version Latest

function Write-Phase {
    param([string]$Phase, [string]$Message, [string]$Level = "info")
    $ts = (Get-Date).ToString("HH:mm:ss")
    $tag = switch ($Level) { "warn" {"[!]"} "error" {"[x]"} "ok" {"[+]"} default {"[*]"} }
    Write-Host "$ts $tag $Phase`: $Message"
}

# Prefix a path for long-path (>260) access by the .NET APIs.
function Get-LongPath {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.Length -ge 248 -and -not $full.StartsWith("\\?\")) {
        if ($full.StartsWith("\\")) { return "\\?\UNC\" + $full.Substring(2) }
        return "\\?\" + $full
    }
    return $full
}

function Get-Config {
    param([string]$ScriptRoot)
    $cfgPath = Join-Path $ScriptRoot "config\config.json"
    if (-not (Test-Path -LiteralPath $cfgPath)) { throw "Config not found: $cfgPath" }
    return (Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Save-Json {
    param([Parameter(Mandatory)] $Object, [Parameter(Mandatory)][string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $json = $Object | ConvertTo-Json -Depth 12
    # ConvertTo-Json escapes nothing harmful; write UTF8 without BOM for portability.
    [System.IO.File]::WriteAllText((Get-LongPath $Path), $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Read-Json {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

# ---- State / checkpoint ---------------------------------------------------

function Read-State {
    param([string]$OutputPath)
    $p = Join-Path $OutputPath "state.json"
    return (Read-Json -Path $p)
}

function Save-State {
    param([Parameter(Mandatory)] $State, [Parameter(Mandatory)][string]$OutputPath)
    $State.updated = (Get-Date).ToString("o")
    Save-Json -Object $State -Path (Join-Path $OutputPath "state.json")
}

function Test-PhaseDone {
    param($State, [string]$Phase)
    return ($State -and $State.phases -and $State.phases.$Phase -eq "done")
}

function Set-PhaseDone {
    param($State, [string]$Phase, [string]$OutputPath)
    $State.phases.$Phase = "done"
    Save-State -State $State -OutputPath $OutputPath
}

# ---- File typing ----------------------------------------------------------

# RECALL_ON_DATA_ACCESS (0x400000) and Offline (0x1000) => OneDrive cloud-only.
function Test-CloudOnly {
    param([System.IO.FileInfo]$Item)
    $a = [int]$Item.Attributes
    return ((($a -band 0x400000) -ne 0) -or (($a -band 0x1000) -ne 0))
}

function Get-FileType {
    param([string]$Ext, $Config)
    $e = $Ext.ToLowerInvariant()
    foreach ($cat in @("text","code","word","excel","ppt","pdf","temp","binary_skip")) {
        if ($Config.extensions.$cat -contains $e) { return $cat }
    }
    return "other"
}

# Files we send through extraction + AI (need semantic judgement).
function Test-Analyzable {
    param([string]$Type)
    return @("text","code","word","excel","ppt","pdf") -contains $Type
}

# ---- Cost helpers ---------------------------------------------------------

function Get-CostUsd {
    param($Config, [string]$Model, [int]$InTok, [int]$OutTok)
    $p = $Config.pricing_per_mtok.$Model
    if (-not $p) { return 0.0 }
    return [math]::Round((($InTok / 1e6) * $p.in) + (($OutTok / 1e6) * $p.out), 6)
}
