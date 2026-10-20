#Requires -Version 5.1

<#
.SYNOPSIS
    Disable or re-enable the Opera Browser Assistant on Windows.

.DESCRIPTION
    This script prevents the Opera Browser Assistant from starting automatically by:

    1. Finding and disabling all scheduled tasks matching:
       "Opera scheduled assistant Autoupdate *"

    2. Blocking execution of:
       browser_assistant.exe
       assistant_installer.exe

       using Windows ACL permissions via icacls.

    3. Providing a status view to verify the scheduled tasks and ACL rules.

    4. Providing an option to undo the changes.

    The regular Opera browser auto-update task is NOT modified.

.NOTES
    Run as Administrator.
    The script will automatically request elevation if required.

    This project is not affiliated with Opera Software.
#>


# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$TaskPattern = 'Opera scheduled assistant Autoupdate *'

$AssistantDir = Join-Path $env:LOCALAPPDATA 'Programs\Opera\assistant'

$BrowserAssistant = Join-Path $AssistantDir 'browser_assistant.exe'
$AssistantInstaller = Join-Path $AssistantDir 'assistant_installer.exe'

$AssistantFiles = @(
    $BrowserAssistant,
    $AssistantInstaller
)

# Full Windows account name, for example:
# DESKTOP-ABC123\User
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name


# ------------------------------------------------------------
# Check for Administrator privileges
# ------------------------------------------------------------

function Test-IsAdministrator {

    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = New-Object System.Security.Principal.WindowsPrincipal(
        $Identity
    )

    return $Principal.IsInRole(
        [System.Security.Principal.WindowsBuiltInRole]::Administrator
    )
}


# ------------------------------------------------------------
# Automatically restart the script as Administrator
# ------------------------------------------------------------

if (-not (Test-IsAdministrator)) {

    Write-Host ""
    Write-Host "Administrator privileges are required." -ForegroundColor Yellow
    Write-Host "Requesting elevation..." -ForegroundColor Yellow

    if ($PSCommandPath) {

        Start-Process powershell.exe `
            -Verb RunAs `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""

    }
    else {

        Write-Host ""
        Write-Host "Unable to restart automatically." -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator."
    }

    exit
}


# ------------------------------------------------------------
# Find Opera Browser Assistant scheduled tasks
# ------------------------------------------------------------

function Get-OperaAssistantTasks {

    @(
        Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object {
            $_.TaskName -like $TaskPattern
        }
    )
}


# ------------------------------------------------------------
# Display scheduled tasks
# ------------------------------------------------------------

