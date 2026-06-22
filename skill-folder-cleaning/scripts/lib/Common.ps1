# Common.ps1 — shared helpers for the folder-organization pipeline.
# Dot-sourced by run-folder-cleaning.ps1. No source-folder side effects on load.

Set-StrictMode -Version Latest

$script:DOCUMENT_ROLES = @("core", "working", "reference", "outdated", "duplicate", "uncertain")
$script:PLAN_ACTIONS = @("keep", "rename", "move", "archive", "review")
$script:CLOUD_MASK = 0x1000 -bor 0x40000 -bor 0x400000
$script:FinalPathApiReady = $false

function Test-ObjectProperty {
    param($Object, [string]$Name)
    return ($null -ne $Object -and $Object.PSObject.Properties.Name -contains $Name)
}

function Get-ObjectProperty {
    param($Object, [string]$Name, $Default = $null)
    if (Test-ObjectProperty -Object $Object -Name $Name) { return $Object.$Name }
    return $Default
}

function Write-Phase {
    param([string]$Phase, [string]$Message, [string]$Level = "info")
    $ts = (Get-Date).ToString("HH:mm:ss")
    $tag = switch ($Level) {
        "warn" { "[!]" }
        "error" { "[x]" }
        "ok" { "[+]" }
        default { "[*]" }
    }
    Write-Host "$ts $tag $Phase`: $Message"
}

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

function Get-AvailablePdfReader {
    # Return the first configured PDF reader available on PATH, or $null. Readers are
    # expected to share the pdftotext command-line interface. Supports the legacy
    # single-value config.pdf_extractor for backward compatibility.
    param($Config)
    $candidates = @()
    if (Test-ObjectProperty -Object $Config -Name "pdf_extractors") { $candidates = @($Config.pdf_extractors) }
    elseif (Test-ObjectProperty -Object $Config -Name "pdf_extractor") { $candidates = @($Config.pdf_extractor) }
    foreach ($name in $candidates) {
        if ([string]::IsNullOrWhiteSpace("$name")) { continue }
        $command = Get-Command "$name" -ErrorAction SilentlyContinue
        if ($command) { return [pscustomobject]@{ name = "$name"; path = "$($command.Source)" } }
    }
    return $null
}

function Get-PdfReaderLabel {
    param($Config)
    if (Test-ObjectProperty -Object $Config -Name "pdf_extractors") { return (@($Config.pdf_extractors) -join ", ") }
    if (Test-ObjectProperty -Object $Config -Name "pdf_extractor") { return "$($Config.pdf_extractor)" }
    return "pdftotext"
}

