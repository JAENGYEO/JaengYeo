//
//  WidgetPresetEntity+CoreDataProperties.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//
//

public import Foundation
public import CoreData


public typealias WidgetPresetEntityCoreDataPropertiesSet = NSSet

extension WidgetPresetEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WidgetPresetEntity> {
        return NSFetchRequest<WidgetPresetEntity>(entityName: "WidgetPresetEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var productIDsData: Data
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

}

extension WidgetPresetEntity : Identifiable {

}
