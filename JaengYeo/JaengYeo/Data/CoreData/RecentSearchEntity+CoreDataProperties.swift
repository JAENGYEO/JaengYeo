//
//  RecentSearchEntity+CoreDataProperties.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/23/26.
//
//

public import Foundation
public import CoreData


public typealias RecentSearchEntityCoreDataPropertiesSet = NSSet

extension RecentSearchEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecentSearchEntity> {
        return NSFetchRequest<RecentSearchEntity>(entityName: "RecentSearchEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var keyword: String
    @NSManaged public var searchedAt: Date

}

extension RecentSearchEntity : Identifiable {

}
