#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Orchestrator V10.1 ULTRA - Windows Installer

.DESCRIPTION
    Complete Windows installer for the Claude Orchestrator multi-agent system.
    Supports PowerShell 5.1+ and 7.x with automatic component selection.

.PARAMETER Silent
    Run in silent mode with default component selection (1,2,3)

.PARAMETER Force
    Force overwrite existing files without prompting

.PARAMETER Components
    Comma-separated list of components to install
    1 = Core (skills + agents) - REQUIRED
    2 = PowerShell Profile Integration (cca/ccg commands)
    3 = Settings Templates (settings-anthropic.json, settings-glm.json)
    4 = MCP Plugin (if available)

.EXAMPLE
    .\setup.ps1
    Interactive installation

.EXAMPLE
    .\setup.ps1 -Silent -Components "1,2,3"
    Silent installation with specified components

.EXAMPLE
    .\setup.ps1 -Force
    Force overwrite existing files

.NOTES
    Version: 10.1.0
    Author: Claude Orchestrator Team
    Requires: PowerShell 5.1+ or 7.x
#>

[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$Force,
    [string]$Components = "1,2,3"
)

# ====================================================================
# CONFIGURATION
# ====================================================================
$script:ORCHESTRATOR_VERSION = "10.1.0"
$script:ORCHESTRATOR_CHANNEL = "stable"
$script:REPO_URL = "https://github.com/eroslifestyle/Claude-Orchestrator-Plugin"

# Paths
$script:SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:CLAUDE_DIR = "$env:USERPROFILE\.claude"
$script:SKILLS_DIR = "$env:USERPROFILE\.claude\skills\orchestrator"
$script:AGENTS_DIR = "$env:USERPROFILE\.claude\agents"
$script:ORCHESTRATOR_DIR = "$env:USERPROFILE\.claude\orchestrator"

# Component names
$script:COMPONENT_NAMES = @{
    1 = "Core (skills + agents)"
    2 = "PowerShell Profile Integration"
    3 = "Settings Templates"
    4 = "MCP Plugin"
}

# Installation results
$script:InstallResults = @{
    Components = @()
    FilesCopied = 0
    FilesSkipped = 0
    Errors = @()
}

# ====================================================================
# FUNCTION: Show-Banner
# ====================================================================
function Show-Banner {
    <#
    .SYNOPSIS
        Display the orchestrator installation banner.
    #>

    Clear-Host

    $banner = @"

  ██████╗ ██████╗  ██████╗ ██████╗ ██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗
 ██╔════╝██╔═══██╗██╔════╝██╔═══██╗╚██╗██╔╝██║   ██║██╔══██╗██╔════╝██╔══██╗
 ██║     ██║   ██║██║     ██║   ██║ ╚███╔╝ ██║   ██║██║  ██║█████╗  ██████╔╝
 ██║     ██║   ██║██║     ██║   ██║ ██╔██╗ ██║   ██║██║  ██║██╔══╝  ██╔══██╗
 ╚██████╗╚██████╔╝╚██████╗╚██████╔╝██╔╝ ██╗╚██████╔╝██████╔╝███████╗██║  ██║
  ╚═════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

                    ORCHESTRATOR V$script:ORCHESTRATOR_VERSION ULTRA
                    FULLY INTEGRATED EDITION - WINDOWS INSTALLER

"@

    Write-Host $banner -ForegroundColor Cyan
    Write-Host "  Repository: " -NoNewline -ForegroundColor Gray
    Write-Host $script:REPO_URL -ForegroundColor White
    Write-Host "  Installing: " -NoNewline -ForegroundColor Gray
    Write-Host "Version $script:ORCHESTRATOR_VERSION ($script:ORCHESTRATOR_CHANNEL)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""
}