function Request-FileHydration {
    # Force a cloud-only (OneDrive Files On-Demand) placeholder to download by opening
    # it for read and touching the first byte. Returns $true if the read succeeded.
    param([string]$Path)
    try {
        $stream = [System.IO.File]::Open((Get-LongPath $Path), [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $buffer = New-Object byte[] 1
            [void]$stream.Read($buffer, 0, 1)
        } finally { $stream.Dispose() }
        return $true
    } catch { return $false }
}

function Get-StringSha256 {
    param([AllowEmptyString()][string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace "-", "") }
    finally { $sha.Dispose() }
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
}

function Save-Json {
    param([Parameter(Mandatory)]$Object, [Parameter(Mandatory)][string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $json = $Object | ConvertTo-Json -Depth 64
    $tmp = "$Path.tmp"
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Get-LongPath $tmp), $json, $enc)
    $null = Get-Content -LiteralPath $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
    [System.IO.File]::Move((Get-LongPath $tmp), (Get-LongPath $Path), $true)
}

function Read-Json {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Initialize-FinalPathApi {
    if ($script:FinalPathApiReady) { return $true }
    try {
        Add-Type -ErrorAction Stop -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;
public static class FcPath {
  [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
  static extern SafeFileHandle CreateFileW(string n, uint a, uint s, IntPtr sa, uint c, uint f, IntPtr t);
  [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
  static extern uint GetFinalPathNameByHandleW(SafeFileHandle h, StringBuilder b, uint cch, uint flags);
  public static string Final(string path) {
    const uint BACKUP = 0x02000000, OPEN_EXISTING = 3, SHARE = 1|2|4;
    using (var h = CreateFileW(path, 0, SHARE, IntPtr.Zero, OPEN_EXISTING, BACKUP, IntPtr.Zero)) {
      if (h.IsInvalid) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      var sb = new StringBuilder(1024);
      uint r = GetFinalPathNameByHandleW(h, sb, (uint)sb.Capacity, 0);
      if (r == 0) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      if (r > sb.Capacity) {
        sb = new StringBuilder((int)r);
        GetFinalPathNameByHandleW(h, sb, (uint)sb.Capacity, 0);
      }
      return sb.ToString();
    }
  }
}
'@
        $script:FinalPathApiReady = $true
    } catch {
        $script:FinalPathApiReady = $false
    }
    return $script:FinalPathApiReady
}

function Get-RealPath {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    if (Initialize-FinalPathApi) {
        try {
            $final = [FcPath]::Final($full)
            if ($final.StartsWith("\\?\UNC\")) { return ("\\" + $final.Substring(8)).TrimEnd("\") }
            if ($final.StartsWith("\\?\")) { return $final.Substring(4).TrimEnd("\") }
            return $final.TrimEnd("\")
        } catch { }
    }
    try {
        $info = Get-Item -LiteralPath $full -Force -ErrorAction Stop
        $target = $info.ResolveLinkTarget($true)
        if ($target) { return $target.FullName.TrimEnd("\") }
    } catch { }
    return $full.TrimEnd("\")
}

function Test-ReparseInAncestry {
    param([string]$Path)
    $current = [System.IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            try {
                $attributes = (Get-Item -LiteralPath $current -Force -ErrorAction Stop).Attributes
                if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
            } catch { }
        }
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { break }
        $current = $parent
    }
    return $false
}

function Resolve-FinalPath {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd("\")
    if (Test-Path -LiteralPath $full) { return (Get-RealPath $full) }
    $parent = Split-Path -Parent $full
    $segments = @(Split-Path -Leaf $full)
    while ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $segments = ,(Split-Path -Leaf $parent) + $segments
        $parent = Split-Path -Parent $parent
    }
    if (-not $parent) { return $full }
    return (Join-Path (Get-RealPath $parent) ($segments -join "\")).TrimEnd("\")
}

function Resolve-Shortcut {
    param([string]$LnkPath)
    try {
        $shell = New-Object -ComObject WScript.Shell
        $target = $shell.CreateShortcut($LnkPath).TargetPath
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        if ([string]::IsNullOrWhiteSpace($target)) { return @{ target = $null; broken = $true } }
        return @{ target = $target; broken = -not (Test-Path -LiteralPath $target) }
    } catch {
        return @{ target = $null; broken = $true }
    }
}

function Read-State {
    param([string]$OutputPath)
    return (Read-Json -Path (Join-Path $OutputPath "state.json"))
}

function Save-State {
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)][string]$OutputPath)
    $State.updated = (Get-Date).ToString("o")
    Save-Json -Object $State -Path (Join-Path $OutputPath "state.json")
}

function Test-PhaseDone {
    param($State, [string]$Phase)
    return ($State -and $State.phases -and $State.phases.$Phase -eq "done")
}

function Set-PhaseState {
    param($State, [string]$Phase, [string]$Value, [string]$OutputPath)
    $State.phases.$Phase = $Value
    Save-State -State $State -OutputPath $OutputPath
}

function Set-PhaseDone {
    param($State, [string]$Phase, [string]$OutputPath)
    Set-PhaseState -State $State -Phase $Phase -Value "done" -OutputPath $OutputPath
}

function Get-CloudMaskHit {
    param([System.IO.FileSystemInfo]$Item)
    return ([int]$Item.Attributes -band $script:CLOUD_MASK)
}

function Test-CloudOnly {
    param([System.IO.FileSystemInfo]$Item)
    return ((Get-CloudMaskHit -Item $Item) -ne 0)
}

function Get-FileType {
    param([string]$Ext, $Config)
    $normalized = $Ext.ToLowerInvariant()
    foreach ($category in @("text", "code", "word", "excel", "ppt", "pdf", "image", "temp", "binary_skip")) {
        if ($Config.extensions.$category -contains $normalized) { return $category }
    }
    return "other"
}

function Test-TextExtractable {
    param([string]$Type)
    return @("text", "code", "word", "excel", "ppt", "pdf") -contains $Type
}

function Normalize-RelativePath {
    param(
        [AllowEmptyString()][string]$Path,
        [switch]$AllowRoot
    )
    $value = ([string]$Path).Trim().Replace("/", "\").Trim("\")
    if ($AllowRoot -and ([string]::IsNullOrWhiteSpace($value) -or $value -eq "ROOT")) { return "ROOT" }
    if ([string]::IsNullOrWhiteSpace($value)) { throw "Relative path cannot be empty." }
    if ([System.IO.Path]::IsPathRooted($value)) { throw "Expected a relative path, got '$Path'." }
    $segments = @($value -split "\\")
    if ($segments -contains ".." -or $segments -contains ".") { throw "Relative path cannot contain '.' or '..': '$Path'." }
    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment)) { throw "Relative path contains an empty segment: '$Path'." }
    }
    return ($segments -join "\")
}

function Get-RelativeParent {
    param([string]$RelativePath)
    $parent = Split-Path -Parent $RelativePath
    if ([string]::IsNullOrWhiteSpace($parent)) { return "ROOT" }
    return (Normalize-RelativePath -Path $parent)
}

function Get-RelativeLeaf {
    param([string]$RelativePath)
    return (Split-Path -Leaf $RelativePath)
}

function Join-OrganizationPath {
    param([string]$Folder, [string]$Name)
    $normalizedFolder = Normalize-RelativePath -Path $Folder -AllowRoot
    if ($normalizedFolder -eq "ROOT") { return $Name }
    return (Join-Path $normalizedFolder $Name)
}

function Get-PathDepth {
    param([string]$Folder)
    $normalized = Normalize-RelativePath -Path $Folder -AllowRoot
    if ($normalized -eq "ROOT") { return 0 }
    return @($normalized -split "\\").Count
}

function Get-StableInternalId {
    param([string]$Prefix, [string]$Key)
    $hash = Get-StringSha256 -Text $Key.ToLowerInvariant()
    return "$Prefix-$($hash.Substring(0, 12).ToLowerInvariant())"
}

function Get-ProtectedItemMap {
    param($Context)
    $map = @{}
    foreach ($item in @(Get-ObjectProperty -Object $Context -Name "protected_items" -Default @())) {
        $path = Normalize-RelativePath -Path "$($item.path)"
        $map[$path.ToLowerInvariant()] = $item
    }
    return $map
}

function Test-ContextFile {
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Config
    )

    $errors = @()
    $knownPaths = @{}
    foreach ($file in @($Manifest.files)) { $knownPaths["$($file.rel_path)".ToLowerInvariant()] = $true }

    if ([string]::IsNullOrWhiteSpace("$(Get-ObjectProperty $Context 'folder_type' '')")) {
        $errors += "folder_type is required"
    }
    if ([string]::IsNullOrWhiteSpace("$(Get-ObjectProperty $Context 'folder_objective' '')")) {
        $errors += "folder_objective is required"
    }
    if ((Get-ObjectProperty $Context "protected_items_confirmed" $false) -isnot [bool] -or
        -not [bool](Get-ObjectProperty $Context "protected_items_confirmed" $false)) {
        $errors += "protected_items_confirmed must be true after explicit user confirmation"
    }

    $protectedSeen = @{}
    foreach ($item in @(Get-ObjectProperty $Context "protected_items" @())) {
        try { $path = Normalize-RelativePath -Path "$($item.path)" }
        catch { $errors += "protected item path invalid: $($_.Exception.Message)"; continue }
        $key = $path.ToLowerInvariant()
        if (-not $knownPaths.ContainsKey($key)) { $errors += "protected item is not in manifest: $path" }
        if ($protectedSeen.ContainsKey($key)) { $errors += "duplicate protected item: $path" }
        $protectedSeen[$key] = $true
        if ((Get-ObjectProperty $item "protect_name" $null) -isnot [bool]) { $errors += "$path`: protect_name must be boolean" }
        if ((Get-ObjectProperty $item "protect_location" $null) -isnot [bool]) { $errors += "$path`: protect_location must be boolean" }
    }

    $prefix = "$(Get-ObjectProperty $Context 'files_prefix' '')"
    if (-not [string]::IsNullOrWhiteSpace($prefix) -and -not [bool](Get-ObjectProperty $Context "files_prefix_supplied_by_user" $false)) {
        $errors += "files_prefix may be set only when files_prefix_supplied_by_user=true"
    }

    $maxDepth = Get-ObjectProperty $Context "max_depth" $Config.organization.max_folder_depth
    try { $maxDepth = [int]$maxDepth } catch { $maxDepth = 0 }
    if ($maxDepth -lt 1 -or $maxDepth -gt 20) { $errors += "max_depth must be between 1 and 20" }

    return [pscustomobject]@{
        valid = ($errors.Count -eq 0)
        errors = $errors
        normalized_max_depth = $maxDepth
    }
}

function Set-DeterministicDisposition {
    param($Entry)

    $reason = $null
    if ($Entry.availability -eq "cloud_only") {
        $reason = "Cloud-only file; make it available locally before approval or apply."
    } elseif ($Entry.availability -eq "unreadable") {
        $reason = "File could not be read or hashed."
    } elseif ($Entry.availability -eq "unstable") {
        $reason = "File changed during inventory."
    } elseif ($Entry.availability -eq "broken_shortcut") {
        $reason = "Shortcut target is missing."
    } elseif ($Entry.kind -eq "shortcut") {
        $reason = "Existing shortcut is preserved as a file but is not analyzed or created automatically."
    } elseif ($Entry.is_temp) {
        $reason = "Temporary or backup filename; content has not established that it is obsolete."
    } elseif ($Entry.is_empty) {
        $reason = "Empty file may be intentional and requires review."
    }

    if (-not $reason) { return $false }
    $Entry.deterministic_disposition = [pscustomobject]@{
        content_summary = $reason
        document_role = "uncertain"
        proposed_name = Get-RelativeLeaf -RelativePath $Entry.rel_path
        target_folder = "to_review"
        action = "review"
        confidence = 10
        related_ids = @()
        evidence = $reason
    }
    return $true
}

function Test-WindowsName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "name is empty" }
    if ($Name -match '[<>:"/\\|?*]') { return "name contains Windows-invalid characters" }
    if ($Name.EndsWith(".") -or $Name.EndsWith(" ")) { return "name ends with a dot or space" }
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($Name).ToUpperInvariant()
    if ($stem -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') { return "name is reserved by Windows" }
    return $null
}
