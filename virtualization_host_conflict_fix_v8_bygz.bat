@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Windows virtualization host conflict fix v8
color 0A

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "ACTION="
set "MODE="

:menu
cls
echo ==============================================================
echo Windows virtualization host conflict fix v8
echo ==============================================================
echo.
echo This script targets common Windows host-side conflicts for:
echo   - VMware Workstation / Player
echo   - Oracle VirtualBox
echo   - Android emulators
echo   - Other desktop virtualization tools
echo.
echo It will:
echo   - set hypervisorlaunchtype to OFF
echo   - set vsmlaunchtype to OFF
echo   - disable common VBS / HVCI / Credential Guard settings
echo   - apply the SecureBiometrics workaround
echo.
echo Important:
echo   - BIOS virtualization stays enabled. That is intentional.
echo   - A reboot is required after applying or undoing changes.
echo   - Aggressive mode may affect WSL2, Sandbox, and similar features.
echo   - Create a System Restore Point before continuing.
echo   - This script is provided AS IS, with no guarantee or warranty.
echo.
echo Project/Updates and Support/Donation:
echo   - github.com/4pp4cc
echo   - ko-fi.com/gzred
echo.
echo.
echo Choose an option:
echo.
echo   [1] Normal fix  ^(recommended^)
echo   [2] Aggressive fix
echo   [3] Undo / restore
echo   [Q] Quit
echo.
choice /C 123Q /N /M "Your choice: "
if errorlevel 4 goto quit
if errorlevel 3 (
    set "ACTION=UNDO"
    set "MODE=RECOMMENDED"
    goto enforce
)
if errorlevel 2 (
    set "ACTION=APPLY"
    set "MODE=AGGRESSIVE"
    goto enforce
)
if errorlevel 1 (
    set "ACTION=APPLY"
    set "MODE=RECOMMENDED"
    goto enforce
)
goto menu

:enforce
cls
echo ==============================================================
echo Required acknowledgment
echo ==============================================================
echo.
if /I "%ACTION%"=="APPLY" (
    echo Selected action: APPLY FIX
) else (
    echo Selected action: UNDO FIX
)
echo Mode: %MODE%
echo.
echo Before continuing:
echo   - You MUST create a System Restore Point first.
echo   - This script is provided AS IS.
echo   - There is NO guarantee and NO warranty.
echo   - You accept full responsibility for any changes.
echo.
set /p "_restore=Type RESTORE to confirm you already created a System Restore Point: "
if /I not "%_restore%"=="RESTORE" (
    echo.
    echo Cancelled. Please create a System Restore Point first.
    pause
    goto menu
)
set /p "_agree=Type AGREE to accept NO GUARANTEE / NO WARRANTY: "
if /I not "%_agree%"=="AGREE" (
    echo.
    echo Cancelled. Agreement not accepted.
    pause
    goto menu
)
goto confirm

:confirm
cls
echo ==============================================================
echo Confirmation
echo ==============================================================
echo.
if /I "%ACTION%"=="APPLY" (
    echo Selected action: APPLY FIX
) else (
    echo Selected action: UNDO FIX
)
echo Mode: %MODE%
echo.
if /I "%ACTION%"=="APPLY" (
    echo This will change Windows boot and registry settings to reduce
    echo host-side virtualization conflicts.
    if /I "%MODE%"=="AGGRESSIVE" (
        echo.
        echo Aggressive mode will also disable extra Windows features such as:
        echo   - VirtualMachinePlatform
        echo   - Windows Subsystem for Linux
        echo   - Containers / Sandbox related features
    )
) else (
    echo This will undo the main changes made by this script.
    echo.
    echo Undo uses a safer restore style:
    echo   - boot launch types back to AUTO
    echo   - script policy overrides removed
    echo   - SecureBiometrics restored to 1
    echo   - optional aggressive features are only re-enabled if you choose
    echo     that separately later in a more advanced script
)
echo.
echo Warning:
echo   - System Restore Point confirmation was required before this step.
echo   - This script is provided AS IS, with no guarantee or warranty.
echo.
echo Do you want to continue?
echo.
choice /C YN /N /M "[Y]es / [N]o: "
if errorlevel 2 goto menu
if errorlevel 1 goto run
goto menu

:run
if /I "%ACTION%"=="UNDO" goto do_undo
goto do_apply

:do_apply
cls
echo ==============================================================
echo Applying Windows virtualization host conflict fix
echo ==============================================================
echo.
echo Mode: %MODE%
echo.

