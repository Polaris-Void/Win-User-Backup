@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Windows Personal Folders Backup
chcp 65001 >nul

:: Request administrator privileges (required for writing directly to C:\ root)
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Set backup destination to C:\Windows Backup
set "BackupRoot=C:\Windows Backup"
set "LogFile=%BackupRoot%\Backup_Errors.log"
set "TotalErrors=0"

cls
echo ======================================================
echo          Windows Personal Folders Backup
echo ======================================================
echo Backup Destination: "%BackupRoot%"
echo.

:: Ensure destination directory exists
if not exist "%BackupRoot%" mkdir "%BackupRoot%"
if exist "%LogFile%" del "%LogFile%"

:: Backup standard personal shell folders
call :BackupFolder "Desktop"   "Desktop"
call :BackupFolder "Downloads" "{374DE290-123F-4565-9164-39C4925E467B}"
call :BackupFolder "Documents" "Personal"
call :BackupFolder "Music"     "My Music"
call :BackupFolder "Pictures"  "My Pictures"
call :BackupFolder "Videos"    "My Video"

echo.
echo ======================================================
if "%TotalErrors%"=="0" (
    echo [SUCCESS] All folders have been backed up successfully.
) else (
    echo [WARNING] Backup completed with errors.
    echo Please review the error log at:
    echo "%LogFile%"
)
echo ======================================================
echo Window will close automatically in 10 seconds...
timeout /t 10 >nul
exit /b 0

:: ========================================================
:: Subroutine: Detect real user folder path & copy files
:: ========================================================
:BackupFolder
set "FolderName=%~1"
set "ValueName=%~2"
set "RawPath="
set "ResolvedPath="

:: Query Windows Registry for user folder path (handles multi-word values like "My Music")
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

:: Expand environment variables (e.g. %USERPROFILE%)
if defined RawPath (
    call set "ResolvedPath=%%RawPath%%"
    if defined ResolvedPath set "ResolvedPath=!ResolvedPath:"=!"
)

:: Fallback mechanisms for default paths and OneDrive sync
if not defined ResolvedPath set "ResolvedPath=%USERPROFILE%\%FolderName%"
if not exist "!ResolvedPath!" set "ResolvedPath=%USERPROFILE%\%FolderName%"
if not exist "!ResolvedPath!" if exist "%USERPROFILE%\OneDrive\%FolderName%" set "ResolvedPath=%USERPROFILE%\OneDrive\%FolderName%"
if defined OneDrive if not exist "!ResolvedPath!" if exist "%OneDrive%\%FolderName%" set "ResolvedPath=%OneDrive%\%FolderName%"

if exist "!ResolvedPath!" (
    echo [Backing up] %FolderName%...
    echo    Source: "!ResolvedPath!"
    
    :: Robocopy flags:
    :: /E : Copy subdirectories, including empty ones
    :: /COPY:DAT /DCOPY:DAT : Preserve data, attributes, and timestamps
    :: /XJ : Exclude Junction Points (avoids infinite loops)
    :: /XD : Exclude backup directory itself to prevent recursive loops
    :: /R:1 /W:1 : Retry 1 time, wait 1 second on locked files
    robocopy "!ResolvedPath!" "%BackupRoot%\%FolderName%" /E /COPY:DAT /DCOPY:DAT /XJ /XD "%BackupRoot%" /R:1 /W:1 /NP /NDL /NFL /NJH /NJS /LOG+:"%LogFile%"
    
    :: In Robocopy, exit codes >= 8 indicate fatal errors
    if errorlevel 8 (
        echo    [ERROR] Failed to back up some files in %FolderName%.
        set "TotalErrors=1"
    ) else (
        echo    [OK] Finished %FolderName%.
    )
) else (
    echo [SKIP] Source folder for %FolderName% was not found.
)

echo ------------------------------------------------------
goto :eof