# ====================================================================
# FUNCTION: Test-Prerequisites
# ====================================================================
function Test-Prerequisites {
    <#
    .SYNOPSIS
        Verify all prerequisites for installation.

    .RETURNS
        [bool] True if all prerequisites pass, False otherwise.
    #>

    Write-Host "[Prerequisites Check]" -ForegroundColor Cyan
    Write-Host ""

    $allPassed = $true

    # 1. PowerShell Version
    $psVersion = $PSVersionTable.PSVersion
    $psVersionOk = $psVersion -ge [version]"5.1"

    if ($psVersionOk) {
        Write-Host "  [OK] " -NoNewline -ForegroundColor Green
        Write-Host "PowerShell Version: $psVersion" -ForegroundColor White
    } else {
        Write-Host "  [ERROR] " -NoNewline -ForegroundColor Red
        Write-Host "PowerShell Version: $psVersion (requires 5.1+)" -ForegroundColor White
        $allPassed = $false
    }

    # 2. Claude Code installed
    $claudeExists = Test-Path $script:CLAUDE_DIR

    if ($claudeExists) {
        Write-Host "  [OK] " -NoNewline -ForegroundColor Green
        Write-Host "Claude Code Directory: $script:CLAUDE_DIR" -ForegroundColor White
    } else {
        Write-Host "  [WARN] " -NoNewline -ForegroundColor Yellow
        Write-Host "Claude Code Directory: Not found" -ForegroundColor White
        Write-Host "        Will be created during installation." -ForegroundColor DarkGray
    }

    # 3. Write permissions
    $canWrite = $false
    try {
        if (-not (Test-Path $script:CLAUDE_DIR)) {
            New-Item -Path $script:CLAUDE_DIR -ItemType Directory -Force | Out-Null
        }
        $testFile = Join-Path $script:CLAUDE_DIR ".write_test_$(Get-Random)"
        [System.IO.File]::WriteAllText($testFile, "test")
        Remove-Item $testFile -Force
        $canWrite = $true
    } catch {
        $canWrite = $false
    }

    if ($canWrite) {
        Write-Host "  [OK] " -NoNewline -ForegroundColor Green
        Write-Host "Write Permission: Granted" -ForegroundColor White
    } else {
        Write-Host "  [ERROR] " -NoNewline -ForegroundColor Red
        Write-Host "Write Permission: Denied" -ForegroundColor White
        $allPassed = $false
    }

    # 4. Git installed (optional)
    $gitInstalled = $null -ne (Get-Command "git" -ErrorAction SilentlyContinue)

    if ($gitInstalled) {
        Write-Host "  [OK] " -NoNewline -ForegroundColor Green
        Write-Host "Git: Installed (optional)" -ForegroundColor White
    } else {
        Write-Host "  [SKIP] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Git: Not installed (optional)" -ForegroundColor White
    }

    Write-Host ""

    return $allPassed
}

# ====================================================================
# FUNCTION: Get-ComponentSelection
# ====================================================================
function Get-ComponentSelection {
    <#
    .SYNOPSIS
        Get user's component selection for installation.

    .RETURNS
        [int[]] Array of selected component numbers.
    #>

    Write-Host "[Component Selection]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Available Components:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Core Only (skills + agents)" -ForegroundColor Green -NoNewline
    Write-Host " - REQUIRED" -ForegroundColor DarkGray
    Write-Host "  [2] PowerShell Profile Integration (cca/ccg commands)" -ForegroundColor White
    Write-Host "  [3] Settings Templates (settings-anthropic.json, settings-glm.json)" -ForegroundColor White
    Write-Host "  [4] MCP Plugin (if available)" -ForegroundColor DarkGray
    Write-Host ""

    if ($Silent) {
        Write-Host "  Silent Mode: Using components [$Components]" -ForegroundColor Yellow
        $selected = $Components -split ',' | ForEach-Object { [int]$_.Trim() }
    } else {
        Write-Host "  Enter components to install (comma-separated, default=1,2,3): " -NoNewline -ForegroundColor Cyan
        $input = Read-Host

        if ([string]::IsNullOrWhiteSpace($input)) {
            $selected = 1, 2, 3
        } else {
            $selected = $input -split ',' | ForEach-Object { [int]$_.Trim() }
        }
    }

    # Always include Core (1) - it's required
    if ($selected -notcontains 1) {
        Write-Host "  [INFO] Core component is required. Adding [1] to selection." -ForegroundColor Yellow
        $selected = ,1 + $selected
    }

    # Validate selection
    $valid = 1..4
    $selected = $selected | Where-Object { $_ -in $valid } | Sort-Object -Unique

    Write-Host ""
    Write-Host "  Selected Components: " -NoNewline
    $selectedNames = $selected | ForEach-Object { $script:COMPONENT_NAMES[$_] }
    Write-Host ($selectedNames -join ", ") -ForegroundColor Green
    Write-Host ""

    return ,$selected
}