echo [1/7] Disabling boot hypervisor and VSM...
call :RunCmd bcdedit /set "{current}" hypervisorlaunchtype off
call :RunCmd bcdedit /set "{current}" vsmlaunchtype off

echo.
echo [2/7] Disabling common Hyper-V related optional features...
call :DisableFeature Microsoft-Hyper-V-All
call :DisableFeature Microsoft-Hyper-V
call :DisableFeature Microsoft-Hyper-V-Hypervisor
call :DisableFeature Microsoft-Hyper-V-Services
call :DisableFeature Microsoft-Hyper-V-Management-PowerShell
call :DisableFeature Microsoft-Hyper-V-Management-Clients
call :DisableFeature HypervisorPlatform

echo.
echo [3/7] Disabling VBS / HVCI / Credential Guard related registry settings...
call :SetDword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" 0
call :SetDword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "RequirePlatformSecurityFeatures" 0
call :SetDword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
call :SetDword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "WasEnabledBy" 0
call :SetDword "HKLM\SYSTEM\CurrentControlSet\Control\LSA" "LsaCfgFlags" 0

echo.
echo [4/7] Disabling policy-side VBS / HVCI / Credential Guard settings...
call :SetDword "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "EnableVirtualizationBasedSecurity" 0
call :SetDword "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "HypervisorEnforcedCodeIntegrity" 0
call :SetDword "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "LsaCfgFlags" 0

echo.
echo [5/7] Applying SecureBiometrics workaround...
call :SetDword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" "Enabled" 0

if /I "%MODE%"=="AGGRESSIVE" (
    echo.
    echo [6/7] Aggressive mode: disabling extra Windows virtualization features...
    call :DisableFeature VirtualMachinePlatform
    call :DisableFeature Microsoft-Windows-Subsystem-Linux
    call :DisableFeature Containers
    call :DisableFeature Containers-DisposableClientVM
    call :DisableFeature Microsoft-Hyper-V-Online
) else (
    echo.
    echo [6/7] Normal mode selected.
    echo       WSL2 / Sandbox style features are left alone unless already disabled.
)

echo.
echo [7/7] Snapshot after applying changes...
call :ShowSnapshot

echo.
echo ==============================================================
echo DONE.
echo Reboot Windows now for the full fix to take effect.
echo.
echo Project/Updates and Support/Donation:
echo   - github.com/4pp4cc
echo   - ko-fi.com/gzred
echo ==============================================================
pause
exit /b

:do_undo
cls
echo ==============================================================
echo Undo Windows virtualization host conflict fix
echo ==============================================================
echo.

echo [1/4] Restoring boot settings...
call :RunCmd bcdedit /set "{current}" hypervisorlaunchtype auto
call :RunCmd bcdedit /set "{current}" vsmlaunchtype auto

echo.
echo [2/4] Removing script policy-side overrides when present...
call :DeleteValue "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "EnableVirtualizationBasedSecurity"
call :DeleteValue "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "HypervisorEnforcedCodeIntegrity"
call :DeleteValue "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "LsaCfgFlags"

echo.
echo [3/4] Restoring SecureBiometrics toggle to 1...
call :SetDword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" "Enabled" 1

echo.
echo [4/4] Removing common override values set by this script...
call :DeleteValue "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity"
call :DeleteValue "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "RequirePlatformSecurityFeatures"
call :DeleteValue "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled"
call :DeleteValue "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "WasEnabledBy"
call :DeleteValue "HKLM\SYSTEM\CurrentControlSet\Control\LSA" "LsaCfgFlags"

echo.
echo Snapshot after undo...
call :ShowSnapshot

echo.
echo ==============================================================
echo DONE.
echo Reboot Windows now for the full restore to take effect.
echo.
echo Project/Updates and Support/Donation:
echo   - github.com/4pp4cc
echo   - ko-fi.com/gzred
echo ==============================================================
pause
exit /b

:RunCmd
echo ^> %*
%*
exit /b

:SetDword
reg add "%~1" /v "%~2" /t REG_DWORD /d %~3 /f
exit /b

:DeleteValue
reg delete "%~1" /v "%~2" /f >nul 2>&1
exit /b

:DisableFeature
dism /online /Disable-Feature /FeatureName:%~1 /NoRestart
exit /b

:ShowSnapshot
echo.
echo Current boot settings:
bcdedit /enum "{current}" | findstr /I "hypervisorlaunchtype vsmlaunchtype"
echo.
echo Current DeviceGuard settings:
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity 2>nul
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2>nul
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SecureBiometrics" /v Enabled 2>nul
exit /b

:quit
exit /b
