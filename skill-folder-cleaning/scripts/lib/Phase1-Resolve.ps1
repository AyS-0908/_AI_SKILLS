# Phase1-Resolve.ps1 — resolve source/output, verify access, enforce safety.

function Invoke-Phase1Resolve {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [string]$OutputPath,
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)] $Config
    )

    Write-Phase "resolve" "Resolving source and output paths"

    $requested = $SourcePath
    # A project shortcut may be passed as the source — resolve it before validating.
    if ([System.IO.Path]::GetExtension($SourcePath).ToLowerInvariant() -eq ".lnk") {
        $r = Resolve-Shortcut -LnkPath $SourcePath
        if ($r.broken -or -not $r.target) { throw "Source shortcut does not resolve to an existing target: $SourcePath" }
        $SourcePath = $r.target
        Write-Phase "resolve" "Source shortcut -> $SourcePath" "ok"
    }

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Source path does not exist: $SourcePath"
    }
    $srcItem = Get-Item -LiteralPath $SourcePath -Force
    if (-not $srcItem.PSIsContainer) { throw "Source is not a folder: $SourcePath" }

    # Real (link-resolved) source path; this is what we scan and guard against.
    $src = (Get-RealPath $SourcePath)

    # Default OutputPath: a reserved artifacts folder INSIDE the analyzed root, e.g.
    # <source>\_DATA_CLEANING\<timestamp>. Phase2 excludes this folder from the scan,
    # so the run never inventories or moves its own artifacts.
    $artifactsName = "$($Config.organization.artifacts_dir)"
    if ([string]::IsNullOrWhiteSpace($artifactsName)) { $artifactsName = "_DATA_CLEANING" }
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
        $OutputPath = Join-Path (Join-Path $src $artifactsName) $stamp
    }

    # Safety: resolve BOTH to real targets (catching junctions/symlinks that would
    # otherwise let artifacts land in an unexpected place), then compare on a separator
    # boundary so C:\src vs C:\src2 are distinct. Guard BEFORE creating OutputPath.
    $outReal = (Resolve-FinalPath $OutputPath)
    # Fail-safe: if we could not use the final-path API and the output's ancestry
    # contains a reparse point, we cannot prove where it really lands. Refuse.
    if (-not (Initialize-FinalPathApi) -and (Test-ReparseInAncestry $OutputPath)) {
        throw "OutputPath ancestry contains an unresolved junction/symlink and the path-resolution API is unavailable. Refusing — choose an output path with no reparse points in its ancestry."
    }
    # Artifacts may live inside the source ONLY within the reserved artifacts folder.
    # Any other in-source output is refused so the run never scans or moves its own files.
    $artifactsRoot = (Resolve-FinalPath (Join-Path $src $artifactsName))
    $srcCmp = $src.TrimEnd('\') + '\'
    $outCmp = $outReal.TrimEnd('\') + '\'
    $artCmp = $artifactsRoot.TrimEnd('\') + '\'
    $insideSource = $outCmp.StartsWith($srcCmp, [System.StringComparison]::OrdinalIgnoreCase) -or
        $outReal.TrimEnd('\').Equals($src.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)
    $insideArtifacts = $outCmp.StartsWith($artCmp, [System.StringComparison]::OrdinalIgnoreCase) -or
        $outReal.TrimEnd('\').Equals($artifactsRoot.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)
    if ($insideSource -and -not $insideArtifacts) {
        throw "OutputPath resolves inside SourcePath (`"$outReal`") outside the reserved '$artifactsName' folder. Refusing to write artifacts into the scanned tree."
    }

    $OutputPath = $outReal
    if (-not (Test-Path -LiteralPath $OutputPath)) {
        New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
    }

    # Verify read access by enumerating one level.
    try { Get-ChildItem -LiteralPath $src -Force -ErrorAction Stop | Select-Object -First 1 | Out-Null }
    catch { throw "Cannot read source folder (access denied?): $($_.Exception.Message)" }

    Write-Phase "resolve" "Source:  $src" "ok"
    Write-Phase "resolve" "Output:  $OutputPath" "ok"

    return [pscustomobject]@{ Source = $src; Output = $OutputPath; Requested = $requested }
}
