<#
.SYNOPSIS
    Claude Orchestrator Plugin Installer for Windows

.DESCRIPTION
    Installs the Claude Orchestrator Plugin (V12.0.3) including:
    - 43 Agent definitions (6 core + 22 L1 + 15 L2)
    - Orchestrator skill with 16 documentation files
    - 11 Rules files (common, python, typescript, go)
    - Learnings system (instincts.json)
    - 3 Templates, 4 Workflows
    - Root CLAUDE.md instructions

.PARAMETER InstallPath
    Target installation directory. Default: $env:USERPROFILE\.claude

.PARAMETER Silent
    Run without user interaction (automated installation)

.PARAMETER Backup
    Create backup of existing installation before overwriting

.PARAMETER BackupPath
    Custom backup location. Default: $InstallPath\backup_<timestamp>

.PARAMETER SourcePath
    Source package directory. Default: script location

.PARAMETER Force
    Overwrite existing files without prompting

.PARAMETER NoVerify
    Skip post-installation verification

.EXAMPLE
    .\install.ps1
    Interactive installation with default settings

.EXAMPLE
    .\install.ps1 -Silent -Backup
    Silent installation with automatic backup

.EXAMPLE
    .\install.ps1 -InstallPath "D:\Claude" -Force
    Install to custom location, overwrite existing

.NOTES
    Version: 1.0.0
    Author: Claude Orchestrator Team
    Requires: PowerShell 5.1+ or PowerShell Core 7+
    Minimum OS: Windows 10/11
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$InstallPath = "$env:USERPROFILE\.claude",
    [switch]$Silent,
    [switch]$Backup,
    [string]$BackupPath = "",
    [string]$SourcePath = "",
    [switch]$Force,
    [switch]$NoVerify
)

#region Constants
$SCRIPT_VERSION = "1.0.0"
$PLUGIN_VERSION = "12.0.3"
$MIN_PYTHON_VERSION = "3.10"
$MIN_PS_VERSION = "5.1"

# Directories to install (relative to source)
$INCLUDE_DIRS = @(
    "agents",
    "skills",
    "rules",
    "learnings",
    "templates",
    "workflows"
)

# Files to exclude (patterns)
$EXCLUDE_PATTERNS = @(
    ".credentials.json",
    "*.env",
    ".env*",
    "stats-cache.json",
    "history.jsonl",
    "NUL",
    "*.tmp",
    "temp_*",
    "*_temp.*",
    ".git",
    ".gitignore",
    "debug",
    "backups",
    "paste-cache",
    "*.bak",
    "*.log"
)

# Files to include from root
$ROOT_FILES = @("CLAUDE.md")

# Color scheme
$COLORS = @{
    Header = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
    Step = "DarkCyan"
    Progress = "DarkGreen"
}
#endregion

#region Logging
$LogFile = ""
$LogBuffer = [System.Collections.ArrayList]::new()

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    [void]$LogBuffer.Add($logEntry)

    if ($LogFile) {
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )

    if (-not $Silent) {
        if ($NoNewline) {
            Write-Host $Message -ForegroundColor $Color -NoNewline
        } else {
            Write-Host $Message -ForegroundColor $Color
        }
    }
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "`n[STEP] $Message" -Color $COLORS.Step
    Write-Log $Message -Level "INFO"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "  [OK] $Message" -Color $COLORS.Success
    Write-Log $Message -Level "SUCCESS"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "  [WARN] $Message" -Color $COLORS.Warning
    Write-Log $Message -Level "WARN"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "  [ERROR] $Message" -Color $COLORS.Error
    Write-Log $Message -Level "ERROR"
}

function Write-Info {
    param([string]$Message)
    if (-not $Silent) {
        Write-ColorOutput "  $Message" -Color $COLORS.Info
    }
    Write-Log $Message -Level "INFO"
}
#endregion