# ====================================================================
# FUNCTION: Install-CoreFiles
# ====================================================================
function Install-CoreFiles {
    <#
    .SYNOPSIS
        Install core orchestrator files (skills and agents).

    .RETURNS
        [hashtable] Installation results with FilesCopied, FilesSkipped counts.
    #>

    Write-Host "[Installing Core Files]" -ForegroundColor Cyan
    Write-Host ""

    $result = @{
        FilesCopied = 0
        FilesSkipped = 0
        SkillsFiles = 0
        AgentsFiles = 0
    }

    # Create directories
    $dirs = @(
        $script:SKILLS_DIR,
        $script:AGENTS_DIR,
        $script:ORCHESTRATOR_DIR
    )

    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "  Created: $dir" -ForegroundColor DarkGray
        }
    }

    # Source paths
    $sourceSkills = Join-Path $script:SCRIPT_DIR "core\skills\orchestrator"
    $sourceAgents = Join-Path $script:SCRIPT_DIR "core\agents"

    # Install Skills
    if (Test-Path $sourceSkills) {
        Write-Host "  Installing skills..." -ForegroundColor White

        $files = Get-ChildItem -Path $sourceSkills -Recurse -File
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($sourceSkills.Length + 1)
            $destPath = Join-Path $script:SKILLS_DIR $relativePath
            $destDir = Split-Path -Parent $destPath

            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            $shouldCopy = $true
            if ((Test-Path $destPath) -and -not $Force) {
                $destFile = Get-Item $destPath
                if ($file.LastWriteTime -le $destFile.LastWriteTime) {
                    $shouldCopy = $false
                    $result.FilesSkipped++
                }
            }

            if ($shouldCopy) {
                Copy-Item -Path $file.FullName -Destination $destPath -Force
                $result.FilesCopied++
                $result.SkillsFiles++
            }
        }

        Write-Host "    Skills files: $($result.SkillsFiles)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Skills source not found: $sourceSkills" -ForegroundColor Yellow
    }

    # Install Agents
    if (Test-Path $sourceAgents) {
        Write-Host "  Installing agents..." -ForegroundColor White

        $files = Get-ChildItem -Path $sourceAgents -Recurse -File
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($sourceAgents.Length + 1)
            $destPath = Join-Path $script:AGENTS_DIR $relativePath
            $destDir = Split-Path -Parent $destPath

            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            $shouldCopy = $true
            if ((Test-Path $destPath) -and -not $Force) {
                $destFile = Get-Item $destPath
                if ($file.LastWriteTime -le $destFile.LastWriteTime) {
                    $shouldCopy = $false
                    $result.FilesSkipped++
                }
            }

            if ($shouldCopy) {
                Copy-Item -Path $file.FullName -Destination $destPath -Force
                $result.FilesCopied++
                $result.AgentsFiles++
            }
        }

        Write-Host "    Agents files: $($result.AgentsFiles)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Agents source not found: $sourceAgents" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  Total files copied: $($result.FilesCopied)" -ForegroundColor Green
    Write-Host "  Total files skipped: $($result.FilesSkipped)" -ForegroundColor DarkGray
    Write-Host ""

    return $result
}

