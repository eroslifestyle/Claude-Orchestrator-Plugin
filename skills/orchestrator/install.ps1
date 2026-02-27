#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Orchestrator Plugin - Windows Installer

.DESCRIPTION
    Installs the Claude Orchestrator Plugin including skills, agents, and configuration.
    Can be run from URL (irm | iex) or locally from the source directory.

.PARAMETER InstallPath
    Base installation path. Default: $env:USERPROFILE\.claude

.PARAMETER Force
    Force overwrite existing files without backup

.EXAMPLE
    # Install from URL
    irm https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.ps1 | iex

.EXAMPLE
    # Install locally with default path
    .\install.ps1

.EXAMPLE
    # Install with custom path and force overwrite
    .\install.ps1 -InstallPath "D:\Custom\.claude" -Force

.NOTES
    Version: 1.0.0
    Author: Claude Orchestrator Team
    Requires: PowerShell 5.1+, Claude Code installed
#>

param(
    [string]$InstallPath = "$env:USERPROFILE\.claude",
    [switch]$Force
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:Version = "1.0.0"
$Script:GitHubRepo = "https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main"
$Script:ErrorActionPreference = "Stop"
$Script:ProgressPreference = "SilentlyContinue"

# ============================================================================
# COLOR OUTPUT HELPERS
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Step {
    param([string]$Message)
    Write-Host "  -> $Message" -ForegroundColor Gray
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
        Write-Error "PowerShell 5.1+ required. Current: $psVersion"
        return $false
    }
    Write-Success "PowerShell version: $psVersion"

    # Check Claude Code installed
    $claudePaths = @(
        "$env:USERPROFILE\.local\bin\claude.exe",
        "$env:LOCALAPPDATA\Programs\claude\claude.exe",
        "${env:ProgramFiles}\Claude\claude.exe"
    )

    $claudeFound = $false
    foreach ($path in $claudePaths) {
        if (Test-Path $path) {
            $claudeFound = $true
            Write-Success "Claude Code found: $path"
            break
        }
    }

    if (-not $claudeFound) {
        Write-Warning "Claude Code not found in standard locations"
        Write-Info "Installation will continue, but verify Claude Code is installed"
    }

    # Check if running as Administrator (not required but note it)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Warning "Running as Administrator - installing to user profile may not be intended"
    }

    return $true
}

# ============================================================================
# DIRECTORY SETUP
# ============================================================================

function Initialize-Directories {
    Write-Header "Creating Directories"

    $directories = @(
        $InstallPath,
        "$InstallPath\skills\orchestrator",
        "$InstallPath\skills\orchestrator\docs",
        "$InstallPath\skills\orchestrator\agents",
        "$InstallPath\agents\agents",
        "$InstallPath\agents\agents\system",
        "$InstallPath\agents\agents\core",
        "$InstallPath\agents\agents\docs",
        "$InstallPath\agents\agents\config",
        "$InstallPath\agents\agents\templates",
        "$InstallPath\agents\agents\workflows",
        "$InstallPath\agents\agents\experts",
        "$InstallPath\agents\agents\experts\L2",
        "$InstallPath\logs\orchestrator"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Step "Created: $dir"
        } else {
            Write-Step "Exists: $dir"
        }
    }

    Write-Success "Directory structure ready"
    return $true
}

# ============================================================================
# FILE INSTALLATION
# ============================================================================

