# Disable Opera Browser Assistant (browser_assistant.exe) on Windows

A small PowerShell utility to **disable Opera Browser Assistant (`browser_assistant.exe`) on Windows 10 and Windows 11**.

Opera Browser Assistant may continue to start even after disabling it in Windows Startup Apps because Opera can create additional Scheduled Tasks such as:

```text
Opera scheduled assistant Autoupdate 1773747108
Opera scheduled assistant Autoupdate 1780325480
```

The numeric ID may change whenever Opera recreates the task.

This script automatically finds all matching:

```text
Opera scheduled assistant Autoupdate *
```

tasks, disables them, and blocks the Opera Browser Assistant executables from running.

The normal Opera browser auto-update task is **not modified**.

---

## How to use

1. Download:

   ```text
   OperaBrowserAssistantControl.ps1
   ```

2. Right-click the file and select **Run with PowerShell**.

   Alternatively, open PowerShell in the script directory and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\OperaBrowserAssistantControl.ps1"
   ```

3. Accept the Administrator/UAC prompt.

4. Select:

   ```text
   [1] Disable Opera Browser Assistant
   ```

5. The script will automatically:
   - find all matching Opera Browser Assistant Scheduled Tasks
   - show which tasks were found
   - disable those tasks
   - block `browser_assistant.exe`
   - block `assistant_installer.exe`
   - stop currently running Opera Browser Assistant processes
   - display the resulting status

You can check everything at any time with:

```text
[2] Show current status
```

To undo all changes, select:

```text
[3] Re-enable Opera Browser Assistant
```

---

## What the script does

### 1. Disables Opera Browser Assistant Scheduled Tasks

The script searches for all Windows Scheduled Tasks matching:

```text
Opera scheduled assistant Autoupdate *
```

This is important because Opera may recreate these tasks with a different numeric ID.

For example:

```text
Opera scheduled assistant Autoupdate 1773747108
Opera scheduled assistant Autoupdate 1780325480
```

Both are detected automatically.

The script does **not** disable the regular Opera browser update task.

---

### 2. Blocks browser_assistant.exe from running

The script blocks execution of:

```text
%LOCALAPPDATA%\Programs\Opera\assistant\browser_assistant.exe
%LOCALAPPDATA%\Programs\Opera\assistant\assistant_installer.exe
```

using Windows ACL permissions through `icacls`.

This is similar to running:

```cmd
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\browser_assistant.exe" /deny USER:(RX)
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\assistant_installer.exe" /deny USER:(RX)
```

This prevents the Opera Browser Assistant executables from running without deleting them.

Because the files remain installed, the change can be reversed.

---

### 3. Stops currently running Browser Assistant processes

When disabling the Assistant, the script also attempts to stop:

```text
browser_assistant.exe
assistant_installer.exe
```

if they are currently running.

---

### 4. Shows the current status

The status option displays:

- all matching Opera Browser Assistant Scheduled Tasks
- whether they are enabled or disabled
- the current ACL permissions for both executables
- whether execution is currently blocked

---

## Re-enable / restore Opera Browser Assistant

All changes made by the script are reversible.

Select:

```text
[3] Re-enable Opera Browser Assistant
```

The script will:

- re-enable matching Scheduled Tasks
- remove the ACL deny rules
- restore execution permission for the Opera Browser Assistant executables

The equivalent ACL commands are:

```cmd
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\browser_assistant.exe" /remove:d USER
icacls "%LOCALAPPDATA%\Programs\Opera\assistant\assistant_installer.exe" /remove:d USER
```

---

## Why this project exists

On some Opera installations, disabling **Opera Browser Assistant** through the normal Windows Startup Apps menu is not enough.

Opera can use Windows Scheduled Tasks such as:

```text
Opera scheduled assistant Autoupdate <ID>
```

and may recreate these tasks later with a new numeric ID.

As a result, `browser_assistant.exe` may start again even though it appears to be disabled in Windows startup settings.

This script provides a simple and reversible way to:

- disable Opera Browser Assistant
- disable Opera Browser Assistant autostart
- disable automatically recreated Opera Scheduled Tasks
- block `browser_assistant.exe`
- block `assistant_installer.exe`
- restore everything later if needed

---

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or newer
- Administrator privileges

The script automatically requests Administrator privileges when required.

---

## Important

This script targets tasks matching:

```text
Opera scheduled assistant Autoupdate *
```

It intentionally does **not** target the normal Opera browser update task:

```text
Opera scheduled Autoupdate *
```

This allows Opera itself to continue receiving browser updates.

---

## Disclaimer

This project is not affiliated with, endorsed by, or associated with Opera Software.

Use this script at your own risk.

The script modifies Windows Scheduled Tasks and file ACL permissions. A restore option is included to reverse the changes.

---

## Keywords

Search terms related to this project:

`Opera Browser Assistant` · `disable Opera Browser Assistant` · `browser_assistant.exe` · `disable browser_assistant.exe` · `block browser_assistant.exe` · `Opera autostart` · `Opera startup` · `Opera scheduled assistant Autoupdate` · `disable Opera scheduled task` · `Opera Task Scheduler` · `Opera Browser Assistant keeps starting` · `Opera Browser Assistant Windows 11` · `Opera Browser Assistant Windows 10` · `PowerShell Opera` · `Task Scheduler Opera` · `icacls Opera` · `stop Opera Browser Assistant` · `remove Opera Browser Assistant` · `prevent Opera Browser Assistant startup`
