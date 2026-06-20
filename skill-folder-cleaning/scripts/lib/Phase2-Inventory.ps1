# Phase2-Inventory.ps1 — enumerate every file, hash, flag dupes/temp/empty.
# Deterministic. No AI. No source writes.

function Resolve-Shortcut {
    param([string]$LnkPath)
    try {
        $sh = New-Object -ComObject WScript.Shell
        $target = $sh.CreateShortcut($LnkPath).TargetPath
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sh) | Out-Null
        if ([string]::IsNullOrWhiteSpace($target)) { return @{ target = $null; broken = $true } }
        return @{ target = $target; broken = -not (Test-Path -LiteralPath $target) }
    } catch {
        return @{ target = $null; broken = $true }
    }
}

function Invoke-Phase2Inventory {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)] $Config
    )

    Write-Phase "inventory" "Scanning files (this can take a moment on large folders)"

    $files = @()
    $idx = 0
    $all = Get-ChildItem -LiteralPath $Source -Recurse -File -Force -ErrorAction SilentlyContinue

    foreach ($f in $all) {
        $idx++
        $id = "f{0:D5}" -f $idx
        $rel = $f.FullName.Substring($Source.Length).TrimStart('\')
        $ext = $f.Extension.ToLowerInvariant()
        $type = Get-FileType -Ext $ext -Config $Config

        $entry = [ordered]@{
            id                 = $id
            rel_path           = $rel
            ext                = $ext
            type               = $type
            size_bytes         = $f.Length
            modified           = $f.LastWriteTimeUtc.ToString("o")
            created            = $f.CreationTimeUtc.ToString("o")
            sha256             = $null
            availability       = "local"
            is_empty           = ($f.Length -eq 0)
            is_temp            = ($type -eq "temp" -or $f.Name.StartsWith("~$"))
            shortcut_target    = $null
            dup_group          = $null
            # Empty and temp files are decided deterministically — don't extract or send to AI.
            analyze            = ((Test-Analyzable -Type $type) -and ($f.Length -gt 0) -and ($type -ne "temp") -and -not $f.Name.StartsWith("~$"))
            extracted_file     = $null
            extraction_status  = "pending"
            extraction_reason  = $null
            classification     = $null
            notes              = @()
        }

        # Windows shortcuts: resolve, don't follow for cleanup.
        if ($ext -eq ".lnk") {
            $r = Resolve-Shortcut -LnkPath $f.FullName
            $entry.shortcut_target = $r.target
            $entry.analyze = $false
            if ($r.broken) { $entry.availability = "broken_shortcut"; $entry.notes += "shortcut target missing" }
            else { $entry.notes += "shortcut -> $($r.target)" }
            $files += [pscustomobject]$entry
            continue
        }

        # OneDrive cloud-only: inventory but do not hash/extract (no local bytes).
        if (Test-CloudOnly -Item $f) {
            $entry.availability = "cloud_only"
            $entry.analyze = $false
            $entry.extraction_status = "skipped"
            $entry.extraction_reason = "cloud_only (OneDrive); user must make available locally"
            $entry.notes += "cloud-only: not downloaded"
            $files += [pscustomobject]$entry
            continue
        }

        # Hash local files (exact-duplicate detection, deterministic, free).
        if ($f.Length -gt 0) {
            try {
                $entry.sha256 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            } catch {
                $entry.availability = "unreadable"
                $entry.analyze = $false
                $entry.notes += "hash failed: $($_.Exception.Message)"
            }
        }

        $files += [pscustomobject]$entry
    }

    # Exact-duplicate groups: same SHA-256 => same bytes. No AI needed.
    $groups = @($files | Where-Object { $_.sha256 } | Group-Object sha256 | Where-Object { $_.Count -gt 1 })
    $g = 0
    foreach ($grp in $groups) {
        $g++
        $label = "d{0:D3}" -f $g
        foreach ($m in $grp.Group) {
            $m.dup_group = $label
            # Keep the oldest copy as canonical; the rest are exact duplicates.
        }
        $sorted = $grp.Group | Sort-Object modified
        for ($i = 1; $i -lt $sorted.Count; $i++) {
            $sorted[$i].analyze = $false
            $sorted[$i].notes += "exact duplicate of $($sorted[0].rel_path)"
        }
    }

    $manifest = [ordered]@{
        schema       = 1
        generated    = (Get-Date).ToString("o")
        source       = $Source
        file_count   = $files.Count
        dup_groups   = $groups.Count
        files        = $files
    }
    Save-Json -Object $manifest -Path (Join-Path $OutputPath "manifest.json")

    $cloud = @($files | Where-Object { $_.availability -eq "cloud_only" }).Count
    $broken = @($files | Where-Object { $_.availability -eq "broken_shortcut" }).Count
    Write-Phase "inventory" "$($files.Count) files | $($groups.Count) exact-dup groups | $cloud cloud-only | $broken broken shortcuts" "ok"
    return $manifest
}
