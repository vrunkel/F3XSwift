//
//  F3Volume.swift
//  F3XS
//
//  Created by Volker Runkel on 08.01.21.
//

import Foundation
import Cocoa
import DiskArbitration

struct F3Volume: Identifiable, Hashable {
    
    static func == (lhs: F3Volume, rhs: F3Volume) -> Bool {
        return lhs.mountPoint == rhs.mountPoint
    }
    

    init(mountPoint: URL, _usable: Bool, _volumeIdentifier: String?, attributes: Dictionary<FileAttributeKey,Any>?) {
        self.mountPoint = mountPoint
        self._usable = _usable
        self.volumeIdentifier = _volumeIdentifier
        self.attributes = attributes
        if self.volumeIdentifier == nil {
            self.fetchVolumeIdentifier()
        }
        self.fetchAttributes()
    }
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var mountPoint: URL
    private(set) var _usable : Bool
    
    var name : String {
        get {
            return self.mountPoint.lastPathComponent
        }
    }
    
    var icon : NSImage {
        get {
            return NSWorkspace.shared.icon(forFile: self.mountPoint.path)
        }
    }
    
    var isUsable : Bool {
        get {
            return self._usable
        }
    }
    
    var volumeIdentifier : String?
    
    var size : String {
        get {
            if self.attributes != nil {
                let bytecountFormatter = ByteCountFormatter()
                return bytecountFormatter.string(fromByteCount: self.attributes![FileAttributeKey.systemSize] as! Int64)
            }
            return "---"
        }
    }
    
    var freespace : String {
            if self.attributes != nil {
                let bytecountFormatter = ByteCountFormatter()
                return bytecountFormatter.string(fromByteCount: self.attributes![FileAttributeKey.systemFreeSize] as! Int64)
            }
            return "---"
        }

    
    var testResults : F3STestResults?
    
    private(set) var attributes: Dictionary<FileAttributeKey,Any>?

    private mutating func fetchAttributes() {
        do {
            self.attributes = try FileManager.default.attributesOfFileSystem(forPath: self.mountPoint.path)
        }
        catch let error {
            Swift.print(error)
        }
    }
    
    private mutating func fetchVolumeIdentifier() {
        guard let sessionRef = DASessionCreate(kCFAllocatorDefault) else {
            return
        }
        guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, sessionRef, self.mountPoint as CFURL) else {
            return
        }
        guard let diskInfo : NSDictionary = DADiskCopyDescription(disk) else {
            return
        }
        let volumeUUIDKey = kDADiskDescriptionVolumeUUIDKey
        let diskID = diskInfo[volumeUUIDKey]
        if let volID = CFUUIDCreateString(kCFAllocatorDefault, (diskID as! CFUUID)) as String? {
            self.volumeIdentifier = volID
        }
    }
}
