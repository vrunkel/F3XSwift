## How to and when to use F3XSwift

F3XSwift is based on the f3 tools to test sd cards for wrong capacity as well as sector defects. With F3XSwift you get a simple UI on macOS to work with these tools. If you are interested in more details you best [read up on f3](https://fight-flash-fraud.readthedocs.io/en/latest/index.html).

Otherwise lets go on. On your Mac this tool will query the available volumes aka disks and display a list. It also determines by some simple parameters if a volume may be an sd card. Mainly by looking at the possibility to eject it and to write data to it. If a volume qualifies it can be slected and tested.

After choosing your SD card volume, press the Test button. Because of App Sandbox restrictions, a file-open panel displays the selected disk and asks you to grant temporary access. Select that volume and confirm the panel. If you cancel, the test will not start. Otherwise, `f3write` fills the empty space on the SD card with test files. After writing finishes, a read test starts automatically.

![screenshot writing test files](/docs/writing-screen.png)

The read test uses f3read and can be started without writing if your sd card already has the test files. This can be done by choosing skip write before starting the test.

![screenshot reading test files](/docs/reading-screen.png)

After the test finishes a simple result is displayed of either approved or failed test.

![screenshot test result](/docs/result.png)
