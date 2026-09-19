@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"

:: ============================================================================
:: Restore.bat
:: Merges "C:\User Backup" back into the current user's standard folders.
:: Non-destructive: nothing is deleted and existing files are never overwritten.
:: ============================================================================

:: ---- Auto-elevate via PowerShell RunAs ------------------------------------
:: The /elevated flag stops an endless relaunch loop if elevation fails.
fltmc >nul 2>&1
if errorlevel 1 (
    if /i "%~1"=="/elevated" (
        echo Administrator privileges are required but could not be obtained.
        pause
        exit /b 1
    )
    set "SelfPath=%~f0"
    powershell -NoProfile -Command "try { Start-Process -FilePath $env:SelfPath -ArgumentList '/elevated' -Verb RunAs -ErrorAction Stop } catch { }"
    exit /b
)

setlocal EnableDelayedExpansion
color 0B
title User Profile Restore

set "BackupRoot=C:\User Backup"
set "Errors=0"

cls
echo +============================================================+
echo ^|                    USER PROFILE RESTORE                    ^|
echo +============================================================+
echo.
echo Source Path  : !BackupRoot!
echo User Profile : !USERPROFILE!
echo.

if not exist "!BackupRoot!\" (
    echo ERROR: Backup folder not found.
    echo.
    call :Countdown
    exit /b 1
)

:: ---- Confirmation ---------------------------------------------------------
echo Missing files will be restored into your profile folders.
echo Existing files are never overwritten or deleted.
echo.
choice /c YN /n /m "Proceed with restore? [Y/N]: "
if errorlevel 2 (
    echo.
    echo Restore cancelled.
    echo.
    call :Countdown
    exit /b 2
)
echo.

:: ---- Folders: display name, "User Shell Folders" registry value name ------
call :RestoreFolder "Desktop"   "Desktop"
call :RestoreFolder "Downloads" "{374DE290-123F-4565-9164-39C4925E467B}"
call :RestoreFolder "Documents" "Personal"
call :RestoreFolder "Music"     "My Music"
call :RestoreFolder "Pictures"  "My Pictures"
call :RestoreFolder "Videos"    "My Video"

echo.
if "!Errors!"=="0" (
    echo Restore completed successfully.
) else (
    echo Restore completed with errors.
)
echo.
call :Countdown
exit /b %Errors%


:: ============================================================================
:: :RestoreFolder  [display name] [registry value name]
:: Non-destructive merge: /XC /XN /XO skips every file that already exists in
:: the destination, and there is no /MIR or /PURGE, so nothing is deleted.
:: ============================================================================
:RestoreFolder
set "Name=%~1"
call :PrintPrefix
if not exist "!BackupRoot!\!Name!\" (
    call :PrintStatus "  SKIP  "
    goto :eof
)
call :ResolveFolder "%~2"
robocopy "!BackupRoot!\!Name!" "!Resolved!" /E /COPY:DAT /DCOPY:DAT /XJ /XC /XN /XO /R:1 /W:1 /NP /NDL /NFL /NJH /NJS >nul 2>&1
if errorlevel 8 (
    set "Errors=1"
    call :PrintStatus " FAILED "
) else (
    call :PrintStatus "  DONE  "
)
goto :eof


:: ============================================================================
:: :ResolveFolder  [registry value name]
:: Sets "Resolved" to the destination folder inside the current profile.
:: Order: registry (User Shell Folders), then standard profile, then OneDrive folders.
:: If none exists yet, the registry path (or standard path) is used and
:: Robocopy creates it.
:: ============================================================================
:ResolveFolder
set "Resolved="
set "RegLine="
set "RegData="

:: 1) Registry. Split on the value TYPE so names with spaces stay intact.
for /f "delims=" %%L in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "%~1" 2^>nul ^| findstr /i /c:"REG_"') do set "RegLine=%%L"
if not defined RegLine goto :ResolveStandard
set "RegData=!RegLine:*REG_EXPAND_SZ=!"
if "!RegData!"=="!RegLine!" set "RegData=!RegLine:*REG_SZ=!"
for /f "tokens=* delims= " %%D in ("!RegData!") do set "RegData=%%D"
if "!RegData: =!"=="" set "RegData="
set "RegData=!RegData:"=!"
call set "RegData=%RegData%"
if defined RegData if exist "!RegData!\" set "Resolved=!RegData!"
if defined Resolved goto :ResolveDone

:ResolveStandard
:: 2) Standard profile folder.
if exist "!USERPROFILE!\!Name!\" set "Resolved=!USERPROFILE!\!Name!"
if defined Resolved goto :ResolveDone

:: 3) OneDrive sync folders.
for %%R in ("%OneDrive%" "%OneDriveConsumer%" "%OneDriveCommercial%" "%USERPROFILE%\OneDrive") do (
    if not defined Resolved if not "%%~R"=="" if exist "%%~R\!Name!\" set "Resolved=%%~R\!Name!"
)
if defined Resolved goto :ResolveDone

:: 4) Nothing exists yet: fall back to the registry path, else the standard path.
if defined RegData (
    set "Resolved=!RegData!"
) else (
    set "Resolved=!USERPROFILE!\!Name!"
)

:ResolveDone
if defined Resolved if "!Resolved:~-1!"=="\" set "Resolved=!Resolved:~0,-1!"
goto :eof


:: ============================================================================
:: UI helpers
:: ============================================================================
:PrintPrefix
:: Prints "[+] Name ........" padded to a fixed width, without a line break.
set "Line=[+] !Name! ............................................................"
set "Line=!Line:~0,51!"
<nul set /p "=!Line! "
goto :eof

:PrintStatus
echo [%~1]
goto :eof


:: ============================================================================
:: :Countdown  - inline 10..1 timer, any key exits immediately.
:: If console input is redirected, [Console]::KeyAvailable throws; key detection
:: is then switched off and the timer simply runs out, so it never freezes.
:: ============================================================================
:Countdown
set "CdCmd=$cr = [string][char]13; $canKey = $true;"
set "CdCmd=!CdCmd! try { while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) } } catch { $canKey = $false };"
set "CdCmd=!CdCmd! for ($i = 10; $i -ge 1; $i--) {"
set "CdCmd=!CdCmd! [Console]::Write($cr + 'Closing in ' + $i.ToString().PadLeft(2) + ' s ...  press any key to exit  ');"
set "CdCmd=!CdCmd! $end = (Get-Date).AddSeconds(1);"
set "CdCmd=!CdCmd! while ((Get-Date) -lt $end) {"
set "CdCmd=!CdCmd! if ($canKey) { try { if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); [Console]::WriteLine(); exit } } catch { $canKey = $false } };"
set "CdCmd=!CdCmd! Start-Sleep -Milliseconds 50 } };"
set "CdCmd=!CdCmd! [Console]::WriteLine()"
powershell -NoProfile -Command "!CdCmd!"
goto :eof