function Install-Files {
    Write-Header "Installing Files"

    # Determine source: URL or local
    $isRemoteInstall = $null -eq $PSScriptRoot -or $PSScriptRoot -eq ""

    if ($isRemoteInstall) {
        Write-Info "Installing from GitHub: $Script:GitHubRepo"
    } else {
        Write-Info "Installing from local: $PSScriptRoot"
    }

    # Define files to install
    $skillFiles = @(
        "SKILL.md",
        "CHANGELOG.md"
    )

    $docFiles = @(
        "docs\routing-table.md",
        "docs\skills-reference.md",
        "docs\team-patterns.md",
        "docs\examples.md",
        "docs\health-check.md",
        "docs\observability.md",
        "docs\test-suite.md",
        "docs\memory-integration.md"
    )

    $agentSystemFiles = @(
        "agents\system\AGENT_REGISTRY.md",
        "agents\system\COMMUNICATION_HUB.md",
        "agents\system\COMPLETION_NOTIFIER.md",
        "agents\system\DEPENDENCY_GRAPH.md",
        "agents\system\PARALLEL_COORDINATOR.md",
        "agents\system\PROTOCOL.md",
        "agents\system\TASK_DECOMPOSITION.md",
        "agents\system\TASK_TRACKER.md"
    )

    $agentCoreFiles = @(
        "agents\core\analyzer.md",
        "agents\core\coder.md",
        "agents\core\documenter.md",
        "agents\core\orchestrator.md",
        "agents\core\reviewer.md",
        "agents\core\system_coordinator.md",
        "agents\core\COMPLETION_REPORT.md",
        "agents\core\DOCUMENTATION_INDEX.md",
        "agents\core\DOCUMENTATION_STATUS.md",
        "agents\core\README_DOCUMENTATION.md",
        "agents\core\TODOLIST.md"
    )

    $agentConfigFiles = @(
        "agents\config\circuit-breaker.json",
        "agents\config\routing.md",
        "agents\config\standards.md"
    )

    $agentTemplateFiles = @(
        "agents\templates\integration.md",
        "agents\templates\review.md",
        "agents\templates\task.md"
    )

    $agentWorkflowFiles = @(
        "agents\workflows\bugfix.md",
        "agents\workflows\feature.md",
        "agents\workflows\OPTIMIZED.md",
        "agents\workflows\refactoring.md"
    )

    $agentExpertFiles = @(
        "agents\experts\ai_integration_expert.md",
        "agents\experts\claude_systems_expert.md",
        "agents\experts\database_expert.md",
        "agents\experts\devops_expert.md",
        "agents\experts\gui-super-expert.md",
        "agents\experts\integration_expert.md",
        "agents\experts\languages_expert.md",
        "agents\experts\mobile_expert.md",
        "agents\experts\mql_expert.md",
        "agents\experts\n8n_expert.md",
        "agents\experts\security_unified_expert.md",
        "agents\experts\social_identity_expert.md",
        "agents\experts\tester_expert.md",
        "agents\experts\trading_strategy_expert.md",
        "agents\experts\reverse_engineering_expert.md",
        "agents\experts\mql_decompilation_expert.md",
        "agents\experts\offensive_security_expert.md",
        "agents\experts\architect_expert.md"
    )

    $agentL2Files = @(
        "agents\experts\L2\ai-model-specialist.md",
        "agents\experts\L2\api-endpoint-builder.md",
        "agents\experts\L2\architect-design-specialist.md",
        "agents\experts\L2\claude-prompt-optimizer.md",
        "agents\experts\L2\db-query-optimizer.md",
        "agents\experts\L2\devops-pipeline-specialist.md",
        "agents\experts\L2\gui-layout-specialist.md",
        "agents\experts\L2\languages-refactor-specialist.md",
        "agents\experts\L2\mobile-ui-specialist.md",
        "agents\experts\L2\mql-optimization.md",
        "agents\experts\L2\n8n-workflow-builder.md",
        "agents\experts\L2\security-auth-specialist.md",
        "agents\experts\L2\social-oauth-specialist.md",
        "agents\experts\L2\test-unit-specialist.md",
        "agents\experts\L2\trading-risk-calculator.md"
    )

    $agentDocFiles = @(
        "agents\docs\changelog.md",
        "agents\docs\getting-started.md",
        "agents\docs\implementation-details.md",
        "agents\docs\INTEGRATION_REPORT.md",
        "agents\docs\orchestrator-advanced.md",
        "agents\docs\orchestrator-examples.md",
        "agents\docs\prompt-library.md",
        "agents\docs\quick-reference.md",
        "agents\docs\quickstart.md",
        "agents\docs\README.md",
        "agents\docs\SYSTEM_ARCHITECTURE.md",
        "agents\docs\deploy-checklist.md"
    )

    $rootAgentFiles = @(
        "agents\CLAUDE.md",
        "agents\INDEX.md"
    )

    # Combine all files
    $allFiles = @()
    $allFiles += $skillFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $docFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentSystemFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentCoreFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentConfigFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentTemplateFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentWorkflowFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentExpertFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentL2Files | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $agentDocFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }
    $allFiles += $rootAgentFiles | ForEach-Object { @{ Source = $_; Dest = "skills\orchestrator\$_" } }

    # Copy agents to agents/agents/ directory (duplicate for agent teams)
    $agentFilesForTeams = @()
    $agentFilesForTeams += $agentSystemFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $agentCoreFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $agentConfigFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $agentTemplateFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $agentWorkflowFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $agentExpertFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $agentL2Files | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $agentDocFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }
    $agentFilesForTeams += $rootAgentFiles | ForEach-Object { @{ Source = $_; Dest = "agents\agents\$($_)" } }

    $allFiles += $agentFilesForTeams

    $successCount = 0
    $failCount = 0
    $skipCount = 0

    foreach ($file in $allFiles) {
        $sourcePath = $file.Source
        $destPath = Join-Path $InstallPath $file.Dest

        if ($isRemoteInstall) {
            $sourceUrl = "$Script:GitHubRepo/$sourcePath"
        } else {
            $sourceUrl = Join-Path $PSScriptRoot $sourcePath
        }

        # Check if file exists
        if ((Test-Path $destPath) -and -not $Force) {
            Write-Step "Skipped (exists): $($file.Dest)"
            $skipCount++
            continue
        }

        # Create backup if force not specified and file exists
        if ((Test-Path $destPath) -and $Force) {
            $backupPath = "$destPath.bak"
            Copy-Item $destPath $backupPath -Force
            Write-Step "Backup: $backupPath"
        }

        try {
            if ($isRemoteInstall) {
                # Download from GitHub
                $content = Invoke-RestMethod -Uri $sourceUrl -Method Get -ErrorAction Stop
                $content | Out-File -FilePath $destPath -Encoding UTF8 -Force
            } else {
                # Copy from local
                Copy-Item $sourceUrl $destPath -Force -ErrorAction Stop
            }
            Write-Step "Installed: $($file.Dest)"
            $successCount++
        } catch {
            Write-Warning "Failed: $($file.Dest) - $($_.Exception.Message)"
            $failCount++
        }
    }

    Write-Host ""
    Write-Info "Files installed: $successCount"
    if ($skipCount -gt 0) { Write-Info "Files skipped: $skipCount" }
    if ($failCount -gt 0) { Write-Warning "Files failed: $failCount" }

    return $failCount -eq 0
}

