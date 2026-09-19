@echo off
setlocal EnableExtensions EnableDelayedExpansion
title User Profile Backup
chcp 65001 >nul

:: Request administrator privileges to allow writing to C:\ root
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "BackupRoot=C:\user_backup"
set "TotalErrors=0"

if not exist "%BackupRoot%" mkdir "%BackupRoot%"

cls
echo.
echo  ======================================================
echo               USER PROFILE BACKUP SYSTEM
echo  ======================================================
echo   Destination : %BackupRoot%
echo   User Profile: %USERPROFILE%
echo  ------------------------------------------------------
echo.

call :BackupFolder "Desktop"   "Desktop"
call :BackupFolder "Downloads" "{374DE290-123F-4565-9164-39C4925E467B}"
call :BackupFolder "Documents" "Personal"
call :BackupFolder "Music"     "My Music"
call :BackupFolder "Pictures"  "My Pictures"
call :BackupFolder "Videos"    "My Video"

echo.
echo  ======================================================
if "%TotalErrors%"=="0" (
    echo   [SUCCESS] All folders backed up successfully.
) else (
    echo   [WARNING] Backup completed with some errors.
)
echo  ======================================================
echo.
timeout /t 10
exit /b 0

:BackupFolder
set "FolderName=%~1"
set "ValueName=%~2"
set "RawPath="
set "ResolvedPath="

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
    call set "ResolvedPath=%%RawPath%%"
    if defined ResolvedPath set "ResolvedPath=!ResolvedPath:"=!"
)

if not defined ResolvedPath set "ResolvedPath=%USERPROFILE%\%FolderName%"
if not exist "!ResolvedPath!" set "ResolvedPath=%USERPROFILE%\%FolderName%"
if not exist "!ResolvedPath!" if exist "%USERPROFILE%\OneDrive\%FolderName%" set "ResolvedPath=%USERPROFILE%\OneDrive\%FolderName%"
if defined OneDrive if not exist "!ResolvedPath!" if exist "%OneDrive%\%FolderName%" set "ResolvedPath=%OneDrive%\%FolderName%"

if exist "!ResolvedPath!" (
    <nul set /p "=[*] Backing up %FolderName% ... "
    robocopy "!ResolvedPath!" "%BackupRoot%\%FolderName%" /E /COPY:DAT /DCOPY:DAT /XJ /XD "%BackupRoot%" /R:1 /W:1 /NP /NDL /NFL /NJH /NJS >nul 2>&1
    if errorlevel 8 (
        echo [ERROR]
        set "TotalErrors=1"
    ) else (
        echo [DONE]
    )
) else (
    echo [-] %FolderName% ... [SKIPPED]
)
goto :eof
