[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ".",

    [Parameter(Mandatory = $false)]
    [string]$Label = "snapshot",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Snapshot", "Release")]
    [string]$Mode = "Snapshot",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeLibrary
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$safeLabel = ($Label.Trim() -replace '[<>:"/\\|?*]', '-') -replace '\s+', '_'
if ([string]::IsNullOrWhiteSpace($safeLabel)) {
    $safeLabel = "snapshot"
}

function Get-ProjectRelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )
    $prefix = $BasePath.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $TargetPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the project root: $TargetPath"
    }
    return $TargetPath.Substring($prefix.Length)
}

$verifyScript = Join-Path $PSScriptRoot "verify-project.ps1"
if (-not (Test-Path -LiteralPath $verifyScript)) {
    throw "Verification script not found: $verifyScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $verifyScript -ProjectRoot $root -Mode $Mode
$verificationExitCode = $LASTEXITCODE
if ($verificationExitCode -ne 0) {
    throw "$Mode checks found an integrity failure. No package was created. Review the latest report under outputs/logs/."
}
$latestVerificationReport = Get-ChildItem -LiteralPath (Join-Path $root "outputs\logs") -File -Filter "project-check-*.json" | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
$verificationPayload = if ($null -ne $latestVerificationReport) { Get-Content -LiteralPath $latestVerificationReport.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

$releaseDir = Join-Path $root "releases"
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$baseName = "${timestamp}_${safeLabel}_$($Mode.ToLowerInvariant())"
$zipPath = Join-Path $releaseDir "$baseName.zip"
$manifestPath = Join-Path $releaseDir "$baseName.manifest.json"
$hashPath = Join-Path $releaseDir "$baseName.sha256.txt"

if ((Test-Path -LiteralPath $zipPath) -or (Test-Path -LiteralPath $manifestPath) -or (Test-Path -LiteralPath $hashPath)) {
    throw "Target release files already exist: $baseName"
}

$excludedDirectoryPatterns = @(
    '^\.git/',
    '^releases/',
    '(^|/)\.venv/',
    '(^|/)venv/',
    '(^|/)node_modules/',
    '(^|/)__pycache__/',
    '(^|/)\.pytest_cache/',
    '(^|/)\.mypy_cache/',
    '(^|/)\.ruff_cache/',
    '(^|/)\.ipynb_checkpoints/',
    '(^|/)tmp/',
    '(^|/)\.miktex/',
    '(^|/)\$base/'
)
$secretFileRegex = '(^|/)(\.env($|\.)|credentials\.json$|secrets?\.|[^/]+\.(pem|key|p12|pfx)$)'
$includedFiles = [System.Collections.Generic.List[object]]::new()
$excludedFiles = [System.Collections.Generic.List[object]]::new()

$reparsePoints = @(Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
if ($reparsePoints.Count -gt 0) {
    $relativeReparsePoints = @($reparsePoints | ForEach-Object { Get-ProjectRelativePath $root $_.FullName })
    throw "Refusing to package filesystem reparse points or symbolic links: $($relativeReparsePoints -join ', ')"
}

foreach ($file in Get-ChildItem -LiteralPath $root -File -Recurse -Force) {
    $relative = (Get-ProjectRelativePath $root $file.FullName).Replace('\', '/')
    $reason = $null

    foreach ($pattern in $excludedDirectoryPatterns) {
        if ($relative -match $pattern) {
            $reason = "excluded-directory"
            break
        }
    }
    if ($null -eq $reason -and -not $IncludeLibrary) {
        if ($relative -match '^research/library/papers/' -and $relative -notmatch '/\.gitkeep$') {
            $reason = "excluded-library-fulltext"
        } elseif ($relative -match '^research/library/books/' -and $relative -notmatch '/(book-index\.csv|\.gitkeep)$') {
            $reason = "excluded-library-fulltext"
        }
    }
    if ($null -eq $reason -and $relative -match $secretFileRegex) {
        $reason = "possible-secret"
    }
    if ($null -eq $reason -and $relative -ieq "PACKAGE_MANIFEST.json") {
        $reason = "generated-manifest-replaced"
    }

    if ($null -ne $reason) {
        $excludedFiles.Add([pscustomobject]@{ path = $relative; reason = $reason }) | Out-Null
    } else {
        $includedFiles.Add([pscustomobject]@{
            path = $relative
            full_path = $file.FullName
            size = $file.Length
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }) | Out-Null
    }
}

$gitCommit = $null
$git = Get-Command git -ErrorAction SilentlyContinue
if ($null -ne $git -and (Test-Path -LiteralPath (Join-Path $root ".git"))) {
    $gitCommit = (& $git.Source -C $root rev-parse HEAD 2>$null | Select-Object -First 1)
}

$planStatusPath = Join-Path $root "model\PLAN_STATUS.txt"
$planStatus = if (Test-Path -LiteralPath $planStatusPath) {
    (Get-Content -LiteralPath $planStatusPath -Raw).Trim()
} else {
    "MISSING"
}
$preprocessingStatusPath = Join-Path $root "data\PREPROCESSING_STATUS.txt"
$preprocessingStatus = if (Test-Path -LiteralPath $preprocessingStatusPath) {
    (Get-Content -LiteralPath $preprocessingStatusPath -Raw).Trim()
} else { "MISSING" }

$manifest = [ordered]@{
    schema_version = 2
    created_at = (Get-Date).ToString("o")
    project = Split-Path -Leaf $root
    label = $Label
    mode = $Mode
    plan_status = $planStatus
    preprocessing_status = $preprocessingStatus
    git_commit = $gitCommit
    verification_exit_code = $verificationExitCode
    verification_report = if ($null -ne $latestVerificationReport) { Get-ProjectRelativePath $root $latestVerificationReport.FullName } else { $null }
    verification_fail_count = if ($null -ne $verificationPayload) { $verificationPayload.fail_count } else { $null }
    verification_warning_count = if ($null -ne $verificationPayload) { $verificationPayload.warning_count } else { $null }
    verification_warnings = if ($null -ne $verificationPayload) { @($verificationPayload.checks | Where-Object { $_.status -eq "WARN" }) } else { @() }
    includes_library_fulltext = [bool]$IncludeLibrary
    included_file_count = $includedFiles.Count
    included_bytes = ($includedFiles | Measure-Object -Property size -Sum).Sum
    included_files = @($includedFiles | ForEach-Object { [ordered]@{ path = $_.path; size = $_.size; sha256 = $_.sha256 } })
    excluded_files = @($excludedFiles)
    continuation_prompt = "Use `$math-modeling-competition. Read HANDOFF.md, PROJECT_STATUS.md, task requirements, frozen preprocessing/model plans, artifact manifest, verification report and paper outline; identify G0-G6 status, reproduce the current result, then continue from the active gate."
}
$manifestJson = $manifest | ConvertTo-Json -Depth 8

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [IO.File]::Open($zipPath, [IO.FileMode]::CreateNew)
try {
    $archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        foreach ($item in $includedFiles) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $item.full_path,
                $item.path,
                [IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
        $manifestEntry = $archive.CreateEntry("PACKAGE_MANIFEST.json", [IO.Compression.CompressionLevel]::Optimal)
        $writer = [IO.StreamWriter]::new($manifestEntry.Open(), [Text.UTF8Encoding]::new($false))
        try {
            $writer.Write($manifestJson)
        } finally {
            $writer.Dispose()
        }
    } finally {
        $archive.Dispose()
    }
} finally {
    $stream.Dispose()
}

$readStream = [IO.File]::OpenRead($zipPath)
try {
    $readArchive = [IO.Compression.ZipArchive]::new($readStream, [IO.Compression.ZipArchiveMode]::Read, $false)
    try {
        $entryNames = @($readArchive.Entries | ForEach-Object { $_.FullName })
        $duplicateNames = @($entryNames | Group-Object { $_.ToLowerInvariant() } | Where-Object { $_.Count -gt 1 })
        if ($duplicateNames.Count -gt 0) {
            throw "ZIP contains duplicate entry names: $($duplicateNames.Name -join ', ')"
        }
        $expectedNames = @($includedFiles | ForEach-Object { $_.path }) + @("PACKAGE_MANIFEST.json")
        $entryDifference = @(Compare-Object ($expectedNames | Sort-Object) ($entryNames | Sort-Object))
        if ($entryDifference.Count -gt 0) {
            throw "ZIP entries do not match the generated manifest file set"
        }
        foreach ($item in $includedFiles) {
            $entry = $readArchive.GetEntry($item.path)
            $entryStream = $entry.Open()
            try {
                $sha = [Security.Cryptography.SHA256]::Create()
                try { $entryHashBytes = $sha.ComputeHash($entryStream) } finally { $sha.Dispose() }
            } finally { $entryStream.Dispose() }
            $entryHash = [BitConverter]::ToString($entryHashBytes).Replace('-', '').ToLowerInvariant()
            if ($entry.Length -ne $item.size -or $entryHash -ne $item.sha256) {
                throw "ZIP entry size or SHA-256 mismatch: $($item.path)"
            }
        }
    } finally {
        $readArchive.Dispose()
    }
} finally {
    $readStream.Dispose()
}

$postflightRoot = Join-Path ([IO.Path]::GetTempPath()) ("math-model-postflight-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $postflightRoot | Out-Null
try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $postflightRoot
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $postflightRoot ".agents\skills\math-modeling-competition\scripts\verify-project.ps1") -ProjectRoot $postflightRoot -Mode $Mode
    if ($LASTEXITCODE -ne 0) { throw "Unpacked package failed $Mode verification" }
} finally {
    $resolvedPostflightRoot = (Resolve-Path -LiteralPath $postflightRoot).Path
    $tempPrefix = ([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedPostflightRoot.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to remove postflight directory outside system temp" }
    Remove-Item -LiteralPath $resolvedPostflightRoot -Recurse -Force
}

[IO.File]::WriteAllText($manifestPath, $manifestJson, [Text.UTF8Encoding]::new($false))
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText($hashPath, "$hash  $([IO.Path]::GetFileName($zipPath))`r`n", [Text.UTF8Encoding]::new($false))

$result = [ordered]@{
    zip = $zipPath
    manifest = $manifestPath
    sha256 = $hashPath
    included_files = $includedFiles.Count
    excluded_files = $excludedFiles.Count
    library_fulltext_included = [bool]$IncludeLibrary
    verification_exit_code = $verificationExitCode
}
$result | ConvertTo-Json -Depth 4 | Write-Output
