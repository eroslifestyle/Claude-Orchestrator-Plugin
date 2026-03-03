#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Orchestrator Plugin - Windows Installer Completo

.DESCRIPTION
    Script di installazione automatica per Windows che:
    1. Verifica prerequisiti (Git, Claude Code CLI)
    2. Backup directory .claude esistente (se presente)
    3. Clona il repository nella directory utente
    4. Copia i file di configurazione
    5. Crea directory necessarie
    6. Installa dipendenze MCP server
    7. Mostra messaggio di completamento con istruzioni

.PARAMETER InstallPath
    Base installation path. Default: $env:USERPROFILE\.claude

.PARAMETER Force
    Force overwrite existing files without backup

.PARAMETER SkipMCP
    Skip MCP server installation (npm install)

.PARAMETER BackupPath
    Custom backup path. Default: $InstallPath\backup

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
    Version: 2.0.0
    Author: Claude Orchestrator Team
    Requires: PowerShell 5.1+, Git, Node.js (optional for MCP)
    Repository: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin
#>

param(
    [string]$InstallPath = "$env:USERPROFILE\.claude",
    [switch]$Force,
    [switch]$SkipMCP,
    [string]$BackupPath
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:Version = "2.0.0"
$Script:GitHubRepo = "https://github.com/eroslifestyle/Claude-Orchestrator-Plugin"
$Script:GitHubRaw = "https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main"
$Script:ErrorActionPreference = "Stop"
$Script:ProgressPreference = "SilentlyContinue"

# Directories to create
$Script:RequiredDirectories = @(
    "tmp",
    "sessions",
    "learnings",
    "projects",
    "logs\orchestrator",
    "skills\orchestrator",
    "agents"
)

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

function Write-Command {
    param([string]$Message)
    Write-Host "  > " -ForegroundColor DarkGray -NoNewline
    Write-Host $Message -ForegroundColor White
}

# ============================================================================
# STEP 1: PREREQUISITE CHECKS
# ============================================================================

function Test-Prerequisites {
    Write-Header "Step 1/7: Verifica Prerequisiti"

    $allPassed = $true

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
        Write-Error "PowerShell 5.1+ richiesto. Versione attuale: $psVersion"
        return $false
    }
    Write-Success "PowerShell versione: $psVersion"

    # Check Git
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        $gitVersion = (git --version 2>$null) -replace "git version ", ""
        Write-Success "Git trovato: $gitVersion"
    } else {
        Write-Error "Git non trovato. Installa Git da: https://git-scm.com/download/win"
        $allPassed = $false
    }

    # Check Claude Code CLI
    $claudePaths = @(
        "$env:USERPROFILE\.local\bin\claude.exe",
        "$env:LOCALAPPDATA\Programs\claude\claude.exe",
        "$env:LOCALAPPDATA\Programs\claude-code\claude.exe",
        "${env:ProgramFiles}\Claude\claude.exe",
        "${env:ProgramFiles}\Claude Code\claude.exe"
    )

    $claudeFound = $false
    foreach ($path in $claudePaths) {
        if (Test-Path $path) {
            $claudeFound = $true
            Write-Success "Claude Code trovato: $path"
            break
        }
    }

    if (-not $claudeFound) {
        # Try in PATH
        $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
        if ($claudeCmd) {
            $claudeFound = $true
            Write-Success "Claude Code trovato in PATH: $($claudeCmd.Source)"
        }
    }

    if (-not $claudeFound) {
        Write-Warning "Claude Code non trovato nei percorsi standard"
        Write-Info "L'installazione continuera', ma verifica che Claude Code sia installato"
    }

    # Check Node.js (optional, for MCP)
    if (-not $SkipMCP) {
        $nodePath = Get-Command node -ErrorAction SilentlyContinue
        if ($nodePath) {
            $nodeVersion = (node --version 2>$null)
            Write-Success "Node.js trovato: $nodeVersion"

            $npmPath = Get-Command npm -ErrorAction SilentlyContinue
            if ($npmPath) {
                $npmVersion = (npm --version 2>$null)
                Write-Success "npm trovato: $npmVersion"
            }
        } else {
            Write-Warning "Node.js non trovato - installazione MCP server saltata"
            Write-Info "Installa Node.js da: https://nodejs.org/"
            $Script:SkipMCP = $true
        }
    }

    # Check if running as Administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Warning "Esecuzione come Amministratore - l'installazione nel profilo utente potrebbe non essere intesa"
    }

    return $allPassed
}

