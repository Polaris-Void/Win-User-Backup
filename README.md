<div align="center">

![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6?logo=windows&logoColor=white)

[English](README.md) | فارسی

</div>

# Windows User Folders Backup & Restore Utility

A fast, lightweight, and automated pair of Windows batch scripts. **`Backup.bat`** safely copies your essential user folders (Desktop, Downloads, Documents, Pictures, Music, and Videos) to `C:\User Backup` using the high-performance **Robocopy** engine, and **`Restore.bat`** merges them back into your profile without overwriting or deleting anything.

Unlike naive backup scripts that rely solely on hardcoded paths, this tool dynamically queries the Windows Registry (`User Shell Folders`) to detect custom folder locations, redirected drives, and Microsoft OneDrive synchronizations.

---

## ✨ Features

### 📥 Backup.bat

- **🔑 Automatic Elevation (UAC):** Relaunches itself as Administrator through PowerShell (`RunAs`) when needed. A guard flag prevents endless relaunch loops if elevation fails.
- **🧠 Dynamic Registry Resolution:** Reads `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders` to find the real folder paths. Value names containing spaces (`My Music`, `My Pictures`, `My Video`) are parsed correctly, and `%USERPROFILE%`-style variables are expanded.
- **☁️ Smart Fallback Chain:** Registry path → standard profile folder → OneDrive sync folders (`%OneDrive%`, `%OneDriveConsumer%`, `%OneDriveCommercial%`, `%USERPROFILE%\OneDrive`).
- **⚡ Robust Robocopy Engine:** Uses `/E /COPY:DAT /DCOPY:DAT` to preserve files, directory structures, attributes, and timestamps. Re-runs only copy new or changed files.
- **🛡️ Recursion & Junction Safety:** Excludes junction points (`/XJ`) and the backup folder itself (`/XD "C:\User Backup"`).
- **⏳ Low-Latency Retries:** `/R:1 /W:1` skips stubborn, locked files instead of freezing the backup.
- **🚫 Zero Log Files:** No `.log` file is ever created and all Robocopy output is silenced. Any existing `*.log` files in the top level of `C:\User Backup` are purged at launch (subfolders are never touched, so log files you backed up from your own folders stay safe).
- **🎨 Clean, Flicker-Free Console:** Cyan theme, boxed header, and one live status line per folder with dot padding.
- **⏱️ Non-Freezing Countdown:** A 10-second inline countdown (`10..1`) that ends instantly on any keypress and keeps running even in elevated or redirected consoles.

### 📤 Restore.bat

- **✅ Confirmation Prompt:** Nothing happens until you press `Y`. Pressing `N` cancels.
- **🧩 Non-Destructive Merge:** Restores only files that are missing from your profile. Existing files are never overwritten and nothing is ever deleted (`/XC /XN /XO`, no `/MIR` or `/PURGE`).
- **🎯 Smart Destinations:** Uses the same registry → profile → OneDrive resolution, so files land in the folders Windows actually uses. If a folder does not exist yet, it is created.
- **⏭️ Graceful Skipping:** Folders that are not present in the backup are marked `SKIP`.
- **🔒 Backup Stays Untouched:** `C:\User Backup` is only read, never modified.
- **🎨 Same Look & Feel:** Identical header, status lines, and countdown as `Backup.bat`.

---

## 📂 Backed-Up Folders

| Folder        | Backup Location            | Registry Value Name                      |
| ------------- | -------------------------- | ---------------------------------------- |
| **Desktop**   | `C:\User Backup\Desktop`   | `Desktop`                                |
| **Downloads** | `C:\User Backup\Downloads` | `{374DE290-123F-4565-9164-39C4925E467B}` |
| **Documents** | `C:\User Backup\Documents` | `Personal`                               |
| **Music**     | `C:\User Backup\Music`     | `My Music`                               |
| **Pictures**  | `C:\User Backup\Pictures`  | `My Pictures`                            |
| **Videos**    | `C:\User Backup\Videos`    | `My Video`                               |

---

## 🚀 How to Use

### Backup

1. Download `Backup.bat` (and `Restore.bat`) and save them anywhere, for example on your Desktop.
2. **Double-click** `Backup.bat`.
3. Confirm the **UAC** prompt when asked for Administrator permissions.
4. Watch the live status of each folder. All data is copied to **`C:\User Backup`**.
5. The window closes after 10 seconds, or immediately when you press any key.

### Restore

1. If you are on a fresh Windows install or another PC, first copy your backup so that it is located at **`C:\User Backup`**.
2. **Double-click** `Restore.bat` and confirm the **UAC** prompt.
3. Press **`Y`** to confirm the restore (or `N` to cancel).
4. Missing files are merged back into your profile folders. The window closes after 10 seconds, or on any keypress.

---

## 🖥️ Console Preview

```text
+============================================================+
|                    USER PROFILE BACKUP                     |
+============================================================+

Target Path  : C:\User Backup
User Profile : C:\Users\YourName

[+] Desktop ....................................... [  DONE  ]
[+] Downloads ..................................... [  DONE  ]
[+] Documents ..................................... [  DONE  ]
[+] Music ......................................... [  DONE  ]
[+] Pictures ...................................... [  DONE  ]
[+] Videos ........................................ [  SKIP  ]

Backup completed successfully.

Closing in  7 s ...  press any key to exit
```