# ============================================================================
# SETTINGS CONFIGURATION
# ============================================================================

function Update-Settings {
    Write-Header "Configuring Settings"

    $settingsPath = Join-Path $InstallPath "settings.json"

    # Load existing settings or create new
    if (Test-Path $settingsPath) {
        Write-Info "Updating existing settings.json"
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else {
        Write-Info "Creating new settings.json"
        $settings = @{}
    }

    # Ensure env block exists
    if (-not $settings.env) {
        $settings | Add-Member -NotePropertyName "env" -NotePropertyValue @{} -Force
    }

    # Add Agent Teams feature flag
    if ($settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS -ne "1") {
        $settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
        Write-Success "Added CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
    } else {
        Write-Info "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS already set"
    }

    # Save settings
    $settings | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding UTF8 -Force
    Write-Success "Settings saved to: $settingsPath"

    return $true
}

# ============================================================================
# VERIFICATION
# ============================================================================

function Test-Installation {
    Write-Header "Verifying Installation"

    $errors = @()

    # Check SKILL.md
    $skillPath = Join-Path $InstallPath "skills\orchestrator\SKILL.md"
    if (Test-Path $skillPath) {
        $content = Get-Content $skillPath -Raw
        if ($content -match "ORCHESTRATOR V10") {
            Write-Success "SKILL.md: Orchestrator V10.x detected"
        } else {
            Write-Warning "SKILL.md: Version check failed"
        }
    } else {
        $errors += "SKILL.md not found"
        Write-Error "SKILL.md not found at: $skillPath"
    }

    # Check agent registry
    $registryPath = Join-Path $InstallPath "skills\orchestrator\agents\system\AGENT_REGISTRY.md"
    if (Test-Path $registryPath) {
        Write-Success "AGENT_REGISTRY.md: Found"
    } else {
        $errors += "AGENT_REGISTRY.md not found"
        Write-Error "AGENT_REGISTRY.md not found"
    }

    # Check settings.json
    $settingsPath = Join-Path $InstallPath "settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS -eq "1") {
            Write-Success "Agent Teams: Enabled"
        } else {
            Write-Warning "Agent Teams: Not enabled"
        }
    } else {
        $errors += "settings.json not found"
        Write-Error "settings.json not found"
    }

    # Count installed files
    $skillFiles = Get-ChildItem -Path "$InstallPath\skills\orchestrator" -Recurse -File -ErrorAction SilentlyContinue
    $agentFiles = Get-ChildItem -Path "$InstallPath\agents\agents" -Recurse -File -ErrorAction SilentlyContinue

    Write-Info "Skill files installed: $($skillFiles.Count)"
    Write-Info "Agent files installed: $($agentFiles.Count)"

    if ($errors.Count -eq 0) {
        Write-Success "Installation verified successfully"
        return $true
    } else {
        Write-Error "Installation has $($errors.Count) error(s)"
        return $false
    }
}