# ====================================================================
# FUNCTION: Install-PowerShellProfile
# ====================================================================
function Install-PowerShellProfile {
    <#
    .SYNOPSIS
        Install PowerShell profile integration with merge support.

    .RETURNS
        [bool] True if successful.
    #>

    Write-Host "[Installing PowerShell Profile Integration]" -ForegroundColor Cyan
    Write-Host ""

    $result = $false

    # Determine profile paths
    $profilePaths = @(
        @{
            Name = "PowerShell 7.x"
            Path = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        },
        @{
            Name = "Windows PowerShell 5.1"
            Path = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        }
    )

    # Template path
    $templatePath = Join-Path $script:SCRIPT_DIR "templates\profiles\Microsoft.PowerShell_profile.ps1.template"

    if (-not (Test-Path $templatePath)) {
        Write-Host "  [WARN] Template not found: $templatePath" -ForegroundColor Yellow
        Write-Host "        Skipping PowerShell profile installation." -ForegroundColor DarkGray
        Write-Host ""
        return $false
    }

    $templateContent = Get-Content -Path $templatePath -Raw

    # Extract functions to inject
    $functionsToInject = @(
        "Switch-ClaudeProfile",
        "Test-ClaudeProfile",
        "Restart-VSCodeSafely",
        "cca",
        "ccg",
        "claude",
        "code"
    )

    foreach ($profileInfo in $profilePaths) {
        $profilePath = $profileInfo.Path
        $profileName = $profileInfo.Name

        Write-Host "  Processing $profileName..." -ForegroundColor White

        # Create directory if needed
        $profileDir = Split-Path -Parent $profilePath
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
            Write-Host "    Created directory: $profileDir" -ForegroundColor DarkGray
        }

        if (Test-Path $profilePath) {
            $existingContent = Get-Content -Path $profilePath -Raw

            # Check which functions are already present
            $missingFunctions = @()
            foreach ($funcName in $functionsToInject) {
                if ($existingContent -notmatch "function $funcName") {
                    $missingFunctions += $funcName
                }
            }

            if ($missingFunctions.Count -eq 0) {
                Write-Host "    All functions already present. Skipping." -ForegroundColor DarkGray
                continue
            }

            # Backup existing profile
            $backupPath = "$profilePath.bak"
            Copy-Item -Path $profilePath -Destination $backupPath -Force
            Write-Host "    Backup created: $backupPath" -ForegroundColor DarkGray

            # Extract missing functions from template
            $functionsContent = ""
            foreach ($funcName in $missingFunctions) {
                $pattern = "(?s)(function $funcName \{.*?\n\}(?:\s*\n)?)"
                if ($templateContent -match $pattern) {
                    $functionsContent += "`n" + $matches[1]
                }
            }

            # Append to existing profile
            $newContent = $existingContent.TrimEnd() + "`n`n# === Claude Orchestrator Integration ===" + $functionsContent
            [System.IO.File]::WriteAllText($profilePath, $newContent)

            Write-Host "    Added functions: $($missingFunctions -join ', ')" -ForegroundColor Green
        } else {
            # Copy template as new profile
            Copy-Item -Path $templatePath -Destination $profilePath -Force
            Write-Host "    Created new profile from template" -ForegroundColor Green
        }

        $result = $true
    }

    Write-Host ""
    return $result
}

# ====================================================================
# FUNCTION: Install-SettingsTemplates
# ====================================================================
function Install-SettingsTemplates {
    <#
    .SYNOPSIS
        Install settings templates with API key configuration.

    .RETURNS
        [bool] True if successful.
    #>

    Write-Host "[Installing Settings Templates]" -ForegroundColor Cyan
    Write-Host ""

    $result = $false

    # Template paths
    $templates = @(
        @{
            Source = "templates\settings-anthropic.json"
            Dest = "$script:CLAUDE_DIR\settings-anthropic.json"
            Name = "Anthropic Settings"
        },
        @{
            Source = "templates\settings-glm.json.template"
            Dest = "$script:CLAUDE_DIR\settings-glm.json"
            Name = "GLM5 Settings"
            NeedsApiKey = $true
        }
    )

    foreach ($template in $templates) {
        $sourcePath = Join-Path $script:SCRIPT_DIR $template.Source
        $destPath = $template.Dest
        $name = $template.Name

        Write-Host "  Processing $name..." -ForegroundColor White

        if (-not (Test-Path $sourcePath)) {
            Write-Host "    [WARN] Template not found: $sourcePath" -ForegroundColor Yellow
            continue
        }

        # Check if destination exists
        if ((Test-Path $destPath) -and -not $Force) {
            Write-Host "    Already exists. Use -Force to overwrite." -ForegroundColor DarkGray
            continue
        }

        # Copy template
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "    Installed: $destPath" -ForegroundColor Green
        $result = $true

        # Handle API key for GLM
        if ($template.NeedsApiKey -and -not $Silent) {
            Write-Host ""
            Write-Host "    Configure Z.AI API key now? (Y/n): " -NoNewline -ForegroundColor Cyan
            $configure = Read-Host

            if ($configure -eq "" -or $configure.ToLower() -eq "y") {
                Write-Host "    Enter your Z.AI API token: " -NoNewline -ForegroundColor Cyan
                $apiKey = Read-Host

                if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
                    $content = Get-Content -Path $destPath -Raw
                    $content = $content -replace '<YOUR_ZAI_API_TOKEN_HERE>', $apiKey
                    [System.IO.File]::WriteAllText($destPath, $content)
                    Write-Host "    API key configured." -ForegroundColor Green
                }
            }
        }
    }

    Write-Host ""
    return $result
}

