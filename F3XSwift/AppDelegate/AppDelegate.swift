//
//  AppDelegate.swift
//  F3XSwift
//
//  Created by Volker Runkel on 11.01.21.
//  Copyright © 2021 ecoObs GmbH. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var volumeTable: NSTableView!

    @IBOutlet weak var testButton: NSButton!
    @IBOutlet weak var skipWriteButton: NSButton!
    
    var testAndProgressController: F3STestAndProgressWindowController?
    var resultDisplayController: F3SResultsController?
    
    var datasource: F3VolumeDataSource = F3VolumeDataSource()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        self.datasource.addObserver(self, forKeyPath: "updated", options: .new, context: nil)
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "F3XSwift")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
    
    @IBAction func runTest(_ sender: Any?) {
        
        /*if self.datasource.volumes![self.volumeTable.selectedRow].freespace == "0 KB" && self.skipWriteButton.state == .off {
            check wether 0 kb due to test files or other content. test files get deleted, other content doesn't.
        }*/
        
        if self.testAndProgressController == nil {
            self.testAndProgressController = F3STestAndProgressWindowController(windowNibName: "F3STestAndProgressWindowController")
        }
        
        let row = self.volumeTable.selectedRow
        
        self.testAndProgressController?.volume = (self.datasource.volumes![row] )
        self.testAndProgressController?.skipWrite = self.skipWriteButton.state == .on
        
        self.testAndProgressController?.createTempBookmark()
        
        self.window.beginSheet(self.testAndProgressController!.window!) { (response) in
            switch response.rawValue {
            case -3:
                self.testAndProgressController?.close()
                self.testAndProgressController = nil
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Couldn't create security bookmark"
                    alert.informativeText = "For some reason I wasn't able to create a security bookmark. Thus write access to the selected volume is not possible. Canceling test."
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            case -2:
                self.testAndProgressController?.close()
                self.testAndProgressController = nil
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Canceled security bookmark"
                    alert.informativeText = "You canceled creation of a security bookmark. Thus write access to the selected volume is not possible. Canceling test."
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            case -1:
                // user cancled
                self.testAndProgressController?.close()
                self.testAndProgressController = nil
            case 0:
                self.testAndProgressController?.close()
                self.testAndProgressController = nil
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Failed to start task"
                    alert.informativeText = "The testing task couldn't be started. Canceling test."
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            case 1:
                if let results = self.testAndProgressController?.runner?.results {
                    DispatchQueue.main.async {
                        self.datasource.volumes![row].testResults = results
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                            self.showResults(volume: self.datasource.volumes![row])
                        }
                        
                        if let identifier = self.datasource.volumes![row].volumeIdentifier {
                            let request : NSFetchRequest<SDCard> = SDCard.fetchRequest()
                            request.predicate = NSPredicate(format: "identifier == %@", identifier)
                            if let cards = try? self.persistentContainer.viewContext.fetch(request), !cards.isEmpty {
                                // update
                            } else {
                                let card = NSEntityDescription.insertNewObject(forEntityName: "SDCard", into: self.persistentContainer.viewContext) as! SDCard
                                card.createdAt = Date()
                                card.lastTestedAt = Date()
                                card.identifier = identifier
                                card.lastResult = results.approved
                                card.lastRawRead = results.rawReadingData
                                card.lastRawWrite = results.rawWritingData
                                
                                self.persistentContainer.viewContext.processPendingChanges()
                                try? self.persistentContainer.viewContext.save()
                            }
                        }
                    }
                }
                else {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Failed to get test results"
                        alert.informativeText = "The test finished successfully yet test results could not be obtained."
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                }
            case 10:
            self.testAndProgressController?.close()
            self.testAndProgressController = nil
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Failed to start write task"
                alert.informativeText = "The write test couldn't be started. The card has no empty space!"
                alert.alertStyle = .warning
                alert.runModal()
            }
            case 11:
            self.testAndProgressController?.close()
            self.testAndProgressController = nil
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Failed to start read task"
                alert.informativeText = "The read test couldn't be started. The card does not contain test files from a write test."
                alert.alertStyle = .warning
                alert.runModal()
            }
            default: ()
            }
        }
        
        self.testAndProgressController?.runTest()
        
    }
    
    func showResults(volume: F3Volume) {
        if self.resultDisplayController == nil {
            self.resultDisplayController = F3SResultsController(windowNibName: "F3SResultsController")
        }
        self.resultDisplayController?.volume = volume
        self.window.beginSheet(self.resultDisplayController!.window!) { (response) in
            self.testAndProgressController?.close()
            self.testAndProgressController = nil
            self.resultDisplayController!.close()
            self.resultDisplayController = nil
            self.volumeTable.reloadData()
        }
        self.resultDisplayController?.showTestResult()
    }

    @IBAction func ejectVolume(_ sender: Any?) {
        let row = self.volumeTable.clickedRow
        let allowSelection = self.volumeTable.delegate?.tableView?(self.volumeTable, shouldSelectRow: row)
        if row == NSNotFound || row < 0 || !(allowSelection ?? false) {
            return
        }
        guard let volume = self.datasource.volumes?[row] else {
            return
        }
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: volume.mountPoint)
        }
        catch let error {
            NSApp.presentError(error)
        }
    }
    
    @IBAction func deleteTestFiles(_ sender: Any?) { // permission problem, needs another solution
        let row = self.volumeTable.clickedRow
        
        let allowSelection = self.volumeTable.delegate?.tableView?(self.volumeTable, shouldSelectRow: row)
        if row == NSNotFound || row < 0 || !(allowSelection ?? false) {
            return
        }
        
        guard let volume = self.datasource.volumes?[row] else {
            return
        }
        
        let op = NSOpenPanel()
        op.canChooseFiles = false
        op.canChooseDirectories = true
        op.message = "Please confirm test file deletion on volume"
        op.directoryURL = volume.mountPoint
        if op.runModal() == .OK {
            
            do {
                var fileCounter = 1
                while FileManager.default.fileExists(atPath: volume.mountPoint.appendingPathComponent("\(fileCounter).h2w").path) {
                    try FileManager.default.removeItem(at: volume.mountPoint.appendingPathComponent("\(fileCounter).h2w"))
                    fileCounter += 1
                }
            }
            catch let error {
                NSApp.presentError(error)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "updated" {
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.volumeTable.reloadData()
                if self.datasource.volumes != nil {
                    for (index,aVolume) in self.datasource.volumes!.enumerated() {
                        if let uniqueID = aVolume.volumeIdentifier {
                            let request : NSFetchRequest<SDCard> = SDCard.fetchRequest()
                            request.predicate = NSPredicate(format: "identifier == %@", uniqueID)
                            if let cards = try? self.persistentContainer.viewContext.fetch(request) {
                                if cards.count == 1 {
                                    //let testResult = cards.first!.lastResult
                                    //let testedAt = cards.first!.lastTestedAt
                                    let testResult = F3STestResults.testResultsWithRaw(writingData: cards.first!.lastRawWrite, readingData: cards.first!.lastRawRead)
                                    testResult.volumeID = uniqueID
                                    testResult.testDate = cards.first!.lastTestedAt
                                    self.datasource.volumes![index].testResults = testResult
                                }
                                else if cards.count > 1 {
                                   print("Multiple entries for this UUID, how can that happen?")
                                }
                            }
                            
                        }
                    }
                }
            })
            return
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.datasource.volumes?.count ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
           if self.datasource.volumes == nil {
               return nil
           }
           
        guard let volume =  self.datasource.volumes?[row] else {
            return nil
        }
   
        if let cell = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("volumeCell"), owner: nil) as? F3SDiskCellView {
            cell.textField?.stringValue = volume.name
            cell.imageView?.image = volume.icon
            cell.freeSpaceTextField.stringValue = "Free: " + volume.freespace
            cell.overallSpaceTextField.stringValue = "Size: " + volume.size
                        
            if volume.testResults == nil {
                cell.testResultTextField.isHidden = true
            }
            else {
                cell.testResultTextField.isHidden = false
                if volume.testResults!.approved {
                    cell.testResultTextField.stringValue = "Approved"
                    cell.testResultTextField.textColor = NSColor.systemGreen
                } else {
                    cell.testResultTextField.stringValue = "Failed"
                    cell.testResultTextField.textColor = NSColor.systemRed
                }
                if volume.testResults!.testDate != nil {
                    cell.testDateTextField.objectValue = volume.testResults!.testDate!
                }
                else {
                    cell.testDateTextField.stringValue = "–––"
                }
            }
            
            if volume.isUsable {
                cell.textField?.textColor = NSColor.controlTextColor
                cell.imageView?.isEnabled = true
                cell.freeSpaceTextField.textColor = NSColor.controlTextColor
                cell.overallSpaceTextField.textColor = NSColor.controlTextColor
            }
            else {
                cell.textField?.textColor = NSColor.disabledControlTextColor
                cell.imageView?.isEnabled = false
                cell.freeSpaceTextField.textColor = NSColor.disabledControlTextColor
                cell.overallSpaceTextField.textColor = NSColor.disabledControlTextColor
            }
            
            return cell
        }
        
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.volumeTable.selectedRow > -1 {
            if self.datasource.volumes![self.volumeTable.selectedRow].isUsable {
                self.testButton.isEnabled = true
            }
            else {
                self.testButton.isEnabled = false
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard let volume =  self.datasource.volumes?[row] else {
            return false
        }
        return volume.isUsable
    }
    
}

fileprivate func convertFromNSUserInterfaceItemIdentifier(_ input: NSUserInterfaceItemIdentifier) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
    return NSUserInterfaceItemIdentifier(rawValue: input)
}
