//
//  SDCard+CoreDataProperties.swift
//  F3XSwift
//
//  Created by Volker Runkel on 22.01.21.
//  Copyright © 2021 ecoObs GmbH. All rights reserved.
//
//

import Foundation
import CoreData


extension SDCard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SDCard> {
        return NSFetchRequest<SDCard>(entityName: "SDCard")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastTestedAt: Date?
    @NSManaged public var lastResult: Bool
    @NSManaged public var lastRawRead: String?
    @NSManaged public var lastRawWrite: String?

}
