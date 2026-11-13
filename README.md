# YUCE Mac Cleaner

**English** · [Türkçe](README.tr.md) · [Português (Brasil)](README.pt-BR.md)

A native macOS app that shows what is inside the mysterious **“System Data”** in your storage settings and helps you safely reclaim disk space.

## Features

- **Disk overview:** used / free space and how much each category takes.
- **Quick Clean:** one button that removes only safe, regenerable data: app caches, logs, developer tool caches, Xcode DerivedData / DeviceSupport, unavailable simulators and the Trash. It never touches personal data, app settings or Xcode archives, and it skips caches of apps that are running.
- **13 categories**, each labeled *Safe to delete*, *Review before deleting* or *Info only*:
  App caches · Logs & crash reports · Xcode data · iOS simulators · Developer tool caches (npm, pip, uv, Gradle, Cargo, Maven, Go…) · Virtual machines, Android & Docker · iPhone/iPad backups · App support data · Mail & Messages attachments · Downloads · Trash · Time Machine local snapshots · System temporary files
- **Select All / Delete Selected** in every category, plus right-click → *Show in Finder*.
- **Folder Explorer:** browse any folder sorted by size and drill down with a double-click to find what is eating your disk.
- **Safe by default:** items are moved to the Trash (restorable) unless you choose *Delete Permanently*. Critical folders such as your home folder, Documents, Desktop, `~/Library` and `/System` are protected and cannot be deleted.
- **Languages:** English, Turkish and Brazilian Portuguese. The app follows your macOS language and falls back to English.

## Download

1. Download the latest **`YUCE-Mac-Cleaner-x.y.z.dmg`** from the [Releases page](https://github.com/bariscagriyuce/mac-cleaner/releases/latest).
2. Open the DMG and drag **YUCE Mac Cleaner** into the **Applications** folder.
3. Launch it from Applications or Launchpad.

The app is signed with a Developer ID and notarized by Apple, so it opens without security warnings. It runs on both Apple silicon and Intel Macs (macOS 14 or later).

## Requirements

- macOS 14 Sonoma or later (Apple silicon or Intel)
- Xcode or the Xcode Command Line Tools (`xcode-select --install`) to build

## Build & run

```bash
git clone https://github.com/bariscagriyuce/mac-cleaner.git
cd mac-cleaner
./build.sh
open "YUCE Mac Cleaner.app"
```

You can then drag `YUCE Mac Cleaner.app` to your Applications folder.

To build a signed and notarized DMG yourself, see the comments at the top of `release.sh`.

## Full Disk Access (recommended)

Some locations, such as the Trash, Mail data and iPhone backups, are protected by macOS. To scan them:

1. Open **System Settings › Privacy & Security › Full Disk Access**
2. Click **+** and add **YUCE Mac Cleaner**
3. Quit and reopen the app

The app also has an *Open Settings* button that takes you there.

## Language

The language is chosen from your macOS preferred languages (System Settings › General › Language & Region):

| System language | App language |
|---|---|
| Turkish | Turkish |
| Portuguese (any region) | Brazilian Portuguese |
| English | English |
| Anything else | English |

You can also choose a language for this app only under **System Settings › General › Language & Region › Applications**.

## Project structure

```
Sources/MacCleaner.swift     App, scanner, deletion logic and SwiftUI views
Sources/Localization.swift   Language detection and translations (tr, pt-BR)
build.sh                     Builds the .app bundle (universal) with swiftc
release.sh                   Signs, notarizes and packages a DMG
```

To add a language, add a dictionary to `Localization.swift`. The keys are the English texts.

## Disclaimer

Deleting files is always at your own risk. Read the category descriptions, prefer *Move to Trash*, and keep backups of important data.
