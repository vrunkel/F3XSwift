# F3XSwift
macOS GUI to the f3 - Fight Flash Fraud - tool and based on [F3X](https://github.com/insidegui/F3X) and based on [F3](https://github.com/AltraMayor/f3).

The tool uses f3write and f3read to test  your SD card for correct capacity as well as defects. 

## Usage
1. Select the SD card you want to test. 
2. Press the Test button. 
3. The app asks you to grant permission to access the selected sd card (App sandbox requirement) and then f3write starts to write to the disk. You see the progress. Expect that this may take several hours for larger or slow cards. 
4. After successfull writing the f3read command is started. Again you will see progress and when finished a result of the test.

You can skip the writing process if the card already contains test files written by f3write.