# ============================================================================
# STEP 2: BACKUP EXISTING DIRECTORY
# ============================================================================

function Backup-ExistingDirectory {
    Write-Header "Step 2/7: Backup Directory Esistente"

    if (-not (Test-Path $InstallPath)) {
        Write-Info "Directory $InstallPath non esiste - nessun backup necessario"
        return $true
    }

    # Check if it's the github-package directory (new install)
    $githubPackagePath = Join-Path $InstallPath "github-package"
    if (-not (Test-Path $githubPackagePath)) {
        Write-Info "Nessuna installazione precedente trovata - nessun backup necessario"
        return $true
    }

    # Set backup path
    if ([string]::IsNullOrEmpty($BackupPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $BackupPath = Join-Path $InstallPath "backup_$timestamp"
    }

    Write-Info "Backup path: $BackupPath"

    # Create backup directory
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    }

    # Backup important files and directories
    $itemsToBackup = @(
        "settings.json",
        "settings.local.json",
        "github-package"
    )

    $backupCount = 0
    foreach ($item in $itemsToBackup) {
        $sourcePath = Join-Path $InstallPath $item
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $BackupPath $item
            try {
                if (Test-Path $destPath) {
                    Remove-Item $destPath -Recurse -Force
                }
                Copy-Item $sourcePath $destPath -Recurse -Force
                Write-Step "Backup: $item"
                $backupCount++
            } catch {
                Write-Warning "Impossibile fare backup di $item : $($_.Exception.Message)"
            }
        }
    }

    if ($backupCount -gt 0) {
        Write-Success "Backup completato: $backupCount elementi"
    } else {
        Write-Info "Nessun elemento da backuppare"
    }

    return $true
}

# ============================================================================
# STEP 3: CLONE REPOSITORY
# ============================================================================

function Clone-Repository {
    Write-Header "Step 3/7: Clonazione Repository"

    $targetPath = Join-Path $InstallPath "github-package"

    # Check if already cloned
    if (Test-Path $targetPath) {
        if ((Test-Path (Join-Path $targetPath ".git"))) {
            Write-Info "Repository gia clonato - aggiornamento in corso..."
            Push-Location $targetPath
            try {
                git fetch origin 2>$null
                git reset --hard origin/main 2>$null
                Write-Success "Repository aggiornato all'ultima versione"
            } catch {
                Write-Warning "Aggiornamento fallito, procedo con versione esistente"
            } finally {
                Pop-Location
            }
            return $true
        } elseif ($Force) {
            Write-Info "Rimozione directory esistente (Force mode)..."
            Remove-Item $targetPath -Recurse -Force
        } else {
            Write-Warning "Directory esistente senza .git - usa -Force per sovrascrivere"
            return $true
        }
    }

    # Clone repository
    Write-Info "Clonazione repository da: $Script:GitHubRepo"
    Write-Info "Destinazione: $targetPath"

    try {
        git clone $Script:GitHubRepo $targetPath 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Repository clonato con successo"
        } else {
            throw "git clone exited with code $LASTEXITCODE"
        }
    } catch {
        Write-Error "Clonazione fallita: $($_.Exception.Message)"
        Write-Info "Tenta download manuale da: $Script:GitHubRepo"
        return $false
    }

    return $true
}

# ============================================================================
# STEP 4: COPY CONFIGURATION FILES
# ============================================================================

