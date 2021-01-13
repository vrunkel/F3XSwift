//
//  F3SResultsController.swift
//  F3XSwift
//
//  Created by Volker Runkel on 12.01.21.
//  Copyright © 2021 ecoObs GmbH. All rights reserved.
//

import Cocoa

class F3SResultsController: NSWindowController {

    @IBOutlet weak var volumeField: NSTextField!
    @IBOutlet weak var approvalStateField: NSTextField!
    @IBOutlet weak var resultsField: NSTextField!
    @IBOutlet weak var resultImageView: NSImageView!
    
    var volume : F3Volume?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func showTestResult() {
        self.volumeField.stringValue = self.volume?.name ?? "---"
        if self.volume?.testResults?.approved ?? false {
            self.approvalStateField.stringValue = "Success!"
            self.resultsField.stringValue = "Your card is ok!"
            self.resultImageView.image = NSImage(named: NSImage.menuOnStateTemplateName)
        }
        else {
            self.approvalStateField.stringValue = "Woops!"
            self.resultsField.stringValue = "Your card is either not genuine or It's about to die!"
            self.resultImageView.image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)
        }
    }
    
    @IBAction func closeSheet(_ sender: Any?) {
        self.window!.sheetParent!.endSheet(self.window!)
    }
    
}
