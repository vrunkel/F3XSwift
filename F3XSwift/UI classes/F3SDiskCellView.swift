//
//  DiskCellView.swift
//  F3XSwift
//
//  Created by Volker Runkel on 11.01.21.
//  Copyright © 2021 ecoObs GmbH. All rights reserved.
//

import Cocoa

class F3SDiskCellView: NSTableCellView {

    @IBOutlet var testResultTextField: NSTextField!
    
    @IBOutlet var freeSpaceTextField: NSTextField!
    @IBOutlet var overallSpaceTextField: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
