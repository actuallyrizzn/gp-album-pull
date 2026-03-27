# SPDX-License-Identifier: AGPL-3.0-or-later
#
# gp_album_pull.ps1 — Download images from a link-shared Google Photos album.
#
# Copyright (C) 2026 gp-album-pull contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# See LICENSE for the full license text.
#
# --- Methodology (keep in sync with gp_album_pull.sh) ---
#
# 1. HTTP GET the public album URL (short goo.gl links redirect to photos.google.com/share/...).
# 2. Parse the HTML body. Google embeds album media in a script block that calls
#    AF_initDataCallback({ key: 'ds:1', ... }). Inside that JSON, each item includes a
#    base image URL under lh3.googleusercontent.com/pw/... followed by width and height.
# 3. Regex-extract lines matching:  https://lh3.googleusercontent.com/pw/...",W,H,
#    Deduplicate with Sort-Object -Unique (order may differ from on-screen order).
# 4. Request full resolution by appending =wWIDTH-hHEIGHT to the base URL (Google's
#    image CDN convention; same idea as common third-party helpers).
# 5. Save bytes, then rename by sniffing JPEG/PNG/WebP magic bytes (no Unix `file` on Windows).
#
# Limitations: Only media present in the initial HTML is retrieved. Albums that load
# additional items only via infinite scroll may be incomplete until the fetch strategy is updated.

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Public album URL (photos.app.goo.gl/... or photos.google.com/share/...)')]
    [string] $AlbumUrl,

    [Parameter(Position = 1, HelpMessage = 'Output directory')]
    [string] $OutDir = '.\gp_download'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Browser-like UA; override for testing or if Google blocks default curl/PS fingerprints.
$UserAgent = if ($env:GP_USER_AGENT) { $env:GP_USER_AGENT } else {
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
}

# Regex: base /pw/ URL, then ",width,height," as emitted in the embedded JSON.
$LinePattern = 'https://lh3\.googleusercontent\.com/pw/[^"]+",[0-9]+,[0-9]+,'
# Split URL and dimensions from one matched line.
$ParsePattern = '^(.+)",(\d+),(\d+),$'

function Get-ExtensionFromMagicBytes {
    <#
    .SYNOPSIS
    Return a file extension from the first bytes of a file (JPEG / PNG / WebP / unknown).
    #>
    param([Parameter(Mandatory)][string] $FilePath)

    $fs = [System.IO.File]::OpenRead((Resolve-Path -LiteralPath $FilePath))
    try {
        $buf = New-Object byte[] 16
        [void]$fs.Read($buf, 0, 16)
    }
    finally {
        $fs.Close()
    }

    # JPEG: FF D8 FF
    if ($buf[0] -eq 0xFF -and $buf[1] -eq 0xD8 -and $buf[2] -eq 0xFF) { return '.jpg' }
    # PNG: 89 50 4E 47 0D 0A 1A 0A
    if ($buf[0] -eq 0x89 -and $buf[1] -eq 0x50 -and $buf[2] -eq 0x4E -and $buf[3] -eq 0x47) { return '.png' }
    # WebP: RIFF....WEBP
    if ($buf[0] -eq 0x52 -and $buf[1] -eq 0x49 -and $buf[2] -eq 0x46 -and $buf[3] -eq 0x46) {
        if ($buf[8] -eq 0x57 -and $buf[9] -eq 0x45 -and $buf[10] -eq 0x42 -and $buf[11] -eq 0x50) { return '.webp' }
    }
    return '.bin'
}

$OutDirResolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutDir)
if (-not (Test-Path -LiteralPath $OutDirResolved)) {
    New-Item -ItemType Directory -Path $OutDirResolved -Force | Out-Null
}

$tmp = [System.IO.Path]::GetTempFileName()
try {
    Write-Host 'Fetching album page...'
    $headers = @{
        'User-Agent' = $UserAgent
        'Accept-Encoding' = 'gzip, deflate, br'
    }
    # -UseBasicParsing: avoids IE engine on Windows PowerShell 5.1; follows redirects by default.
    Invoke-WebRequest -Uri $AlbumUrl -Headers $headers -UseBasicParsing -OutFile $tmp
}
catch {
    Write-Error "Failed to fetch album page: $_"
    exit 1
}

try {
    $html = Get-Content -LiteralPath $tmp -Raw -Encoding UTF8
}
finally {
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}

# Collect and dedupe match strings (same as: grep -oE ... | sort -u).
$lines = @([regex]::Matches($html, $LinePattern) | ForEach-Object { $_.Value } | Sort-Object -Unique)

if (-not $lines -or $lines.Count -eq 0) {
    Write-Error 'No lh3 /pw/ photo URLs found. Google may have changed the page shape, or the album is not public. File an issue using the breakage template (see docs/AGENT_MAINTENANCE.md).'
    exit 1
}

Write-Host "Found $($lines.Count) image(s). Downloading..."
$i = 0
foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $line = $line.TrimEnd("`r")
    if ($line -notmatch $ParsePattern) {
        Write-Warning "skip malformed: $($line.Substring(0, [Math]::Min(80, $line.Length)))..."
        continue
    }
    $baseUrl = $Matches[1]
    $w = $Matches[2]
    $h = $Matches[3]
    $i++
    $fullUrl = "${baseUrl}=w${w}-h${h}"
    $outBase = Join-Path $OutDirResolved ('{0:D3}.img' -f $i)
    Write-Host "  [$i] ${w}x${h}"
    try {
        Invoke-WebRequest -Uri $fullUrl -Headers @{ 'User-Agent' = $UserAgent } -UseBasicParsing -OutFile $outBase
    }
    catch {
        Write-Error "Download failed for image ${i}: $_"
        exit 1
    }
    $ext = Get-ExtensionFromMagicBytes -FilePath $outBase
    $final = Join-Path $OutDirResolved ('{0:D3}{1}' -f $i, $ext)
    Move-Item -LiteralPath $outBase -Destination $final -Force
}

Write-Host "Done -> $OutDirResolved"
