[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ".",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Snapshot", "Release")]
    [string]$Mode = "Snapshot",

    [Parameter(Mandatory = $false)]
    [switch]$SkipSelfTests
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$rootPrefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$results = [System.Collections.Generic.List[object]]::new()

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

function Add-Check {
    param(
        [string]$Name,
        [ValidateSet("PASS", "WARN", "FAIL")]
        [string]$Status,
        [string]$Detail
    )
    $results.Add([pscustomobject]@{
        name = $Name
        status = $Status
        detail = $Detail
    }) | Out-Null
}

function Add-ReadinessCheck {
    param([string]$Name, [bool]$Ok, [string]$Detail)
    if ($Ok) { Add-Check $Name "PASS" $Detail }
    elseif ($Mode -eq "Release") { Add-Check $Name "FAIL" $Detail }
    else { Add-Check $Name "WARN" $Detail }
}

function Test-PlaceholderValue {
    param([object]$Value)
    if ($null -eq $Value) { return $true }
    $valueText = ([string]$Value).Trim()
    return [string]::IsNullOrWhiteSpace($valueText) -or $valueText -match '^(\u5F85\u586B\u5199|\u5C1A\u672A\u586B\u5199|\u5C1A\u672A\u5F00\u59CB|\u5C1A\u672A\u68C0\u9A8C|TODO|TBD|PLACEHOLDER|PLACE_[A-Z0-9_]+_HERE)[.!\u3002\uFF01]?$'
}

function Split-IdentifierList {
    param([object]$Value)
    if ($null -eq $Value) { return @() }
    return @(([string]$Value).Split(';') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

function Get-NormalizedFileSha256 {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $text = $text.TrimStart([char]0xFEFF) -replace "`r`n", "`n" -replace "`r", "`n"
    $contractMatch = [regex]::Match($text, '(?s)<!--\s*G2-CONTRACT-BEGIN\s*-->(.*?)<!--\s*G2-CONTRACT-END\s*-->')
    if ($contractMatch.Success) { $text = $contractMatch.Groups[1].Value }
    $normalizedLines = @(($text -split "`n", -1) | ForEach-Object { $_.TrimEnd() })
    while ($normalizedLines.Count -gt 0 -and $normalizedLines[-1] -eq "") {
        if ($normalizedLines.Count -eq 1) { $normalizedLines = @() }
        else { $normalizedLines = @($normalizedLines[0..($normalizedLines.Count - 2)]) }
    }
    $normalized = ($normalizedLines -join "`n") + "`n"
    $bytes = [Text.Encoding]::UTF8.GetBytes($normalized)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-StringSha256 {
    param([string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-ReadinessMetadataValue {
    param([string]$Text, [string]$Label)
    $match = [regex]::Match($Text, "(?mi)^-\s*" + [regex]::Escape($Label) + "\s*[:\uFF1A]\s*(.+?)\s*$")
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return $null
}

function Add-G2ReadinessCheck {
    param([string]$Name, [bool]$Ok, [string]$Detail, [bool]$Strict)
    if ($Ok) { Add-Check $Name "PASS" $Detail }
    elseif ($Strict) { Add-Check $Name "FAIL" $Detail }
    else { Add-Check $Name "WARN" $Detail }
}

$requiredPaths = @(
    "AGENTS.md",
    "START-HERE.md",
    "WORKFLOW-GUIDE.md",
    "PROJECT_STATUS.md",
    "HANDOFF.md",
    ".codex\config.toml",
    ".codex\agents",
    ".agents\skills\math-modeling-competition\SKILL.md",
    ".agents\skills\math-modeling-competition\scripts\verify-project.ps1",
    ".agents\skills\math-modeling-competition\scripts\package-project.ps1",
    "problem",
    "data\raw",
    "research",
    "research\algorithm-briefs",
    "research\library\papers",
    "research\library\books",
    "research\library\library-index.csv",
    "research\library\download-log.csv",
    "model",
    "src",
    "tests",
    "experiments",
    "outputs",
    "outputs\tables\raw",
    "outputs\tables\final",
    "outputs\figures\drafts",
    "outputs\figures\final",
    "reports",
    "writing",
    "coordination",
    "coordination\dispatches",
    "coordination\receipts"
)

$phasePaths = @(
    "competition\competition-profile.md",
    "problem\task-requirements.csv",
    "data\data-inventory.csv",
    "data\raw-hashes.csv",
    "data\preprocessing-plan.md",
    "data\PREPROCESSING_STATUS.txt",
    "research\evidence-matrix.csv",
    "research\literature-review.md",
    "research\citation-brief.md",
    "model\algorithm-evidence-request.csv",
    "research\algorithm-evidence-coverage.csv",
    "research\search-log.csv",
    "research\library\books\book-index.csv",
    "model\model-plan.md",
    "model\PLAN_STATUS.txt",
    "model\protected-invariants.md",
    "model\implementation-defaults.md",
    "model\implementation-readiness.md",
    "model\readiness\implementer-review.md",
    "model\readiness\verifier-review.md",
    "model\g2-approval.json",
    "model\decision-register.csv",
    "model\complexity-budget.csv",
    "outputs\result-summary.json",
    "outputs\artifact-manifest.csv",
    "reports\verification-report.md",
    "reports\claim-audit.csv",
    "reports\late-stage-ai-self-check.csv",
    "writing\paper-outline.md",
    "writing\claim-evidence-matrix.csv",
    "coordination\README.md",
    "coordination\CONTROL-BOARD.md",
    "coordination\thread-registry.csv",
    "coordination\dispatch-log.csv",
    "coordination\path-ownership.csv",
    "coordination\sync-ledger.csv",
    "coordination\user-authority-log.csv",
    "coordination\role-thread-prompts.md",
    "coordination\dispatches\dispatch-template.md",
    "coordination\receipts\receipt-template.md",
    ".agents\skills\math-modeling-competition\references\thread-coordination-v1.md"
)

foreach ($relative in $requiredPaths) {
    $target = Join-Path $root $relative
    if (Test-Path -LiteralPath $target) {
        Add-Check "required:$relative" "PASS" "Path exists"
    } else {
        Add-Check "required:$relative" "FAIL" "Required path is missing"
    }
}

foreach ($relative in $phasePaths) {
    $target = Join-Path $root $relative
    Add-ReadinessCheck "stage-file:$relative" (Test-Path -LiteralPath $target) "Stage deliverable must exist"
}

$expectedAgents = [ordered]@{
    "literature-researcher.toml" = "literature_researcher"
    "model-architect.toml" = "model_architect"
    "model-implementer.toml" = "model_implementer"
    "model-verifier.toml" = "model_verifier"
    "paper-outline-writer.toml" = "paper_outline_writer"
    "release-packager.toml" = "release_packager"
}
$agentDir = Join-Path $root ".codex\agents"
$actualAgentFiles = if (Test-Path -LiteralPath $agentDir) { @(Get-ChildItem -LiteralPath $agentDir -File -Filter "*.toml") } else { @() }
$actualAgentNames = @($actualAgentFiles | ForEach-Object { $_.Name })
$agentSetOk = (@(Compare-Object @($expectedAgents.Keys) $actualAgentNames).Count -eq 0)
Add-ReadinessCheck "agent-allowlist" $agentSetOk ("Expected exactly: " + ($expectedAgents.Keys -join ", "))
foreach ($entry in $expectedAgents.GetEnumerator()) {
    $agentPath = Join-Path $agentDir $entry.Key
    $ok = $false
    if (Test-Path -LiteralPath $agentPath) {
        $agentText = Get-Content -LiteralPath $agentPath -Raw -Encoding UTF8
        $ok = $agentText -match ('(?m)^name\s*=\s*"' + [regex]::Escape($entry.Value) + '"\s*$') -and
              $agentText -match '(?m)^description\s*=\s*".+"\s*$' -and
              $agentText -match '(?m)^model\s*=\s*".+"\s*$' -and
              $agentText -match '(?m)^developer_instructions\s*=\s*"""[\s\S]+"""\s*$'
    }
    Add-ReadinessCheck "agent:$($entry.Value)" $ok "Exact internal name and a nonempty contract are required"
}

# Persistent role task coordination checks. Empty UNREGISTERED rows are valid for a reusable
# Snapshot template, but an active or release topology must fail closed on identity, hashes,
# dispatch ownership and receipt binding.
$coordinationRequiredHeaders = [ordered]@{
    "coordination\thread-registry.csv" = @("protocol_version", "role", "task_title", "thread_id", "host_id", "generation", "environment", "status", "current_dispatch_id", "last_receipt_id", "role_contract_path", "role_contract_sha256", "registered_at", "last_seen_at", "replacement_for", "notes")
    "coordination\dispatch-log.csv" = @("protocol_version", "dispatch_id", "gate", "subgate", "mode", "from_role", "to_role", "role_generation", "thread_id", "status", "request_file", "request_sha256", "input_bundle_sha256", "exclusive_scope_id", "allowed_write_scope", "expected_output_paths", "depends_on_dispatch_ids", "user_authorization_id", "created_at", "acknowledged_at", "completed_at", "receipt_file", "blocker_code", "supersedes_dispatch_id")
    "coordination\path-ownership.csv" = @("scope_id", "path_pattern", "owner_role", "merge_role", "concurrent_policy", "notes")
    "coordination\sync-ledger.csv" = @("protocol_version", "sync_id", "receipt_id", "receipt_sha256", "dispatch_id", "role", "decision", "decision_reason", "applied_shared_files", "applied_shared_hashes", "decided_by_thread_id", "decided_at")
    "coordination\user-authority-log.csv" = @("protocol_version", "authorization_id", "authorization_type", "status", "user_request_quote", "mode", "label", "bound_bundle_sha256", "bound_dispatch_id", "max_uses", "used_count", "created_at", "consumed_at", "notes")
}
$coordinationSchemaOk = $true
foreach ($entry in $coordinationRequiredHeaders.GetEnumerator()) {
    $coordinationPath = Join-Path $root $entry.Key
    if (-not (Test-Path -LiteralPath $coordinationPath -PathType Leaf)) {
        $coordinationSchemaOk = $false
        continue
    }
    $firstLine = Get-Content -LiteralPath $coordinationPath -Encoding UTF8 -TotalCount 1
    $actualHeaders = @(([string]$firstLine).Split(",") | ForEach-Object { $_.Trim() })
    if (@(Compare-Object $entry.Value $actualHeaders).Count -ne 0) { $coordinationSchemaOk = $false }
}
Add-Check "coordination-files-and-schema" $(if ($coordinationSchemaOk) { "PASS" } else { "FAIL" }) "Coordination CSV files must use the exact THREAD-PROTOCOL-v1 schemas"

$expectedRoles = @("coordinator", "literature_researcher", "model_architect", "model_implementer", "model_verifier", "paper_outline_writer", "release_packager")
$registryRows = @()
$registryStructureOk = $false
$activeRows = @()
try {
    $registryRows = @(Import-Csv -LiteralPath (Join-Path $root "coordination\thread-registry.csv") -Encoding UTF8)
    $registryRoles = @($registryRows | ForEach-Object { $_.role })
    $registryStructureOk = $registryRows.Count -eq 7 -and
        @($registryRoles | Sort-Object -Unique).Count -eq 7 -and
        @(Compare-Object ($expectedRoles | Sort-Object) ($registryRoles | Sort-Object)).Count -eq 0
    foreach ($row in $registryRows) {
        $parsedGeneration = 0
        if ($row.protocol_version -ne "THREAD-PROTOCOL-v1" -or
            $row.environment -ne "LOCAL_SHARED_PROJECT" -or
            $row.status -notin @("UNREGISTERED", "ACTIVE", "PAUSED", "RETIRED", "LOST") -or
            -not [int]::TryParse([string]$row.generation, [ref]$parsedGeneration) -or
            $parsedGeneration -lt 0) {
            $registryStructureOk = $false
        }
    }
    $activeRows = @($registryRows | Where-Object { $_.status -eq "ACTIVE" })
} catch {
    $registryStructureOk = $false
}
Add-Check "thread-registry-roles" $(if ($registryStructureOk) { "PASS" } else { "FAIL" }) "Registry must contain exactly one valid row for coordinator and all six professional roles"

$activeTopologyOk = $registryStructureOk -and $activeRows.Count -eq 7
$activeIdentityOk = $activeTopologyOk
if ($activeRows.Count -gt 0) {
    if (@($activeRows | Group-Object role | Where-Object { $_.Count -ne 1 }).Count -gt 0 -or
        @($activeRows | Group-Object thread_id | Where-Object { $_.Count -ne 1 }).Count -gt 0) {
        $activeIdentityOk = $false
    }
    foreach ($row in $activeRows) {
        if ((Test-PlaceholderValue $row.task_title) -or (Test-PlaceholderValue $row.thread_id) -or
            (Test-PlaceholderValue $row.host_id) -or $row.role_contract_sha256 -notmatch '^[0-9a-fA-F]{64}$') {
            $activeIdentityOk = $false
            continue
        }
        $contractFullPath = [IO.Path]::GetFullPath((Join-Path $root ([string]$row.role_contract_path)))
        if (-not $contractFullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $contractFullPath -PathType Leaf)) {
            $activeIdentityOk = $false
            continue
        }
        $actualContractHash = (Get-FileHash -LiteralPath $contractFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualContractHash -ne ([string]$row.role_contract_sha256).ToLowerInvariant()) { $activeIdentityOk = $false }
    }
}
if ($activeRows.Count -gt 0 -and -not $activeIdentityOk) {
    Add-Check "thread-registry-uniqueness" "FAIL" "Any active topology must have seven unique, non-placeholder task identities with current role contract hashes"
} elseif ($activeTopologyOk -and $activeIdentityOk) {
    Add-Check "thread-registry-uniqueness" "PASS" "All seven persistent role tasks are active and uniquely bound"
} elseif ($Mode -eq "Release") {
    Add-Check "thread-registry-uniqueness" "FAIL" "Release requires all seven persistent role tasks to be active and valid"
} else {
    Add-Check "thread-registry-uniqueness" "WARN" "Reusable Snapshot template has no active task bindings; initialize the seven tasks at contest start"
}

$ownershipRows = @()
$scopeIds = @()
$ownershipOk = $true
try {
    $ownershipRows = @(Import-Csv -LiteralPath (Join-Path $root "coordination\path-ownership.csv") -Encoding UTF8)
    $scopeIds = @($ownershipRows | ForEach-Object { $_.scope_id })
    if ($ownershipRows.Count -eq 0 -or @($scopeIds | Sort-Object -Unique).Count -ne $scopeIds.Count) { $ownershipOk = $false }
    $pathTokens = [System.Collections.Generic.List[string]]::new()
    foreach ($row in $ownershipRows) {
        if ($row.owner_role -notin $expectedRoles -or $row.merge_role -ne "coordinator" -or
            $row.concurrent_policy -ne "EXCLUSIVE" -or (Test-PlaceholderValue $row.path_pattern)) { $ownershipOk = $false }
        foreach ($token in @(([string]$row.path_pattern).Split(";") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })) {
            if ($token -in @("tests/**", "experiments/**") -or $pathTokens.Contains($token)) { $ownershipOk = $false }
            $pathTokens.Add($token)
        }
    }
} catch { $ownershipOk = $false }
Add-Check "coordination-path-ownership" $(if ($ownershipOk) { "PASS" } else { "FAIL" }) "Ownership scopes must be unique, coordinator-merged and must not use broad tests/** or experiments/** overlaps"

$authorityRows = @()
$authorityOk = $true
try {
    $authorityRows = @(Import-Csv -LiteralPath (Join-Path $root "coordination\user-authority-log.csv") -Encoding UTF8)
    $authorityIds = @($authorityRows | ForEach-Object { $_.authorization_id })
    if (@($authorityIds | Sort-Object -Unique).Count -ne $authorityIds.Count) { $authorityOk = $false }
    foreach ($row in $authorityRows) {
        $maxUses = 0
        $usedCount = 0
        if ($row.protocol_version -ne "THREAD-PROTOCOL-v1" -or $row.authorization_type -ne "G6_PACKAGE" -or
            $row.status -notin @("ISSUED", "CONSUMED", "CANCELLED") -or
            -not [int]::TryParse([string]$row.max_uses, [ref]$maxUses) -or
            -not [int]::TryParse([string]$row.used_count, [ref]$usedCount) -or
            $maxUses -ne 1 -or $usedCount -lt 0 -or $usedCount -gt 1 -or
            $row.bound_bundle_sha256 -notmatch '^[0-9a-fA-F]{64}$' -or
            (Test-PlaceholderValue $row.user_request_quote)) { $authorityOk = $false }
        if ($row.status -eq "ISSUED" -and $usedCount -ne 0) { $authorityOk = $false }
        if ($row.status -eq "CONSUMED" -and $usedCount -ne 1) { $authorityOk = $false }
    }
} catch { $authorityOk = $false }
Add-Check "user-authority-ledger" $(if ($authorityOk) { "PASS" } else { "FAIL" }) "G6 authorizations must be current, single-use and bound to one exact package request"

$dispatchRows = @()
$dispatchOk = $true
$dispatchScopeOk = $true
$receiptBindingOk = $true
try {
    $dispatchRows = @(Import-Csv -LiteralPath (Join-Path $root "coordination\dispatch-log.csv") -Encoding UTF8)
    $dispatchIds = @($dispatchRows | ForEach-Object { $_.dispatch_id })
    if (@($dispatchIds | Sort-Object -Unique).Count -ne $dispatchIds.Count) { $dispatchOk = $false }
    $openDispatches = @($dispatchRows | Where-Object { $_.status -in @("QUEUED", "ACKNOWLEDGED", "IN_PROGRESS") })
    if (@($openDispatches | Group-Object to_role | Where-Object { $_.Count -gt 1 }).Count -gt 0 -or
        @($openDispatches | Group-Object exclusive_scope_id | Where-Object { $_.Count -gt 1 }).Count -gt 0) { $dispatchScopeOk = $false }
    foreach ($row in $dispatchRows) {
        if ($row.protocol_version -ne "THREAD-PROTOCOL-v1" -or $row.from_role -ne "coordinator" -or
            $row.to_role -eq "coordinator" -or $row.to_role -notin $expectedRoles -or
            $row.status -notin @("QUEUED", "ACKNOWLEDGED", "IN_PROGRESS", "SUBMITTED", "BLOCKED", "COMPLETE", "SUPERSEDED", "CANCELLED") -or
            $row.input_bundle_sha256 -notmatch '^[0-9a-fA-F]{64}$' -or
            $row.request_sha256 -notmatch '^[0-9a-fA-F]{64}$' -or
            $scopeIds -notcontains $row.exclusive_scope_id) { $dispatchOk = $false; continue }
        $scopeOwner = @($ownershipRows | Where-Object { $_.scope_id -eq $row.exclusive_scope_id })
        if ($scopeOwner.Count -ne 1 -or $scopeOwner[0].owner_role -ne $row.to_role) { $dispatchScopeOk = $false }
        $registeredTarget = @($activeRows | Where-Object { $_.role -eq $row.to_role -and $_.thread_id -eq $row.thread_id -and [string]$_.generation -eq [string]$row.role_generation })
        if ($registeredTarget.Count -ne 1) { $dispatchOk = $false }
        if ($row.to_role -eq "release_packager") {
            $matchingAuthority = @($authorityRows | Where-Object {
                $_.authorization_id -eq $row.user_authorization_id -and
                $_.status -eq "ISSUED" -and $_.used_count -eq "0" -and
                $_.bound_dispatch_id -eq $row.dispatch_id -and
                $_.bound_bundle_sha256 -eq $row.input_bundle_sha256 -and
                $_.mode -eq $row.mode
            })
            if ($matchingAuthority.Count -ne 1) { $dispatchOk = $false }
        } elseif ($row.user_authorization_id -ne "NONE") {
            $dispatchOk = $false
        }
        $requestFullPath = [IO.Path]::GetFullPath((Join-Path $root ([string]$row.request_file)))
        if (-not $requestFullPath.StartsWith((Join-Path $root "coordination\dispatches"), [StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $requestFullPath -PathType Leaf)) { $dispatchOk = $false; continue }
        $actualRequestHash = (Get-FileHash -LiteralPath $requestFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualRequestHash -ne ([string]$row.request_sha256).ToLowerInvariant()) { $dispatchOk = $false }
        if ($row.status -in @("SUBMITTED", "BLOCKED", "COMPLETE")) {
            if (Test-PlaceholderValue $row.receipt_file) { $receiptBindingOk = $false; continue }
            $receiptFullPath = [IO.Path]::GetFullPath((Join-Path $root ([string]$row.receipt_file)))
            if (-not $receiptFullPath.StartsWith((Join-Path $root "coordination\receipts"), [StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath $receiptFullPath -PathType Leaf)) { $receiptBindingOk = $false; continue }
            $receiptText = Get-Content -LiteralPath $receiptFullPath -Raw -Encoding UTF8
            if ((Get-ReadinessMetadataValue $receiptText "dispatch_id") -ne $row.dispatch_id -or
                (Get-ReadinessMetadataValue $receiptText "request_sha256") -ne $row.request_sha256 -or
                (Get-ReadinessMetadataValue $receiptText "role") -ne $row.to_role -or
                (Get-ReadinessMetadataValue $receiptText "thread_id") -ne $row.thread_id -or
                (Get-ReadinessMetadataValue $receiptText "input_bundle_sha256") -ne $row.input_bundle_sha256) { $receiptBindingOk = $false }
        }
    }
} catch { $dispatchOk = $false; $dispatchScopeOk = $false; $receiptBindingOk = $false }
if ($dispatchRows.Count -eq 0) {
    Add-Check "dispatch-integrity" $(if ($Mode -eq "Release") { "FAIL" } else { "WARN" }) "No formal dispatch has been recorded"
} else {
    Add-Check "dispatch-integrity" $(if ($dispatchOk) { "PASS" } else { "FAIL" }) "Dispatches must bind active task identities, immutable request hashes and valid protocol states"
}
Add-Check "dispatch-exclusive-scope" $(if ($dispatchScopeOk) { "PASS" } else { "FAIL" }) "Open dispatches must have one order per role and non-overlapping owner scopes"
Add-Check "receipt-and-sync-binding" $(if ($receiptBindingOk) { "PASS" } else { "FAIL" }) "Submitted, blocked and complete dispatches must have matching receipts"

$syncOk = $true
try {
    $syncRows = @(Import-Csv -LiteralPath (Join-Path $root "coordination\sync-ledger.csv") -Encoding UTF8)
    $syncIds = @($syncRows | ForEach-Object { $_.sync_id })
    $syncedReceiptIds = @($syncRows | ForEach-Object { $_.receipt_id })
    if (@($syncIds | Sort-Object -Unique).Count -ne $syncIds.Count -or @($syncedReceiptIds | Sort-Object -Unique).Count -ne $syncedReceiptIds.Count) { $syncOk = $false }
    foreach ($row in $syncRows) {
        if ($row.protocol_version -ne "THREAD-PROTOCOL-v1" -or $row.decision -notin @("ACCEPTED", "REWORK", "REJECTED", "CANCELLED") -or
            $row.receipt_sha256 -notmatch '^[0-9a-fA-F]{64}$' -or $dispatchIds -notcontains $row.dispatch_id) { $syncOk = $false }
    }
    foreach ($dispatch in @($dispatchRows | Where-Object { $_.status -eq "COMPLETE" })) {
        if (@($syncRows | Where-Object { $_.dispatch_id -eq $dispatch.dispatch_id -and $_.decision -eq "ACCEPTED" }).Count -ne 1) { $syncOk = $false }
    }
} catch { $syncOk = $false }
Add-Check "status-sync-binding" $(if ($syncOk) { "PASS" } else { "FAIL" }) "Only one accepted receipt can close a dispatch and justify shared status updates"

$planStatusPath = Join-Path $root "model\PLAN_STATUS.txt"
$planStatus = if (Test-Path -LiteralPath $planStatusPath) {
    (Get-Content -LiteralPath $planStatusPath -Raw).Trim().ToUpperInvariant()
} else {
    "MISSING"
}

$preprocessStatusPath = Join-Path $root "data\PREPROCESSING_STATUS.txt"
$preprocessStatus = if (Test-Path -LiteralPath $preprocessStatusPath) {
    (Get-Content -LiteralPath $preprocessStatusPath -Raw).Trim().ToUpperInvariant()
} else {
    "MISSING"
}

$modelPlanPath = Join-Path $root "model\model-plan.md"
$preprocessPlanPath = Join-Path $root "data\preprocessing-plan.md"
$freezeContentOk = $false
$modelPlanVersion = $null
$preprocessPlanVersion = $null
if ((Test-Path -LiteralPath $modelPlanPath) -and (Test-Path -LiteralPath $preprocessPlanPath)) {
    $modelPlanText = Get-Content -LiteralPath $modelPlanPath -Raw -Encoding UTF8
    $preprocessPlanText = Get-Content -LiteralPath $preprocessPlanPath -Raw -Encoding UTF8
    $placeholderPattern = '(\u5F85\u586B\u5199|\u5C1A\u672A\u586B\u5199|\u5C1A\u672A\u5F00\u59CB|\u5C1A\u672A\u68C0\u9A8C|\u5C1A\u672A\u9A8C\u8BC1|TODO|TBD|PLACEHOLDER|PLACE_[A-Z0-9_]+_HERE|NOT_STARTED|NOT_TESTED|NOT_RUN)'
    $modelApproved = $modelPlanText -match '(?m)^-\s*\u5EFA\u6A21\u624B\u6279\u51C6\s*[:\uFF1A]\s*\u662F\s*$'
    $preprocessApproved = $preprocessPlanText -match '(?m)^-\s*\u5EFA\u6A21\u624B\u6279\u51C6\s*[:\uFF1A]\s*\u662F\s*$'
    $internalFrozen = $modelPlanText -match '(?m)^-\s*\u72B6\u6001\s*[:\uFF1A]\s*FROZEN\s*$' -and $preprocessPlanText -match '(?m)^-\s*\u72B6\u6001\s*[:\uFF1A]\s*FROZEN\s*$'
    $nonInitialVersion = $modelPlanText -notmatch '(?m)^-\s*\u7248\u672C\s*[:\uFF1A]\s*v0\s*$' -and $preprocessPlanText -notmatch '(?m)^-\s*\u7248\u672C\s*[:\uFF1A]\s*v0\s*$'
    $modelVersionMatch = [regex]::Match($modelPlanText, '(?m)^-\s*\u7248\u672C\s*[:\uFF1A]\s*(\S+)\s*$')
    $preprocessVersionMatch = [regex]::Match($preprocessPlanText, '(?m)^-\s*\u7248\u672C\s*[:\uFF1A]\s*(\S+)\s*$')
    if ($modelVersionMatch.Success) { $modelPlanVersion = $modelVersionMatch.Groups[1].Value }
    if ($preprocessVersionMatch.Success) { $preprocessPlanVersion = $preprocessVersionMatch.Groups[1].Value }
    $freezeContentOk = $modelApproved -and $preprocessApproved -and $internalFrozen -and $nonInitialVersion -and $modelPlanText -notmatch $placeholderPattern -and $preprocessPlanText -notmatch $placeholderPattern
}
Add-ReadinessCheck "frozen-plan-content" $freezeContentOk "Both plans require non-v0 versions, internal FROZEN status, explicit approval and no placeholders"

$competitionProfilePath = Join-Path $root "competition\competition-profile.md"
$competitionProfileOk = $false
if (Test-Path -LiteralPath $competitionProfilePath) {
    $competitionProfileText = Get-Content -LiteralPath $competitionProfilePath -Raw -Encoding UTF8
    $competitionProfileOk = $competitionProfileText -notmatch $placeholderPattern -and $competitionProfileText -match '(https?://|\.pdf\b)'
}
Add-ReadinessCheck "competition-profile-content" $competitionProfileOk "Contest profile must be completed and cite a current official URL or rules PDF"

$paperOutlinePath = Join-Path $root "writing\paper-outline.md"
$paperOutlineOk = $false
if (Test-Path -LiteralPath $paperOutlinePath) {
    $paperOutlineText = Get-Content -LiteralPath $paperOutlinePath -Raw -Encoding UTF8
    $requiredPaperAnchors = @("ABSTRACT", "PROBLEM", "ASSUMPTIONS", "SYMBOLS", "DATA", "BASELINE", "FINAL_MODEL", "SOLUTION", "RESULTS", "VERIFICATION", "SENSITIVITY_ROBUSTNESS_ABLATION", "LIMITATIONS", "CONCLUSION", "REFERENCES")
    $missingPaperAnchors = @($requiredPaperAnchors | Where-Object { $paperOutlineText -notmatch ('\[' + [regex]::Escape($_) + '\]') })
    $paperOutlineOk = $paperOutlineText -notmatch $placeholderPattern -and $missingPaperAnchors.Count -eq 0
}
Add-ReadinessCheck "paper-outline-content" $paperOutlineOk "Paper outline must have all stable anchors and no placeholders"

$handoffPath = Join-Path $root "HANDOFF.md"
$handoffOk = $false
if (Test-Path -LiteralPath $handoffPath) {
    $handoffText = Get-Content -LiteralPath $handoffPath -Raw -Encoding UTF8
    $handoffOk = $handoffText -notmatch $placeholderPattern -and $handoffText -notmatch '(?m)^-\s*\u5EFA\u6A21\u65B9\u6848\u72B6\u6001\s*[:\uFF1A]\s*DRAFT\s*$'
}
Add-ReadinessCheck "handoff-content" $handoffOk "Handoff must be current, non-placeholder and not describe a draft model"

if (($planStatus -eq "FROZEN") -xor ($preprocessStatus -eq "FROZEN")) {
    Add-Check "plan-status" "FAIL" "Model and preprocessing statuses must freeze synchronously; current statuses are $planStatus / $preprocessStatus"
} elseif ($Mode -eq "Release") {
    if ($planStatus -eq "FROZEN" -and $preprocessStatus -eq "FROZEN") {
        Add-Check "plan-status" "PASS" "Model and preprocessing plans are frozen"
    } else {
        Add-Check "plan-status" "FAIL" "Release requires model and preprocessing FROZEN; current statuses are $planStatus / $preprocessStatus"
    }
} elseif ($planStatus -eq "FROZEN" -and $preprocessStatus -eq "FROZEN") {
    Add-Check "plan-status" "PASS" "Model and preprocessing plans are frozen"
} else {
    Add-Check "plan-status" "WARN" "Snapshot contains non-frozen plans; current statuses are $planStatus / $preprocessStatus"
}

$csvContracts = @(
    @{ path = "problem\task-requirements.csv"; fields = @("task_id", "requirement", "required_output", "model_section", "implementation_path", "verification_ids", "paper_section", "g0_status", "g1_status", "g2_status", "g3_status", "g4_status", "g5_status", "overall_status") },
    @{ path = "data\data-inventory.csv"; fields = @("data_id", "path", "source", "license_or_permission", "sha256", "fields_and_units", "status") },
    @{ path = "research\evidence-matrix.csv"; fields = @() },
    @{ path = "model\algorithm-evidence-request.csv"; fields = @("request_id", "round_id", "plan_version", "task_id", "candidate_id", "component_id", "tier_role", "selection_eligible", "algorithm_name", "role", "keywords_zh", "keywords_en", "theory_questions", "assumptions_to_verify", "blocking", "status") },
    @{ path = "research\algorithm-evidence-coverage.csv"; fields = @("coverage_id", "request_id", "round_id", "plan_version", "task_id", "candidate_id", "component_id", "evidence_id", "evidence_role", "source_type", "evidence_direction", "independent_group", "fulltext_status", "knowledge_card", "supported_claim", "limitations", "task_transfer_judgment", "coverage_status", "conflict_resolution", "resolution_status") },
    @{ path = "research\search-log.csv"; fields = @("search_id", "request_id", "round_id", "search_date", "database", "query_language", "query", "query_type", "inclusion_rule", "exclusion_rule", "result_count", "screened_count", "negative_result", "stop_reason") },
    @{ path = "research\library\books\book-index.csv"; fields = @("book_id", "title", "authors", "edition", "license_or_access_note", "verified", "notes_path", "status") },
    @{ path = "outputs\artifact-manifest.csv"; fields = @("artifact_id", "task_id", "path", "source_data", "generator", "command", "run_id", "model_version", "verification_ids", "verification_status", "sha256") },
    @{ path = "reports\claim-audit.csv"; fields = @("claim_id", "task_id", "proposed_claim", "artifact_ids", "verification_ids", "status") },
    @{ path = "writing\claim-evidence-matrix.csv"; fields = @("claim_id", "task_id", "paper_section", "claim_text", "artifact_ids", "verification_ids", "status") }
)
foreach ($contract in $csvContracts) {
    $csvPath = Join-Path $root $contract.path
    $valid = $false
    $detail = "Missing or invalid CSV"
    if (Test-Path -LiteralPath $csvPath) {
        try {
            $rows = @(Import-Csv -LiteralPath $csvPath -Encoding UTF8)
            $valid = $rows.Count -gt 0
            foreach ($row in $rows) {
                foreach ($field in $contract.fields) {
                    if (-not ($row.PSObject.Properties.Name -contains $field) -or (Test-PlaceholderValue $row.$field)) { $valid = $false }
                }
            }
            $detail = "Rows=$($rows.Count); required fields must be non-placeholder"
        } catch { $detail = $_.Exception.Message }
    }
    Add-ReadinessCheck "content:$($contract.path)" $valid $detail
}

$lateAuditPath = Join-Path $root "reports\late-stage-ai-self-check.csv"
$lateAuditExpectedIds = @(
    "L1-01", "L1-02", "L1-03", "L1-04",
    "L2-01", "L2-02", "L2-03", "L2-04",
    "L3-01", "L3-02", "L3-03", "L3-04", "L3-05",
    "L4-01", "L4-02", "L4-03",
    "L5-01", "L5-02", "L5-03", "L5-04"
)
$lateAuditStructureOk = $false
$lateAuditComplete = $false
try {
    $lateAuditRows = @(Import-Csv -LiteralPath $lateAuditPath -Encoding UTF8)
    $lateAuditIds = @($lateAuditRows | ForEach-Object { $_.item_id })
    $lateAuditStructureOk = $lateAuditRows.Count -eq 20 -and
        @($lateAuditIds | Sort-Object -Unique).Count -eq 20 -and
        @(Compare-Object ($lateAuditExpectedIds | Sort-Object) ($lateAuditIds | Sort-Object)).Count -eq 0
    $lateAuditComplete = $lateAuditStructureOk
    foreach ($row in $lateAuditRows) {
        if ($row.status -notin @("PASS", "NOT_APPLICABLE") -or
            (Test-PlaceholderValue $row.evidence_path) -or
            (Test-PlaceholderValue $row.reviewer) -or
            (Test-PlaceholderValue $row.reviewed_at)) {
            $lateAuditComplete = $false
        }
        if ($row.status -eq "NOT_APPLICABLE" -and (Test-PlaceholderValue $row.issue_summary)) {
            $lateAuditComplete = $false
        }
    }
} catch {
    $lateAuditStructureOk = $false
    $lateAuditComplete = $false
}
Add-Check "late-stage-ai-audit-structure" $(if ($lateAuditStructureOk) { "PASS" } else { "FAIL" }) "The G5.5 audit must contain exactly the predefined 20 unique item IDs"
Add-ReadinessCheck "late-stage-ai-audit-completion" $lateAuditComplete "Release requires PASS/justified NOT_APPLICABLE plus evidence, reviewer and review time for all 20 G5.5 items"

$resultSummaryPath = Join-Path $root "outputs\result-summary.json"
$resultSummaryOk = $false
if (Test-Path -LiteralPath $resultSummaryPath) {
    try {
        $summary = Get-Content -LiteralPath $resultSummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $generatedAtValid = $false
        try { [void][DateTimeOffset]::Parse([string]$summary.generated_at); $generatedAtValid = $true } catch { $generatedAtValid = $false }
        $resultSummaryOk = $summary.project_status -eq "COMPLETE" -and @($summary.task_results).Count -gt 0 -and @($summary.runs).Count -gt 0 -and $summary.model_version -eq $modelPlanVersion -and $summary.preprocessing_version -eq $preprocessPlanVersion -and $generatedAtValid
    } catch { $resultSummaryOk = $false }
}
Add-ReadinessCheck "result-summary" $resultSummaryOk "Release requires a parseable COMPLETE result summary with task results and frozen versions"

$statusPath = Join-Path $root "PROJECT_STATUS.md"
$gatesReady = $false
$gateStructureOk = $false
if (Test-Path -LiteralPath $statusPath) {
    $statusText = Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8
    $gateRows = @([regex]::Matches($statusText, '(?m)^\|\s*G([0-6])\b[^\r\n]*\|\s*(NOT_STARTED|IN_PROGRESS|BLOCKED|PASS)\s*\|') | ForEach-Object {
        [pscustomobject]@{ gate = [int]$_.Groups[1].Value; status = $_.Groups[2].Value }
    })
    $gateStructureOk = $gateRows.Count -eq 7 -and @($gateRows | Group-Object gate | Where-Object { $_.Count -ne 1 }).Count -eq 0
    $nonPassRequiredGates = @()
    foreach ($gateNumber in 0..5) {
        $matchingGate = @($gateRows | Where-Object { $_.gate -eq $gateNumber })
        if ($matchingGate.Count -ne 1 -or $matchingGate[0].status -ne "PASS") { $nonPassRequiredGates += $gateNumber }
    }
    $gatesReady = $gateStructureOk -and $nonPassRequiredGates.Count -eq 0
}
if ($gateStructureOk) { Add-Check "gate-status-structure" "PASS" "Exactly one valid row exists for each G0 through G6" } else { Add-Check "gate-status-structure" "FAIL" "PROJECT_STATUS must contain exactly one valid row for each G0 through G6" }
Add-ReadinessCheck "g0-g5-status" $gatesReady "Release requires PROJECT_STATUS G0 through G5 PASS; G6 is post-package"

$evidencePath = Join-Path $root "research\evidence-matrix.csv"
if (Test-Path -LiteralPath $evidencePath) {
    $evidenceLines = @(Get-Content -LiteralPath $evidencePath | Where-Object { $_.Trim() -ne "" })
    if ($evidenceLines.Count -gt 1) {
        Add-Check "literature-evidence" "PASS" "Evidence matrix contains at least one data row"
    } elseif ($Mode -eq "Release") {
        Add-Check "literature-evidence" "FAIL" "Release mode requires at least one evidence record"
    } else {
        Add-Check "literature-evidence" "WARN" "Evidence matrix currently contains only its header"
    }
}

$verificationPath = Join-Path $root "reports\verification-report.md"
$reportVerificationRecords = @()
if (Test-Path -LiteralPath $verificationPath) {
    $verificationText = Get-Content -LiteralPath $verificationPath -Raw
    $reportVerificationRecords = @([regex]::Matches($verificationText, '(?m)^\|\s*([^|\s][^|]*)\|\s*([^|]+)\|\s*(YES|NO)\s*\|\s*([^|]+)\|\s*(PASS|CONDITIONAL|FAIL|NOT_TESTED|NOT_APPLICABLE)\s*\|\s*([^|]*)\|\s*([^|]*)\|\s*([^|]*)\|\s*([^|]*)\|\s*([^|]*)\|\s*([^|]*)\|\s*([^|]*)\|') | ForEach-Object {
        [pscustomobject]@{
            id = $_.Groups[1].Value.Trim(); task_id = $_.Groups[2].Value.Trim(); critical = $_.Groups[3].Value.Trim(); applicability = $_.Groups[4].Value.Trim(); status = $_.Groups[5].Value.Trim()
            check_type = $_.Groups[6].Value.Trim(); command_input = $_.Groups[7].Value.Trim(); criterion = $_.Groups[8].Value.Trim(); actual_result = $_.Groups[9].Value.Trim()
            evidence_path = $_.Groups[10].Value.Trim(); limitation = $_.Groups[11].Value.Trim(); action = $_.Groups[12].Value.Trim()
        }
    })
    $statusCells = @($reportVerificationRecords | ForEach-Object { $_.status })
    $notTested = $statusCells -contains "NOT_TESTED"
    $hasFail = $statusCells -contains "FAIL"
    $hasConditional = $statusCells -contains "CONDITIONAL"
    $criticalStatuses = @($reportVerificationRecords | Where-Object { $_.critical -eq "YES" } | ForEach-Object { $_.status })
    $criticalNonPass = @($criticalStatuses | Where-Object { $_ -ne "PASS" }).Count -gt 0
    $limitedMetadataOk = $true
    foreach ($verificationRecord in $reportVerificationRecords) {
        if ($verificationRecord.status -eq "CONDITIONAL" -and ((Test-PlaceholderValue $verificationRecord.evidence_path) -or (Test-PlaceholderValue $verificationRecord.limitation) -or (Test-PlaceholderValue $verificationRecord.action))) { $limitedMetadataOk = $false }
        if ($verificationRecord.status -eq "NOT_APPLICABLE" -and ($verificationRecord.applicability -notmatch '^NOT_APPLICABLE:.+' -or (Test-PlaceholderValue $verificationRecord.limitation))) { $limitedMetadataOk = $false }
    }
    $overallPass = $verificationText -match '(?m)^-\s*\u603B\u4F53\u7ED3\u8BBA\s*[:\uFF1A]\s*PASS\s*$'
    if ($Mode -eq "Release" -and (-not $overallPass -or $statusCells.Count -eq 0 -or $criticalStatuses.Count -eq 0 -or $criticalNonPass -or $notTested -or $hasFail -or -not $limitedMetadataOk)) {
        Add-Check "verification-report" "FAIL" "Release requires overall PASS, critical PASS, no FAIL/NOT_TESTED, and evidence plus limitations for conditional or not-applicable checks"
    } elseif ($notTested) {
        Add-Check "verification-report" "WARN" "Independent verification is not complete"
    } elseif ($hasFail) {
        Add-Check "verification-report" "WARN" "Verification report contains a failed check"
    } elseif ($hasConditional) {
        Add-Check "verification-report" "WARN" "Verification contains conditional conclusions that must restrict paper wording"
    } elseif (-not $overallPass) {
        Add-Check "verification-report" "WARN" "Verification overall conclusion is not PASS"
    } else {
        Add-Check "verification-report" "PASS" "Overall conclusion and structured check statuses pass"
    }
}

$taskRows = @(Import-Csv -LiteralPath (Join-Path $root "problem\task-requirements.csv") -Encoding UTF8)
$taskIds = @($taskRows | ForEach-Object { $_.task_id })
$formalTaskIds = @($taskIds | Where-Object { -not (Test-PlaceholderValue $_) } | Sort-Object -Unique)

# G2-B pre-freeze implementation readiness.  These records bind the user-review
# package to the exact model, preprocessing, invariants, defaults and budget that
# were jointly reviewed by the implementer and verifier.
$g2FreezeStrict = $Mode -eq "Release" -or $planStatus -eq "FROZEN" -or $preprocessStatus -eq "FROZEN" -or @($gateRows | Where-Object { $_.gate -eq 2 -and $_.status -eq "PASS" }).Count -eq 1
$g2ReadinessStrict = $g2FreezeStrict
$readinessPath = Join-Path $root "model\implementation-readiness.md"
$invariantsPath = Join-Path $root "model\protected-invariants.md"
$defaultsPath = Join-Path $root "model\implementation-defaults.md"
$decisionRegisterPath = Join-Path $root "model\decision-register.csv"
$budgetPath = Join-Path $root "model\complexity-budget.csv"
$implementerReviewPath = Join-Path $root "model\readiness\implementer-review.md"
$verifierReviewPath = Join-Path $root "model\readiness\verifier-review.md"
$approvalPath = Join-Path $root "model\g2-approval.json"

$readinessText = if (Test-Path -LiteralPath $readinessPath) { Get-Content -LiteralPath $readinessPath -Raw -Encoding UTF8 } else { "" }
$readinessStatus = Get-ReadinessMetadataValue $readinessText "status"
$g2ReadinessStrict = $g2ReadinessStrict -or $readinessStatus -eq "READY_FOR_USER_REVIEW"
$g2ReadinessFiles = @($readinessPath, $invariantsPath, $defaultsPath, $decisionRegisterPath, $budgetPath, $implementerReviewPath, $verifierReviewPath, $approvalPath)
$g2ReadinessFilesOk = @($g2ReadinessFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }).Count -eq 0
Add-G2ReadinessCheck "g2-readiness-files" $g2ReadinessFilesOk "G2-B requires readiness, independent role reviews, protected invariants, defaults, decision register, budget and G2 approval sidecar" $g2ReadinessStrict

$implementerSignoff = Get-ReadinessMetadataValue $readinessText "implementer_signoff"
$verifierSignoff = Get-ReadinessMetadataValue $readinessText "verifier_signoff"
$readinessStatusOk = $readinessStatus -eq "READY_FOR_USER_REVIEW" -and $implementerSignoff -eq "YES" -and $verifierSignoff -eq "YES"
Add-G2ReadinessCheck "g2-readiness-status-and-signoff" $readinessStatusOk "implementation-readiness.md must be READY_FOR_USER_REVIEW with independent implementer and verifier YES signoffs" $g2ReadinessStrict

$implementerReviewText = if (Test-Path -LiteralPath $implementerReviewPath) { Get-Content -LiteralPath $implementerReviewPath -Raw -Encoding UTF8 } else { "" }
$verifierReviewText = if (Test-Path -LiteralPath $verifierReviewPath) { Get-Content -LiteralPath $verifierReviewPath -Raw -Encoding UTF8 } else { "" }
$implementerReviewerId = Get-ReadinessMetadataValue $implementerReviewText "reviewer_id"
$verifierReviewerId = Get-ReadinessMetadataValue $verifierReviewText "reviewer_id"
$implementerReviewHash = Get-ReadinessMetadataValue $implementerReviewText "reviewed_readiness_bundle_sha256"
$verifierReviewHash = Get-ReadinessMetadataValue $verifierReviewText "reviewed_readiness_bundle_sha256"
$reviewIdentityOk = (Get-ReadinessMetadataValue $implementerReviewText "role") -eq "model_implementer" -and
    (Get-ReadinessMetadataValue $verifierReviewText "role") -eq "model_verifier" -and
    (Get-ReadinessMetadataValue $implementerReviewText "mode") -eq "PREFREEZE_READINESS" -and
    (Get-ReadinessMetadataValue $verifierReviewText "mode") -eq "PREFREEZE_READINESS" -and
    (Get-ReadinessMetadataValue $implementerReviewText "verdict") -eq "READY_FOR_USER_REVIEW" -and
    (Get-ReadinessMetadataValue $verifierReviewText "verdict") -eq "READY_FOR_USER_REVIEW" -and
    (Get-ReadinessMetadataValue $implementerReviewText "signoff") -eq "YES" -and
    (Get-ReadinessMetadataValue $verifierReviewText "signoff") -eq "YES" -and
    -not (Test-PlaceholderValue $implementerReviewerId) -and -not (Test-PlaceholderValue $verifierReviewerId) -and $implementerReviewerId -ne $verifierReviewerId -and
    (Get-ReadinessMetadataValue $implementerReviewText "used_formal_results") -eq "NO" -and
    (Get-ReadinessMetadataValue $verifierReviewText "used_formal_results") -eq "NO" -and
    (Get-ReadinessMetadataValue $implementerReviewText "ran_full_real_model") -eq "NO" -and
    (Get-ReadinessMetadataValue $verifierReviewText "ran_full_real_model") -eq "NO" -and
    (Get-ReadinessMetadataValue $verifierReviewText "g4_status_claimed") -eq "NO"
Add-G2ReadinessCheck "g2-independent-prefreeze-reviews" $reviewIdentityOk "Implementer and verifier reviews need distinct identities, matching mode, READY verdicts, no formal-result use and no G4 claim" $g2ReadinessStrict

$invariantsText = if (Test-Path -LiteralPath $invariantsPath) { Get-Content -LiteralPath $invariantsPath -Raw -Encoding UTF8 } else { "" }
$invariantsOk = -not [string]::IsNullOrWhiteSpace($invariantsText) -and $invariantsText -notmatch $placeholderPattern -and $invariantsText -match '(?m)^\|\s*INV-'
Add-G2ReadinessCheck "g2-protected-invariants" $invariantsOk "Protected A-class invariants must be non-placeholder and structured" $g2ReadinessStrict

$decisionRegisterOk = $false
if (Test-Path -LiteralPath $decisionRegisterPath) {
    try {
        $decisionRows = @(Import-Csv -LiteralPath $decisionRegisterPath -Encoding UTF8)
        $decisionRegisterOk = $decisionRows.Count -gt 0
        $decisionIds = @($decisionRows | ForEach-Object { $_.decision_id })
        if (@($decisionIds | Sort-Object -Unique).Count -ne $decisionIds.Count) { $decisionRegisterOk = $false }
        $requiredATopics = @("STUDY_TARGET", "INCLUSION_ALIGNMENT", "SPLIT_LEAKAGE", "MODEL_OBJECTIVE", "PRIMARY_METRIC_DECISION", "TIER_FAIRNESS_FALLBACK", "CLAIM_SCOPE")
        foreach ($decision in $decisionRows) {
            foreach ($field in @("decision_id", "plan_version", "preprocessing_version", "task_id", "decision_class", "topic_group", "topic", "applicability", "owner", "resolution_status")) {
                if (-not ($decision.PSObject.Properties.Name -contains $field) -or (Test-PlaceholderValue $decision.$field)) { $decisionRegisterOk = $false }
            }
            if ($decision.plan_version -ne $modelPlanVersion -or $decision.preprocessing_version -ne $preprocessPlanVersion) { $decisionRegisterOk = $false }
            if ($decision.decision_class -eq "A" -and ($decision.resolution_status -ne "RESOLVED" -or $decision.requires_user_approval -ne "YES" -or (Test-PlaceholderValue $decision.protected_invariant_id) -or (Test-PlaceholderValue $decision.source_refs))) { $decisionRegisterOk = $false }
            if ($decision.applicability -eq "APPLICABLE" -and (Test-PlaceholderValue $decision.selected_value)) { $decisionRegisterOk = $false }
            if ($decision.applicability -eq "NOT_APPLICABLE" -and (Test-PlaceholderValue $decision.na_reason)) { $decisionRegisterOk = $false }
            if ($decision.decision_class -eq "B") {
                if ($decision.resolution_status -ne "RESOLVED" -or (Test-PlaceholderValue $decision.equivalence_test_id)) { $decisionRegisterOk = $false }
                foreach ($impactField in @("affects_rank", "affects_objective", "affects_prediction", "affects_threshold", "affects_model_selection")) { if ($decision.$impactField -ne "NO") { $decisionRegisterOk = $false } }
                if (-not ([string]$decision.equivalence_test_id).Replace('\', '/').StartsWith("tests/contract/") -or -not (Test-Path -LiteralPath (Join-Path $root $decision.equivalence_test_id))) { $decisionRegisterOk = $false }
            }
        }
        foreach ($taskId in $formalTaskIds) {
            $taskATopics = @($decisionRows | Where-Object { $_.task_id -eq $taskId -and $_.decision_class -eq "A" } | ForEach-Object { $_.topic_group } | Sort-Object -Unique)
            foreach ($topic in $requiredATopics) { if ($taskATopics -notcontains $topic) { $decisionRegisterOk = $false } }
        }
    } catch { $decisionRegisterOk = $false }
}
Add-G2ReadinessCheck "g2-a-class-decisions" $decisionRegisterOk "Decision register must contain no unresolved A-class scientific decision" $g2ReadinessStrict

$budgetOk = $formalTaskIds.Count -gt 0 -and (Test-Path -LiteralPath $budgetPath)
if ($budgetOk) {
    try {
        $budgetRows = @(Import-Csv -LiteralPath $budgetPath -Encoding UTF8)
        foreach ($taskId in $formalTaskIds) {
            $taskBudgets = @($budgetRows | Where-Object { $_.task_id -eq $taskId })
            foreach ($tier in @("TIER_0", "TIER_1")) {
                $tierRows = @($taskBudgets | Where-Object { $_.tier -eq $tier -and $_.status -eq "READY" })
                if ($tierRows.Count -ne 1) { $budgetOk = $false; continue }
                foreach ($budget in $tierRows) {
                    foreach ($field in @("candidate_id", "tier", "entry_point", "command", "interface_contract_id", "outer_split_id", "evaluation_unit", "primary_metric_id", "single_fit_minutes", "expected_total_minutes", "available_window_minutes", "window_fraction", "fallback_tier", "over_budget_action", "estimation_basis", "status")) {
                        if (-not ($budget.PSObject.Properties.Name -contains $field) -or (Test-PlaceholderValue $budget.$field)) { $budgetOk = $false }
                    }
                    try {
                        $windowMinutes = [double]$budget.available_window_minutes
                        $totalMinutes = [double]$budget.expected_total_minutes
                        $windowFraction = [double]$budget.window_fraction
                        $singleFit = [double]$budget.single_fit_minutes
                        $totalFitCount = [double]$budget.total_fit_count
                        $memoryGb = [double]$budget.memory_gb
                        $diskGb = [double]$budget.disk_gb
                        $reserveFraction = [double]$budget.safety_reserve_fraction
                        if ($windowMinutes -le 0 -or $totalMinutes -lt 0 -or $windowFraction -lt 0 -or $singleFit -lt 0 -or $totalFitCount -lt 0 -or $memoryGb -lt 0 -or $diskGb -lt 0 -or $reserveFraction -lt 0.3) { $budgetOk = $false }
                        if ([Math]::Abs($windowFraction - ($totalMinutes / $windowMinutes)) -gt 0.01) { $budgetOk = $false }
                        if (-not ([string]$budget.interface_contract_id).Replace('\', '/').StartsWith("tests/contract/") -or -not (Test-Path -LiteralPath (Join-Path $root $budget.interface_contract_id))) { $budgetOk = $false }
                        if ($tier -eq "TIER_0" -and $budget.fallback_tier -ne "NONE") { $budgetOk = $false }
                        if ($tier -eq "TIER_1" -and $budget.fallback_tier -ne "TIER_0") { $budgetOk = $false }
                        if ($tier -eq "TIER_1" -and $windowFraction -gt 0.4) { $budgetOk = $false }
                    } catch { $budgetOk = $false }
                }
            }
            $readyCoreRows = @($taskBudgets | Where-Object { $_.tier -in @("TIER_0", "TIER_1") -and $_.status -eq "READY" })
            if (@($readyCoreRows | ForEach-Object { $_.outer_split_id } | Sort-Object -Unique).Count -ne 1 -or @($readyCoreRows | ForEach-Object { $_.evaluation_unit } | Sort-Object -Unique).Count -ne 1 -or @($readyCoreRows | ForEach-Object { $_.primary_metric_id } | Sort-Object -Unique).Count -ne 1) { $budgetOk = $false }
            foreach ($tier2 in @($taskBudgets | Where-Object { $_.tier -eq "TIER_2" })) {
                try {
                    foreach ($field in @("effect_gate", "interval_rule", "stability_gate", "calibration_gate", "cost_gate", "run_condition", "over_budget_action")) { if (Test-PlaceholderValue $tier2.$field) { $budgetOk = $false } }
                    if ((Test-PlaceholderValue $tier2.safety_reserve_fraction) -or [double]$tier2.safety_reserve_fraction -lt 0.3 -or $tier2.fallback_tier -ne "TIER_1" -or $tier2.over_budget_action -notmatch 'FALLBACK.*TIER_1') { $budgetOk = $false }
                    $tier1 = @($taskBudgets | Where-Object { $_.tier -eq "TIER_1" -and $_.status -eq "READY" })[0]
                    if ($tier2.outer_split_id -ne $tier1.outer_split_id -or $tier2.evaluation_unit -ne $tier1.evaluation_unit -or $tier2.primary_metric_id -ne $tier1.primary_metric_id) { $budgetOk = $false }
                } catch { $budgetOk = $false }
            }
        }
    } catch { $budgetOk = $false }
}
Add-G2ReadinessCheck "g2-tier-budget-and-fallback" $budgetOk "Every formal task needs Tier 0/1 executable entries, budgets and failure actions; Tier 1 uses at most 40% of its window and Tier 2 reserves at least 30% with Tier 1 fallback" $g2ReadinessStrict

$reviewHashEntries = @(
    [pscustomobject]@{ label = "model_plan_sha256"; relative = "model/model-plan.md"; path = $modelPlanPath },
    [pscustomobject]@{ label = "preprocessing_plan_sha256"; relative = "data/preprocessing-plan.md"; path = $preprocessPlanPath },
    [pscustomobject]@{ label = "protected_invariants_sha256"; relative = "model/protected-invariants.md"; path = $invariantsPath },
    [pscustomobject]@{ label = "implementation_defaults_sha256"; relative = "model/implementation-defaults.md"; path = $defaultsPath },
    [pscustomobject]@{ label = "complexity_budget_sha256"; relative = "model/complexity-budget.csv"; path = $budgetPath }
)
$reviewHashesOk = $g2ReadinessFilesOk
$bundleInput = ""
foreach ($entry in $reviewHashEntries) {
    $recorded = Get-ReadinessMetadataValue $readinessText $entry.label
    $actual = Get-NormalizedFileSha256 $entry.path
    if ((Test-PlaceholderValue $recorded) -or $recorded -notmatch '^[0-9a-fA-F]{64}$' -or $null -eq $actual -or $recorded.ToLowerInvariant() -ne $actual) { $reviewHashesOk = $false }
    $bundleInput += $entry.relative + [char]0 + $actual + "`n"
}
$actualBundleHash = Get-StringSha256 $bundleInput
$recordedBundleHash = Get-ReadinessMetadataValue $readinessText "readiness_bundle_sha256"
if ($recordedBundleHash -notmatch '^[0-9a-fA-F]{64}$' -or $recordedBundleHash.ToLowerInvariant() -ne $actualBundleHash -or $implementerReviewHash -ne $actualBundleHash -or $verifierReviewHash -ne $actualBundleHash) { $reviewHashesOk = $false }
Add-G2ReadinessCheck "g2-readiness-review-hashes" $reviewHashesOk "Readiness review must bind normalized SHA-256 values for the current model, preprocessing, invariants, defaults and complexity budget" $g2ReadinessStrict

$approvalOk = $false
if (Test-Path -LiteralPath $approvalPath) {
    try {
        $approval = Get-Content -LiteralPath $approvalPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $approvalOk = $approval.status -eq "APPROVED" -and -not (Test-PlaceholderValue $approval.approval_id) -and -not (Test-PlaceholderValue $approval.approved_by) -and -not (Test-PlaceholderValue $approval.approval_quote) -and
            $approval.readiness_bundle_sha256 -eq $actualBundleHash -and $approval.plan_version -eq $modelPlanVersion -and $approval.preprocessing_version -eq $preprocessPlanVersion -and $approval.readiness_id -eq (Get-ReadinessMetadataValue $readinessText "readiness_id")
        [void][DateTimeOffset]::Parse([string]$approval.approved_at)
    } catch { $approvalOk = $false }
}
if ($g2FreezeStrict) { Add-G2ReadinessCheck "g2-user-approval-binding" $approvalOk "Frozen G2 requires an APPROVED sidecar bound to the reviewed bundle, versions, readiness ID, timestamp and user quote" $g2FreezeStrict }

$knownEvidenceRowsForTasks = @(Import-Csv -LiteralPath (Join-Path $root "research\evidence-matrix.csv") -Encoding UTF8)
$knownEvidenceIdsForTasks = @($knownEvidenceRowsForTasks | ForEach-Object { $_.id })
$taskStatusFields = @("g0_status", "g1_status", "g2_status", "g3_status", "g4_status", "g5_status", "overall_status")
$taskCoverageOk = $taskRows.Count -gt 0 -and @($taskIds | Sort-Object -Unique).Count -eq $taskIds.Count
foreach ($taskRow in $taskRows) {
    foreach ($field in $taskStatusFields) {
        if ($taskRow.$field -ne "PASS") { $taskCoverageOk = $false }
    }
    $taskEvidenceIds = Split-IdentifierList $taskRow.evidence_ids
    if ($taskEvidenceIds.Count -eq 0) { $taskCoverageOk = $false }
    foreach ($id in $taskEvidenceIds) { if ($knownEvidenceIdsForTasks -notcontains $id) { $taskCoverageOk = $false } }
    $implementationPaths = Split-IdentifierList $taskRow.implementation_path
    if ($implementationPaths.Count -eq 0) { $taskCoverageOk = $false }
    foreach ($implementationPath in $implementationPaths) {
        try {
            $implementationFullPath = [IO.Path]::GetFullPath((Join-Path $root $implementationPath))
            if (-not $implementationFullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $implementationFullPath)) { $taskCoverageOk = $false }
        } catch { $taskCoverageOk = $false }
    }
    if ($requiredPaperAnchors -notcontains $taskRow.paper_section) { $taskCoverageOk = $false }
}
Add-ReadinessCheck "task-stage-statuses" $taskCoverageOk "Every unique task requires G0-G5 and overall PASS"

$reportVerificationIds = @($reportVerificationRecords | ForEach-Object { $_.id })
$fixedVerificationIds = @("V-BL", "V-SA", "V-RB", "V-RP", "V-CX")
$modelPlanVerificationIds = @([regex]::Matches($modelPlanText, '(?m)^\|\s*(V-[A-Za-z0-9_-]+)\s*\|') | ForEach-Object { $_.Groups[1].Value })
$requiredVerificationIds = @($fixedVerificationIds) + @($modelPlanVerificationIds)
$taskRequiredVerificationIds = @()
foreach ($taskRow in $taskRows) { $taskRequiredVerificationIds += Split-IdentifierList $taskRow.verification_ids }
$requiredVerificationIds += $taskRequiredVerificationIds
$requiredVerificationIds = @($requiredVerificationIds | Sort-Object -Unique)
$strictVerificationIds = @($fixedVerificationIds + $taskRequiredVerificationIds | Sort-Object -Unique)
$missingVerificationIds = @($requiredVerificationIds | Where-Object { $reportVerificationIds -notcontains $_ })
$verificationCoverageOk = $reportVerificationIds.Count -gt 0 -and @($reportVerificationIds | Sort-Object -Unique).Count -eq $reportVerificationIds.Count -and $missingVerificationIds.Count -eq 0
foreach ($requiredVerificationId in $strictVerificationIds) {
    $requiredRecord = @($reportVerificationRecords | Where-Object { $_.id -eq $requiredVerificationId })
    if ($requiredRecord.Count -ne 1 -or $requiredRecord[0].critical -ne "YES" -or $requiredRecord[0].applicability -ne "APPLICABLE" -or $requiredRecord[0].status -ne "PASS") { $verificationCoverageOk = $false }
}
Add-ReadinessCheck "verification-id-coverage" $verificationCoverageOk "Verification report must contain each fixed and task-required ID exactly once"

$inventoryRows = @(Import-Csv -LiteralPath (Join-Path $root "data\data-inventory.csv") -Encoding UTF8)
$rawHashRows = @(Import-Csv -LiteralPath (Join-Path $root "data\raw-hashes.csv") -Encoding UTF8)
$rawFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "data\raw") -File -Recurse -Force | Where-Object { $_.Name -ne ".gitkeep" -and $_.Name -notmatch '^PLACE_.*_HERE' })
$rawDataIntegrityOk = $true
if ($rawFiles.Count -eq 0) {
    $rawDataIntegrityOk = @($inventoryRows | Where-Object { $_.data_id -eq "NO_OFFICIAL_DATA" }).Count -eq 1 -and @($rawHashRows | Where-Object { $_.data_id -eq "NO_OFFICIAL_DATA" }).Count -eq 1
} else {
    if ($inventoryRows.Count -ne $rawFiles.Count -or $rawHashRows.Count -ne $rawFiles.Count) { $rawDataIntegrityOk = $false }
    foreach ($rawFile in $rawFiles) {
        $rawRelative = (Get-ProjectRelativePath $root $rawFile.FullName).Replace('\', '/')
        $inventoryMatch = @($inventoryRows | Where-Object { $_.path.Replace('\', '/') -eq $rawRelative })
        $hashMatch = @($rawHashRows | Where-Object { $_.path.Replace('\', '/') -eq $rawRelative })
        if ($inventoryMatch.Count -ne 1 -or $hashMatch.Count -ne 1) { $rawDataIntegrityOk = $false; continue }
        $actualRawHash = (Get-FileHash -LiteralPath $rawFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        if ([string]$rawFile.Length -ne $hashMatch[0].size_bytes -or $hashMatch[0].sha256 -notmatch '^[0-9a-fA-F]{64}$' -or $actualRawHash -ne $hashMatch[0].sha256.ToLowerInvariant()) { $rawDataIntegrityOk = $false }
        if ($inventoryMatch[0].sha256 -ne $hashMatch[0].sha256) { $rawDataIntegrityOk = $false }
    }
}
Add-ReadinessCheck "raw-data-integrity" $rawDataIntegrityOk "Raw file set, inventory, sizes and SHA-256 table must agree; no-data projects require explicit sentinel rows"

$artifactRows = @(Import-Csv -LiteralPath (Join-Path $root "outputs\artifact-manifest.csv") -Encoding UTF8)
$artifactIds = @($artifactRows | ForEach-Object { $_.artifact_id })
$verifiedArtifactIds = @($artifactRows | Where-Object { $_.verification_status -eq "VERIFIED" } | ForEach-Object { $_.artifact_id })
$artifactIntegrityOk = $artifactRows.Count -gt 0 -and @($artifactIds | Sort-Object -Unique).Count -eq $artifactIds.Count
$knownRunIdsForArtifacts = if ($resultSummaryOk) { @($summary.runs | ForEach-Object { $_.run_id }) } else { @() }
foreach ($artifactRow in $artifactRows) {
    if ($artifactRow.verification_status -eq "VERIFIED") {
        try {
            $artifactFullPath = [IO.Path]::GetFullPath((Join-Path $root $artifactRow.path))
            if (-not $artifactFullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $artifactFullPath -PathType Leaf)) { $artifactIntegrityOk = $false; continue }
            if ((Get-Item -LiteralPath $artifactFullPath).Length -le 0) { $artifactIntegrityOk = $false }
            $actualArtifactHash = (Get-FileHash -LiteralPath $artifactFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($artifactRow.sha256 -notmatch '^[0-9a-fA-F]{64}$' -or $actualArtifactHash -ne $artifactRow.sha256.ToLowerInvariant()) { $artifactIntegrityOk = $false }
            $generatorFullPath = [IO.Path]::GetFullPath((Join-Path $root $artifactRow.generator))
            if (-not $generatorFullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $generatorFullPath -PathType Leaf)) { $artifactIntegrityOk = $false }
            foreach ($sourcePath in (Split-IdentifierList $artifactRow.source_data)) {
                $sourceFullPath = [IO.Path]::GetFullPath((Join-Path $root $sourcePath))
                if (-not $sourceFullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $sourceFullPath)) { $artifactIntegrityOk = $false }
            }
            if ((Test-PlaceholderValue $artifactRow.command) -or $artifactRow.model_version -ne $modelPlanVersion -or $knownRunIdsForArtifacts -notcontains $artifactRow.run_id) { $artifactIntegrityOk = $false }
        } catch { $artifactIntegrityOk = $false }
    }
}
foreach ($taskId in $taskIds) {
    if (@($artifactRows | Where-Object { $_.task_id -eq $taskId -and $_.verification_status -eq "VERIFIED" }).Count -eq 0) { $artifactIntegrityOk = $false }
}
Add-ReadinessCheck "artifact-integrity" $artifactIntegrityOk "Each task needs a VERIFIED artifact with an existing nonempty file and matching SHA-256"

$summaryTaskSetOk = $false
if ($resultSummaryOk) {
    $summaryTaskIds = @($summary.task_results | ForEach-Object { $_.task_id } | Sort-Object -Unique)
    $summaryTaskSetOk = @(Compare-Object @($taskIds | Sort-Object -Unique) $summaryTaskIds).Count -eq 0
    $summaryRunIds = @($summary.runs | ForEach-Object { $_.run_id })
    foreach ($taskResult in @($summary.task_results)) {
        foreach ($field in @("task_id", "run_id", "baseline", "final", "metrics", "unit", "artifact_ids")) {
            if (-not ($taskResult.PSObject.Properties.Name -contains $field) -or $null -eq $taskResult.$field -or (Test-PlaceholderValue $taskResult.$field)) { $summaryTaskSetOk = $false }
        }
        if ($summaryRunIds -notcontains $taskResult.run_id) { $summaryTaskSetOk = $false }
        foreach ($id in @($taskResult.artifact_ids)) { if ($verifiedArtifactIds -notcontains $id) { $summaryTaskSetOk = $false } }
    }
}
Add-ReadinessCheck "result-task-coverage" $summaryTaskSetOk "Result summary task IDs must exactly match task requirements"

$evidenceRows = @(Import-Csv -LiteralPath (Join-Path $root "research\evidence-matrix.csv") -Encoding UTF8)
$evidenceIds = @($evidenceRows | ForEach-Object { $_.id })
$evidenceIntegrityOk = $evidenceRows.Count -gt 0 -and @($evidenceIds | Sort-Object -Unique).Count -eq $evidenceIds.Count
foreach ($evidenceRow in $evidenceRows) {
    foreach ($field in @("id", "title", "authors", "year", "doi_or_url", "source_status", "method", "limitations")) {
        if (-not ($evidenceRow.PSObject.Properties.Name -contains $field) -or (Test-PlaceholderValue $evidenceRow.$field)) { $evidenceIntegrityOk = $false }
    }
    if ($evidenceRow.doi_or_url -notmatch '^(https?://|10\.)') { $evidenceIntegrityOk = $false }
}
$literatureReviewText = Get-Content -LiteralPath (Join-Path $root "research\literature-review.md") -Raw -Encoding UTF8
$citationBriefText = Get-Content -LiteralPath (Join-Path $root "research\citation-brief.md") -Raw -Encoding UTF8
if ($literatureReviewText -match $placeholderPattern -or $citationBriefText -match $placeholderPattern) { $evidenceIntegrityOk = $false }
Add-ReadinessCheck "literature-evidence-integrity" $evidenceIntegrityOk "Evidence IDs and verified metadata must be unique and research handoff documents must be complete"

$algorithmRequestPath = Join-Path $root "model\algorithm-evidence-request.csv"
$algorithmCoveragePath = Join-Path $root "research\algorithm-evidence-coverage.csv"
$algorithmSearchPath = Join-Path $root "research\search-log.csv"
$bookIndexPath = Join-Path $root "research\library\books\book-index.csv"
$libraryIndexPath = Join-Path $root "research\library\library-index.csv"
$downloadLogPath = Join-Path $root "research\library\download-log.csv"

$algorithmEvidenceOk = $true
$algorithmEvidenceDetails = [System.Collections.Generic.List[string]]::new()
try {
    $algorithmRequests = @(Import-Csv -LiteralPath $algorithmRequestPath -Encoding UTF8)
    $algorithmCoverage = @(Import-Csv -LiteralPath $algorithmCoveragePath -Encoding UTF8)
    $algorithmSearches = @(Import-Csv -LiteralPath $algorithmSearchPath -Encoding UTF8)
    $bookRows = @(Import-Csv -LiteralPath $bookIndexPath -Encoding UTF8)
    $libraryRows = @(Import-Csv -LiteralPath $libraryIndexPath -Encoding UTF8)
    $downloadRows = @(Import-Csv -LiteralPath $downloadLogPath -Encoding UTF8)

    $requestIds = @($algorithmRequests | ForEach-Object { $_.request_id })
    $coverageIds = @($algorithmCoverage | ForEach-Object { $_.coverage_id })
    if ($algorithmRequests.Count -eq 0 -or @($requestIds | Sort-Object -Unique).Count -ne $requestIds.Count) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("request IDs missing or duplicated") }
    if ($algorithmCoverage.Count -eq 0 -or @($coverageIds | Sort-Object -Unique).Count -ne $coverageIds.Count) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("coverage IDs missing or duplicated") }

    foreach ($request in $algorithmRequests) {
        foreach ($field in @("request_id", "round_id", "plan_version", "task_id", "candidate_id", "component_id", "tier_role", "selection_eligible", "algorithm_name", "role", "keywords_zh", "keywords_en", "theory_questions", "assumptions_to_verify", "blocking", "status")) {
            if (-not ($request.PSObject.Properties.Name -contains $field) -or (Test-PlaceholderValue $request.$field)) { $algorithmEvidenceOk = $false }
        }
        if ($request.plan_version -ne $modelPlanVersion) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("request $($request.request_id) has stale plan version") }
        if ($request.status -notin @("EVIDENCE_COVERED", "REJECTED")) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("request $($request.request_id) is $($request.status)") }

        $requestCoverage = @($algorithmCoverage | Where-Object { $_.request_id -eq $request.request_id -and $_.round_id -eq $request.round_id -and $_.plan_version -eq $request.plan_version })
        if ($requestCoverage.Count -eq 0) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("request $($request.request_id) has no current coverage"); continue }
        foreach ($coverage in $requestCoverage) {
            if ($coverage.task_id -ne $request.task_id -or $coverage.candidate_id -ne $request.candidate_id -or $coverage.component_id -ne $request.component_id) { $algorithmEvidenceOk = $false }
            if ($coverage.coverage_status -ne "NOT_APPLICABLE" -and $evidenceIds -notcontains $coverage.evidence_id) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("coverage $($coverage.coverage_id) has unresolved evidence ID") }
            if ($coverage.evidence_direction -notin @("SUPPORTS", "CONTRADICTS", "MIXED", "NO_BEARING")) { $algorithmEvidenceOk = $false }
            if ($coverage.coverage_status -notin @("SUPPORTED", "PARTIAL", "CONFLICTED", "UNSUPPORTED", "NOT_APPLICABLE")) { $algorithmEvidenceOk = $false }
            if ($request.status -eq "EVIDENCE_COVERED" -and $coverage.coverage_status -notin @("SUPPORTED", "NOT_APPLICABLE") -and ($coverage.resolution_status -ne "RESOLVED" -or (Test-PlaceholderValue $coverage.conflict_resolution))) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("coverage $($coverage.coverage_id) has unresolved contrary or partial evidence") }
            $cardPath = [string]$coverage.knowledge_card
            if (-not (Test-PlaceholderValue $cardPath)) {
                $cardFullPath = [IO.Path]::GetFullPath((Join-Path $root $cardPath))
                if (-not $cardFullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $cardFullPath -PathType Leaf)) { $algorithmEvidenceOk = $false }
            }
        }

        $searchRows = @($algorithmSearches | Where-Object { $_.request_id -eq $request.request_id -and $_.round_id -eq $request.round_id })
        $queryTypes = @($searchRows | ForEach-Object { $_.query_type } | Sort-Object -Unique)
        foreach ($queryType in @("NEUTRAL", "SUPPORT", "LIMITATION", "COMPARISON")) { if ($queryTypes -notcontains $queryType) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("request $($request.request_id) lacks $queryType search") } }

        $roleStatuses = if ($request.status -eq "REJECTED") { @("SUPPORTED", "PARTIAL", "CONFLICTED", "UNSUPPORTED") } else { @("SUPPORTED") }
        $roles = @($requestCoverage | Where-Object { $_.coverage_status -in $roleStatuses } | ForEach-Object { $_.evidence_role } | Sort-Object -Unique)
        if ($roles -notcontains "FOUNDATIONAL" -or @($roles | Where-Object { $_ -in @("TASK_APPLICATION", "COMPARATIVE_OR_LIMITATION") }).Count -eq 0) { $algorithmEvidenceOk = $false }

        if (($request.role -eq "FINAL_COMPONENT" -or $request.selection_eligible -eq "YES") -and $request.blocking -eq "YES") {
            foreach ($requiredRole in @("FOUNDATIONAL", "TASK_APPLICATION", "COMPARATIVE_OR_LIMITATION")) { if ($roles -notcontains $requiredRole) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("final component $($request.component_id) lacks $requiredRole") } }
            $textbookRows = @($requestCoverage | Where-Object { $_.evidence_role -eq "TEXTBOOK_OR_MONOGRAPH" })
            $textbookSatisfied = @($textbookRows | Where-Object { $_.coverage_status -eq "SUPPORTED" -and -not (Test-PlaceholderValue $_.chapter_pages) }).Count -gt 0
            $textbookExplained = @($textbookRows | Where-Object { $_.coverage_status -eq "NOT_APPLICABLE" -and $_.limitations -match '^TEXTBOOK_NOT_AVAILABLE:.+' }).Count -gt 0
            if (-not ($textbookSatisfied -or $textbookExplained)) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("final component $($request.component_id) lacks textbook/monograph check") }
            $independentGroups = @($requestCoverage | Where-Object { $_.coverage_status -eq "SUPPORTED" } | ForEach-Object { $_.independent_group } | Where-Object { -not (Test-PlaceholderValue $_) } | Sort-Object -Unique)
            if ($independentGroups.Count -lt 3) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("final component $($request.component_id) has fewer than three independent source groups") }
            $readableFulltexts = @($requestCoverage | Where-Object { $_.coverage_status -eq "SUPPORTED" -and $_.fulltext_status -in @("PDF_VERIFIED", "AUTHORIZED_BOOK", "OPEN_HTML_FULLTEXT") })
            if ($readableFulltexts.Count -lt 2) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("final component $($request.component_id) has fewer than two readable full texts") }
        }
    }

    foreach ($coverage in $algorithmCoverage) { if ($requestIds -notcontains $coverage.request_id) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("orphan coverage $($coverage.coverage_id)") } }

    $paperDir = Join-Path $root "research\library\papers"
    $paperFiles = if (Test-Path -LiteralPath $paperDir) { @(Get-ChildItem -LiteralPath $paperDir -File -Recurse -Force | Where-Object { $_.Name -ne ".gitkeep" }) } else { @() }
    foreach ($paperFile in $paperFiles) {
        $relativePaper = (Get-ProjectRelativePath $root $paperFile.FullName).Replace('\', '/')
        $indexMatch = @($libraryRows | Where-Object { ([string]$_.local_path).Replace('\', '/') -eq $relativePaper -and $_.download_status -eq "DOWNLOADED" })
        if ($indexMatch.Count -ne 1 -or $paperFile.Length -le 5) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("orphan or invalid paper $relativePaper"); continue }
        $headerBytes = [IO.File]::ReadAllBytes($paperFile.FullName)[0..4]
        $pdfHeader = [Text.Encoding]::ASCII.GetString($headerBytes)
        $actualHash = (Get-FileHash -LiteralPath $paperFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $logMatch = @($downloadRows | Where-Object { ([string]$_.local_path).Replace('\', '/') -eq $relativePaper -and $_.status -eq "DOWNLOADED" -and $_.sha256.ToLowerInvariant() -eq $actualHash })
        if ($pdfHeader -ne "%PDF-" -or $indexMatch[0].sha256.ToLowerInvariant() -ne $actualHash -or [string]$paperFile.Length -ne $indexMatch[0].size_bytes -or $logMatch.Count -ne 1) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("paper chain mismatch for $relativePaper") }
    }

    $bookDir = Join-Path $root "research\library\books"
    $bookFiles = @(Get-ChildItem -LiteralPath $bookDir -File -Force | Where-Object { $_.Name -notin @(".gitkeep", "book-index.csv") })
    foreach ($bookFile in $bookFiles) {
        $relativeBook = (Get-ProjectRelativePath $root $bookFile.FullName).Replace('\', '/')
        $bookMatch = @($bookRows | Where-Object { ([string]$_.local_path).Replace('\', '/') -eq $relativeBook })
        if ($bookMatch.Count -ne 1 -or $bookMatch[0].status -ne "AUTHORIZED" -or $bookMatch[0].license_or_access_note -match 'ACCESS_UNVERIFIED' -or $bookMatch[0].sha256 -notmatch '^[0-9a-fA-F]{64}$') { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("book access or index invalid for $relativeBook"); continue }
        $actualBookHash = (Get-FileHash -LiteralPath $bookFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($bookMatch[0].sha256.ToLowerInvariant() -ne $actualBookHash -or [string]$bookFile.Length -ne $bookMatch[0].size_bytes) { $algorithmEvidenceOk = $false; $algorithmEvidenceDetails.Add("book hash mismatch for $relativeBook") }
    }
} catch {
    $algorithmEvidenceOk = $false
    $algorithmEvidenceDetails.Add($_.Exception.Message)
}

$g2MarkedPass = @($gateRows | Where-Object { $_.gate -eq 2 -and $_.status -eq "PASS" }).Count -eq 1
$algorithmDetail = if ($algorithmEvidenceDetails.Count -eq 0) { "Algorithm requests, searches, coverage, sources and plan versions form a complete chain" } else { ($algorithmEvidenceDetails | Sort-Object -Unique) -join "; " }
if (($planStatus -eq "FROZEN" -or $g2MarkedPass) -and -not $algorithmEvidenceOk) {
    Add-Check "algorithm-evidence-readiness" "FAIL" $algorithmDetail
} else {
    Add-ReadinessCheck "algorithm-evidence-readiness" $algorithmEvidenceOk $algorithmDetail
}

$claimRows = @(Import-Csv -LiteralPath (Join-Path $root "reports\claim-audit.csv") -Encoding UTF8)
$writingRows = @(Import-Csv -LiteralPath (Join-Path $root "writing\claim-evidence-matrix.csv") -Encoding UTF8)
$claimIds = @($claimRows | ForEach-Object { $_.claim_id })
$writingClaimIds = @($writingRows | ForEach-Object { $_.claim_id })
$claimCrossReferenceOk = $claimRows.Count -gt 0 -and $writingRows.Count -gt 0 -and @($claimIds | Sort-Object -Unique).Count -eq $claimIds.Count -and @(Compare-Object @($claimIds | Sort-Object -Unique) @($writingClaimIds | Sort-Object -Unique)).Count -eq 0
foreach ($claimRow in $claimRows) {
    if ($claimRow.status -notin @("PASS", "CONDITIONAL") -or (Test-PlaceholderValue $claimRow.allowed_wording)) { $claimCrossReferenceOk = $false }
    foreach ($id in (Split-IdentifierList $claimRow.artifact_ids)) { if ($verifiedArtifactIds -notcontains $id) { $claimCrossReferenceOk = $false } }
    foreach ($id in (Split-IdentifierList $claimRow.literature_evidence_ids)) { if ($evidenceIds -notcontains $id) { $claimCrossReferenceOk = $false } }
    foreach ($id in (Split-IdentifierList $claimRow.verification_ids)) {
        $verificationRecord = @($reportVerificationRecords | Where-Object { $_.id -eq $id })
        if ($verificationRecord.Count -ne 1 -or $verificationRecord[0].status -notin @("PASS", "CONDITIONAL")) { $claimCrossReferenceOk = $false }
        if ($verificationRecord.Count -eq 1 -and $verificationRecord[0].status -eq "CONDITIONAL" -and $claimRow.status -ne "CONDITIONAL") { $claimCrossReferenceOk = $false }
    }
}
foreach ($writingRow in $writingRows) {
    if ($writingRow.status -notin @("PASS", "CONDITIONAL") -or (Test-PlaceholderValue $writingRow.allowed_wording)) { $claimCrossReferenceOk = $false }
    foreach ($id in (Split-IdentifierList $writingRow.artifact_ids)) { if ($verifiedArtifactIds -notcontains $id) { $claimCrossReferenceOk = $false } }
    foreach ($id in (Split-IdentifierList $writingRow.literature_evidence_ids)) { if ($evidenceIds -notcontains $id) { $claimCrossReferenceOk = $false } }
    foreach ($id in (Split-IdentifierList $writingRow.verification_ids)) {
        $verificationRecord = @($reportVerificationRecords | Where-Object { $_.id -eq $id })
        if ($verificationRecord.Count -ne 1 -or $verificationRecord[0].status -notin @("PASS", "CONDITIONAL")) { $claimCrossReferenceOk = $false }
        if ($verificationRecord.Count -eq 1 -and $verificationRecord[0].status -eq "CONDITIONAL" -and $writingRow.status -ne "CONDITIONAL") { $claimCrossReferenceOk = $false }
    }
    $auditMatch = @($claimRows | Where-Object { $_.claim_id -eq $writingRow.claim_id })
    if ($auditMatch.Count -ne 1 -or $auditMatch[0].task_id -ne $writingRow.task_id -or $auditMatch[0].proposed_claim -ne $writingRow.claim_text -or $auditMatch[0].status -ne $writingRow.status -or $auditMatch[0].allowed_wording -ne $writingRow.allowed_wording) { $claimCrossReferenceOk = $false }
}
Add-ReadinessCheck "claim-cross-references" $claimCrossReferenceOk "Writing claims must match claim audit and resolve to verified artifacts, literature and verification IDs"

$secretNameRegex = '(^|\\)(\.env($|\.)|credentials\.json$|secrets?\.|.*\.(pem|key|p12|pfx)$)'
$secretFiles = @(
    Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and
            $_.FullName -notmatch '[\\/]releases[\\/]' -and
            $_.FullName -match $secretNameRegex
        }
)

if ($secretFiles.Count -gt 0) {
    $relativeSecrets = $secretFiles | ForEach-Object { Get-ProjectRelativePath $root $_.FullName }
    Add-Check "secret-file-names" "WARN" ("Possible secret files found; packaging will exclude them: " + ($relativeSecrets -join ", "))
} else {
    Add-Check "secret-file-names" "PASS" "No common secret filenames were found"
}

$python = Get-Command python -ErrorAction SilentlyContinue
if ($SkipSelfTests -and $Mode -eq "Release") {
    Add-Check "python-syntax" "FAIL" "Release mode cannot skip verifier self-tests"
    Add-Check "workflow-contract-tests" "FAIL" "Release mode cannot skip verifier self-tests"
    Add-Check "documented-smoke-entry" "FAIL" "Release mode cannot skip verifier self-tests"
} elseif ($SkipSelfTests) {
    Add-Check "python-syntax" "PASS" "Skipped only for an isolated Snapshot-mode verifier behavior fixture"
    Add-Check "workflow-contract-tests" "PASS" "Skipped only for an isolated Snapshot-mode verifier behavior fixture"
    Add-Check "documented-smoke-entry" "PASS" "Skipped only for an isolated Snapshot-mode verifier behavior fixture"
} elseif ($null -ne $python) {
    & $python.Source -m compileall -q (Join-Path $root "src") (Join-Path $root "tests")
    if ($LASTEXITCODE -eq 0) {
        Add-Check "python-syntax" "PASS" "src/ and tests/ passed Python compilation"
    } else {
        Add-Check "python-syntax" "FAIL" "Python compilation failed"
    }
    Push-Location $root
    try {
        & $python.Source -m unittest discover -s "tests" -p "test_workflow_contract.py"
        $workflowTestOk = $LASTEXITCODE -eq 0
        & $python.Source -c "from src.main import main; raise SystemExit(0 if main() == 0 else 1)"
        $smokeOk = $LASTEXITCODE -eq 0
    } finally {
        Pop-Location
    }
    Add-ReadinessCheck "workflow-contract-tests" $workflowTestOk "Workflow contract unit tests must pass"
    Add-ReadinessCheck "documented-smoke-entry" $smokeOk "The documented src.main entry point must run successfully"
} else {
    Add-ReadinessCheck "python-syntax" $false "python command was not found; compilation was skipped"
    Add-ReadinessCheck "workflow-contract-tests" $false "python command was not found; tests were skipped"
    Add-ReadinessCheck "documented-smoke-entry" $false "python command was not found; smoke entry was skipped"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = Join-Path $root "outputs\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$reportPath = Join-Path $logDir "project-check-$timestamp.json"
$failCount = @($results | Where-Object { $_.status -eq "FAIL" }).Count
$warnCount = @($results | Where-Object { $_.status -eq "WARN" }).Count
$payload = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    mode = $Mode
    project = Split-Path -Leaf $root
    plan_status = $planStatus
    preprocessing_status = $preprocessStatus
    fail_count = $failCount
    warning_count = $warnCount
    checks = $results
}
$json = $payload | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText($reportPath, $json, [Text.UTF8Encoding]::new($false))

$results | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "Check report: $reportPath"
Write-Host "Failures: $failCount; warnings: $warnCount"

if ($failCount -gt 0) {
    exit 1
}
exit 0
