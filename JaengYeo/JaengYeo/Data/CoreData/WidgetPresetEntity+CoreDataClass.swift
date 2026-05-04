//
//  WidgetPresetEntity+CoreDataClass.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/30/26.
//
//

public import Foundation
public import CoreData

public typealias WidgetPresetEntityCoreDataClassSet = NSSet

@objc(WidgetPresetEntity)
public class WidgetPresetEntity: NSManagedObject {
    static let className = "WidgetPresetEntity"
}