# ====================================================================
# FUNCTION: Install-McpPlugin
# ====================================================================
function Install-McpPlugin {
    <#
    .SYNOPSIS
        Install MCP plugin if available.

    .RETURNS
        [bool] True if successful.
    #>

    Write-Host "[Installing MCP Plugin]" -ForegroundColor Cyan
    Write-Host ""

    $mcpSource = Join-Path $script:SCRIPT_DIR "mcp-plugin"

    if (-not (Test-Path $mcpSource)) {
        Write-Host "  [SKIP] MCP plugin not available in this distribution." -ForegroundColor DarkGray
        Write-Host ""
        return $false
    }

    $mcpDest = Join-Path $script:CLAUDE_DIR "mcp-plugins\orchestrator"

    if (-not (Test-Path $mcpDest)) {
        New-Item -Path $mcpDest -ItemType Directory -Force | Out-Null
    }

    $files = Get-ChildItem -Path $mcpSource -Recurse -File
    $copied = 0

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($mcpSource.Length + 1)
        $destPath = Join-Path $mcpDest $relativePath
        $destDir = Split-Path -Parent $destPath

        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $file.FullName -Destination $destPath -Force
        $copied++
    }

    Write-Host "  MCP plugin files installed: $copied" -ForegroundColor Green
    Write-Host ""

    return $true
}

# ====================================================================
# FUNCTION: New-VersionTracking
# ====================================================================
function New-VersionTracking {
    <#
    .SYNOPSIS
        Create version tracking file for installed components.

    .PARAMETER Components
        Array of installed component numbers.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [int[]]$Components
    )

    Write-Host "[Creating Version Tracking]" -ForegroundColor Cyan
    Write-Host ""

    $componentNames = $Components | ForEach-Object { $script:COMPONENT_NAMES[$_] }

    $versionData = @{
        installed = $script:ORCHESTRATOR_VERSION
        channel = $script:ORCHESTRATOR_CHANNEL
        installDate = (Get-Date -Format "o")
        components = $componentNames
        lastCheck = $null
        updateAvailable = $false
    }

    $versionPath = Join-Path $script:ORCHESTRATOR_DIR "VERSION.json"

    # Ensure directory exists
    $versionDir = Split-Path -Parent $versionPath
    if (-not (Test-Path $versionDir)) {
        New-Item -Path $versionDir -ItemType Directory -Force | Out-Null
    }

    # Write with formatting
    $json = $versionData | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($versionPath, $json)

    Write-Host "  Created: $versionPath" -ForegroundColor Green
    Write-Host ""
}

# ====================================================================
# FUNCTION: Test-Installation
# ====================================================================
function Test-Installation {
    <#
    .SYNOPSIS
        Verify the installation completed successfully.

    .PARAMETER Components
        Array of installed component numbers.

    .RETURNS
        [hashtable] Verification results.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [int[]]$Components
    )

    Write-Host "[Verifying Installation]" -ForegroundColor Cyan
    Write-Host ""

    $result = @{
        Success = $true
        SkillsValid = $false
        AgentsCount = 0
        ProfileInstalled = $false
        SettingsInstalled = $false
    }

    # 1. Verify SKILL.md
    $skillPath = Join-Path $script:SKILLS_DIR "SKILL.md"
    if (Test-Path $skillPath) {
        $content = Get-Content -Path $skillPath -Raw
        if ($content -match "^---" -and $content -match "name:\s*orchestrator") {
            $result.SkillsValid = $true
            Write-Host "  [OK] SKILL.md is valid" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] SKILL.md exists but may be invalid" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [ERROR] SKILL.md not found" -ForegroundColor Red
        $result.Success = $false
    }

    # 2. Count agent files
    if (Test-Path $script:AGENTS_DIR) {
        $result.AgentsCount = (Get-ChildItem -Path $script:AGENTS_DIR -Recurse -File -Filter "*.md").Count
        Write-Host "  [OK] Agent files installed: $($result.AgentsCount)" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Agents directory not found" -ForegroundColor Yellow
    }

    # 3. Verify PowerShell profile (if component 2 was selected)
    if ($Components -contains 2) {
        $profilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        if (Test-Path $profilePath) {
            $content = Get-Content -Path $profilePath -Raw
            if ($content -match "Switch-ClaudeProfile") {
                $result.ProfileInstalled = $true
                Write-Host "  [OK] PowerShell profile integration installed" -ForegroundColor Green
            }
        }
    }

    # 4. Verify settings templates (if component 3 was selected)
    if ($Components -contains 3) {
        $settingsAnthropic = Join-Path $script:CLAUDE_DIR "settings-anthropic.json"
        $settingsGlm = Join-Path $script:CLAUDE_DIR "settings-glm.json"

        if ((Test-Path $settingsAnthropic) -and (Test-Path $settingsGlm)) {
            $result.SettingsInstalled = $true
            Write-Host "  [OK] Settings templates installed" -ForegroundColor Green
        }
    }

    Write-Host ""

    return $result
}