function Show-OperaTasks {

    $Tasks = Get-OperaAssistantTasks

    Write-Host ""
    Write-Host "Scheduled Tasks" -ForegroundColor Cyan
    Write-Host "---------------" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "Search pattern:"
    Write-Host "  $TaskPattern" -ForegroundColor DarkGray

    Write-Host ""

    if ($Tasks.Count -eq 0) {

        Write-Host "No matching Opera Browser Assistant tasks were found." `
            -ForegroundColor Yellow

        return
    }

    $Tasks |
        Select-Object TaskName, TaskPath, State |
        Format-Table -AutoSize
}


# ------------------------------------------------------------
# Check whether execution is denied via ACL
# ------------------------------------------------------------

function Test-ExecuteDenied {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $false
    }

    try {

        $Acl = Get-Acl $Path

        $DenyRule = $Acl.Access | Where-Object {

            $_.IdentityReference.Value -eq $CurrentUser -and

            $_.AccessControlType -eq 'Deny' -and

            (
                $_.FileSystemRights -band
                [System.Security.AccessControl.FileSystemRights]::ExecuteFile
            )
        }

        return [bool]$DenyRule
    }
    catch {

        return $false
    }
}


# ------------------------------------------------------------
# Display ACL status
# ------------------------------------------------------------

function Show-AclStatus {

    Write-Host ""
    Write-Host "Executable ACL Status" -ForegroundColor Cyan
    Write-Host "---------------------" -ForegroundColor Cyan

    foreach ($File in $AssistantFiles) {

        Write-Host ""
        Write-Host $File -ForegroundColor White

        if (-not (Test-Path $File)) {

            Write-Host "File not found." -ForegroundColor Yellow
            continue
        }

        Write-Host ""
        Write-Host "icacls output:" -ForegroundColor DarkGray

        & icacls.exe $File

        Write-Host ""

        if (Test-ExecuteDenied $File) {

            Write-Host "[BLOCKED] Execution is denied." `
                -ForegroundColor Green

        }
        else {

            Write-Host "[NOT BLOCKED] Execution is currently allowed." `
                -ForegroundColor Red
        }
    }
}


# ------------------------------------------------------------
# Disable Opera Browser Assistant
# ------------------------------------------------------------

function Disable-OperaAssistant {

    Clear-Host

    Write-Host "==============================================" `
        -ForegroundColor Cyan

    Write-Host " Disabling Opera Browser Assistant"

    Write-Host "==============================================" `
        -ForegroundColor Cyan


    # --------------------------------------------------------
    # Disable scheduled tasks
    # --------------------------------------------------------

    $Tasks = Get-OperaAssistantTasks

    Write-Host ""
    Write-Host "Searching for scheduled tasks..." `
        -ForegroundColor Yellow

    if ($Tasks.Count -eq 0) {

        Write-Host ""
        Write-Host "No matching scheduled tasks were found." `
            -ForegroundColor Yellow

    }
    else {

        foreach ($Task in $Tasks) {

            Write-Host ""
            Write-Host "Found:"
            Write-Host "  $($Task.TaskPath)$($Task.TaskName)" `
                -ForegroundColor Cyan

            try {

                Disable-ScheduledTask `
                    -TaskName $Task.TaskName `
                    -TaskPath $Task.TaskPath `
                    -ErrorAction Stop |
                    Out-Null

                Write-Host "  -> Scheduled task disabled." `
                    -ForegroundColor Green

            }
            catch {

                Write-Host "  -> ERROR: $($_.Exception.Message)" `
                    -ForegroundColor Red
            }
        }
    }


    # --------------------------------------------------------
    # Block executables using ACL
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Applying executable ACL blocks..." `
        -ForegroundColor Yellow

    foreach ($File in $AssistantFiles) {

        Write-Host ""

        if (Test-Path $File) {

            Write-Host "Blocking:"
            Write-Host "  $File" -ForegroundColor Cyan

            & icacls.exe $File /deny "${CurrentUser}:(RX)"

        }
        else {

            Write-Host "File not found:"
            Write-Host "  $File" -ForegroundColor Yellow
        }
    }


    # --------------------------------------------------------
    # Stop currently running Assistant processes
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Stopping running Opera Browser Assistant processes..." `
        -ForegroundColor Yellow

    Stop-Process `
        -Name 'browser_assistant' `
        -Force `
        -ErrorAction SilentlyContinue

    Stop-Process `
        -Name 'assistant_installer' `
        -Force `
        -ErrorAction SilentlyContinue


    # --------------------------------------------------------
    # Show resulting status
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "==============================================" `
        -ForegroundColor Green

    Write-Host " Current Status"

    Write-Host "==============================================" `
        -ForegroundColor Green

    Show-OperaTasks
    Show-AclStatus
}


# ------------------------------------------------------------
# Re-enable Opera Browser Assistant
# ------------------------------------------------------------

function Enable-OperaAssistant {

    Clear-Host

    Write-Host "==============================================" `
        -ForegroundColor Cyan

    Write-Host " Re-enabling Opera Browser Assistant"

    Write-Host "==============================================" `
        -ForegroundColor Cyan


    # --------------------------------------------------------
    # Enable scheduled tasks
    # --------------------------------------------------------

    $Tasks = Get-OperaAssistantTasks

    Write-Host ""
    Write-Host "Searching for scheduled tasks..." `
        -ForegroundColor Yellow

    if ($Tasks.Count -eq 0) {

        Write-Host ""
        Write-Host "No matching scheduled tasks were found." `
            -ForegroundColor Yellow

    }
    else {

        foreach ($Task in $Tasks) {

            Write-Host ""
            Write-Host "Found:"
            Write-Host "  $($Task.TaskPath)$($Task.TaskName)" `
                -ForegroundColor Cyan

            try {

                Enable-ScheduledTask `
                    -TaskName $Task.TaskName `
                    -TaskPath $Task.TaskPath `
                    -ErrorAction Stop |
                    Out-Null

                Write-Host "  -> Scheduled task enabled." `
                    -ForegroundColor Green

            }
            catch {

                Write-Host "  -> ERROR: $($_.Exception.Message)" `
                    -ForegroundColor Red
            }
        }
    }


    # --------------------------------------------------------
    # Remove ACL deny rules
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Removing executable ACL blocks..." `
        -ForegroundColor Yellow

    foreach ($File in $AssistantFiles) {

        Write-Host ""

        if (Test-Path $File) {

            Write-Host "Removing deny rule from:"
            Write-Host "  $File" -ForegroundColor Cyan

            & icacls.exe $File /remove:d "$CurrentUser"

        }
        else {

            Write-Host "File not found:"
            Write-Host "  $File" -ForegroundColor Yellow
        }
    }


    # --------------------------------------------------------
    # Show resulting status
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "==============================================" `
        -ForegroundColor Green

    Write-Host " Current Status"

    Write-Host "==============================================" `
        -ForegroundColor Green

    Show-OperaTasks
    Show-AclStatus
}


# ------------------------------------------------------------
# Main menu
# ------------------------------------------------------------

do {

    Clear-Host

    Write-Host "==============================================" `
        -ForegroundColor Cyan

    Write-Host " Opera Browser Assistant Control"

    Write-Host "==============================================" `
        -ForegroundColor Cyan

    Write-Host ""
    Write-Host "Scheduled task filter:"
    Write-Host "  $TaskPattern" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "[1] Disable Opera Browser Assistant"
    Write-Host "[2] Show current status"
    Write-Host "[3] Re-enable Opera Browser Assistant"
    Write-Host "[4] Exit"

    Write-Host ""

    $Choice = Read-Host "Select an option"

    switch ($Choice) {

        '1' {

            Disable-OperaAssistant

            Write-Host ""
            Read-Host "Press Enter to return to the menu"
        }

        '2' {

            Clear-Host

            Show-OperaTasks
            Show-AclStatus

            Write-Host ""
            Read-Host "Press Enter to return to the menu"
        }

        '3' {

            Enable-OperaAssistant

            Write-Host ""
            Read-Host "Press Enter to return to the menu"
        }

        '4' {
            break
        }

        default {

            Write-Host ""
            Write-Host "Invalid selection." -ForegroundColor Red

            Start-Sleep -Seconds 1
        }
    }

}
while ($Choice -ne '4')