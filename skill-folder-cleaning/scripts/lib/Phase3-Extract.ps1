# Phase3-Extract.ps1 — extract representative text from analyzable files.
# Office formats are parsed as zips via .NET (no external deps).
# PDFs need an external extractor (config.pdf_extractor, default pdftotext).
# Every failure is recorded; nothing is silently skipped.

Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

function Get-ZipPartText {
    param([string]$ZipPath, [string[]]$EntryPatterns)
    $sb = New-Object System.Text.StringBuilder
    $zip = $null
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead((Get-LongPath $ZipPath))
        foreach ($entry in $zip.Entries) {
            foreach ($pat in $EntryPatterns) {
                if ($entry.FullName -like $pat) {
                    $reader = New-Object System.IO.StreamReader($entry.Open())
                    $xml = $reader.ReadToEnd(); $reader.Dispose()
                    # Insert spaces for paragraph/cell boundaries, then strip tags.
                    $xml = $xml -replace '<(w:p|a:p|c:v|t)\b[^>]*>', ' '
                    $txt = ($xml -replace '<[^>]+>', ' ')
                    $txt = [System.Net.WebUtility]::HtmlDecode($txt)
                    [void]$sb.Append($txt).Append(' ')
                    break
                }
            }
        }
    } finally { if ($zip) { $zip.Dispose() } }
    return ($sb.ToString() -replace '\s+', ' ').Trim()
}

function Get-TextContent {
    param([string]$Path, [int]$Cap)
    # Read as UTF-8 with BOM detection; report undecodable rather than guessing.
    $bytes = [System.IO.File]::ReadAllBytes((Get-LongPath $Path))
    $take = [Math]::Min($bytes.Length, $Cap * 4)
    $slice = New-Object byte[] $take
    [Array]::Copy($bytes, $slice, $take)
    $text = [System.Text.Encoding]::UTF8.GetString($slice)
    return $text
}

function Get-PdfText {
    param([string]$Path, [string]$Extractor, [int]$Cap)
    $exe = Get-Command $Extractor -ErrorAction SilentlyContinue
    if (-not $exe) {
        return @{ ok = $false; text = $null; reason = "no PDF extractor '$Extractor' on PATH (install poppler or set config.pdf_extractor)" }
    }
    try {
        $tmp = [System.IO.Path]::GetTempFileName()
        & $exe.Source -q -enc UTF-8 -l 20 $Path $tmp 2>$null
        $txt = if (Test-Path -LiteralPath $tmp) { Get-Content -LiteralPath $tmp -Raw -Encoding UTF8 } else { "" }
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($txt)) { return @{ ok = $false; text = $null; reason = "extractor returned no text (scanned/image PDF?)" } }
        return @{ ok = $true; text = $txt; reason = $null }
    } catch {
        return @{ ok = $false; text = $null; reason = "pdf extraction error: $($_.Exception.Message)" }
    }
}

function Invoke-Phase3Extract {
    param(
        [Parameter(Mandatory)] $Manifest,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)] $Config
    )

    Write-Phase "extraction" "Extracting text from analyzable files"
    $extDir = Join-Path $OutputPath "extracted"
    if (-not (Test-Path -LiteralPath $extDir)) { New-Item -ItemType Directory -Force -Path $extDir | Out-Null }
    $cap = [int]$Config.openai.extract_char_cap
    $log = @()
    $done = 0; $failed = 0

    foreach ($e in ($Manifest.files | Where-Object { $_.analyze })) {
        $full = Join-Path $Source $e.rel_path
        $text = $null; $status = "ok"; $reason = $null
        try {
            switch ($e.type) {
                "text"  { $text = Get-TextContent -Path $full -Cap $cap }
                "code"  { $text = Get-TextContent -Path $full -Cap $cap }
                "word"  { $text = Get-ZipPartText -ZipPath $full -EntryPatterns @("word/document.xml") }
                "ppt"   { $text = Get-ZipPartText -ZipPath $full -EntryPatterns @("ppt/slides/slide*.xml") }
                "excel" { $text = Get-ZipPartText -ZipPath $full -EntryPatterns @("xl/sharedStrings.xml", "xl/worksheets/sheet*.xml") }
                "pdf"   {
                    $r = Get-PdfText -Path $full -Extractor $Config.pdf_extractor -Cap $cap
                    if ($r.ok) { $text = $r.text } else { $status = "failed"; $reason = $r.reason }
                }
                default { $status = "failed"; $reason = "unsupported type for extraction" }
            }
        } catch {
            $status = "failed"; $reason = $_.Exception.Message
        }

        if ($status -eq "ok") {
            if ([string]::IsNullOrWhiteSpace($text)) { $status = "failed"; $reason = "no text content found" }
            else {
                if ($text.Length -gt $cap) { $text = $text.Substring(0, $cap); $status = "truncated" }
                $outFile = Join-Path $extDir ("{0}.txt" -f $e.id)
                [System.IO.File]::WriteAllText((Get-LongPath $outFile), $text, (New-Object System.Text.UTF8Encoding($false)))
                $e.extracted_file = "extracted/{0}.txt" -f $e.id
            }
        }

        $e.extraction_status = $status
        $e.extraction_reason = $reason
        if ($status -eq "failed") {
            $failed++
            $e.analyze = $false   # cannot judge content; will be flagged unreadable in classify
            $e.notes += "extraction_failed: $reason"
        } else { $done++ }

        $log += [pscustomobject]@{ id = $e.id; rel_path = $e.rel_path; status = $status; reason = $reason; chars = ($(if ($text) { $text.Length } else { 0 })) }
    }

    Save-Json -Object @{ schema = 1; generated = (Get-Date).ToString("o"); entries = $log } -Path (Join-Path $OutputPath "extraction-log.json")
    # Persist manifest updates (extracted_file / status).
    Save-Json -Object $Manifest -Path (Join-Path $OutputPath "manifest.json")
    Write-Phase "extraction" "$done extracted, $failed failed (recorded in extraction-log.json)" "ok"
    return $Manifest
}
