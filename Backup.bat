@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"

:: ============================================================================
:: Backup.bat
:: Copies the current user's standard folders to "C:\User Backup".
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
title User Profile Backup

set "BackupRoot=C:\User Backup"
set "Errors=0"

cls
echo +============================================================+
echo ^|                    USER PROFILE BACKUP                     ^|
echo +============================================================+
echo.
echo Target Path  : !BackupRoot!
echo User Profile : !USERPROFILE!
echo.

:: ---- Zero log files: purge stray logs, make sure the target exists --------
if exist "!BackupRoot!\*.log" del /f /q "!BackupRoot!\*.log" >nul 2>&1
if not exist "!BackupRoot!\" mkdir "!BackupRoot!" >nul 2>&1
if not exist "!BackupRoot!\" (
    echo ERROR: Cannot create the target folder.
    echo.
    call :Countdown
    exit /b 1
)

:: ---- Folders: display name, "User Shell Folders" registry value name ------
call :BackupFolder "Desktop"   "Desktop"
call :BackupFolder "Downloads" "{374DE290-123F-4565-9164-39C4925E467B}"
call :BackupFolder "Documents" "Personal"
call :BackupFolder "Music"     "My Music"
call :BackupFolder "Pictures"  "My Pictures"
call :BackupFolder "Videos"    "My Video"

echo.
if "!Errors!"=="0" (
    echo Backup completed successfully.
) else (
    echo Backup completed with errors.
)
echo.
call :Countdown
exit /b %Errors%


:: ============================================================================
:: :BackupFolder  [display name] [registry value name]
:: ============================================================================
:BackupFolder
set "Name=%~1"
call :PrintPrefix
call :ResolveFolder "%~2"
if not defined Resolved (
    call :PrintStatus "  SKIP  "
    goto :eof
)
robocopy "!Resolved!" "!BackupRoot!\!Name!" /E /COPY:DAT /DCOPY:DAT /XJ /XD "!BackupRoot!" /R:1 /W:1 /NP /NDL /NFL /NJH /NJS >nul 2>&1
if errorlevel 8 (
    set "Errors=1"
    call :PrintStatus " FAILED "
) else (
    call :PrintStatus "  DONE  "
)
goto :eof


:: ============================================================================
:: :ResolveFolder  [registry value name]
:: Sets "Resolved" to the source folder, or leaves it undefined if none exists.
:: Order: registry (User Shell Folders), then standard profile, then OneDrive folders.
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
