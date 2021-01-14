## How to and when to use F3XSwift

F3XSwift is based on the f3 tools to test sd cards for wrong capacity as well as sector defects. With F3XSwift you get a simple UI on macOS to work with these tools. If you are interested in more detaisl you best [read up on f3](https://fight-flash-fraud.readthedocs.io/en/latest/index.html).

Otherwise lets go on. On your Mac this too will query the availbale volumes aka disks and display a list. It also determines by some simple parameters if a volume maybe an sd card. mainly by looking at the possibility to eject it and to write data to it. If a volume qualifies it can be slected and tested.

So, after choosing your sd card volume, press the Test button and the write test will commence. Due to App sandboxing you need to give permission to do so. For this reason a file open panel opens with the selected disk displayed. If you cancel here, the test will cancel as well. Otherwise f3write will fill the empty space on your sd card with fiels for testing. After finishing a read test is started automatically. 

![screenshot writing test files](/docs/writing-screen.png)

The read test uses f3read and can be started without writing if your sd card already has the test files. This can be done by choosing skip write before starting the test.

![screenshot reading test files](/docs/reading-screen.png)