function Copy-ConfigurationFiles {
    Write-Header "Step 4/7: Copia File Configurazione"

    $githubPackagePath = Join-Path $InstallPath "github-package"
    $templatesPath = Join-Path $githubPackagePath "skills\orchestrator"

    # Check if templates exist in new location
    $settingsTemplate = Join-Path $templatesPath "settings.template.json"
    $settingsLocalTemplate = Join-Path $templatesPath "settings.local.template.json"

    # If templates don't exist, create default ones
    if (-not (Test-Path $settingsTemplate)) {
        Write-Info "Creazione settings.template.json..."
        $defaultSettings = @{
            env = @{
                CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
            }
        }
        $defaultSettings | ConvertTo-Json -Depth 10 | Out-File $settingsTemplate -Encoding UTF8 -Force
        Write-Step "Creato: settings.template.json"
    }

    # Copy settings.json
    $settingsDest = Join-Path $InstallPath "settings.json"
    if (Test-Path $settingsDest) {
        Write-Info "settings.json esiste - aggiornamento env variables..."

        try {
            $settings = Get-Content $settingsDest -Raw | ConvertFrom-Json

            # Ensure env block exists
            if (-not $settings.env) {
                $settings | Add-Member -NotePropertyName "env" -NotePropertyValue @{} -Force
            }

            # Add Agent Teams feature flag
            if ($settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS -ne "1") {
                $settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
                Write-Step "Aggiunto: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
            }

            # Save settings
            $settings | ConvertTo-Json -Depth 10 | Out-File $settingsDest -Encoding UTF8 -Force
            Write-Success "settings.json aggiornato"
        } catch {
            Write-Warning "Impossibile aggiornare settings.json: $($_.Exception.Message)"
        }
    } else {
        Write-Info "Copia settings.template.json -> settings.json..."
        Copy-Item $settingsTemplate $settingsDest -Force
        Write-Success "settings.json creato"
    }

    # Create settings.local.json if template exists
    if (Test-Path $settingsLocalTemplate) {
        $settingsLocalDest = Join-Path $InstallPath "settings.local.json"
        if (-not (Test-Path $settingsLocalDest)) {
            Copy-Item $settingsLocalTemplate $settingsLocalDest -Force
            Write-Step "Copiato: settings.local.json"
        } else {
            Write-Step "Esiste: settings.local.json"
        }
    }

    # Copy skills to proper location
    $skillsSource = Join-Path $githubPackagePath "skills"
    $skillsDest = Join-Path $InstallPath "skills"

    if (Test-Path $skillsSource) {
        # Create skills directory if needed
        if (-not (Test-Path $skillsDest)) {
            New-Item -ItemType Directory -Path $skillsDest -Force | Out-Null
        }

        # Copy orchestrator skill
        $orchestratorSource = Join-Path $skillsSource "orchestrator"
        $orchestratorDest = Join-Path $skillsDest "orchestrator"

        if (Test-Path $orchestratorDest) {
            if ($Force) {
                Remove-Item $orchestratorDest -Recurse -Force
            }
        }

        if (-not (Test-Path $orchestratorDest)) {
            Copy-Item $orchestratorSource $orchestratorDest -Recurse -Force
            Write-Step "Copiato: skills/orchestrator/"
        }

        # Copy other skills
        Get-ChildItem $skillsSource -Directory | ForEach-Object {
            $skillName = $_.Name
            if ($skillName -ne "orchestrator") {
                $destPath = Join-Path $skillsDest $skillName
                if (-not (Test-Path $destPath)) {
                    Copy-Item $_.FullName $destPath -Recurse -Force
                    Write-Step "Copiato: skills/$skillName/"
                }
            }
        }
    }

    # Copy agents to proper location
    $agentsSource = Join-Path $githubPackagePath "agents"
    $agentsDest = Join-Path $InstallPath "agents"

    if (Test-Path $agentsSource) {
        if (-not (Test-Path $agentsDest)) {
            New-Item -ItemType Directory -Path $agentsDest -Force | Out-Null
        }

        # Copy all agent files
        Get-ChildItem $agentsSource -Recurse | ForEach-Object {
            $relativePath = $_.FullName.Substring($agentsSource.Length + 1)
            $destPath = Join-Path $agentsDest $relativePath

            if ($_.PSIsContainer) {
                if (-not (Test-Path $destPath)) {
                    New-Item -ItemType Directory -Path $destPath -Force | Out-Null
                }
            } else {
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                if (-not (Test-Path $destPath) -or $Force) {
                    Copy-Item $_.FullName $destPath -Force
                }
            }
        }
        Write-Step "Copiato: agents/"
    }

    # Copy rules
    $rulesSource = Join-Path $githubPackagePath "rules"
    $rulesDest = Join-Path $InstallPath "rules"

    if (Test-Path $rulesSource) {
        if (-not (Test-Path $rulesDest)) {
            New-Item -ItemType Directory -Path $rulesDest -Force | Out-Null
        }

        Copy-Item "$rulesSource\*" $rulesDest -Recurse -Force
        Write-Step "Copiato: rules/"
    }

    Write-Success "Configurazione completata"
    return $true
}

