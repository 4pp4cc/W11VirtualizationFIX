# Windows Virtualization Windows 11 Host Conflict Fix

A small Windows batch script to reduce common **host-side conflicts** that can slow down or interfere with:

- VMware Workstation / Player
- Oracle VirtualBox
- Android emulators
- Other desktop virtualization tools

This project focuses on the **Windows host configuration**, not guest VM tuning.

This script modifies Windows boot configuration, registry values, and optional features related to virtualization-based security and host hypervisor behavior. Use at your own risk, review the contents before running, and reboot after applying changes.

CAUTION IS ADVISED, MAKE A SYSTEM RESTORE POINT BEFORE USING!
THIS SCRIPT COMES WITH ABSOLUTELY NO GARANTEE
USED AND TESTED BY ME AND A SMALL CONTRIBUTERS LOCALLY, Both VMWare and VirtualBox started to work faster after the script MENU 2!

---

## What this script does

The script presents a simple menu and lets the user choose:

- **Normal fix**
- **Aggressive fix**
- **Undo / restore**
- **Quit**

It can automatically request **Administrator** rights if needed.

### Normal fix

Applies the most common Windows-side changes used to reduce virtualization conflicts:

- sets `hypervisorlaunchtype` to `off`
- sets `vsmlaunchtype` to `off`
- disables common VBS / HVCI / Credential Guard related registry values
- disables common Hyper-V related optional features when available
- applies the `SecureBiometrics` workaround

### Aggressive fix

Includes everything in **Normal fix**, plus disables extra Windows virtualization-related features such as:

- `VirtualMachinePlatform`
- `Microsoft-Windows-Subsystem-Linux`
- `Containers`
- `Containers-DisposableClientVM`
- other extra Hyper-V related components when available

Use this only if you want a more aggressive cleanup and do **not** currently depend on things like **WSL2**, **Windows Sandbox**, or container-related features.

### Undo / restore

Attempts to restore a safer default state by:

- setting `hypervisorlaunchtype` back to `auto`
- setting `vsmlaunchtype` back to `auto`
- removing policy values written by the script
- removing common registry overrides written by the script
- restoring `SecureBiometrics` to `1`

---

## Why this exists

Some Windows 11 systems can keep **VBS**, the **secure kernel**, or the **Windows hypervisor path** active even when the usual toggles look disabled.

That can cause:

- poor VMware / VirtualBox performance
- guest lag or stutter
- higher CPU overhead
- nested virtualization problems
- host-side conflicts with third-party virtualization software

During testing, one important extra issue was found:

- `SecureBiometrics` could keep the secure kernel / VBS path alive on some systems

Because of that, this script includes a workaround that sets:

```reg
HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics\Enabled = 0
```

---

## What this script does **not** do

- It does **not** disable BIOS / UEFI CPU virtualization.
- It does **not** tune your VM settings.
- It does **not** optimize storage, RAM allocation, or guest OS settings.
- It does **not** guarantee performance improvements on every system.

Keeping CPU virtualization enabled in BIOS/UEFI is intentional, because VMware, VirtualBox, and similar tools still need it.

---

## Requirements

- Windows 10 or Windows 11
- Administrator rights
- Reboot after applying changes

---

## How to use

1. Download the batch file.
2. Right-click and run it, or just double-click it.
3. Accept the Administrator prompt if Windows asks.
4. Read the introduction screen.
5. Choose:
   - `1` for **Normal fix**
   - `2` for **Aggressive fix**
   - `3` for **Undo / restore**
   - `Q` to quit
6. Reboot after the script finishes.

---

## How to verify the result

After reboot, open:

```text
msinfo32
```

A good result usually looks like:

- **Virtualisation-based security: Not enabled**
- no line saying **A hypervisor has been detected**

You can also check in PowerShell:

```powershell
Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard | fl *
```

A good result usually includes:

```text
VirtualizationBasedSecurityStatus : 0
```

---

## Warnings

Use this script only if you understand what it changes.

Possible side effects:

- Windows security features may be reduced
- Windows Hello / secure biometric behavior may change
- WSL2, Sandbox, Containers, and related features may stop working, especially in **Aggressive** mode
- some corporate or managed systems may re-enable settings through policy

If you depend on Windows security hardening features, test carefully before using this on a production system.

You have an UNDO MENU but its not garanteed that it will actually UNDO everything, so make a System Restore Point before using!

---

## Menu behavior summary

### Option 1 — Normal fix
Recommended for most users.

### Option 2 — Aggressive fix
For users who want a stronger cleanup and do not need extra Microsoft virtualization features.

### Option 3 — Undo / restore
Attempts to revert the main changes.

### Option Q — Quit
Exits without changing anything.

---

## Included technical actions

### Boot configuration

```text
bcdedit /set "{current}" hypervisorlaunchtype off
bcdedit /set "{current}" vsmlaunchtype off
```

### Main registry areas touched

```text
HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard
HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity
HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics
HKLM\SYSTEM\CurrentControlSet\Control\LSA
HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard
```

### Optional Windows features touched
Depending on mode and OS edition:

```text
Microsoft-Hyper-V-All
Microsoft-Hyper-V
Microsoft-Hyper-V-Hypervisor
Microsoft-Hyper-V-Services
Microsoft-Hyper-V-Management-PowerShell
Microsoft-Hyper-V-Management-Clients
HypervisorPlatform
VirtualMachinePlatform
Microsoft-Windows-Subsystem-Linux
Containers
Containers-DisposableClientVM
Microsoft-Hyper-V-Online
```

---

## Best use case

This script is best for people who:

- mainly use VMware or VirtualBox
- want to reduce Windows host-side virtualization conflicts
- do not need VBS-based protections on that machine
- are comfortable rebooting and verifying results manually

---

## Not for everyone

This is **not** a general “make Windows faster” script.
It is specifically aimed at **virtualization host conflicts**.

If your system relies on:

- Hyper-V
- WSL2
- Windows Sandbox
- Containers
- secure enterprise policy baselines
- Windows Hello security features

then use extra care.

---

## License

MIT license.

---

## File

Main script:

- `virtualization_host_conflict_fix_v#_bygz.bat`

---

## Thanks?

If you found this useful and helped you alot (like it did to me), you can give me a little Ko-Fi to keep this script updated :)
https://ko-fi.com/gzred
Thank you for being awesome!

## Suggestions and contact?

If you want to give a suggestion or get in touch with me: 4pp4cc@gmail.com or PM me :)
Feel free to fork this project but i'd appreciate if you keep my Ko-Fi link <3
