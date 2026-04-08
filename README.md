# 🦷 ELEGOO Saturn 4 Ultra 16K Profile Patch for CHITUBOX Dental

> A small automated patch that adds the **ELEGOO Saturn 4 Ultra 16K** printer profile to **CHITUBOX Dental**.

The script does all the heavy lifting for you: it automatically finds where the program is installed, correctly copies the printer models and settings, and adds them to your user profile. Just run it and choose your preferred mode!

---

## 🚀 Installation Guide

> **Important:** The script modifies system program folders and requires **Administrator privileges**. Don't worry — it's completely safe and creates automatic backups of your original files.

1. **Download the files** — grab the patch archive (click `Code` → `Download ZIP`).
2. **Extract the archive** — unzip all files into a regular folder on your PC. Do **not** run the script directly from inside the ZIP file.
3. **Close CHITUBOX** — make sure CHITUBOX Dental is completely closed before proceeding.
4. **Check the files** — make sure the `Data` folder is located right next to the `Install.bat` file.
5. **Run** — right-click `Install.bat` and select 🛡️ **"Run as administrator"**.
6. Follow the prompts in the console window that appears.

---

## ⚙️ Operation Modes

When launched, the script will ask you to choose one of three options. Press `1`, `2`, or `3`:

### `[1]` ADD
Creates a new **"Ultra 16K"** printer profile without touching the existing **"Ultra"** profile.

| | |
|---|---|
| ✅ **Pros** | Both printers will be available in your software |
| ❌ **Cons** | Print time estimation may be inaccurate for the 16K version |

---

### `[2]` REPLACE
Completely **replaces** the standard Saturn 4 Ultra profile with the new 16K version.

| | |
|---|---|
| ✅ **Pros** | Print time in the software will be displayed correctly |
| ❌ **Cons** | The original Saturn 4 Ultra (non-16K) profile will be removed from the list |

---

### `[3]` RESTORE
Removes the 16K patch and safely **restores** your original CHITUBOX Dental files from the automatic backup.

| | |
|---|---|
| ✅ **Pros** | Safely rolls back to factory settings without needing to reinstall the software |
| ℹ️ **Note** | You must have used the ADD or REPLACE mode at least once for the backup to exist |

---
