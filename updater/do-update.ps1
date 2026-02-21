#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Orchestrator - Perform Update

.DESCRIPTION
    Executes the update process:
    1. Creates backup in ~/.claude/backups/orchestrator/v{current}/
    2. Downloads latest release from GitHub OR performs git pull
    3. Runs setup.ps1 to reinstall
    4. Updates VERSION.json
    5. Verifies installation
    Supports automatic rollback if update fails.

.PARAMETER Version
    Specific version to update to (default: latest)

.PARAMETER Force
    Force update even if already up to date

.PARAMETER SkipBackup
    Skip creating backup (not recommended)

.PARAMETER Silent
    Minimal output for automation

.EXAMPLE
    .\do-update.ps1
    Update to latest version

.EXAMPLE
    .\do-update.ps1 -Version "10.2.0"
    Update to specific version

.EXAMPLE
    .\do-update.ps1 -SkipBackup
    Update without backup (risky)

.NOTES
    Version: 10.1.0
    Supports: GitHub releases, git pull, rollback
#>

[CmdletBinding()]
param(
    [string]$Version,
    [switch]$Force,
    [switch]$SkipBackup,
    [switch]$Silent
)

# ====================================================================
# CONFIGURATION
# ====================================================================
$script:ORCHESTRATOR_VERSION = "10.1.0"
$script:CLAUDE_DIR = "$env:USERPROFILE\.claude"
$script:ORCHESTRATOR_DIR = "$env:CLAUDE_DIR\orchestrator"
$script:BACKUP_DIR = "$env:CLAUDE_DIR\backups\orchestrator"
$script:SKILLS_DIR = "$env:CLAUDE_DIR\skills\orchestrator"
$script:AGENTS_DIR = "$env:CLAUDE_DIR\agents"
$script:VERSION_FILE = Join-Path $script:ORCHESTRATOR_DIR "VERSION.json"

# GitHub configuration
$script:GITHUB_REPO = "eroslifestyle/Claude-Orchestrator-Plugin"
$script:GITHUB_RELEASES = "https://api.github.com/repos/$script:GITHUB_REPO/releases"
$script:GITHUB_REPO_URL = "https://github.com/$script:GITHUB_REPO"

# Script location (distribution or installed)
$script:SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:DIST_DIR = Split-Path -Parent $script:SCRIPT_DIR

# Update state
$script:UpdateSuccess = $false
$script:BackupPath = $null
$script:PreviousVersion = $null

# ====================================================================
# HELPER FUNCTIONS
# ====================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    if ($Silent -and $Level -ne "ERROR") { return }

    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "INFO"  { "Cyan" }
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "STEP"  { "Magenta" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Invoke-GitHubApi {
    param([string]$Url)

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $headers = @{
            "User-Agent" = "Claude-Orchestrator-Updater/$script:ORCHESTRATOR_VERSION"
            "Accept" = "application/vnd.github.v3+json"
        }

        if ($env:GITHUB_TOKEN) {
            $headers["Authorization"] = "token $env:GITHUB_TOKEN"
        }

        return Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -ErrorAction Stop
    } catch {
        throw "GitHub API error: $_"
    }
}

function Compare-Versions {
    param([string]$Version1, [string]$Version2)

    $v1 = $Version1 -split '\.' | ForEach-Object { [int]$_ }
    $v2 = $Version2 -split '\.' | ForEach-Object { [int]$_ }

    $maxLen = [Math]::Max($v1.Count, $v2.Count)
    while ($v1.Count -lt $maxLen) { $v1 += 0 }
    while ($v2.Count -lt $maxLen) { $v2 += 0 }

    for ($i = 0; $i -lt $maxLen; $i++) {
        if ($v1[$i] -lt $v2[$i]) { return -1 }
        if ($v1[$i] -gt $v2[$i]) { return 1 }
    }
    return 0
}

