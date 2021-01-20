//
//  F3STestAndProgressWindowController.swift
//  F3XSwift
//
//  Created by Volker Runkel on 12.01.21.
//  Copyright © 2021 ecoObs GmbH. All rights reserved.
//

import Cocoa

class F3STestAndProgressWindowController: NSWindowController {

    @IBOutlet weak var volumeTestLabel: NSTextField!
    @IBOutlet weak var testProgress: NSProgressIndicator!
    @IBOutlet weak var explanationField: NSTextField!
    @IBOutlet weak var statsField: NSTextField!
    
    var runner: F3SRunner?
    var volume: F3Volume?
    var skipWrite: Bool = false
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func createTempBookmark() {
        guard let volume = self.volume else {
            return
        }
        let op = NSOpenPanel()
        op.canChooseFiles = false
        op.canChooseDirectories = true
        op.message = "Please confirm write permissions for the selected volume"
        op.directoryURL = volume.mountPoint
        if op.runModal() == .OK {
            do {
                let _ = try op.url?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch let error as NSError {
                print("Set Bookmark Fails: \(error.description)")
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.window!.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse(rawValue: -3))
                }
            }
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.window!.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse(rawValue: -2))
            }
        }
    }
        
    func runTest() {
        guard let volume = self.volume else {
            return
        }
        
        self.volumeTestLabel.stringValue = volume.name
        
        self.runner = F3SRunner.runnerWithVolume(at: volume.mountPoint, progressHandler: { (runner) in
            switch runner.state {
            case .F3SRunnerStateWaiting:
                self.explanationField.stringValue = "Waiting..."
                self.testProgress.isIndeterminate = true
                self.testProgress.startAnimation(nil)
                self.statsField.stringValue = ""
            case .F3SRunnerStateWriting:
                if self.testProgress.isIndeterminate {
                    self.explanationField.stringValue = "Writing test files"
                    self.testProgress.doubleValue = 0.0
                    self.testProgress.isIndeterminate = false
                    self.testProgress.startAnimation(nil)
                }
                self.testProgress.doubleValue = runner.progress
                if runner.info?.count ?? 0 > 0 {
                    var statString = ""
                    statString += runner.info!["speed"] ?? " "
                    statString += " - "
                    statString += runner.info!["eta"] ?? " "
                    self.statsField.stringValue = statString
                }
            case .F3SRunnerStateReading:
                if self.explanationField.stringValue != "Reading test files" {
                    self.explanationField.stringValue = "Reading test files"
                    self.statsField.stringValue = "This can take several minutes"
                    self.testProgress.doubleValue = 0.0
                    self.testProgress.isIndeterminate = false
                    self.testProgress.startAnimation(nil)
                }
                self.testProgress.doubleValue = runner.progress
                if runner.info?.count ?? 0 > 0 {
                    var statString = ""
                    statString += runner.info!["speed"] ?? " "
                    statString += " - "
                    statString += runner.info!["eta"] ?? " "
                    self.statsField.stringValue = statString
                }
                /*self.testProgress.stopAnimation(nil)
                self.testProgress.doubleValue = 1
                self.testProgress.isIndeterminate = true
                self.testProgress.startAnimation(nil)*/
                
            case .F3SRunnerStateCancelled:
                self.testProgress.stopAnimation(nil)
                self.window!.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse(rawValue: -1))
            case .F3SRunnerStateCompleted:
                self.testProgress.stopAnimation(nil)
                self.window!.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse(rawValue: 1))
            case .F3SRunnerStateFailed:
                self.window!.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse(rawValue: 10))
            default:
                ()
            }
        })
        
        self.runner!.volumeID = volume.volumeIdentifier
        self.runner!.run(skipWrite: self.skipWrite)
    }
    
    @IBAction func cancelTest(_ sender: Any?) {
        self.runner!.cancel()
    }
    
}
