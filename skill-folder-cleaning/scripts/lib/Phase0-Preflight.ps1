# Phase0-Preflight.ps1 — verify readers and scan completeness before extraction.

function Invoke-Phase0Preflight {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Config,
        [bool]$ContinuePartial
    )

    Write-Phase "preflight" "Checking readers, scan completeness, and local availability"
    $issues = @()
    $blocking = $false
    $approvalBlocked = $false
    $readerStatus = @()

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        $issues += [pscustomobject]@{ code = "source_inaccessible"; severity = "error"; count = 1; message = "Source folder is no longer accessible."; action = "fix_access" }
        $blocking = $true
    }

    $requiredVersion = [version]"$($Config.runtime.requires_pwsh)"
    if ($PSVersionTable.PSVersion -lt $requiredVersion) {
        $issues += [pscustomobject]@{ code = "powershell_version"; severity = "error"; count = 1; message = "PowerShell $requiredVersion or newer is required."; action = "install_pwsh" }
        $blocking = $true
    }

    $pdfFiles = @($Manifest.files | Where-Object { $_.type -eq "pdf" -and $_.availability -eq "local" })
    if ($pdfFiles.Count -gt 0) {
        $reader = Get-AvailablePdfReader -Config $Config
        $readerLabel = Get-PdfReaderLabel -Config $Config
        $readerStatus += [pscustomobject]@{
            format = "pdf"
            reader = $readerLabel
            available = ($null -ne $reader)
            affected_file_count = $pdfFiles.Count
        }
        if (-not $reader) {
            # A missing PDF reader no longer stops the run. PDFs keep their SHA-256 and
            # are handed to the host as metadata-only, then routed to review. Install a
            # reader (e.g. poppler's pdftotext) on PATH to enable PDF text extraction.
            $issues += [pscustomobject]@{
                code = "required_reader_missing"
                severity = "warning"
                count = $pdfFiles.Count
                message = "PDF reader ($readerLabel) is not on PATH; $($pdfFiles.Count) PDF file(s) will be reviewed without text extraction."
                action = "install_reader_to_extract_pdf_text"
            }
            foreach ($file in $pdfFiles) {
                $file.extract_text = $false
                $file.extraction_status = "skipped"
                $file.extraction_reason = "no PDF reader on PATH; routed to review without text extraction"
                $file.submit_to_host = $true
                $file.notes += "PDF content unavailable: install a PDF reader to extract text"
            }
        }
    }

    if (-not [bool]$Manifest.complete) {
        $errorCount = @($Manifest.scan_errors).Count
        $severity = if ($ContinuePartial) { "warning" } else { "error" }
        $issues += [pscustomobject]@{
            code = "scan_incomplete"
            severity = $severity
            count = $errorCount
            message = "Inventory is incomplete; $errorCount path(s) could not be read."
            action = "fix_access_or_continue_partial"
        }
        if (-not $ContinuePartial) { $blocking = $true }
    }

    $unreadable = @($Manifest.files | Where-Object { $_.availability -eq "unreadable" })
    if ($unreadable.Count -gt 0) {
        $issues += [pscustomobject]@{
            code = "permission_or_read_failure"
            severity = "warning"
            count = $unreadable.Count
            message = "$($unreadable.Count) file(s) could not be read or hashed."
            action = "fix_access"
        }
        $approvalBlocked = $true
    }

    $cloudOnly = @($Manifest.files | Where-Object { $_.availability -eq "cloud_only" })
    if ($cloudOnly.Count -gt 0) {
        $issues += [pscustomobject]@{
            code = "cloud_only_files"
            severity = "warning"
            count = $cloudOnly.Count
            message = "$($cloudOnly.Count) cloud-only file(s) were inventoried without downloading."
            action = "make_available_locally"
        }
        $approvalBlocked = $true
    }

    if ($blocking) { $approvalBlocked = $true }
    $status = if ($blocking) { "stop" } elseif ($issues.Count -gt 0) { "partial" } else { "ok" }
    $preflight = [ordered]@{
        schema = 1
        generated = (Get-Date).ToString("o")
        status = $status
        continue_partial = $ContinuePartial
        approval_blocked = $approvalBlocked
        manifest_complete = [bool]$Manifest.complete
        scan_errors = @($Manifest.scan_errors)
        cloud_only_paths = @($cloudOnly | ForEach-Object { $_.rel_path })
        readers = $readerStatus
        issues = $issues
    }
    Save-Json -Object $preflight -Path (Join-Path $OutputPath "preflight.json")
    Save-Json -Object $Manifest -Path (Join-Path $OutputPath "manifest.json")

    $level = if ($status -eq "ok") { "ok" } elseif ($status -eq "stop") { "error" } else { "warn" }
    Write-Phase "preflight" "status=$status | issues=$($issues.Count) | approval_blocked=$approvalBlocked" $level
    return [pscustomobject]$preflight
}
