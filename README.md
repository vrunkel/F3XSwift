# F3XSwift
macOS GUI to the f3 - Fight Flash Fraud - tool and based on [F3X](https://github.com/insidegui/F3X) and based on [F3](https://github.com/AltraMayor/f3).

The tool uses f3write and f3read to test  your SD card for correct capacity as well as defects. 

## Requirements

macOS 13 (Ventura) or later, including macOS 26 (Tahoe). Runs natively on both Apple Silicon and Intel Macs.

## What's new in 1.2

- Updated for macOS Tahoe (macOS 26) and Apple Silicon: the bundled `f3write`/`f3read` are now universal (arm64 + x86_64) binaries built from [f3](https://github.com/AltraMayor/f3) v10.0 — no Rosetta required.
- Updated output parsing for f3 v10 (progress, completion detection, and results).
- Migrated off deprecated `Process` APIs and fixed several potential crashes in output handling.
- New app icon.
- Project modernized for current Xcode (deployment target macOS 13, no deprecated `--deep` code signing).

## Installation
1. Navigate to [Releases](https://github.com/vrunkel/F3XSwift/releases) tab
2. Latest Release > Assets > Download `F3XSwift.app.zip`
3. Finder > Downloads > Double click `F3XSwift.app.zip` to extract it
4. Double click `F3XSwift.app` to run it

## Usage
1. Select the SD card you want to test. 
2. Press the Test button. 
3. The app asks you to grant temporary access to the selected SD card (an App Sandbox requirement), and then `f3write` starts writing to the disk. You see the progress. Expect this to take several hours for larger or slower cards.
4. After successfull writing the f3read command is started. Again you will see progress and when finished a result of the test.

You can skip the writing process if the card already contains test files written by f3write.

[See more on using F3XSwift](/docs/usage.md)