function New-Backup {
    param([string]$CurrentVersion)

    if ($SkipBackup) {
        Write-Log "Backup skipped (--SkipBackup)" -Level "WARN"
        return $null
    }

    $backupPath = Join-Path $script:BACKUP_DIR "v$CurrentVersion"

    if (Test-Path $backupPath) {
        Write-Log "Backup already exists: $backupPath" -Level "WARN"
        return $backupPath
    }

    Write-Log "Creating backup at: $backupPath" -Level "STEP"

    # Create backup directory
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null

    # Backup skills
    if (Test-Path $script:SKILLS_DIR) {
        $skillsBackup = Join-Path $backupPath "skills"
        Copy-Item -Path $script:SKILLS_DIR -Destination $skillsBackup -Recurse -Force
        Write-Log "  Backed up skills"
    }

    # Backup agents
    if (Test-Path $script:AGENTS_DIR) {
        $agentsBackup = Join-Path $backupPath "agents"
        Copy-Item -Path $script:AGENTS_DIR -Destination $agentsBackup -Recurse -Force
        Write-Log "  Backed up agents"
    }

    # Backup VERSION.json
    if (Test-Path $script:VERSION_FILE) {
        Copy-Item -Path $script:VERSION_FILE -Destination (Join-Path $backupPath "VERSION.json") -Force
        Write-Log "  Backed up VERSION.json"
    }

    # Create backup manifest
    $manifest = @{
        version = $CurrentVersion
        backupDate = (Get-Date -Format "o")
        skillsPath = $script:SKILLS_DIR
        agentsPath = $script:AGENTS_DIR
    }
    $manifest | ConvertTo-Json | Set-Content -Path (Join-Path $backupPath "manifest.json")

    Write-Log "Backup completed successfully" -Level "OK"
    return $backupPath
}

function Restore-Backup {
    param([string]$BackupPath)

    if (-not $BackupPath -or -not (Test-Path $BackupPath)) {
        Write-Log "No valid backup to restore" -Level "ERROR"
        return $false
    }

    Write-Log "Restoring from backup: $BackupPath" -Level "STEP"

    try {
        # Restore skills
        $skillsBackup = Join-Path $BackupPath "skills"
        if (Test-Path $skillsBackup) {
            if (Test-Path $script:SKILLS_DIR) {
                Remove-Item -Path $script:SKILLS_DIR -Recurse -Force
            }
            Copy-Item -Path $skillsBackup -Destination $script:SKILLS_DIR -Recurse -Force
            Write-Log "  Restored skills"
        }

        # Restore agents
        $agentsBackup = Join-Path $BackupPath "agents"
        if (Test-Path $agentsBackup) {
            if (Test-Path $script:AGENTS_DIR) {
                Remove-Item -Path $script:AGENTS_DIR -Recurse -Force
            }
            Copy-Item -Path $agentsBackup -Destination $script:AGENTS_DIR -Recurse -Force
            Write-Log "  Restored agents"
        }

        # Restore VERSION.json
        $versionBackup = Join-Path $BackupPath "VERSION.json"
        if (Test-Path $versionBackup) {
            Copy-Item -Path $versionBackup -Destination $script:VERSION_FILE -Force
            Write-Log "  Restored VERSION.json"
        }

        Write-Log "Rollback completed successfully" -Level "OK"
        return $true

    } catch {
        Write-Log "Rollback failed: $_" -Level "ERROR"
        return $false
    }
}

function Update-ViaGit {
    param([string]$TargetDir)

    Write-Log "Attempting git pull update..." -Level "STEP"

    Push-Location $TargetDir

    try {
        # Check if it's a git repo
        $isGitRepo = Test-Path -Path ".git"

        if (-not $isGitRepo) {
            Write-Log "Not a git repository, falling back to download" -Level "WARN"
            return $false
        }

        # Fetch and pull
        git fetch origin --quiet
        $currentBranch = git rev-parse --abbrev-ref HEAD

        if ($Version) {
            # Checkout specific tag
            git checkout "v$Version" --quiet 2>$null
            if ($LASTEXITCODE -ne 0) {
                git checkout $Version --quiet 2>$null
            }
        } else {
            git pull origin $currentBranch --quiet
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Git pull successful" -Level "OK"
            return $true
        } else {
            Write-Log "Git pull failed" -Level "WARN"
            return $false
        }

    } catch {
        Write-Log "Git error: $_" -Level "WARN"
        return $false
    } finally {
        Pop-Location
    }
}

