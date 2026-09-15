<p align="right">
  <a href="README_FA.md"> <strong>فارسی</strong></a>
</p>

---

# Windows User Libraries & Shell Folders Backup Utility

A fast, lightweight, and automated Windows batch utility designed to safely back up essential user libraries (Desktop, Downloads, Documents, Pictures, Music, and Videos) using the high-performance **Robocopy** engine.

Unlike naive backup scripts that rely solely on hardcoded paths, this tool dynamically queries the Windows Registry (`User Shell Folders`) to detect custom folder locations, redirected drives, and Microsoft OneDrive synchronizations.

---

## ✨ Features

- **🔑 Automatic Elevation (UAC):** Automatically requests administrator privileges via PowerShell if not already running as Administrator.
- **🧠 Dynamic Registry Resolution:** Queries `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders` to accurately pinpoint custom or relocated user paths.
- **☁️ Smart OneDrive Detection:** Seamlessly identifies and backs up folders even if they have been relocated or redirected to Microsoft OneDrive.
- **⚡ Robust Robocopy Engine:** Utilizes Robocopy with `/E`, `/COPY:DAT`, and `/DCOPY:DAT` flags to preserve files, directory structures, extended attributes, and timestamps.
- **🛡️ Recursion & Junction Safety:** Excludes Junction Points (`/XJ`) to prevent infinite recursion loops and automatically excludes the target backup folder (`/XD`).
- **⏳ Low-Latency Retries:** Configured with `/R:1 /W:1` to skip stubborn, locked files without freezing the backup process.
- **📦 Fully Portable:** Backups are stored in a dedicated `Windows Backup` folder directly next to the script, making it ideal for running from an external hard drive or USB stick.

---

## 📂 Backed-Up Libraries

| Library | Value Name / Registry Reference |
| :--- | :--- |
| **Desktop** | `Desktop` |
| **Downloads** | `{374DE290-123F-4565-9164-39C4925E467B}` |
| **Documents** | `Personal` |
| **Music** | `My Music` |
| **Pictures** | `My Pictures` |
| **Videos** | `My Video` |

---

## 🚀 How to Use

1. Save the script with a `.bat` extension (e.g., `Windows-Backup.bat`).
2. Place the file in the destination drive where you want your backup stored (e.g., on a USB drive or secondary storage partition).
3. **Double-click** the script to execute it.
4. Confirm the **UAC** prompt when asked for Administrator permissions.
5. The script will back up all libraries into a newly created folder named **`Windows Backup`**.
6. The terminal will display progress and exit automatically after 10 seconds.

---

## 💻 System Requirements

- **OS:** Windows 7, Windows 8.1, Windows 10, or Windows 11.
- **PowerShell:** Required for automatic UAC elevation.
- **Permissions:** Administrator access (requested automatically).
