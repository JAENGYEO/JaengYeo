//
//  MidCategoryEntity+CoreDataClass.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//
//

import Foundation
import CoreData

public typealias MidCategoryEntityCoreDataClassSet = NSSet

@objc(MidCategoryEntity)
public class MidCategoryEntity: NSManagedObject {
    static let className = "MidCategoryEntity"
    
    enum Keys{
        static let id = "id"
        static let userId = "userId"
        static let mainCategory = "mainCategory"
        static let name = "name"
        static let iconName = "iconName"
        static let sortOrder = "sortOrder"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let syncStatus = "syncStatus"
    }
}
