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

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func runTest(_ sender: Any?) {
        if self.testAndProgressController == nil {
            self.testAndProgressController = F3STestAndProgressWindowController(windowNibName: "F3STestAndProgressWindowController")
        }
        self.testAndProgressController?.volume = (self.datasource.volumes![self.volumeTable.selectedRow] )
        self.testAndProgressController?.skipWrite = self.skipWriteButton.state == .on
        
        self.testAndProgressController?.createTempBookmark()
        
        self.window.beginSheet(self.testAndProgressController!.window!) { (response) in
            switch response.rawValue {
            case -3: print("Bookmark error")
            case -2: print("User cancel bookmark")
            case 0:
                self.datasource.volumes![self.volumeTable.selectedRow].testResults = self.testAndProgressController!.runner!.results!
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.showResults(volume: self.datasource.volumes![self.volumeTable.selectedRow])
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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "updated" {
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0, execute: {
                self.volumeTable.reloadData()
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