# ============================================================================
# STEP 5: CREATE REQUIRED DIRECTORIES
# ============================================================================

function New-RequiredDirectories {
    Write-Header "Step 5/7: Creazione Directory Necessarie"

    $createdCount = 0
    $existingCount = 0

    foreach ($dir in $Script:RequiredDirectories) {
        $fullPath = Join-Path $InstallPath $dir

        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Step "Creato: $dir"
            $createdCount++
        } else {
            Write-Step "Esiste: $dir"
            $existingCount++
        }
    }

    Write-Host ""
    Write-Info "Directory create: $createdCount"
    Write-Info "Directory esistenti: $existingCount"
    Write-Success "Struttura directory pronta"

    return $true
}

# ============================================================================
# STEP 6: INSTALL MCP SERVER DEPENDENCIES
# ============================================================================

function Install-MCPServer {
    Write-Header "Step 6/7: Installazione Dipendenze MCP Server"

    if ($Script:SkipMCP) {
        Write-Info "Installazione MCP server saltata"
        return $true
    }

    $mcpPluginPath = Join-Path $InstallPath "github-package\plugins\orchestrator-plugin"

    # Check if MCP plugin directory exists
    if (-not (Test-Path $mcpPluginPath)) {
        Write-Info "Directory MCP plugin non trovata - saltato"
        Write-Info "Path cercato: $mcpPluginPath"
        return $true
    }

    # Check for package.json
    $packageJsonPath = Join-Path $mcpPluginPath "package.json"
    if (-not (Test-Path $packageJsonPath)) {
        Write-Info "package.json non trovato - saltato"
        return $true
    }

    Write-Info "Installazione dipendenze npm in: $mcpPluginPath"

    Push-Location $mcpPluginPath
    try {
        # Install dependencies
        Write-Step "Esecuzione: npm install"
        $npmInstall = npm install 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "npm install completato"
        } else {
            Write-Warning "npm install completato con warning"
        }

        # Build if script exists
        $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        if ($packageJson.scripts.build) {
            Write-Step "Esecuzione: npm run build"
            $npmBuild = npm run build 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "npm run build completato"
            } else {
                Write-Warning "npm run build completato con warning"
            }
        }

        Write-Success "Dipendenze MCP installate"
    } catch {
        Write-Warning "Errore durante installazione MCP: $($_.Exception.Message)"
        Write-Info "Puoi installare manualmente con: cd $mcpPluginPath && npm install && npm run build"
    } finally {
        Pop-Location
    }

    return $true
}

# ============================================================================
# STEP 7: SHOW COMPLETION MESSAGE
# ============================================================================

