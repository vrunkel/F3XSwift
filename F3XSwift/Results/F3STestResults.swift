//
//  F3STestResults.swift
//  F3XSwift
//
//  Created by Volker Runkel on 12.01.21.
//  Copyright © 2021 ecoObs GmbH. All rights reserved.
//

import Foundation

class F3STestResults {
    
    var volumeID: String?
    var createdAt: Date?
    
    var rawWritingData: String? {
        didSet {
            self.parseWritingData()
        }
    }
    var rawReadingData: String? {
        didSet {
            self.parseReadingData()
        }
    }
    
    var data: String?
    var dataLoss: String?
    var corrupted: String?
    var isSlightlyChanged: String?
    var overwritten: String?
    var avgWritingSpeed: String?
    var avgReadingSpeed: String?
    var testDate: Date?
    
    var approved: Bool {
        let lost = (self.dataLoss ?? " 0 0.00").components(separatedBy: " ")[1]
        let corrupted = (self.corrupted ?? " 0 0.00").components(separatedBy: " ")[1]
        let isSlightlyChanged = (self.isSlightlyChanged ?? " 0 0.00").components(separatedBy: " ")[1]
        let overwritten = (self.overwritten ?? " 0 0.00").components(separatedBy: " ")[1]
        
        return lost == "0.00" && corrupted == "0.00" && isSlightlyChanged == "0.00" && overwritten == "0.00"
    }
    
    static func testResultsWithRaw(writingData: String?, readingData: String?) -> F3STestResults {
        let results = F3STestResults()
        results.rawWritingData = writingData
        results.rawReadingData = readingData
        results.testDate = Date()
        return results
    }
    
    init() {
        self.createdAt = Date()
    }
    
    private func parseWritingData() {
        // f3 <= 8 printed "Average writing speed:", f3 >= 9 prints "Average sequential write speed:"
        for marker in ["Average sequential write speed: ", "Average writing speed: "] {
            if let components = self.rawWritingData?.components(separatedBy: marker), components.count > 1 {
                self.avgWritingSpeed = components[1]
                return
            }
        }
    }

    private func parseReadingData() {
        let cleanedReadingData = self.rawReadingData?.replacingOccurrences(of: "\t", with: "")
        guard let components = cleanedReadingData?.components(separatedBy: "Data OK: "), components.count > 1 else {
            return
        }
        let dataLines = components[1].components(separatedBy: "\n")
        if dataLines.count < 6 {
            return
        }
        if dataLines[5].contains("Reading speed not available") || dataLines[5].contains("NO DATA") {
            return
        }
        self.data = dataLines[0].components(separatedBy: " ")[0]
        self.dataLoss = dataLines[1].components(separatedBy: ":")[1]
        self.corrupted = dataLines[2].components(separatedBy: ":")[1]
        self.isSlightlyChanged = dataLines[3].components(separatedBy: ":")[1]
        self.overwritten = dataLines[4].components(separatedBy: ":")[1]
        self.avgReadingSpeed = dataLines[5].components(separatedBy: ":")[1]
    }
    
}
