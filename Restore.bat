@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Windows Personal Folders Restore
chcp 65001 >nul

:: Request administrator privileges (required for reading from C:\ root)
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Set backup source location
set "BackupRoot=C:\Windows Backup"
set "LogFile=%BackupRoot%\Restore_Errors.log"
set "TotalErrors=0"

cls
echo ======================================================
echo          Windows Personal Folders Restore
echo ======================================================
echo Backup Source: "%BackupRoot%"
echo.

:: Verify backup directory exists
if not exist "%BackupRoot%" (
    echo [ERROR] Backup directory not found at:
    echo "%BackupRoot%"
    echo Please make sure your backup exists in C:\Windows Backup.
    echo.
    pause
    exit /b 1
)

:: Confirmation prompt
echo WARNING: This will restore backed up files into your current profile.
set /p "Confirm=Are you sure you want to proceed? (Y/N): "
if /i not "%Confirm%"=="Y" (
    echo Restore operation cancelled by user.
    timeout /t 3 >nul
    exit /b 0
)

echo.
if exist "%LogFile%" del "%LogFile%"

:: Restore each shell folder
call :RestoreFolder "Desktop"   "Desktop"
call :RestoreFolder "Downloads" "{374DE290-123F-4565-9164-39C4925E467B}"
call :RestoreFolder "Documents" "Personal"
call :RestoreFolder "Music"     "My Music"
call :BackupFolder "Pictures"  "My Pictures"
call :RestoreFolder "Videos"    "My Video"

echo.
echo ======================================================
if "%TotalErrors%"=="0" (
    echo [SUCCESS] Restore operation completed successfully.
) else (
    echo [WARNING] Restore completed with errors.
    echo Please review the error log at:
    echo "%LogFile%"
)
echo ======================================================
echo Window will close automatically in 10 seconds...
timeout /t 10 >nul
exit /b 0

:: ========================================================
:: Subroutine: Detect destination path & restore files
:: ========================================================
:RestoreFolder
set "FolderName=%~1"
set "ValueName=%~2"
set "SourceFolder=%BackupRoot%\%FolderName%"
set "RawPath="
set "ResolvedDest="

:: Check if folder exists in backup
if not exist "%SourceFolder%" (
    echo [SKIP] No backup found for %FolderName%. Skipping.
    goto :eof
)

:: Query Windows Registry for target folder path
for /f "tokens=1,2* delims=	 " %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "%ValueName%" 2^>nul ^| findstr /i "REG_"') do (
    if /i "%%B"=="REG_SZ" (
        set "RawPath=%%C"
    ) else if /i "%%B"=="REG_EXPAND_SZ" (
        set "RawPath=%%C"
    ) else (
        for /f "tokens=1* delims=	 " %%X in ("%%C") do (
            if /i "%%X"=="REG_SZ" set "RawPath=%%Y"
            if /i "%%X"=="REG_EXPAND_SZ" set "RawPath=%%Y"
        )
    )
)

if defined RawPath (
    call set "ResolvedDest=%%RawPath%%"
    if defined ResolvedDest set "ResolvedDest=!ResolvedDest:"=!"
)

:: Fallback destinations
if not defined ResolvedDest set "ResolvedDest=%USERPROFILE%\%FolderName%"
if not exist "!ResolvedDest!" set "ResolvedDest=%USERPROFILE%\%FolderName%"
if not exist "!ResolvedDest!" if exist "%USERPROFILE%\OneDrive\%FolderName%" set "ResolvedDest=%USERPROFILE%\OneDrive\%FolderName%"
if defined OneDrive if not exist "!ResolvedDest!" if exist "%OneDrive%\%FolderName%" set "ResolvedDest=%OneDrive%\%FolderName%"

:: Ensure target destination folder exists
if not exist "!ResolvedDest!" mkdir "!ResolvedDest!" 2>nul

echo [Restoring] %FolderName%...
echo    Target: "!ResolvedDest!"

:: Robocopy merge (does not delete existing files created after backup)
robocopy "%SourceFolder%" "!ResolvedDest!" /E /COPY:DAT /DCOPY:DAT /XJ /R:1 /W:1 /NP /NDL /NFL /NJH /NJS /LOG+:"%LogFile%"

if errorlevel 8 (
    echo    [ERROR] Failed to restore some files in %FolderName%.
    set "TotalErrors=1"
) else (
    echo    [OK] Restored %FolderName%.
)

echo ------------------------------------------------------
goto :eof