# ====================================================================
# FUNCTION: Show-CompletionMessage
# ====================================================================
function Show-CompletionMessage {
    <#
    .SYNOPSIS
        Display installation completion message with next steps.

    .PARAMETER Components
        Array of installed component numbers.

    .PARAMETER Verification
        Verification results hashtable.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [int[]]$Components,

        [Parameter(Mandatory = $true)]
        [hashtable]$Verification
    )

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""

    if ($Verification.Success) {
        Write-Host "  INSTALLATION COMPLETE" -ForegroundColor Green
    } else {
        Write-Host "  INSTALLATION COMPLETE (with warnings)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  Installed Components:" -ForegroundColor White
    foreach ($comp in $Components) {
        $name = $script:COMPONENT_NAMES[$comp]
        Write-Host "    - $name" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  Installation Details:" -ForegroundColor White
    Write-Host "    Version:      $script:ORCHESTRATOR_VERSION" -ForegroundColor Gray
    Write-Host "    Skills Dir:   $script:SKILLS_DIR" -ForegroundColor Gray
    Write-Host "    Agents Dir:   $script:AGENTS_DIR" -ForegroundColor Gray
    Write-Host "    Agents Count: $($Verification.AgentsCount)" -ForegroundColor Gray

    Write-Host ""
    Write-Host "  Next Steps:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    1. Restart VS Code or your PowerShell terminal" -ForegroundColor White
    Write-Host "    2. Test orchestrator with: " -NoNewline -ForegroundColor White
    Write-Host "/orchestrator" -ForegroundColor Yellow
    Write-Host "    3. View documentation: " -NoNewline -ForegroundColor White
    Write-Host "$script:SKILLS_DIR" -ForegroundColor Gray

    if ($Components -contains 2) {
        Write-Host ""
        Write-Host "  Profile Commands Available:" -ForegroundColor Cyan
        Write-Host "    cca              - Switch to Anthropic profile" -ForegroundColor Gray
        Write-Host "    ccg              - Switch to GLM5 profile" -ForegroundColor Gray
        Write-Host "    claude           - Run claude.exe with active profile" -ForegroundColor Gray
        Write-Host "    Test-ClaudeProfile - Verify current profile" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

# ====================================================================
# MAIN EXECUTION
# ====================================================================

try {
    # Phase 1: Banner
    Show-Banner

    # Phase 2: Prerequisites
    $prereqPassed = Test-Prerequisites
    if (-not $prereqPassed) {
        Write-Host "[ERROR] Prerequisites not met. Please resolve the issues above." -ForegroundColor Red
        exit 1
    }

    # Phase 3: Component Selection
    $selectedComponents = Get-ComponentSelection

    # Phase 4: Install Components
    $installStart = Get-Date

    # Core (Component 1) - Always installed
    $coreResult = Install-CoreFiles
    $script:InstallResults.FilesCopied += $coreResult.FilesCopied
    $script:InstallResults.FilesSkipped += $coreResult.FilesSkipped

    # PowerShell Profile (Component 2)
    if ($selectedComponents -contains 2) {
        $profileResult = Install-PowerShellProfile
        if ($profileResult) {
            $script:InstallResults.Components += "PowerShell Profile"
        }
    }

    # Settings Templates (Component 3)
    if ($selectedComponents -contains 3) {
        $settingsResult = Install-SettingsTemplates
        if ($settingsResult) {
            $script:InstallResults.Components += "Settings Templates"
        }
    }

    # MCP Plugin (Component 4)
    if ($selectedComponents -contains 4) {
        $mcpResult = Install-McpPlugin
        if ($mcpResult) {
            $script:InstallResults.Components += "MCP Plugin"
        }
    }

    # Phase 5: Version Tracking
    New-VersionTracking -Components $selectedComponents

    # Phase 6: Verification
    $verification = Test-Installation -Components $selectedComponents

    # Phase 7: Completion Message
    Show-CompletionMessage -Components $selectedComponents -Verification $verification

    $installDuration = ((Get-Date) - $installStart).TotalSeconds
    Write-Host "  Installation completed in $([math]::Round($installDuration, 1)) seconds" -ForegroundColor DarkGray
    Write-Host ""

    exit 0

} catch {
    Write-Host ""
    Write-Host "[FATAL ERROR] Installation failed: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}
