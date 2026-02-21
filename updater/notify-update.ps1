#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Orchestrator - Update Notification Helper

.DESCRIPTION
    Displays update notifications via:
    - Windows Toast notifications (if supported)
    - Console messages with formatting

.PARAMETER Message
    The message to display

.PARAMETER Title
    Notification title (default: "Claude Orchestrator")

.PARAMETER Type
    Notification type: info, success, warning, error

.PARAMETER Silent
    Only show toast, no console output

.EXAMPLE
    .\notify-update.ps1 -Message "Update available: v10.2.0" -Type info

.EXAMPLE
    .\notify-update.ps1 -Title "Update Complete" -Message "Successfully updated to v10.2.0" -Type success

.NOTES
    Version: 10.1.0
    Supports: Windows Toast, PowerShell Console
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [string]$Title = "Claude Orchestrator",

    [ValidateSet("info", "success", "warning", "error")]
    [string]$Type = "info",

    [switch]$Silent
)

# ====================================================================
# CONFIGURATION
# ====================================================================
$script:APP_ID = "Claude Orchestrator"
$script:APP_LOGO = $null  # Can be set to icon path

# ====================================================================
# CONSOLE OUTPUT
# ====================================================================

function Show-ConsoleMessage {
    param([string]$Title, [string]$Message, [string]$Type)

    if ($Silent) { return }

    $border = "=" * 50
    $color = switch ($Type) {
        "info"    { "Cyan" }
        "success" { "Green" }
        "warning" { "Yellow" }
        "error"   { "Red" }
        default   { "White" }
    }

    $icon = switch ($Type) {
        "info"    { "[i]" }
        "success" { "[+]" }
        "warning" { "[!]" }
        "error"   { "[x]" }
        default   { "[*]" }
    }

    Write-Host ""
    Write-Host "  $border" -ForegroundColor $color
    Write-Host "  $icon $Title" -ForegroundColor $color
    Write-Host "  $border" -ForegroundColor $color
    Write-Host ""
    Write-Host "  $Message" -ForegroundColor White
    Write-Host ""
    Write-Host "  $border" -ForegroundColor $color
    Write-Host ""
}

# ====================================================================
# WINDOWS TOAST NOTIFICATION
# ====================================================================

function Show-ToastNotification {
    param([string]$Title, [string]$Message, [string]$Type)

    # Check if running in a supported environment
    if ($env:TERM_PROGRAM -eq "vscode") {
        # VS Code terminal - toast may not work well
        return $false
    }

    try {
        # Method 1: Use BurntToast module if available
        if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
            $toastParams = @{
                Text = @($Title, $Message)
                AppId = $script:APP_ID
            }

            if ($script:APP_LOGO -and (Test-Path $script:APP_LOGO)) {
                $toastParams["AppLogo"] = $script:APP_LOGO
            }

            New-BurntToastNotification @toastParams
            return $true
        }

        # Method 2: Use Windows PowerShell native toast via .NET
        # This requires Windows 8+ and a proper AppId registration
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            return Show-NativeToast -Title $Title -Message $Message -Type $Type
        }

        return $false

    } catch {
        return $false
    }
}

function Show-NativeToast {
    param([string]$Title, [string]$Message, [string]$Type)

    try {
        # Load required assemblies
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

        # Use Windows Forms balloon tip as fallback
        if (-not ([System.Windows.Forms.Application]::MessageLoop)) {
            # Create a hidden form to host the notify icon
            $form = New-Object System.Windows.Forms.Form -Property @{
                WindowState = "Minimized"
                ShowInTaskbar = $false
                FormBorderStyle = "None"
                Opacity = 0
            }

            $notifyIcon = New-Object System.Windows.Forms.NotifyIcon -Property @{
                BalloonTipTitle = $Title
                BalloonTipText = $Message
                BalloonTipIcon = switch ($Type) {
                    "info"    { "Info" }
                    "success" { "Info" }
                    "warning" { "Warning" }
                    "error"   { "Error" }
                    default   { "None" }
                }
                Visible = $true
                Icon = [System.Drawing.SystemIcons]::Information
            }

            # Show balloon tip for 5 seconds
            $notifyIcon.ShowBalloonTip(5000)

            # Wait briefly for the notification to display
            Start-Sleep -Milliseconds 1000

            # Cleanup
            $notifyIcon.Dispose()
            $form.Dispose()

            return $true
        }

        return $false

    } catch {
        return $false
    }
}

# ====================================================================
# WINDOWS TERMINAL BELL (Alternative)
# ====================================================================

function Show-TerminalBell {
    param([string]$Message)

    # Visual bell for Windows Terminal
    if ($env:WT_SESSION) {
        # Windows Terminal - use OSC sequence for attention
        Write-Host "`e]9;$Message`e\" -NoNewline
        return $true
    }
    return $false
}

# ====================================================================
# MAIN EXECUTION
# ====================================================================

# Try toast notification first
$toastShown = Show-ToastNotification -Title $Title -Message $Message -Type $Type

# Show console message (always, unless silent AND toast worked)
if (-not $Silent -or -not $toastShown) {
    Show-ConsoleMessage -Title $Title -Message $Message -Type $Type
}

# Try terminal bell as additional notification
if (-not $Silent) {
    Show-TerminalBell -Message "$Title: $Message" | Out-Null
}