function Update-ViaDownload {
    param([string]$TargetVersion)

    Write-Log "Downloading release v$TargetVersion..." -Level "STEP"

    $downloadDir = Join-Path $env:TEMP "orchestrator-update-$(Get-Random)"
    New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null

    try {
        # Get release info
        $releaseUrl = if ($TargetVersion) {
            "$script:GITHUB_RELEASES/tags/v$TargetVersion"
        } else {
            "$script:GITHUB_RELEASES/latest"
        }

        $release = Invoke-GitHubApi -Url $releaseUrl
        $downloadVersion = $release.tag_name -replace '^v', ''

        # Find ZIP asset
        $zipAsset = $release.assets | Where-Object { $_.name -like "*.zip" -and $_.name -like "*orchestrator*" } | Select-Object -First 1

        if (-not $zipAsset) {
            # Fallback to source archive
            $zipUrl = "https://github.com/$script:GITHUB_REPO/archive/refs/tags/v$downloadVersion.zip"
        } else {
            $zipUrl = $zipAsset.browser_download_url
        }

        Write-Log "  Downloading from: $zipUrl"

        # Download ZIP
        $zipPath = Join-Path $downloadDir "update.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

        Write-Log "  Extracting..."

        # Extract
        $extractDir = Join-Path $downloadDir "extracted"
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

        # Find extracted directory (usually has version suffix)
        $sourceDir = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1

        if (-not $sourceDir) {
            throw "Failed to extract update package"
        }

        Write-Log "  Extracted to: $($sourceDir.FullName)"

        # Copy to distribution directory
        if (Test-Path $script:DIST_DIR) {
            # Copy new files
            Get-ChildItem -Path $sourceDir.FullName -Recurse | ForEach-Object {
                $relativePath = $_.FullName.Substring($sourceDir.FullName.Length + 1)
                $destPath = Join-Path $script:DIST_DIR $relativePath

                if ($_.PSIsContainer) {
                    New-Item -Path $destPath -ItemType Directory -Force | Out-Null
                } else {
                    $destDir = Split-Path -Parent $destPath
                    if (-not (Test-Path $destDir)) {
                        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                    }
                    Copy-Item -Path $_.FullName -Destination $destPath -Force
                }
            }
        }

        Write-Log "Download update completed" -Level "OK"
        return $true

    } catch {
        Write-Log "Download failed: $_" -Level "ERROR"
        return $false
    } finally {
        # Cleanup temp directory
        if (Test-Path $downloadDir) {
            Remove-Item -Path $downloadDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-Setup {
    param([string]$SetupDir)

    $setupScript = Join-Path $SetupDir "setup.ps1"

    if (-not (Test-Path $setupScript)) {
        Write-Log "setup.ps1 not found in $SetupDir" -Level "WARN"
        return $false
    }

    Write-Log "Running setup.ps1..." -Level "STEP"

    try {
        # Run setup with silent mode and default components
        $result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setupScript -Silent -Components "1,2,3" 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Setup completed successfully" -Level "OK"
            return $true
        } else {
            Write-Log "Setup failed with exit code: $LASTEXITCODE" -Level "ERROR"
            return $false
        }

    } catch {
        Write-Log "Setup error: $_" -Level "ERROR"
        return $false
    }
}

function Update-VersionFile {
    param([string]$NewVersion)

    if (-not (Test-Path $script:VERSION_FILE)) {
        Write-Log "VERSION.json not found" -Level "WARN"
        return
    }

    Write-Log "Updating VERSION.json..." -Level "STEP"

    $versionData = Get-Content -Path $script:VERSION_FILE -Raw | ConvertFrom-Json
    $versionData.version = $NewVersion
    $versionData.updateCheck.lastCheck = $null
    $versionData.updateCheck.cachedResult = $null

    $versionData | ConvertTo-Json -Depth 10 | Set-Content -Path $script:VERSION_FILE -Encoding UTF8

    Write-Log "VERSION.json updated to $NewVersion" -Level "OK"
}

function Test-Installation {
    $skillPath = Join-Path $script:SKILLS_DIR "SKILL.md"

    if (-not (Test-Path $skillPath)) {
        Write-Log "Installation verification failed: SKILL.md not found" -Level "ERROR"
        return $false
    }

    $content = Get-Content -Path $skillPath -Raw
    if ($content -notmatch "name:\s*orchestrator") {
        Write-Log "Installation verification failed: Invalid SKILL.md" -Level "ERROR"
        return $false
    }

    Write-Log "Installation verified successfully" -Level "OK"
    return $true
}

# ====================================================================
# MAIN EXECUTION
# ====================================================================

try {
    Write-Log "========================================" -Level "INFO"
    Write-Log "Claude Orchestrator Update Script" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    Write-Log ""

    # ----------------------------------------------------------------
    # Step 1: Read current version
    # ----------------------------------------------------------------
    Write-Log "Step 1: Checking current installation" -Level "STEP"

    if (-not (Test-Path $script:VERSION_FILE)) {
        Write-Log "VERSION.json not found. Is orchestrator installed?" -Level "ERROR"
        exit 1
    }

    $versionData = Get-Content -Path $script:VERSION_FILE -Raw | ConvertFrom-Json
    $script:PreviousVersion = $versionData.version

    Write-Log "  Current version: $script:PreviousVersion"

    # ----------------------------------------------------------------
    # Step 2: Check for updates
    # ----------------------------------------------------------------
    Write-Log "Step 2: Checking for updates" -Level "STEP"

    $targetVersion = $Version

    if (-not $targetVersion) {
        # Get latest version
        $latestRelease = Invoke-GitHubApi -Url "$script:GITHUB_RELEASES/latest"
        $targetVersion = $latestRelease.tag_name -replace '^v', ''
    }

    Write-Log "  Target version: $targetVersion"

    # Compare versions
    $comparison = Compare-Versions -Version1 $script:PreviousVersion -Version2 $targetVersion

    if ($comparison -ge 0 -and -not $Force) {
        Write-Log "Already up to date (or ahead). Use -Force to update anyway." -Level "OK"
        exit 0
    }

    # ----------------------------------------------------------------
    # Step 3: Create backup
    # ----------------------------------------------------------------
    Write-Log "Step 3: Creating backup" -Level "STEP"
    $script:BackupPath = New-Backup -CurrentVersion $script:PreviousVersion

    # ----------------------------------------------------------------
    # Step 4: Download/Update
    # ----------------------------------------------------------------
    Write-Log "Step 4: Downloading update" -Level "STEP"

    $updateSuccess = $false

    # Try git first if distribution dir is a git repo
    if (Test-Path (Join-Path $script:DIST_DIR ".git")) {
        $updateSuccess = Update-ViaGit -TargetDir $script:DIST_DIR
    }

    # Fallback to download if git failed
    if (-not $updateSuccess) {
        $updateSuccess = Update-ViaDownload -TargetVersion $targetVersion
    }

    if (-not $updateSuccess) {
        throw "Failed to download update"
    }

    # ----------------------------------------------------------------
    # Step 5: Run setup
    # ----------------------------------------------------------------
    Write-Log "Step 5: Running installation" -Level "STEP"

    $setupSuccess = Invoke-Setup -SetupDir $script:DIST_DIR

    if (-not $setupSuccess) {
        throw "Setup failed"
    }

    # ----------------------------------------------------------------
    # Step 6: Update VERSION.json
    # ----------------------------------------------------------------
    Write-Log "Step 6: Updating version tracking" -Level "STEP"
    Update-VersionFile -NewVersion $targetVersion

    # ----------------------------------------------------------------
    # Step 7: Verify installation
    # ----------------------------------------------------------------
    Write-Log "Step 7: Verifying installation" -Level "STEP"

    if (-not (Test-Installation)) {
        throw "Installation verification failed"
    }

    # ----------------------------------------------------------------
    # Success!
    # ----------------------------------------------------------------
    $script:UpdateSuccess = $true

    Write-Log ""
    Write-Log "========================================" -Level "OK"
    Write-Log "UPDATE SUCCESSFUL" -Level "OK"
    Write-Log "  From: $script:PreviousVersion" -Level "OK"
    Write-Log "  To:   $targetVersion" -Level "OK"
    Write-Log "========================================" -Level "OK"

    exit 0

} catch {
    Write-Log ""
    Write-Log "========================================" -Level "ERROR"
    Write-Log "UPDATE FAILED: $_" -Level "ERROR"
    Write-Log "========================================" -Level "ERROR"

    # Attempt rollback
    if ($script:BackupPath -and -not $script:UpdateSuccess) {
        Write-Log ""
        Write-Log "Attempting rollback..." -Level "WARN"

        if (Restore-Backup -BackupPath $script:BackupPath) {
            Write-Log "Rollback successful. Previous version restored." -Level "OK"
        } else {
            Write-Log "Rollback FAILED! Manual restoration may be required." -Level "ERROR"
            Write-Log "Backup location: $script:BackupPath" -Level "ERROR"
        }
    }

    exit 1
}