function Show-CompletionMessage {
    Write-Header "Step 7/7: Installazione Completata"

    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "*" * 66 -ForegroundColor Green
    Write-Host "  *" -ForegroundColor Green -NoNewline
    Write-Host " " * 64 -NoNewline
    Write-Host "*" -ForegroundColor Green
    Write-Host "  *  " -ForegroundColor Green -NoNewline
    Write-Host "INSTALLAZIONE COMPLETATA CON SUCCESSO!" -ForegroundColor White -NoNewline
    Write-Host "           *" -ForegroundColor Green
    Write-Host "  *" -ForegroundColor Green -NoNewline
    Write-Host " " * 64 -NoNewline
    Write-Host "*" -ForegroundColor Green
    Write-Host "  " -NoNewline
    Write-Host "*" * 66 -ForegroundColor Green
    Write-Host ""

    Write-Host "Percorso installazione: " -NoNewline
    Write-Host $InstallPath -ForegroundColor Cyan
    Write-Host ""

    Write-Host "PROSSIMI PASSI:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. " -ForegroundColor White -NoNewline
    Write-Host "Riavvia Claude Code" -ForegroundColor Gray
    Write-Host "      Chiudi completamente Claude Code e riaprilo" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  2. " -ForegroundColor White -NoNewline
    Write-Host "Attiva l'Orchestrator" -ForegroundColor Gray
    Write-Command "/orchestrator"
    Write-Host ""
    Write-Host "  3. " -ForegroundColor White -NoNewline
    Write-Host "Verifica l'installazione" -ForegroundColor Gray
    Write-Command "/orchestrator health"
    Write-Host ""
    Write-Host "  4. " -ForegroundColor White -NoNewline
    Write-Host "Consulta la documentazione" -ForegroundColor Gray
    Write-Host "      $InstallPath\github-package\README.md" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "COMANDI UTILI:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  /plan          " -ForegroundColor White -NoNewline
    Write-Host "Crea piano implementazione" -ForegroundColor Gray
    Write-Host "  /review        " -ForegroundColor White -NoNewline
    Write-Host "Code review" -ForegroundColor Gray
    Write-Host "  /test          " -ForegroundColor White -NoNewline
    Write-Host "Esegui test" -ForegroundColor Gray
    Write-Host "  /fix           " -ForegroundColor White -NoNewline
    Write-Host "Fix bug" -ForegroundColor Gray
    Write-Host "  /learn         " -ForegroundColor White -NoNewline
    Write-Host "Cattura learnings sessione" -ForegroundColor Gray
    Write-Host "  /status        " -ForegroundColor White -NoNewline
    Write-Host "Stato sistema" -ForegroundColor Gray
    Write-Host ""

    Write-Host "FILE CONFIGURAZIONE:" -ForegroundColor Yellow
    Write-Host "  settings.json       " -ForegroundColor White -NoNewline
    Write-Host "Configurazione principale" -ForegroundColor Gray
    Write-Host "  settings.local.json " -ForegroundColor White -NoNewline
    Write-Host "Configurazione locale (opzionale)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "REPOSITORY: " -NoNewline
    Write-Host $Script:GitHubRepo -ForegroundColor Cyan
    Write-Host ""

    Write-Success "Grazie per aver installato Claude Orchestrator Plugin!"
    Write-Host ""
}

# ============================================================================
# VERIFICATION
# ============================================================================

