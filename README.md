# Windows Shell Folder Backup Script

A lightweight, automated Windows Batch script designed to back up core user shell folders (Desktop, Downloads, Documents, Music, Pictures, Videos) safely and efficiently using `Robocopy`.

## Key Features

- **Dynamic Path Resolution**: Automatically queries the Windows Registry (`User Shell Folders`) to determine exact directory paths, respecting custom user configurations.
- **OneDrive Fallback**: Automatically detects and falls back to standard user profile paths or OneDrive directory structures if registry keys are missing.
- **Admin Privilege Escalation**: Automatically prompts for Administrator privileges via PowerShell if executed without elevation.
- **Optimized Robocopy Integration**:
  - Excludes NTFS Junction Points to prevent infinite recursion loops.
  - Preserves file and directory timestamps and attributes (`DAT`).
  - Implements fast retry logic (`/R:1 /W:1`) to prevent hangs on locked files.
  - Self-excludes destination backup directories to prevent recursive copying.
- **Clean Execution**: Runs silently with error logging detection based on Robocopy exit status codes.

## Requirements

- **Operating System**: Windows 10, Windows 11, or Windows Server.
- **Privileges**: Administrative privileges (requested automatically upon execution).

## Usage

1. Download or clone this repository.
2. Place `win_backup.bat` in the target drive/folder where you wish to store the backups.
3. Run `win_backup.bat` (Right-click and "Run as administrator", or double-click to accept the UAC prompt).
4. The script will create a directory named `Windows Backup` in the same directory where the script resides and copy the target folders.

## Processed Folders

- **Desktop**
- **Downloads**
- **Documents**
- **Music**
- **Pictures**
- **Videos**

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for full details.