| Status       | Meaning                                                                                 |
| ------------ | --------------------------------------------------------------------------------------- |
| `[  DONE  ]` | The folder was processed successfully.                                                  |
| `[  SKIP  ]` | The source folder (Backup) or the backed-up folder (Restore) was not found.             |
| `[ FAILED ]` | Robocopy reported an error (for example, files that stayed locked after the retry).     |

---

## ⚙️ Customization

- **Change the backup location:** Edit the `BackupRoot` line near the top of **both** scripts (`set "BackupRoot=C:\User Backup"`).
- **Let newer backup files replace older ones on restore:** In `Restore.bat`, replace `/XC /XN /XO` with `/XO`. Existing files that are newer than the backup are still preserved.
- **Also purge logs recursively:** In `Backup.bat`, add `/s` to the `del` command on the log-purge line. Note that this also deletes `.log` files that belong to your backed-up data.

---

## ⚠️ Notes & Limitations

- The backup lives on your system drive by default. To protect against disk failure, copy `C:\User Backup` to an external drive or cloud storage as well.
- Backups are additive: files that you delete from your profile later are **not** removed from `C:\User Backup`.
- If OneDrive Files On-Demand is enabled, online-only files may be downloaded while they are copied.
- Run the scripts from your own administrator account. If UAC elevates through a different account, `%USERPROFILE%` and the registry hive refer to that account instead.
- Only the six standard folders are covered. `AppData`, browser profiles, and installed programs are not included.

---

## 💻 System Requirements

- **OS:** Windows 7, Windows 8.1, Windows 10, or Windows 11.
- **PowerShell:** Required for automatic UAC elevation and the countdown timer.
- **Permissions:** Administrator access (requested automatically).

---

## 📄 License

Distributed under the [Apache-2.0 License](LICENSE).

---

## ⚖️ Absolute Legal Disclaimer, Waiver & Limitation of Liability

This project is licensed under the **Apache License, Version 2.0**. This disclaimer expressly supplements, expands, and reinforces **Section 7 (Disclaimer of Warranty)** and **Section 8 (Limitation of Liability)** of the Apache License 2.0, and shall control to the maximum extent permitted by applicable law.

**FOR EDUCATIONAL, RESEARCH, AND INFORMATIONAL PURPOSES ONLY. NO COMMERCIAL WARRANTY OR LIABILITY IS ASSUMED.**

### 1. Complete Disclaimer of All Warranties
To the maximum extent permitted by applicable law, the Software (including all code, documentation, data, and related materials) is provided strictly on an **"AS IS"** and **"AS AVAILABLE"** basis, without any warranties or conditions of any kind, whether express, implied, statutory, customary, or otherwise. This includes, without limitation, any warranties of merchantability, fitness for a particular purpose, non-infringement, title, security, accuracy, completeness, uninterrupted or error-free operation, or freedom from viruses or other harmful components. The author(s), copyright holder(s), maintainer(s), and contributor(s) expressly disclaim all such warranties.

### 2. Absolute Limitation of Liability
Under no circumstances and under no legal theory (whether in contract, tort — including negligence, gross negligence, and willful misconduct — strict liability, product liability, or otherwise) shall the author(s), maintainer(s), contributor(s), or copyright holder(s) be liable for any damages whatsoever, including but not limited to direct, indirect, incidental, special, consequential, exemplary, punitive, or any other damages (including loss of data, profits, revenue, business interruption, system failure, hardware damage, security breaches, personal injury, or any other loss), arising out of or related to the use, inability to use, modification, distribution, or reliance upon the Software, even if advised of the possibility of such damages and even if any remedy fails of its essential purpose.

### 3. Assumption of All Risk & User Responsibility
Any use, cloning, modification, deployment, distribution, or reliance upon this Software is undertaken entirely at the user’s sole risk and discretion. The user is exclusively and solely responsible for:
- Ensuring full compliance with all applicable local, national, and international laws, regulations, export controls, and third-party terms;
- Evaluating the suitability, security, and legality of the Software for any purpose;
- Any consequences arising from its use or misuse.

Nothing in this repository constitutes legal, financial, cybersecurity, medical, architectural, or any other form of professional advice.

### 4. Broad Indemnification
By accessing, downloading, cloning, forking, viewing, compiling, distributing, or using any part of this repository, you irrevocably agree to indemnify, defend, and hold harmless the author(s), contributor(s), and copyright holder(s) from and against any and all claims, demands, actions, proceedings, liabilities, damages, losses, costs, and expenses (including reasonable attorneys’ fees and legal costs) arising out of or related to your access, use, misuse, modification, distribution, or violation of this disclaimer or any applicable law.

### 5. Severability & Maximum Enforceability
If any provision of this disclaimer is held to be unenforceable or invalid under applicable law, such provision shall be modified to the minimum extent necessary to make it enforceable, or if modification is not possible, severed. The remaining provisions shall continue in full force and effect. This disclaimer shall be interpreted to provide the maximum protection permitted by law.

### 6. No Waiver of Non-Waivable Rights
Nothing in this disclaimer is intended to exclude or limit any liability that cannot be excluded or limited under applicable mandatory law (including liability for death or personal injury caused by negligence in jurisdictions where such exclusion is prohibited). In such cases, liability is limited to the maximum extent permitted by law.