# ============================================================================
# MAIN
# ============================================================================

function Main {
    Clear-Host

    Write-Host ""
    Write-Host "  ____ _           _        _                          _ " -ForegroundColor Cyan
    Write-Host " / ___| |__   __ _(_)_ __  | |__   ___ _ __  _ __   ___| |" -ForegroundColor Cyan
    Write-Host "| |   | '_ \ / _` | | '_ \ | '_ \ / _ \ '_ \| '_ \ / _ \ |" -ForegroundColor Cyan
    Write-Host "| |___| | | | (_| | | | | || | | |  __/ | | | | | |  __/ |" -ForegroundColor Cyan
    Write-Host " \____|_| |_|\__,_|_|_| |_||_| |_|\___|_| |_|_| |_|\___|_|" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Claude Orchestrator Plugin Installer v$Script:Version" -ForegroundColor White
    Write-Host ""

    Write-Info "Install path: $InstallPath"
    Write-Info "Force mode: $Force"
    Write-Host ""

    # Run installation steps
    $steps = @(
        @{ Name = "Prerequisites"; Function = "Test-Prerequisites" },
        @{ Name = "Directories"; Function = "Initialize-Directories" },
        @{ Name = "Files"; Function = "Install-Files" },
        @{ Name = "Settings"; Function = "Update-Settings" },
        @{ Name = "Verification"; Function = "Test-Installation" }
    )

    foreach ($step in $steps) {
        $result = & $step.Function
        if (-not $result) {
            Write-Host ""
            Write-Error "Installation failed at step: $($step.Name)"
            Write-Host ""
            exit 1
        }
    }

    Write-Header "Installation Complete"

    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "  1. Restart Claude Code" -ForegroundColor Gray
    Write-Host "  2. Run: /orchestrator to activate" -ForegroundColor Gray
    Write-Host "  3. Run: /orchestrator health to verify" -ForegroundColor Gray
    Write-Host ""

    Write-Success "Orchestrator V10.2 ULTRA installed successfully!"
    Write-Host ""
}

# Run main function
Main