#region Prerequisites
function Test-Prerequisites {
    Write-Step "Checking prerequisites..."

    $errors = @()

    # Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    $buildNumber = (Get-CimInstance Win32_OperatingSystem).BuildNumber
    if ($buildNumber -lt 10240) {
        $errors += "Windows 10/11 required. Build: $buildNumber"
        Write-Error "Windows 10/11 required (Build >= 10240). Current: $buildNumber"
    } else {
        Write-Success "Windows version OK (Build $buildNumber)"
    }

    # PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion -lt [version]$MIN_PS_VERSION) {
        $errors += "PowerShell $MIN_PS_VERSION+ required. Current: $psVersion"
        Write-Error "PowerShell $MIN_PS_VERSION+ required. Current: $psVersion"
    } else {
        Write-Success "PowerShell version OK ($psVersion)"
    }

    # Python (optional but recommended)
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        $pythonVersion = & python --version 2>&1
        Write-Success "Python found: $pythonVersion"
    } else {
        Write-Warning "Python not found (optional for MCP orchestrator)"
    }

    # Git (optional)
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitVersion = & git --version 2>&1
        Write-Success "Git found: $gitVersion"
    } else {
        Write-Warning "Git not found (optional for updates)"
    }

    # Claude Code CLI (optional)
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($claudeCmd) {
        Write-Success "Claude Code CLI found"
    } else {
        Write-Warning "Claude Code CLI not found (install after setup)"
    }

    # Administrator check (not required but informational)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Info "Running as Administrator"
    } else {
        Write-Info "Running as standard user (OK for user-level install)"
    }

    return ($errors.Count -eq 0)
}
#endregion

