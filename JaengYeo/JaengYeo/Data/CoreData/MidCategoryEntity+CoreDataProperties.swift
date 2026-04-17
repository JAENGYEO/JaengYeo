//
//  MidCategoryEntity+CoreDataProperties.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//
//

import Foundation
import CoreData


public typealias MidCategoryEntityCoreDataPropertiesSet = NSSet

extension MidCategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MidCategoryEntity> {
        return NSFetchRequest<MidCategoryEntity>(entityName: "MidCategoryEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var userId: String?
    @NSManaged public var mainCategory: String
    @NSManaged public var name: String
    @NSManaged public var iconName: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String

}

extension MidCategoryEntity : Identifiable {

}

extension MidCategoryEntity {
    var toDomain: MidCategory {
        MidCategory(
            id: id,
            userId: userId.flatMap { UUID(uuidString: $0) },
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            sortOrder: Int(sortOrder),
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }
}
