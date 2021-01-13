//
//  F3VolumeDataSource.swift
//  F3XS
//
//  Created by Volker Runkel on 07.01.21.
//

import Foundation
import Cocoa
import DiskArbitration
import Combine

class F3VolumeDataSource: NSObject {
    
    let volumeURL = URL(fileURLWithPath: "/Volumes")
    
    var volumes: Array<F3Volume>?
    @objc dynamic var updated: Int = 0
    
    private var diskObservationSession: DASession?
    private var diskObservationQ: DispatchQueue?
    
    private var fetchInProgress: Bool = false
    
    override init() {
        super.init()
        self.startObservingDisks()
    }
    
    func fetchVolumes() {
        self.fetchInProgress = true
        let volumeKeys = [URLResourceKey.isVolumeKey, URLResourceKey.isWritableKey, URLResourceKey.volumeIdentifierKey]
        let enumerationOptions : FileManager.DirectoryEnumerationOptions = [FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants , FileManager.DirectoryEnumerationOptions.skipsPackageDescendants , FileManager.DirectoryEnumerationOptions.skipsHiddenFiles]
        
        let enumerator = FileManager.default.enumerator(at: volumeURL, includingPropertiesForKeys: volumeKeys, options: enumerationOptions) { (anURL, error) -> Bool in
            Swift.print(error)
            return true
        }
        
        var url: URL?
        var volumes = Array<F3Volume>()
        url = enumerator?.nextObject() as? URL
        
        while url != nil {
            
            var isUsable : Bool = false
            
            if let resouceValues = try? url?.resourceValues(forKeys: [.isVolumeKey, .isWritableKey, .volumeIsEjectableKey, .volumeIsReadOnlyKey]) {
                let isVolume : Bool = resouceValues.isVolume ?? false
                let isWritable : Bool = !(resouceValues.volumeIsReadOnly ?? true)
                let isEjectable: Bool = resouceValues.volumeIsEjectable ?? false
                isUsable = isVolume && isWritable && isEjectable
            }
            
            let volume : F3Volume = F3Volume(mountPoint: url!, _usable: isUsable, _volumeIdentifier: nil, attributes: nil)
            volumes.append(volume)
            url = enumerator?.nextObject() as? URL
        }
        self.volumes = volumes
        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
            self.updated += 1
        }
    }
    
    let _volumeManagerDiskArbitrationCallback : @convention(c) (_ disk: DADisk, _ context: UnsafeMutableRawPointer?) -> Void = { (disk, context) in
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            let mySelf = Unmanaged<F3VolumeDataSource>.fromOpaque(context!).takeUnretainedValue()
            mySelf.fetchVolumes()
        }
    }
    
    let _diskDescriptionChanged : @convention(c) (_ disk: DADisk, _ keys: CFArray, _ context: UnsafeMutableRawPointer?) -> Void = { (disk, keys, context) in
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            let mySelf = Unmanaged<F3VolumeDataSource>.fromOpaque(context!).takeUnretainedValue()
            mySelf.fetchVolumes()
        }
    }
    
    private func startObservingDisks() {
        if self.diskObservationQ == nil || self.diskObservationSession == nil {
            self.diskObservationQ = DispatchQueue(label: "F3XS Disk Observation", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
            self.diskObservationSession = DASessionCreate(kCFAllocatorDefault)
            DASessionSetDispatchQueue(self.diskObservationSession!, self.diskObservationQ)
        }
        
        DARegisterDiskAppearedCallback(self.diskObservationSession!, nil, _volumeManagerDiskArbitrationCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        DARegisterDiskDisappearedCallback(self.diskObservationSession!, nil, _volumeManagerDiskArbitrationCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        let descriptionKeys = [kDADiskDescriptionVolumeNameKey]
        DARegisterDiskDescriptionChangedCallback(self.diskObservationSession!, nil, (descriptionKeys as CFArray), _diskDescriptionChanged, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
    }
    
}
