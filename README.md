# Disable Opera Browser Assistant

A small PowerShell utility for Windows that disables the **Opera Browser Assistant (`browser_assistant.exe`)** and prevents it from automatically starting again.

Opera Browser Assistant can be launched through Windows startup entries and automatically generated Scheduled Tasks such as:

```text
Opera scheduled assistant Autoupdate 1773747108
Opera scheduled assistant Autoupdate 1780325480
```

The numeric ID at the end may change whenever Opera recreates the task. This script therefore searches using:

```text
Opera scheduled assistant Autoupdate *
```

so newly generated task names are detected automatically.

## What the script does

The script finds all matching Opera Browser Assistant Scheduled Tasks and disables them without affecting the regular Opera browser update task.

It also blocks execution of:

```text
%LOCALAPPDATA%\Programs\Opera\assistant\browser_assistant.exe
%LOCALAPPDATA%\Programs\Opera\assistant\assistant_installer.exe
```

using Windows file ACLs and `icacls`.

The equivalent ACL commands are:

```cmd
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\browser_assistant.exe" /deny USER:(RX)
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\assistant_installer.exe" /deny USER:(RX)
```

This prevents the executables from running without deleting or modifying the Opera installation itself.

The script also stops currently running Browser Assistant processes and displays the resulting Scheduled Task and ACL status.

## Reversible

All changes can be undone from the script.

The **Re-enable Opera Browser Assistant** option enables the matching Scheduled Tasks again and removes the ACL deny rules.

Equivalent commands:

```cmd
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\browser_assistant.exe" /remove:d USER
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\assistant_installer.exe" /remove:d USER
```

## Usage

Download:

```text
OperaBrowserAssistantControl.ps1
```

Right-click the file and run it with PowerShell, or start it from a PowerShell terminal:

```powershell
powershell -ExecutionPolicy Bypass -File ".\OperaBrowserAssistantControl.ps1"
```

Administrator privileges are required. The script automatically requests elevation when necessary.

The menu provides:

```text
[1] Disable Opera Browser Assistant
[2] Show current status
[3] Re-enable Opera Browser Assistant
[4] Exit
```

## Why this exists

On some Opera installations, disabling the Browser Assistant through normal Windows startup controls is not sufficient because Opera may create Scheduled Tasks that launch or update the assistant.

These tasks can also be recreated with a different numeric ID.

This utility provides a simple and reversible way to disable those tasks and prevent the Browser Assistant executable from running.

The regular Opera browser auto-update Scheduled Task is intentionally left untouched.

## Compatibility

Designed for Windows 10 and Windows 11 with Windows PowerShell 5.1 or newer.

## Disclaimer

This project is not affiliated with, endorsed by, or associated with Opera Software.

Use it at your own risk. Windows ACL changes can affect application behavior. The script includes a restore option so the changes can be reversed.
