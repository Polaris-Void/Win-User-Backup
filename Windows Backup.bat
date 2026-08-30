@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Windows Backup

:: Request administrator privileges if not already elevated.
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "BackupRoot=%~dp0Windows Backup"
set "Errors=0"

call :BackupFolder "Desktop" "Desktop"
call :BackupFolder "Downloads" "{374DE290-123F-4565-9164-39C4925E467B}"
call :BackupFolder "Documents" "Personal"
call :BackupFolder "Music" "My Music"
call :BackupFolder "Pictures" "My Pictures"
call :BackupFolder "Videos" "My Video"

if "%Errors%"=="0" (
    echo Windows Backup completed successfully.
) else (
    echo Windows Backup completed with errors.
)

timeout /t 10
exit /b

:BackupFolder
set "FolderName=%~1"
set "ValueName=%~2"
set "Source="
set "RawPath="

for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "%ValueName%" 2^>nul ^| find /i "%ValueName%"') do set "RawPath=%%B"

if defined RawPath (
    call set "Source=%%RawPath%%"
    if defined Source set "Source=!Source:"=!"
)

if not defined Source set "Source=%USERPROFILE%\%FolderName%"
if not exist "!Source!" set "Source=%USERPROFILE%\%FolderName%"
if not exist "!Source!" if exist "%USERPROFILE%\OneDrive\%FolderName%" set "Source=%USERPROFILE%\OneDrive\%FolderName%"
if defined OneDrive if not exist "!Source!" if exist "%OneDrive%\%FolderName%" set "Source=%OneDrive%\%FolderName%"

if exist "!Source!" (
    echo Backing up %FolderName%...
    robocopy "!Source!" "%BackupRoot%\%FolderName%" /E /COPY:DAT /DCOPY:DAT /XJ /XD "%BackupRoot%" /R:1 /W:1 /NP /NFL /NDL /NJH /NJS >nul
    if errorlevel 8 set "Errors=1"
) else (
    echo Source not found: %FolderName%
)

goto :eof