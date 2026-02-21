#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Orchestrator - Check for Updates

.DESCRIPTION
    Checks GitHub API for latest release and compares with installed version.
    Implements rate limiting: max 1 check per hour.

.PARAMETER Force
    Force check regardless of rate limiting

.PARAMETER Silent
    Output only JSON (no colored messages)

.OUTPUTS
    JSON object with update status:
    {
      "updateAvailable": true/false,
      "currentVersion": "10.1.0",
      "latestVersion": "10.2.0",
      "releaseNotes": "...",
      "publishedAt": "...",
      "checkedAt": "...",
      "error": null or error message
    }

.EXAMPLE
    .\check-update.ps1
    Check for updates with rate limiting

.EXAMPLE
    .\check-update.ps1 -Force
    Force check bypassing rate limit

.EXAMPLE
    .\check-update.ps1 -Silent
    Output only JSON for programmatic use

.NOTES
    Version: 10.1.0
    Rate Limit: 1 check per hour (stored in VERSION.json.lastCheck)
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Silent
)

# ====================================================================
# CONFIGURATION
# ====================================================================
$script:ORCHESTRATOR_DIR = "$env:USERPROFILE\.claude\orchestrator"
$script:VERSION_FILE = Join-Path $script:ORCHESTRATOR_DIR "VERSION.json"
$script:RATE_LIMIT_HOURS = 1

# GitHub API configuration
$script:GITHUB_API = "https://api.github.com/repos/eroslifestyle/Claude-Orchestrator-Plugin/releases/latest"

# ====================================================================
# HELPER FUNCTIONS
# ====================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    if ($Silent) { return }

    $color = switch ($Level) {
        "INFO"  { "Cyan" }
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }

    Write-Host "  [$Level] $Message" -ForegroundColor $color
}

function Invoke-GitHubApi {
    param([string]$Url)

    try {
        # Use TLS 1.2 for GitHub API
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $headers = @{
            "User-Agent" = "Claude-Orchestrator-Updater/10.1.0"
            "Accept" = "application/vnd.github.v3+json"
        }

        # Add GITHUB_TOKEN if available (for higher rate limits)
        if ($env:GITHUB_TOKEN) {
            $headers["Authorization"] = "token $env:GITHUB_TOKEN"
        }

        $response = Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -ErrorAction Stop
        return $response
    } catch {
        throw "GitHub API error: $_"
    }
}

function Compare-Versions {
    param([string]$Version1, [string]$Version2)

    # Parse versions (e.g., "10.1.0" -> [10, 1, 0])
    $v1 = $Version1 -split '\.' | ForEach-Object { [int]$_ }
    $v2 = $Version2 -split '\.' | ForEach-Object { [int]$_ }

    # Pad to same length
    $maxLen = [Math]::Max($v1.Count, $v2.Count)
    while ($v1.Count -lt $maxLen) { $v1 += 0 }
    while ($v2.Count -lt $maxLen) { $v2 += 0 }

    # Compare each segment
    for ($i = 0; $i -lt $maxLen; $i++) {
        if ($v1[$i] -lt $v2[$i]) { return -1 }  # v1 < v2 (update available)
        if ($v1[$i] -gt $v2[$i]) { return 1 }   # v1 > v2 (ahead of release)
    }

    return 0  # Equal
}

# ====================================================================
# MAIN LOGIC
# ====================================================================

$result = @{
    updateAvailable = $false
    currentVersion = "unknown"
    latestVersion = "unknown"
    releaseNotes = $null
    publishedAt = $null
    checkedAt = (Get-Date -Format "o")
    error = $null
}

try {
    # ----------------------------------------------------------------
    # Step 1: Read installed version
    # ----------------------------------------------------------------
    if (-not (Test-Path $script:VERSION_FILE)) {
        throw "VERSION.json not found at $script:VERSION_FILE"
    }

    $versionData = Get-Content -Path $script:VERSION_FILE -Raw | ConvertFrom-Json
    $result.currentVersion = $versionData.version

    Write-Log "Current version: $($result.currentVersion)"

    # ----------------------------------------------------------------
    # Step 2: Check rate limiting
    # ----------------------------------------------------------------
    $lastCheck = $versionData.updateCheck.lastCheck
    if ($lastCheck -and -not $Force) {
        $lastCheckTime = [DateTime]::Parse($lastCheck)
        $timeSinceCheck = (Get-Date) - $lastCheckTime

        if ($timeSinceCheck.TotalHours -lt $script:RATE_LIMIT_HOURS) {
            $remainingMinutes = [int]($script:RATE_LIMIT_HOURS * 60 - $timeSinceCheck.TotalMinutes)
            Write-Log "Rate limit: skipping check ($remainingMinutes min remaining)" -Level "WARN"
            Write-Log "Use -Force to bypass rate limit" -Level "INFO"

            # Return cached result if available
            $cachedResult = $versionData.updateCheck.cachedResult
            if ($cachedResult) {
                $result = $cachedResult
            }
            $result.error = "Rate limited - use -Force to bypass"

            # Output JSON and exit
            $result | ConvertTo-Json -Depth 10
            exit 0
        }
    }

    # ----------------------------------------------------------------
    # Step 3: Call GitHub API
    # ----------------------------------------------------------------
    Write-Log "Checking GitHub for updates..."

    $release = Invoke-GitHubApi -Url $script:GITHUB_API

    $result.latestVersion = $release.tag_name -replace '^v', ''  # Remove 'v' prefix if present
    $result.releaseNotes = $release.body
    $result.publishedAt = $release.published_at

    Write-Log "Latest version: $($result.latestVersion)" -Level "OK"
    Write-Log "Published at: $($result.publishedAt)"

    # ----------------------------------------------------------------
    # Step 4: Compare versions
    # ----------------------------------------------------------------
    $comparison = Compare-Versions -Version1 $result.currentVersion -Version2 $result.latestVersion

    if ($comparison -lt 0) {
        $result.updateAvailable = $true
        Write-Log "Update available!" -Level "OK"
    } elseif ($comparison -gt 0) {
        $result.updateAvailable = $false
        Write-Log "Running pre-release or dev version" -Level "WARN"
    } else {
        $result.updateAvailable = $false
        Write-Log "Already up to date" -Level "OK"
    }

    # ----------------------------------------------------------------
    # Step 5: Update VERSION.json with last check time and cache result
    # ----------------------------------------------------------------
    $versionData.updateCheck.lastCheck = $result.checkedAt
    $versionData.updateCheck.cachedResult = @{
        updateAvailable = $result.updateAvailable
        latestVersion = $result.latestVersion
        publishedAt = $result.publishedAt
    }

    $versionData | ConvertTo-Json -Depth 10 | Set-Content -Path $script:VERSION_FILE -Encoding UTF8

} catch {
    $result.error = $_.Exception.Message
    Write-Log "Error: $_" -Level "ERROR"
}

# ====================================================================
# OUTPUT
# ====================================================================

if ($Silent) {
    # Output only JSON
    $result | ConvertTo-Json -Depth 10
} else {
    Write-Host ""
    Write-Host "  Result:" -ForegroundColor White
    $result | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
}