#region Backup
function New-InstallationBackup {
    param([string]$TargetPath)

    if (-not (Test-Path $TargetPath)) {
        Write-Info "No existing installation to backup"
        return $true
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    if ([string]::IsNullOrWhiteSpace($BackupPath)) {
        $BackupPath = Join-Path $TargetPath "backup_$timestamp"
    }

    Write-Step "Creating backup at: $BackupPath"

    try {
        # Create backup directory
        New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null

        # Backup critical directories only (not entire structure)
        $backupItems = @("agents", "skills", "rules", "learnings", "templates", "workflows", "CLAUDE.md")

        foreach ($item in $backupItems) {
            $source = Join-Path $TargetPath $item
            if (Test-Path $source) {
                $dest = Join-Path $BackupPath $item
                Copy-Item -Path $source -Destination $dest -Recurse -Force -ErrorAction Stop
                Write-Info "Backed up: $item"
            }
        }

        # Create backup manifest
        $manifest = @{
            Timestamp = $timestamp
            SourcePath = $TargetPath
            BackupPath = $BackupPath
            Items = $backupItems
            Version = $PLUGIN_VERSION
        }
        $manifest | ConvertTo-Json | Out-File (Join-Path $BackupPath "backup_manifest.json") -Encoding UTF8

        Write-Success "Backup completed"
        return $true
    }
    catch {
        Write-Error "Backup failed: $_"
        return $false
    }
}
#endregion

#region File Operations
function Should-ExcludeFile {
    param([string]$FilePath, [string]$FileName)

    foreach ($pattern in $EXCLUDE_PATTERNS) {
        if ($pattern.StartsWith("*")) {
            # Wildcard pattern
            if ($FileName -like $pattern) { return $true }
        } elseif ($pattern.Contains("*")) {
            if ($FileName -like $pattern) { return $true }
        } else {
            # Exact match
            if ($FileName -eq $pattern) { return $true }
        }
    }

    # Check path for excluded directories
    foreach ($excl in @("debug", "backups", "paste-cache", ".git")) {
        if ($FilePath -match [regex]::Escape($excl)) { return $true }
    }

    return $false
}

function Copy-WithProgress {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$DirName
    )

    Write-Info "Copying $DirName..."

    $sourcePath = Join-Path $SourceDir $DirName
    $targetPath = Join-Path $TargetDir $DirName

    if (-not (Test-Path $sourcePath)) {
        Write-Warning "Source directory not found: $DirName"
        return @{ Copied = 0; Skipped = 0; Errors = 0 }
    }

    # Get all files
    $files = Get-ChildItem -Path $sourcePath -Recurse -File -ErrorAction SilentlyContinue
    $totalFiles = $files.Count
    $copied = 0
    $skipped = 0
    $errors = 0

    if ($totalFiles -eq 0) {
        Write-Info "  No files in $DirName"
        return @{ Copied = 0; Skipped = 0; Errors = 0 }
    }

    # Create target directory structure
    $dirs = Get-ChildItem -Path $sourcePath -Recurse -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $relativeDir = $dir.FullName.Substring($sourcePath.Length).TrimStart('\', '/')
        $newDir = Join-Path $targetPath $relativeDir

        # Skip excluded directories
        $skipDir = $false
        foreach ($excl in @("debug", "backups", "paste-cache", ".git", "__pycache__", "node_modules")) {
            if ($relativeDir -match [regex]::Escape($excl)) {
                $skipDir = $true
                break
            }
        }

        if (-not $skipDir) {
            New-Item -Path $newDir -ItemType Directory -Force | Out-Null
        }
    }

    # Copy files with progress
    $progress = 0
    foreach ($file in $files) {
        $progress++
        $relativePath = $file.FullName.Substring($sourcePath.Length).TrimStart('\', '/')
        $targetFile = Join-Path $targetPath $relativePath

        # Check exclusion
        if (Should-ExcludeFile -FilePath $file.FullName -FileName $file.Name) {
            $skipped++
            continue
        }

        # Check directory exclusion in path
        $skipFile = $false
        foreach ($excl in @("debug", "backups", "paste-cache", ".git", "__pycache__", "node_modules")) {
            if ($relativePath -match [regex]::Escape($excl)) {
                $skipFile = $true
                break
            }
        }

        if ($skipFile) {
            $skipped++
            continue
        }

        try {
            $targetDir2 = Split-Path $targetFile -Parent
            if (-not (Test-Path $targetDir2)) {
                New-Item -Path $targetDir2 -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $file.FullName -Destination $targetFile -Force -ErrorAction Stop
            $copied++
        }
        catch {
            $errors++
            Write-Log "Failed to copy: $($file.FullName) - $_" -Level "ERROR"
        }

        # Progress update every 10% or every 10 files
        if (-not $Silent -and ($progress % [Math]::Max(1, [Math]::Floor($totalFiles / 10)) -eq 0 -or $progress % 10 -eq 0)) {
            $percent = [Math]::Floor(($progress / $totalFiles) * 100)
            Write-Progress -Activity "Copying $DirName" -Status "$progress / $totalFiles files" -PercentComplete $percent
        }
    }

    Write-Progress -Activity "Copying $DirName" -Completed

    Write-Info "  Copied: $copied, Skipped: $skipped, Errors: $errors"
    Write-Log "${DirName}: Copied=$copied, Skipped=$skipped, Errors=$errors" -Level "INFO"

    return @{ Copied = $copied; Skipped = $skipped; Errors = $errors }
}
#endregion

#region Verification
function Test-Installation {
    param([string]$TargetPath)

    Write-Step "Verifying installation..."

    $issues = @()
    $passed = 0

    # Check required directories
    $requiredDirs = @("agents", "skills\orchestrator", "rules", "learnings")
    foreach ($dir in $requiredDirs) {
        $path = Join-Path $TargetPath $dir
        if (Test-Path $path) {
            $fileCount = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue).Count
            Write-Success "$dir ($fileCount files)"
            $passed++
        } else {
            Write-Error "Missing directory: $dir"
            $issues += "Missing: $dir"
        }
    }

    # Check CLAUDE.md
    $claudeMd = Join-Path $TargetPath "CLAUDE.md"
    if (Test-Path $claudeMd) {
        Write-Success "CLAUDE.md present"
        $passed++
    } else {
        Write-Error "Missing CLAUDE.md"
        $issues += "Missing: CLAUDE.md"
    }

    # Check orchestrator SKILL.md
    $skillMd = Join-Path $TargetPath "skills\orchestrator\SKILL.md"
    if (Test-Path $skillMd) {
        $version = Select-String -Path $skillMd -Pattern "V(\d+\.\d+\.\d+)" -ErrorAction SilentlyContinue
        if ($version) {
            Write-Success "Orchestrator SKILL.md ($($version.Matches[0]))"
            $passed++
        } else {
            Write-Warning "Orchestrator SKILL.md (version not detected)"
            $passed++
        }
    } else {
        Write-Error "Missing orchestrator SKILL.md"
        $issues += "Missing: skills\orchestrator\SKILL.md"
    }

    # Check agents count
    $agentsPath = Join-Path $TargetPath "agents"
    if (Test-Path $agentsPath) {
        $agentFiles = Get-ChildItem -Path $agentsPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
        $agentCount = $agentFiles.Count
        if ($agentCount -ge 40) {
            Write-Success "Agent definitions ($agentCount files)"
            $passed++
        } else {
            Write-Warning "Agent definitions incomplete ($agentCount files, expected 43+)"
        }
    }

    # Check rules
    $rulesPath = Join-Path $TargetPath "rules"
    if (Test-Path $rulesPath) {
        $rulesFiles = Get-ChildItem -Path $rulesPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
        $rulesCount = $rulesFiles.Count
        if ($rulesCount -ge 10) {
            Write-Success "Rules files ($rulesCount files)"
            $passed++
        } else {
            Write-Warning "Rules incomplete ($rulesCount files, expected 11+)"
        }
    }

    $success = ($issues.Count -eq 0)

    return @{
        Success = $success
        Passed = $passed
        Issues = $issues
    }
}
#endregion

#region Rollback
function Invoke-Rollback {
    param(
        [string]$TargetPath,
        [string]$BackupLocation
    )

    Write-Step "Rolling back installation..."

    if ([string]::IsNullOrWhiteSpace($BackupLocation) -or -not (Test-Path $BackupLocation)) {
        Write-Error "No backup available for rollback"
        return $false
    }

    try {
        # Remove failed installation
        $dirsToClean = @("agents", "skills", "rules", "learnings", "templates", "workflows")
        foreach ($dir in $dirsToClean) {
            $path = Join-Path $TargetPath $dir
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # Restore from backup
        $backupItems = Get-ChildItem -Path $BackupLocation -ErrorAction SilentlyContinue
        foreach ($item in $backupItems) {
            if ($item.Name -ne "backup_manifest.json") {
                Copy-Item -Path $item.FullName -Destination $TargetPath -Recurse -Force
            }
        }

        Write-Success "Rollback completed"
        return $true
    }
    catch {
        Write-Error "Rollback failed: $_"
        return $false
    }
}
#endregion

#region Main Installation
function Install-ClaudeOrchestrator {
    param()

    $startTime = Get-Date
    $backupLocation = ""
    $rollbackNeeded = $false

    # Header
    Write-ColorOutput @"
================================================================================
  CLAUDE ORCHESTRATOR PLUGIN INSTALLER
  Version: $SCRIPT_VERSION (Plugin: V$PLUGIN_VERSION)
================================================================================
"@ -Color $COLORS.Header

    # Determine source path
    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        $SourcePath = $PSScriptRoot
        if ([string]::IsNullOrWhiteSpace($SourcePath)) {
            $SourcePath = Get-Location
        }
    }

    Write-Info "Source: $SourcePath"
    Write-Info "Target: $InstallPath"
    Write-Info "Silent: $Silent"
    Write-Info "Backup: $Backup"

    # Initialize log file
    $LogFile = Join-Path $InstallPath "install.log"

    # Ensure install directory exists for logging
    if (-not (Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }

    Write-Log "Installation started" -Level "INFO"
    Write-Log "Source: $SourcePath" -Level "INFO"
    Write-Log "Target: $InstallPath" -Level "INFO"

    # Step 1: Prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Error "Prerequisites check failed. Aborting installation."
        Write-Log "Installation aborted: prerequisites failed" -Level "ERROR"
        return 1
    }

    # Step 2: Backup (if requested or existing installation)
    $existingInstall = Test-Path (Join-Path $InstallPath "CLAUDE.md")
    if ($Backup -or ($existingInstall -and -not $Force)) {
        if (-not $Backup -and $existingInstall -and -not $Silent) {
            $response = Read-Host "Existing installation found. Create backup? [Y/n]"
            if ($response -ne 'n' -and $response -ne 'N') {
                $Backup = $true
            }
        }

        if ($Backup) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            if ([string]::IsNullOrWhiteSpace($BackupPath)) {
                $backupLocation = Join-Path $InstallPath "backup_$timestamp"
            } else {
                $backupLocation = $BackupPath
            }

            if (-not (New-InstallationBackup -TargetPath $InstallPath)) {
                Write-Error "Backup failed. Aborting installation."
                Write-Log "Installation aborted: backup failed" -Level "ERROR"
                return 1
            }
        }
    }

    # Step 3: Create directory structure
    Write-Step "Creating directory structure..."

    try {
        foreach ($dir in $INCLUDE_DIRS) {
            $targetDir = Join-Path $InstallPath $dir
            if (-not (Test-Path $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                Write-Info "Created: $dir"
            } else {
                Write-Info "Exists: $dir"
            }
        }
        Write-Success "Directory structure ready"
    }
    catch {
        Write-Error "Failed to create directories: $_"
        Write-Log "Directory creation failed: $_" -Level "ERROR"
        return 1
    }

    $rollbackNeeded = $true

    # Step 4: Copy files
    Write-Step "Copying files..."

    $stats = @{
        TotalCopied = 0
        TotalSkipped = 0
        TotalErrors = 0
    }

    # Copy directories
    foreach ($dir in $INCLUDE_DIRS) {
        $result = Copy-WithProgress -SourceDir $SourcePath -TargetDir $InstallPath -DirName $dir
        $stats.TotalCopied += $result.Copied
        $stats.TotalSkipped += $result.Skipped
        $stats.TotalErrors += $result.Errors
    }

    # Copy root files
    Write-Info "Copying root files..."
    foreach ($file in $ROOT_FILES) {
        $sourceFile = Join-Path $SourcePath $file
        $targetFile = Join-Path $InstallPath $file

        if (Test-Path $sourceFile) {
            try {
                Copy-Item -Path $sourceFile -Destination $targetFile -Force
                Write-Success "Copied: $file"
                $stats.TotalCopied++
            }
            catch {
                Write-Error "Failed to copy $file : $_"
                $stats.TotalErrors++
            }
        } else {
            Write-Warning "Source file not found: $file"
        }
    }

    Write-ColorOutput "`n  Copy Summary: Copied=$($stats.TotalCopied), Skipped=$($stats.TotalSkipped), Errors=$($stats.TotalErrors)" -Color $COLORS.Info

    # Step 5: Set permissions (Windows)
    Write-Step "Setting permissions..."

    try {
        $acl = Get-Acl -Path $InstallPath
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl -Path $InstallPath -AclObject $acl
        Write-Success "Permissions set for $currentUser"
    }
    catch {
        Write-Warning "Could not set permissions: $_"
    }

    # Step 6: Verification
    if (-not $NoVerify) {
        $verifyResult = Test-Installation -TargetPath $InstallPath

        if (-not $verifyResult.Success) {
            Write-Error "Installation verification failed!"
            foreach ($issue in $verifyResult.Issues) {
                Write-Error "  - $issue"
            }

            if ($backupLocation -and (Test-Path $backupLocation)) {
                if (-not $Silent) {
                    $response = Read-Host "Rollback to previous installation? [Y/n]"
                    if ($response -ne 'n' -and $response -ne 'N') {
                        Invoke-Rollback -TargetPath $InstallPath -BackupLocation $backupLocation
                    }
                }
            }

            Write-Log "Installation verification failed" -Level "ERROR"
            return 1
        }

        Write-Success "Installation verified ($($verifyResult.Passed) checks passed)"
    }

    # Step 7: Final summary
    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-ColorOutput @"

================================================================================
  INSTALLATION COMPLETE
================================================================================
"@ -Color $COLORS.Header

    Write-ColorOutput "  Installation Path: $InstallPath" -Color $COLORS.Success
    Write-ColorOutput "  Files Copied:      $($stats.TotalCopied)" -Color $COLORS.Info
    Write-ColorOutput "  Files Skipped:     $($stats.TotalSkipped)" -Color $COLORS.Info
    Write-ColorOutput "  Duration:          $($duration.ToString('mm\:ss'))" -Color $COLORS.Info

    if ($backupLocation) {
        Write-ColorOutput "  Backup Location:   $backupLocation" -Color $COLORS.Warning
    }

    Write-ColorOutput "`n  Log File: $LogFile" -Color $COLORS.Info

    Write-ColorOutput @"

  NEXT STEPS:
  1. Restart Claude Code CLI if running
  2. Verify with: claude /status
  3. View docs: $InstallPath\skills\orchestrator\docs\

================================================================================
"@ -Color $COLORS.Header

    Write-Log "Installation completed successfully" -Level "SUCCESS"
    Write-Log "Duration: $($duration.ToString('mm\:ss'))" -Level "INFO"

    return 0
}
#endregion

#region Entry Point
try {
    $exitCode = Install-ClaudeOrchestrator
    exit $exitCode
}
catch {
    Write-Error "Unexpected error: $_"
    Write-Log "Unexpected error: $_" -Level "ERROR"
    Write-Log $_.ScriptStackTrace -Level "DEBUG"
    exit 1
}
#endregion
