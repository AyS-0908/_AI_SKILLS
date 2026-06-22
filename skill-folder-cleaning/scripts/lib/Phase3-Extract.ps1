# Phase3-Extract.ps1 — extract representative text from analyzable files.
# Office formats are parsed as zips via .NET XML reader (no external deps).
# PDFs need an external extractor (config.pdf_extractors, default pdftotext); when none
# is on PATH the run continues and the PDF is routed to review without text.
# Every failure is recorded; nothing is silently skipped. The extracted text is a
# representative snippet for organization analysis, not a faithful render.

Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

# Read text nodes from one ZIP entry's XML, bounded by a byte cap. Truncation may
# cut a tag; we return whatever parsed before the break rather than throwing.
function Read-XmlEntryText {
    param($Entry, [int]$EntryByteCap)
    $stream = $Entry.Open()
    $ms = New-Object System.IO.MemoryStream
    try {
        $buf = New-Object byte[] 65536
        $total = 0
        while (($read = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
            $ms.Write($buf, 0, $read); $total += $read
            if ($total -ge $EntryByteCap) { break }
        }
        $ms.Position = 0
        $sb = New-Object System.Text.StringBuilder
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $reader = [System.Xml.XmlReader]::Create($ms, $settings)
        $interrupted = $false
        try {
            while ($reader.Read()) {
                if ($reader.NodeType -eq [System.Xml.XmlNodeType]::Text -or
                    $reader.NodeType -eq [System.Xml.XmlNodeType]::CDATA) {
                    [void]$sb.Append($reader.Value).Append(' ')
                }
            }
        } catch { $interrupted = $true } finally { $reader.Dispose() }
        return @{ text = $sb.ToString(); interrupted = $interrupted }
    } finally { $stream.Dispose(); $ms.Dispose() }
}

function Get-OfficeText {
    param([string]$ZipPath, [string[]]$Patterns, $Config, [int]$CharCap)
    $entryCap = [int]$Config.extraction.zip_entry_byte_cap
    $totalCap = [int]$Config.extraction.zip_total_byte_cap
    $zip = [System.IO.Compression.ZipFile]::OpenRead((Get-LongPath $ZipPath))
    try {
        $sb = New-Object System.Text.StringBuilder
        $consumed = 0; $truncated = $false
        $entries = @($zip.Entries | Where-Object {
            $name = $_.FullName
            @($Patterns | Where-Object { $name -like $_ }).Count -gt 0
        } | Sort-Object FullName)
        foreach ($e in $entries) {
            if ($consumed -ge $totalCap -or $sb.Length -ge $CharCap) { $truncated = $true; break }
            $consumed += [int]$e.Length
            $part = Read-XmlEntryText -Entry $e -EntryByteCap $entryCap
            [void]$sb.Append($part.text).Append(' ')
            if ($part.interrupted) { $truncated = $true }   # malformed/truncated XML — not a clean parse
        }
        $txt = ($sb.ToString() -replace '\s+', ' ').Trim()
        return @{ text = $txt; truncated = $truncated }
    } finally { $zip.Dispose() }
}

# Bounded, BOM-aware text read. Supports UTF-8 (with/without BOM) and UTF-16 LE/BE.
function Get-TextContent {
    param([string]$Path, [int]$Cap)
    $fs = [System.IO.File]::OpenRead((Get-LongPath $Path))
    try {
        $max = [Math]::Min($fs.Length, [long]($Cap * 4 + 4))
        $bytes = New-Object byte[] $max
        $n = $fs.Read($bytes, 0, $bytes.Length)
    } finally { $fs.Dispose() }

    $start = 0
    if     ($n -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $enc = [System.Text.Encoding]::UTF8; $start = 3 }
    elseif ($n -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { $enc = [System.Text.Encoding]::Unicode; $start = 2 }
    elseif ($n -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { $enc = [System.Text.Encoding]::BigEndianUnicode; $start = 2 }
    else   { $enc = New-Object System.Text.UTF8Encoding($false, $false) }  # no BOM: decode UTF-8, invalid -> U+FFFD

    $text = $enc.GetString($bytes, $start, $n - $start)
    if ($text.Length -gt $Cap) { $text = $text.Substring(0, $Cap) }
    # U+FFFD means bytes did not decode cleanly under the chosen encoding.
    return @{ text = $text; decoding_errors = $text.Contains([char]0xFFFD) }
}

function Get-PdfText {
    param([string]$Path, [string]$Extractor, [int]$Cap, [int]$MaxPages)
    $exe = Get-Command $Extractor -ErrorAction SilentlyContinue
    if (-not $exe) {
        return @{ ok = $false; text = $null; reason = "no PDF extractor '$Extractor' on PATH (install poppler or set config.pdf_extractor)" }
    }
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        $out = & $exe.Source -q -enc UTF-8 -l $MaxPages -- $Path $tmp 2>&1
        if ($LASTEXITCODE -ne 0) {
            return @{ ok = $false; text = $null; reason = "pdftotext exit $LASTEXITCODE`: $(($out | Select-Object -First 3) -join ' ')" }
        }
        $txt = if (Test-Path -LiteralPath $tmp) { Get-Content -LiteralPath $tmp -Raw -Encoding UTF8 } else { "" }
        if ([string]::IsNullOrWhiteSpace($txt)) { return @{ ok = $false; text = $null; reason = "extractor returned no text (scanned/image PDF?)" } }
        if ($txt.Length -gt $Cap) { $txt = $txt.Substring(0, $Cap) }
        return @{ ok = $true; text = $txt; reason = $null }
    } catch {
        return @{ ok = $false; text = $null; reason = "pdf extraction error: $($_.Exception.Message)" }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-Phase3Extract {
    param(
        [Parameter(Mandatory)] $Manifest,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)] $Config
    )

    Write-Phase "extraction" "Extracting bounded text from eligible files"
    $extDir = Join-Path $OutputPath "extracted"
    if (-not (Test-Path -LiteralPath $extDir)) { New-Item -ItemType Directory -Force -Path $extDir | Out-Null }
    $cap = [int]$Config.extraction.extract_char_cap
    $maxPages = [int]$Config.extraction.pdf_max_pages
    $log = @()
    $done = 0; $failed = 0

    foreach ($e in ($Manifest.files | Where-Object { $_.extract_text })) {
        $full = Join-Path $Source $e.rel_path
        $text = $null; $status = "ok"; $reason = $null; $trunc = $false; $decErr = $false
        try {
            switch ($e.type) {
                "text"  { $tc = Get-TextContent -Path $full -Cap $cap; $text = $tc.text; $decErr = $tc.decoding_errors }
                "code"  { $tc = Get-TextContent -Path $full -Cap $cap; $text = $tc.text; $decErr = $tc.decoding_errors }
                "word"  { $r = Get-OfficeText -ZipPath $full -Patterns @("word/document.xml") -Config $Config -CharCap $cap; $text = $r.text; $trunc = $r.truncated }
                "ppt"   { $r = Get-OfficeText -ZipPath $full -Patterns @("ppt/slides/slide*.xml","ppt/notesSlides/notesSlide*.xml") -Config $Config -CharCap $cap; $text = $r.text; $trunc = $r.truncated }
                "excel" { $r = Get-OfficeText -ZipPath $full -Patterns @("xl/sharedStrings.xml","xl/worksheets/sheet*.xml") -Config $Config -CharCap $cap; $text = $r.text; $trunc = $r.truncated }
                "pdf"   {
                    $reader = Get-AvailablePdfReader -Config $Config
                    if (-not $reader) {
                        $status = "failed"; $reason = "no PDF reader on PATH; install poppler's pdftotext to extract PDF text"
                    } else {
                        $pr = Get-PdfText -Path $full -Extractor $reader.path -Cap $cap -MaxPages $maxPages
                        if ($pr.ok) { $text = $pr.text } else { $status = "failed"; $reason = $pr.reason }
                    }
                }
                default { $status = "failed"; $reason = "unsupported type for extraction" }
            }
        } catch {
            $status = "failed"; $reason = $_.Exception.Message
        }

        if ($status -eq "ok") {
            if ([string]::IsNullOrWhiteSpace($text)) { $status = "failed"; $reason = "no text content found" }
            else {
                if ($text.Length -gt $cap) { $text = $text.Substring(0, $cap); $trunc = $true }
                # Undecodable bytes (U+FFFD) mean this snippet is NOT a faithful extraction.
                # Mark it truncated and record the flag so the host is warned, never handed
                # a corrupt read as if it were clean content.
                if ($decErr) {
                    $trunc = $true
                    $e.decoding_errors = $true
                    $reason = "decoding_errors: invalid byte sequences were replaced (U+FFFD)"
                    $e.notes += "decoding_errors during text extraction"
                }
                if ($trunc) { $status = "truncated" }
                $outFile = Join-Path $extDir ("{0}.txt" -f $e.id)
                [System.IO.File]::WriteAllText((Get-LongPath $outFile), $text, (New-Object System.Text.UTF8Encoding($false)))
                $e.extracted_file = "extracted/{0}.txt" -f $e.id
                $e.extracted_sha256 = Get-StringSha256 -Text $text
            }
        }

        $e.extraction_status = $status
        $e.extraction_reason = $reason
        if ($status -eq "failed") {
            $failed++
            $e.extract_text = $false
            # Extraction failure does not remove the file from semantic organization.
            # The host still receives metadata and must place it or route it to review.
            $e.submit_to_host = $true
            $e.notes += "extraction_failed: $reason"
        } else { $done++ }

        $log += [pscustomobject]@{ id = $e.id; rel_path = $e.rel_path; status = $status; reason = $reason; chars = ($(if ($text) { $text.Length } else { 0 })) }
    }

    Save-Json -Object @{ schema = 3; generated = (Get-Date).ToString("o"); entries = $log } -Path (Join-Path $OutputPath "extraction-log.json")
    Save-Json -Object $Manifest -Path (Join-Path $OutputPath "manifest.json")
    Write-Phase "extraction" "$done extracted, $failed failed (recorded in extraction-log.json)" "ok"
    return $Manifest
}
