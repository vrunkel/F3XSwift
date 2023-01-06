# F3XSwift
macOS GUI to the f3 - Fight Flash Fraud - tool and based on [F3X](https://github.com/insidegui/F3X) and based on [F3](https://github.com/AltraMayor/f3).

The tool uses f3write and f3read to test  your SD card for correct capacity as well as defects. 

## Installation
1. Navigate to [Releases](https://github.com/vrunkel/F3XSwift/releases) tab
2. Latest Release > Assets > Download `F3XSwift.app.zip`
3. Finder > Downloads > Double click `F3XSwift.app.zip` to extract it
4. Double click `F3XSwift.app` to run it

## Usage
1. Select the SD card you want to test. 
2. Press the Test button. 
3. The app asks you to grant permission to access the selected sd card (App sandbox requirement) and then f3write starts to write to the disk. You see the progress. Expect that this may take several hours for larger or slow cards. 
4. After successfull writing the f3read command is started. Again you will see progress and when finished a result of the test.

You can skip the writing process if the card already contains test files written by f3write.

[See more on using F3XSwift](/docs/usage.md)

## To come
Output of full testlog as well as storage of results per card are planned for one of the upcoming updates.
