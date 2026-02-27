<#
.SYNOPSIS
    Claude Orchestrator Plugin - Bootstrap Installer

.DESCRIPTION
    Downloads and installs the Claude Orchestrator Plugin from GitHub.
    This is the entry point for the one-liner installation command.

.EXAMPLE
    irm https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/bootstrap-installer.ps1 | iex

.NOTES
    Version: 1.0.0
    This script downloads the full package and runs the main installer.
#>

param(
    [string]$InstallPath = "$env:USERPROFILE\.claude",
    [switch]$Silent,
    [switch]$Backup,
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$GITHUB_REPO = "eroslifestyle/Claude-Orchestrator-Plugin"
$PLUGIN_VERSION = "12.0.3"

function Write-Header {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  CLAUDE ORCHESTRATOR PLUGIN" -ForegroundColor Cyan
    Write-Host "  Version: $PLUGIN_VERSION" -ForegroundColor Cyan
    Write-Host "  Bootstrap Installer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Download-File {
    param(
        [string]$Url,
        [string]$Output
    )

    try {
        if (Test-Command "Invoke-WebRequest") {
            Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing
        } elseif (Test-Command "curl") {
            curl -sL $Url -o $Output
        } else {
            # Fallback to .NET WebClient
            $client = New-Object System.Net.WebClient
            $client.DownloadFile($Url, $Output)
        }
        return $true
    }
    catch {
        Write-Error "Failed to download: $Url"
        Write-Error $_.Exception.Message
        return $false
    }
}

function Main {
    Write-Header

    # Step 1: Check prerequisites
    Write-Step "Checking prerequisites..."

    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Write-Error "PowerShell 5.1+ required. Current: $psVersion"
        return 1
    }
    Write-Success "PowerShell version: $psVersion"

    # Step 2: Create temp directory for download
    $tempDir = Join-Path $env:TEMP "claude-orchestrator-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Step "Creating temp directory: $tempDir"

    try {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        Write-Success "Temp directory created"
    }
    catch {
        Write-Error "Failed to create temp directory: $_"
        return 1
    }

    # Step 3: Download the package
    Write-Step "Downloading Claude Orchestrator Plugin..."

    $zipUrl = "https://github.com/$GITHUB_REPO/archive/refs/heads/$Branch.zip"
    $zipFile = Join-Path $tempDir "package.zip"

    Write-Host "    URL: $zipUrl" -ForegroundColor Gray

    if (-not (Download-File -Url $zipUrl -Output $zipFile)) {
        Write-Error "Download failed"
        return 1
    }
    Write-Success "Package downloaded"

    # Step 4: Extract the package
    Write-Step "Extracting package..."

    try {
        # Use Expand-Archive (PowerShell 5+)
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
        Write-Success "Package extracted"

        # Find the extracted directory (GitHub adds -branch suffix)
        $extractedDir = Get-ChildItem -Path $tempDir -Directory -Filter "Claude-Orchestrator-Plugin*" | Select-Object -First 1
        if (-not $extractedDir) {
            Write-Error "Could not find extracted directory"
            return 1
        }
        $sourcePath = $extractedDir.FullName
        Write-Success "Source path: $sourcePath"
    }
    catch {
        Write-Error "Extraction failed: $_"
        return 1
    }

    # Step 5: Run the main installer
    Write-Step "Running main installer..."
    Write-Host ""

    $installerScript = Join-Path $sourcePath "install.ps1"

    if (-not (Test-Path $installerScript)) {
        Write-Error "Installer script not found: $installerScript"
        return 1
    }

    # Build arguments
    $installArgs = @{
        SourcePath = $sourcePath
        InstallPath = $InstallPath
    }
    if ($Silent) { $installArgs.Silent = $true }
    if ($Backup) { $installArgs.Backup = $true }

    # Run the installer
    try {
        & $installerScript @installArgs
        $installResult = $LASTEXITCODE
        if ($null -eq $installResult) { $installResult = 0 }
    }
    catch {
        Write-Error "Installer failed: $_"
        $installResult = 1
    }

    # Step 6: Cleanup
    Write-Step "Cleaning up temp files..."

    try {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Cleanup complete"
    }
    catch {
        Write-Host "    Note: Temp files can be manually deleted: $tempDir" -ForegroundColor Gray
    }

    # Final status
    Write-Host ""
    if ($installResult -eq 0) {
        Write-Success "Installation completed successfully!"
        Write-Host ""
        Write-Host "Installation path: $InstallPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Restart Claude Code CLI if running"
        Write-Host "  2. Verify with: claude /status"
        Write-Host "  3. View docs: $InstallPath\skills\orchestrator\docs\"
    } else {
        Write-Error "Installation failed with exit code: $installResult"
    }

    return $installResult
}

# Run main function
try {
    $result = Main

    # Don't exit - let user see output
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Error "Unexpected error: $_"
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