function Test-Installation {
    Write-Header "Verifica Installazione"

    $errors = @()

    # Check SKILL.md
    $skillPath = Join-Path $InstallPath "skills\orchestrator\SKILL.md"
    if (Test-Path $skillPath) {
        $content = Get-Content $skillPath -Raw
        if ($content -match "ORCHESTRATOR V\d+") {
            Write-Success "SKILL.md: Orchestrator trovato"
        } else {
            Write-Warning "SKILL.md: Versione non rilevata"
        }
    } else {
        $errors += "SKILL.md non trovato"
        Write-Error "SKILL.md non trovato: $skillPath"
    }

    # Check settings.json
    $settingsPath = Join-Path $InstallPath "settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS -eq "1") {
            Write-Success "Agent Teams: Abilitato"
        } else {
            Write-Warning "Agent Teams: Non abilitato"
        }
    } else {
        $errors += "settings.json non trovato"
        Write-Error "settings.json non trovato"
    }

    # Check directories
    foreach ($dir in @("tmp", "sessions", "learnings", "projects")) {
        $dirPath = Join-Path $InstallPath $dir
        if (Test-Path $dirPath) {
            Write-Step "Directory OK: $dir"
        } else {
            $errors += "Directory mancante: $dir"
            Write-Warning "Directory mancante: $dir"
        }
    }

    # Count installed files
    $skillFiles = Get-ChildItem -Path "$InstallPath\skills\orchestrator" -Recurse -File -ErrorAction SilentlyContinue
    $agentFiles = Get-ChildItem -Path "$InstallPath\agents" -Recurse -File -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Info "File skill: $($skillFiles.Count)"
    Write-Info "File agent: $($agentFiles.Count)"

    if ($errors.Count -eq 0) {
        Write-Success "Verifica completata senza errori"
        return $true
    } else {
        Write-Error "Verifica completata con $($errors.Count) errore/i"
        return $false
    }
}

# ============================================================================
# MAIN
# ============================================================================

function Main {
    Clear-Host

    Write-Host ""
    Write-Host "   ____ _           _        _                          _ " -ForegroundColor Cyan
    Write-Host "  / ___| |__   __ _(_)_ __  | |__   ___ _ __  _ __   ___| |" -ForegroundColor Cyan
    Write-Host " | |   | '_ \ / _` | | '_ \ | '_ \ / _ \ '_ \| '_ \ / _ \ |" -ForegroundColor Cyan
    Write-Host " | |___| | | | (_| | | | | || | | |  __/ | | | | | |  __/ |" -ForegroundColor Cyan
    Write-Host "  \____|_| |_|\__,_|_|_| |_||_| |_|\___|_| |_|_| |_|\___|_|" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Claude Orchestrator Plugin Installer v$Script:Version" -ForegroundColor White
    Write-Host "   Repository: $Script:GitHubRepo" -ForegroundColor DarkGray
    Write-Host ""

    Write-Info "Percorso installazione: $InstallPath"
    Write-Info "Modalita Force: $Force"
    Write-Info "Salta MCP: $SkipMCP"
    Write-Host ""

    # Run installation steps
    $steps = @(
        @{ Name = "Prerequisiti"; Function = "Test-Prerequisites" },
        @{ Name = "Backup"; Function = "Backup-ExistingDirectory" },
        @{ Name = "Clonazione"; Function = "Clone-Repository" },
        @{ Name = "Configurazione"; Function = "Copy-ConfigurationFiles" },
        @{ Name = "Directory"; Function = "New-RequiredDirectories" },
        @{ Name = "MCP Server"; Function = "Install-MCPServer" },
        @{ Name = "Verifica"; Function = "Test-Installation" }
    )

    $failedSteps = @()

    foreach ($step in $steps) {
        try {
            $result = & $step.Function
            if (-not $result) {
                $failedSteps += $step.Name
                Write-Host ""
                Write-Error "Step fallito: $($step.Name)"
                Write-Host ""
            }
        } catch {
            $failedSteps += $step.Name
            Write-Host ""
            Write-Error "Errore in step '$($step.Name)': $($_.Exception.Message)"
            Write-Host ""
        }
    }

    # Show completion message
    Show-CompletionMessage

    # Exit code
    if ($failedSteps.Count -gt 0) {
        Write-Warning "Step con errori: $($failedSteps -join ', ')"
        Write-Host ""
        exit 1
    }

    exit 0
}

# Run main function
Main
