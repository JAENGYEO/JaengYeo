//
//  SubCategoryEntity+CoreDataProperties.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/2/26.
//
//

import Foundation
import CoreData


public typealias SubCategoryEntityCoreDataPropertiesSet = NSSet

extension SubCategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubCategoryEntity> {
        return NSFetchRequest<SubCategoryEntity>(entityName: "SubCategoryEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var userId: String?
    @NSManaged public var mainCategory: String
    @NSManaged public var name: String
    @NSManaged public var iconName: String?
    @NSManaged public var thumbnailKey: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String
}

extension SubCategoryEntity : Identifiable {

}

extension SubCategoryEntity {
    var toDomain: SubCategory {
        SubCategory(
            id: id,
            userId: userId.flatMap { UUID(uuidString: $0) },
            mainCategory: mainCategory,
            name: name,
            iconName: iconName,
            thumbnailKey: thumbnailKey,
            sortOrder: Int(sortOrder),
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }
}
