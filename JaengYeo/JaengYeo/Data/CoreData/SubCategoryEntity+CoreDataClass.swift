//
//  SubCategoryEntity+CoreDataClass.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//
//

import Foundation
import CoreData

public typealias SubCategoryEntityCoreDataClassSet = NSSet

@objc(SubCategoryEntity)
public class SubCategoryEntity: NSManagedObject {
    static let className = "SubCategoryEntity"
    
    enum Keys {
        static let id = "id"
        static let userId = "userId"
        static let mainCategory = "mainCategory"
        static let name = "name"
        static let iconName = "iconName"
        static let thumbnailKey = "thumbnailKey"
        static let sortOrder = "sortOrder"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let syncStatus = "syncStatus"
    }
}
