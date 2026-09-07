[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ".",

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$Id,

    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $true)]
    [ValidateSet("OPEN_ACCESS", "AUTHOR_PUBLIC_COPY", "TEAM_AUTHORIZED")]
    [string]$AccessBasis,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LicenseNote,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedSha256,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 500)]
    [int]$MaxSizeMB = 100
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$papersDir = Join-Path $root "research\library\papers"
$logPath = Join-Path $root "research\library\download-log.csv"
New-Item -ItemType Directory -Force -Path $papersDir | Out-Null

$uri = $null
if (-not [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne "https" -or [string]::IsNullOrWhiteSpace($uri.Host)) {
    throw "Only absolute HTTPS URLs with a host are allowed"
}

$destination = Join-Path $papersDir ($Id + ".pdf")
$destinationFull = [IO.Path]::GetFullPath($destination)
$papersPrefix = [IO.Path]::GetFullPath($papersDir).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $destinationFull.StartsWith($papersPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Resolved destination is outside research/library/papers"
}
if (Test-Path -LiteralPath $destinationFull) {
    throw "Destination already exists; use a new literature ID or review the existing file: $destinationFull"
}

$temporary = Join-Path $papersDir ("." + $Id + ".download.tmp")
$status = "DOWNLOAD_FAILED"
$detail = "Download did not complete"
$sizeBytes = 0
$sha256 = ""

try {
    if (Test-Path -LiteralPath $temporary) {
        throw "Temporary download path already exists: $temporary"
    }

    Invoke-WebRequest -Uri $uri.AbsoluteUri -OutFile $temporary -UseBasicParsing -Headers @{ "User-Agent" = "MathModelingResearch/1.0" }
    $downloaded = Get-Item -LiteralPath $temporary
    $sizeBytes = $downloaded.Length
    if ($sizeBytes -lt 512) {
        throw "Downloaded file is too small to be a valid paper PDF"
    }
    if ($sizeBytes -gt ($MaxSizeMB * 1MB)) {
        throw "Downloaded file exceeds MaxSizeMB"
    }

    $stream = [IO.File]::OpenRead($temporary)
    try {
        $signatureBytes = New-Object byte[] 5
        $readCount = $stream.Read($signatureBytes, 0, 5)
    } finally {
        $stream.Dispose()
    }
    $signature = [Text.Encoding]::ASCII.GetString($signatureBytes, 0, $readCount)
    if ($signature -ne "%PDF-") {
        throw "Downloaded content does not have a PDF signature"
    }

    $sha256 = (Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant()
    if (-not [string]::IsNullOrWhiteSpace($ExpectedSha256) -and $sha256 -ne $ExpectedSha256.ToLowerInvariant()) {
        throw "Downloaded SHA-256 does not match ExpectedSha256"
    }

    Move-Item -LiteralPath $temporary -Destination $destinationFull
    $status = "DOWNLOADED"
    $detail = "PDF signature and SHA-256 verified"
} catch {
    $detail = $_.Exception.Message
    throw
} finally {
    if (Test-Path -LiteralPath $temporary) {
        $resolvedTemporary = (Resolve-Path -LiteralPath $temporary).Path
        if (-not $resolvedTemporary.StartsWith($papersPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove a temporary file outside research/library/papers"
        }
        Remove-Item -LiteralPath $resolvedTemporary -Force
    }

    $relativePath = if ($status -eq "DOWNLOADED") { "research/library/papers/$Id.pdf" } else { "" }
    $row = [pscustomobject]@{
        downloaded_at = (Get-Date).ToString("o")
        id = $Id
        url = $uri.AbsoluteUri
        access_basis = $AccessBasis
        license_or_access_note = $LicenseNote
        local_path = $relativePath
        size_bytes = $sizeBytes
        sha256 = $sha256
        status = $status
        detail = $detail
    }
    if (-not (Test-Path -LiteralPath $logPath)) {
        $row | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8
    } else {
        $row | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8 -Append
    }
}

[ordered]@{
    id = $Id
    url = $uri.AbsoluteUri
    local_path = "research/library/papers/$Id.pdf"
    size_bytes = $sizeBytes
    sha256 = $sha256
    access_basis = $AccessBasis
    status = $status
} | ConvertTo-Json -Depth 3 | Write-Output
