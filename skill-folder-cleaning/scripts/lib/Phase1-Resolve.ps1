# Phase1-Resolve.ps1 — resolve source/output, verify access, enforce safety.

function Invoke-Phase1Resolve {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [string]$OutputPath,
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)] $Config
    )

    Write-Phase "resolve" "Resolving source and output paths"

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Source path does not exist: $SourcePath"
    }
    $srcItem = Get-Item -LiteralPath $SourcePath
    if (-not $srcItem.PSIsContainer) { throw "Source is not a folder: $SourcePath" }
    $src = (Resolve-Path -LiteralPath $SourcePath).Path.TrimEnd('\')

    # Default OutputPath: a sibling _folder-cleaning dir, never inside the source.
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $parent = Split-Path -Parent $src
        $name = Split-Path -Leaf $src
        $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
        $OutputPath = Join-Path (Join-Path $parent "_folder-cleaning") "$name-$stamp"
    }
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath).TrimEnd('\')

    # Safety: artifacts must never live inside the source tree.
    $srcCmp = $src.ToLowerInvariant() + '\'
    $outCmp = $OutputPath.ToLowerInvariant() + '\'
    if ($outCmp.StartsWith($srcCmp)) {
        throw "OutputPath is inside SourcePath. Refusing to write artifacts into the source folder."
    }
    if (-not (Test-Path -LiteralPath $OutputPath)) {
        New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
    }

    # Verify read access by enumerating one level.
    try { Get-ChildItem -LiteralPath $src -Force -ErrorAction Stop | Select-Object -First 1 | Out-Null }
    catch { throw "Cannot read source folder (access denied?): $($_.Exception.Message)" }

    Write-Phase "resolve" "Source:  $src" "ok"
    Write-Phase "resolve" "Output:  $OutputPath" "ok"

    return [pscustomobject]@{ Source = $src; Output = $OutputPath }
}
