# Phase2-Inventory.ps1 — enumerate every file, hash exact duplicates, and record
# enough metadata for context intake and global organization analysis.

function Get-ImageMetadata {
    param([string]$Path)
    $result = [ordered]@{ width = $null; height = $null; format = $null }
    try {
        Add-Type -AssemblyName System.Drawing.Common -ErrorAction SilentlyContinue
        $image = [System.Drawing.Image]::FromFile((Get-LongPath $Path))
        try {
            $result.width = $image.Width
            $result.height = $image.Height
            $result.format = "$($image.RawFormat)"
        } finally {
            $image.Dispose()
        }
    } catch { }
    return [pscustomobject]$result
}

function Invoke-Phase2Inventory {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)]$Config,
        [bool]$HydrateCloud
    )

    Write-Phase "inventory" "Scanning folders and files"

    $scanErrors = @()
    $items = @(Get-ChildItem -LiteralPath $Source -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +scanErr)
    foreach ($errorRecord in @($scanErr)) {
        $target = if ($errorRecord.TargetObject) { "$($errorRecord.TargetObject)" } else { "" }
        $scanErrors += [pscustomobject]@{ path = $target; error = "$($errorRecord.Exception.Message)" }
    }

    # The reserved artifacts folder (default _DATA_CLEANING) lives inside the analyzed
    # root, so exclude it and everything under it: the run must never inventory, plan,
    # or move its own state, extracted text, plans, or transaction journals.
    $artifactsName = "$($Config.organization.artifacts_dir)"
    if (-not [string]::IsNullOrWhiteSpace($artifactsName)) {
        $artifactsExact = (Join-Path $Source $artifactsName).TrimEnd("\")
        $artifactsPrefix = $artifactsExact + "\"
        $items = @($items | Where-Object {
            $fullName = "$($_.FullName)"
            -not ($fullName.Equals($artifactsExact, [System.StringComparison]::OrdinalIgnoreCase) -or
                  $fullName.StartsWith($artifactsPrefix, [System.StringComparison]::OrdinalIgnoreCase))
        })
    }

    # VCS/dev-metadata internals (.git etc.) are untouchable: inventorying them wastes
    # host tokens, flags normal refs/reflogs as duplicates, and a planned move on one
    # would corrupt the repo. Excluded by directory name at any depth.
    $excludeDirs = @(@($Config.organization.scan_exclude_dirs) | Where-Object { $_ })
    if ($excludeDirs.Count -gt 0) {
        $items = @($items | Where-Object {
            $segments = $_.FullName.Substring($Source.Length).TrimStart("\").Split("\")
            -not ($segments | Where-Object { $excludeDirs -contains $_ })
        })
    }

    $folders = @($items |
        Where-Object { $_.PSIsContainer } |
        ForEach-Object { $_.FullName.Substring($Source.Length).TrimStart("\") } |
        Where-Object { $_ } |
        Sort-Object { $_.ToLowerInvariant() })

    $ordered = @($items |
        Where-Object { -not $_.PSIsContainer } |
        Sort-Object { $_.FullName.Substring($Source.Length).TrimStart("\").ToLowerInvariant() })

    $files = @()
    $index = 0
    foreach ($file in $ordered) {
        $index++
        $id = "f{0:D5}" -f $index

        # Opt-in: download OneDrive (Files On-Demand) placeholders so they can be hashed
        # and analyzed like local files instead of being routed to review as cloud-only.
        if ($HydrateCloud -and (Get-CloudMaskHit -Item $file) -ne 0) {
            if (Request-FileHydration -Path $file.FullName) {
                try { $file = Get-Item -LiteralPath $file.FullName -Force -ErrorAction Stop } catch { }
            }
        }

        $relativePath = $file.FullName.Substring($Source.Length).TrimStart("\")
        $extension = $file.Extension.ToLowerInvariant()
        $type = Get-FileType -Ext $extension -Config $Config
        $isTemp = ($type -eq "temp" -or $file.Name.StartsWith("~$"))
        $isEmpty = ($file.Length -eq 0)
        $kind = switch ($type) {
            "image" { "image" }
            "binary_skip" { "binary" }
            default { "document" }
        }

        $entry = [ordered]@{
            id = $id
            rel_path = $relativePath
            ext = $extension
            type = $type
            kind = $kind
            size_bytes = $file.Length
            modified = $file.LastWriteTimeUtc.ToString("o")
            created = $file.CreationTimeUtc.ToString("o")
            sha256 = $null
            availability = "local"
            attr_mask = ("0x{0:X}" -f [int]$file.Attributes)
            is_empty = $isEmpty
            is_temp = $isTemp
            shortcut_target = $null
            image_metadata = $null
            needs_visual = ($type -eq "image")
            extract_text = ((Test-TextExtractable -Type $type) -and -not $isEmpty -and -not $isTemp)
            submit_to_host = (-not $isTemp -and -not $isEmpty)
            exact_duplicate_group = $null
            analysis_representative_id = $null
            is_analysis_representative = $false
            extracted_file = $null
            extracted_sha256 = $null
            extraction_status = "pending"
            extraction_reason = $null
            decoding_errors = $false
            deterministic_disposition = $null
            notes = @()
        }

        if ($extension -eq ".lnk") {
            $entry.kind = "shortcut"
            $resolved = Resolve-Shortcut -LnkPath $file.FullName
            $entry.shortcut_target = $resolved.target
            $entry.extract_text = $false
            $entry.submit_to_host = $false
            $entry.extraction_status = "skipped"
            $entry.extraction_reason = "shortcut"
            if ($resolved.broken) {
                $entry.availability = "broken_shortcut"
                $entry.notes += "shortcut target missing"
            } else {
                $entry.notes += "shortcut -> $($resolved.target)"
            }
        }

        $cloudMask = Get-CloudMaskHit -Item $file
        if ($cloudMask -ne 0) {
            $entry.availability = "cloud_only"
            $entry.extract_text = $false
            $entry.submit_to_host = $false
            $entry.extraction_status = "skipped"
            $entry.extraction_reason = "cloud-only placeholder; make available locally"
            $entry.notes += "cloud-only: not hashed or downloaded"
            $files += [pscustomobject]$entry
            continue
        }

        try {
            $sizeBefore = $file.Length
            $modifiedBefore = $file.LastWriteTimeUtc
            $entry.sha256 = Get-FileSha256 -Path $file.FullName
            $after = Get-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            if ($after.Length -ne $sizeBefore -or $after.LastWriteTimeUtc -ne $modifiedBefore) {
                $entry.availability = "unstable"
                $entry.sha256 = $null
                $entry.extract_text = $false
                $entry.submit_to_host = $false
                $entry.extraction_status = "skipped"
                $entry.extraction_reason = "file changed during inventory"
                $entry.notes += "file changed during inventory"
            }
        } catch {
            $entry.availability = "unreadable"
            $entry.sha256 = $null
            $entry.extract_text = $false
            $entry.submit_to_host = $false
            $entry.extraction_status = "skipped"
            $entry.extraction_reason = "hash failed: $($_.Exception.Message)"
            $entry.notes += $entry.extraction_reason
        }

        if ($type -eq "image" -and $entry.availability -eq "local") {
            $entry.image_metadata = Get-ImageMetadata -Path $file.FullName
        }
        if (-not $entry.extract_text -and $entry.extraction_status -eq "pending") {
            $entry.extraction_status = "skipped"
            $entry.extraction_reason = "metadata-only host analysis"
        }

        $files += [pscustomobject]$entry
    }

    # Group only real content files. Temp/empty/shortcut files share trivial hashes
    # (e.g. every empty file) but must keep their deterministic review disposition
    # instead of being forced through host analysis as a "duplicate".
    $duplicateGroups = @()
    $hashGroups = @($files |
        Where-Object { $_.sha256 -and $_.submit_to_host } |
        Group-Object sha256 |
        Where-Object { $_.Count -gt 1 } |
        Sort-Object Name)
    $groupIndex = 0
    foreach ($group in $hashGroups) {
        $groupIndex++
        $groupId = "d{0:D3}" -f $groupIndex
        $members = @($group.Group | Sort-Object { $_.rel_path.ToLowerInvariant() })
        $representative = $members[0]
        foreach ($member in $members) {
            $member.exact_duplicate_group = $groupId
            $member.analysis_representative_id = $representative.id
            $member.is_analysis_representative = ($member.id -eq $representative.id)
            if ($member.id -ne $representative.id) {
                $member.extract_text = $false
                $member.submit_to_host = $false
                $member.extraction_status = "skipped"
                $member.extraction_reason = "exact duplicate; representative content submitted once"
            }
        }
        $representative.submit_to_host = $true
        $duplicateGroups += [pscustomobject]@{
            group_id = $groupId
            sha256 = $group.Name
            analysis_representative_id = $representative.id
            occurrence_paths = @($members | ForEach-Object { $_.rel_path })
        }
    }

    foreach ($entry in $files) {
        [void](Set-DeterministicDisposition -Entry $entry)
    }

    $formatCensus = @($files |
        Group-Object type |
        Sort-Object Name |
        ForEach-Object { [pscustomobject]@{ type = $_.Name; count = $_.Count } })

    $manifest = [ordered]@{
        schema = 3
        generated = (Get-Date).ToString("o")
        source = $Source
        complete = ($scanErrors.Count -eq 0)
        scan_errors = $scanErrors
        file_count = $files.Count
        folders = $folders
        format_census = $formatCensus
        duplicate_groups = $duplicateGroups
        files = $files
    }
    Save-Json -Object $manifest -Path (Join-Path $OutputPath "manifest.json")

    $cloudCount = @($files | Where-Object { $_.availability -eq "cloud_only" }).Count
    $imageCount = @($files | Where-Object { $_.kind -eq "image" }).Count
    $level = if ($manifest.complete) { "ok" } else { "warn" }
    Write-Phase "inventory" "$($files.Count) files | $($folders.Count) folders | $($duplicateGroups.Count) exact-duplicate groups | $imageCount images | $cloudCount cloud-only | $($scanErrors.Count) scan errors" $level
    return [pscustomobject]$manifest
}
